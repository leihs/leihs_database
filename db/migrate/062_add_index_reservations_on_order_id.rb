class AddIndexReservationsOnOrderId < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      CREATE INDEX index_reservations_on_order_id
        ON reservations (order_id);
      CREATE INDEX index_reservations_on_order_id_and_start_date
        ON reservations (order_id, start_date);
      CREATE INDEX index_reservations_on_order_id_and_end_date
        ON reservations (order_id, end_date);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX IF EXISTS index_reservations_on_order_id;
      DROP INDEX IF EXISTS index_reservations_on_order_id_and_start_date;
      DROP INDEX IF EXISTS index_reservations_on_order_id_and_end_date;
    SQL
  end
end
