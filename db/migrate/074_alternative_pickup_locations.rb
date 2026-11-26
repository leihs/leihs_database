class AlternativePickupLocations < ActiveRecord::Migration[7.2]
  include Leihs::MigrationHelper

  def up
    add_column :inventory_pools, :transfer_buffer_before_pick_up, :integer,
      null: false, default: 1
    add_column :inventory_pools, :transfer_buffer_after_drop_off, :integer,
      null: false, default: 1
    add_column :inventory_pools, :default_pickup_location_name, :text,
      null: false, default: "Hauptlager"
    add_column :inventory_pools, :enable_alternative_pickup_locations, :boolean,
      null: false, default: false

    add_column :models, :transportable, :boolean, null: false, default: true

    create_table :pickup_locations, id: :uuid do |t|
      t.uuid :inventory_pool_id, null: false
      t.text :name, null: false
      t.text :description
      t.boolean :active, null: false, default: true
    end

    add_auto_timestamps(:pickup_locations,
      created_at_null: false,
      updated_at_null: false)

    add_foreign_key :pickup_locations, :inventory_pools,
      column: :inventory_pool_id,
      on_delete: :cascade

    add_index :pickup_locations, :inventory_pool_id

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

    execute <<~SQL
      DROP TRIGGER IF EXISTS update_updated_at_column_of_pickup_locations ON pickup_locations;
    SQL

    drop_table :pickup_locations

    remove_column :models, :transportable

    remove_column :inventory_pools, :enable_alternative_pickup_locations
    remove_column :inventory_pools, :default_pickup_location_name
    remove_column :inventory_pools, :transfer_buffer_after_drop_off
    remove_column :inventory_pools, :transfer_buffer_before_pick_up
  end
end
