ALTER TABLE orders DROP CONSTRAINT check_state_and_reject_reason_consistency;

ALTER TABLE orders
ADD CONSTRAINT check_state_and_reject_reason_consistency
CHECK (
  (state = ANY (ARRAY['submitted', 'rejected', 'canceled', 'approved']))
  AND reject_reason IS NULL OR state = 'rejected' AND reject_reason IS NOT NULL
);

--------------------------------------------------------------------------------------------

ALTER TABLE orders DROP CONSTRAINT check_valid_state;

ALTER TABLE orders
ADD CONSTRAINT check_valid_state
CHECK (state = ANY (ARRAY['submitted', 'rejected', 'canceled', 'approved']));

--------------------------------------------------------------------------------------------

ALTER TABLE reservations DROP CONSTRAINT check_allowed_statuses;

ALTER TABLE reservations
ADD CONSTRAINT check_allowed_statuses
CHECK (
  status = ANY (
    ARRAY['draft',
          'unsubmitted',
          'submitted',
          'canceled',
          'rejected',
          'approved',
          'signed',
          'closed']
  )
);

--------------------------------------------------------------------------------------------

ALTER TABLE reservations DROP CONSTRAINT check_order_id_for_different_statuses_of_item_line;

ALTER TABLE reservations
ADD CONSTRAINT check_order_id_for_different_statuses_of_item_line
CHECK (
  type = 'ItemLine' AND
    ((status = ANY (ARRAY['draft', 'unsubmitted'])) AND order_id IS NULL
    OR (status = ANY (ARRAY['submitted', 'rejected', 'canceled'])) AND order_id IS NOT NULL
    OR (status = ANY (ARRAY['approved', 'signed', 'closed'])))
  OR type = 'OptionLine' AND (status = ANY (ARRAY['approved', 'signed', 'closed']))
);

--------------------------------------------------------------------------------------------

ALTER TABLE reservations DROP CONSTRAINT check_valid_status_and_contract_id;

ALTER TABLE reservations
ADD CONSTRAINT check_valid_status_and_contract_id
CHECK (
  (status = ANY (ARRAY['draft', 'unsubmitted', 'submitted', 'rejected', 'canceled', 'approved'])) AND contract_id IS NULL
  OR (status = ANY (ARRAY['signed', 'closed'])) AND contract_id IS NOT NULL
);

--------------------------------------------------------------------------------------------

DROP TRIGGER trigger_check_item_line_state_consistency ON reservations;
DROP FUNCTION check_item_line_state_consistency();

CREATE FUNCTION check_item_line_state_consistency()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
  IF (
    (NEW.type = 'ItemLine' AND NEW.status = 'submitted' AND EXISTS (
        SELECT 1
        FROM orders
        WHERE id = NEW.order_id AND state <> 'submitted')) OR
    (NEW.type = 'ItemLine' AND NEW.status = 'rejected' AND EXISTS (
        SELECT 1
        FROM orders
        WHERE id = NEW.order_id AND state <> 'rejected')) OR
    (NEW.type = 'ItemLine' AND NEW.status = 'canceled' AND EXISTS (
        SELECT 1
        FROM orders
        WHERE id = NEW.order_id AND state <> 'canceled')) OR
    (NEW.type = 'ItemLine' AND NEW.status IN ('approved', 'signed', 'closed') AND EXISTS (
        SELECT 1
        FROM orders
        WHERE id = NEW.order_id AND state <> 'approved'))
    )
    THEN
      RAISE EXCEPTION 'state between item line and order is inconsistent';
  END IF;

  RETURN NEW;
END;
$BODY$; 

CREATE CONSTRAINT TRIGGER trigger_check_item_line_state_consistency
AFTER INSERT OR UPDATE 
ON reservations
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE check_item_line_state_consistency();
