class AddPickupLocationToReservations < ActiveRecord::Migration[7.2]
  def up
    add_column :reservations, :pickup_location_id, :uuid
    add_column :reservations, :sent_to_pickup_location_at, :datetime
    add_column :reservations, :sent_to_pickup_location_by_user_id, :uuid
    add_column :reservations, :sent_back_to_main_location_at, :datetime
    add_column :reservations, :sent_back_to_main_location_by_user_id, :uuid

    add_foreign_key :reservations, :pickup_locations, column: :pickup_location_id
    add_foreign_key :reservations, :users, column: :sent_to_pickup_location_by_user_id
    add_foreign_key :reservations, :users, column: :sent_back_to_main_location_by_user_id

    add_index :reservations, :pickup_location_id

    execute <<~SQL
      CREATE FUNCTION check_reservation_pickup_location_inventory_pool_id_consistency() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
          BEGIN
            IF (
              NEW.pickup_location_id IS NOT NULL
              AND NEW.inventory_pool_id != (
                SELECT inventory_pool_id
                FROM pickup_locations
                WHERE id = NEW.pickup_location_id)
            )
            THEN
              RAISE EXCEPTION 'inventory_pool_id between reservation and pickup_location is inconsistent';
            END IF;

            RETURN NEW;
          END;
          $$;

      CREATE CONSTRAINT TRIGGER trigger_check_reservation_pickup_location_inventory_pool_id
        AFTER INSERT OR UPDATE ON public.reservations
        DEFERRABLE INITIALLY DEFERRED
        FOR EACH ROW EXECUTE FUNCTION check_reservation_pickup_location_inventory_pool_id_consistency();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS trigger_check_reservation_pickup_location_inventory_pool_id ON reservations;
      DROP FUNCTION IF EXISTS check_reservation_pickup_location_inventory_pool_id_consistency();
    SQL

    remove_index :reservations, :pickup_location_id

    remove_foreign_key :reservations, column: :sent_back_to_main_location_by_user_id
    remove_foreign_key :reservations, column: :sent_to_pickup_location_by_user_id
    remove_foreign_key :reservations, column: :pickup_location_id

    remove_column :reservations, :sent_back_to_main_location_by_user_id
    remove_column :reservations, :sent_back_to_main_location_at
    remove_column :reservations, :sent_to_pickup_location_by_user_id
    remove_column :reservations, :sent_to_pickup_location_at
    remove_column :reservations, :pickup_location_id
  end
end
