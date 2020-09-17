class AddDraftStatusForReservations < ActiveRecord::Migration[5.0]
  def up
    execute "DROP VIEW visits"
    execute "ALTER TABLE reservations DROP CONSTRAINT check_order_id_for_different_statuses_of_item_line"
    execute "ALTER TABLE reservations DROP CONSTRAINT check_valid_status_and_contract_id"
    
    change_column(:reservations, :status, :text, null: false)

    execute <<-SQL.strip_heredoc
      ALTER TABLE reservations
        ADD CONSTRAINT check_allowed_statuses
        CHECK (
          status IN ('draft', 'unsubmitted', 'submitted', 'rejected', 'approved', 'signed', 'closed')
        );
    SQL

    execute <<-SQL
      ALTER TABLE reservations
      ADD CONSTRAINT check_order_id_for_different_statuses_of_item_line
      CHECK ((type = 'ItemLine' AND
              ((status IN ('draft', 'unsubmitted') AND order_id IS NULL) OR
               (status IN ('submitted', 'rejected') AND order_id IS NOT NULL) OR
               (status IN ('approved', 'signed', 'closed')))) OR
             (type = 'OptionLine' AND status IN ('approved', 'signed', 'closed')))
    SQL

    execute <<-SQL
      ALTER TABLE reservations
      ADD CONSTRAINT check_valid_status_and_contract_id
      CHECK (
        (status IN ('draft', 'unsubmitted', 'submitted', 'approved', 'rejected') AND contract_id IS NULL) OR
        (status IN ('signed', 'closed') AND contract_id IS NOT NULL)
      )
    SQL

    execute IO.read(
      Pathname(__FILE__).dirname.join("215_create_visits_view.sql")
    )

    execute "DROP TYPE reservation_status"
  end

  def down
    execute "DROP VIEW visits"
    execute "ALTER TABLE reservations DROP CONSTRAINT check_order_id_for_different_statuses_of_item_line"
    execute "ALTER TABLE reservations DROP CONSTRAINT check_valid_status_and_contract_id"
    execute "ALTER TABLE reservations DROP CONSTRAINT check_allowed_statuses"

    execute <<~SQL
      CREATE TYPE reservation_status AS ENUM  ('unsubmitted', 'submitted', 'rejected', 'approved', 'signed', 'closed');
    SQL

    execute <<~SQL
      ALTER TABLE reservations ALTER COLUMN status TYPE reservation_status USING status::reservation_status;
    SQL

    execute <<-SQL
      ALTER TABLE reservations
      ADD CONSTRAINT check_order_id_for_different_statuses_of_item_line
      CHECK ((type = 'ItemLine' AND
              ((status = 'unsubmitted' AND order_id IS NULL) OR
               (status IN ('submitted', 'rejected') AND order_id IS NOT NULL) OR
               (status IN ('approved', 'signed', 'closed')))) OR
             (type = 'OptionLine' AND status IN ('approved', 'signed', 'closed')))
    SQL

    execute <<-SQL
      ALTER TABLE reservations
      ADD CONSTRAINT check_valid_status_and_contract_id
      CHECK (
        (status IN ('unsubmitted', 'submitted', 'approved', 'rejected') AND contract_id IS NULL) OR
        (status IN ('signed', 'closed') AND contract_id IS NOT NULL)
      )
    SQL

    execute IO.read(
      Pathname(__FILE__).dirname.join("215_create_visits_view.sql")
    )
  end
end
