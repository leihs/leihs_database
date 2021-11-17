class EnforceModelIdOrOptionIdOnReservations < ActiveRecord::Migration[5.0]
  def up
    # add constraint
    execute <<~SQL
      ALTER TABLE reservations
      ADD CONSTRAINT check_model_id_or_option_id_on_reservations
      CHECK (model_id IS NOT NULL OR option_id IS NOT NULL)
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE reservations
      DROP CONSTRAINT check_model_id_or_option_id_on_reservations
    SQL
  end
end
