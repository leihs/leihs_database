class AddNameColumnToModelsAndOptions < ActiveRecord::Migration[7.2]
  def up
    remove_index :models, name: :unique_model_name_idx if index_exists?(:models, :name, name: :unique_model_name_idx)

    [:models, :options].each do |table|
      unless column_exists?(table, :name)
        execute <<~SQL
          ALTER TABLE #{table}
          ADD COLUMN name TEXT GENERATED ALWAYS AS (
            CASE
              WHEN version IS NULL THEN product
              ELSE product || ' ' || version
            END
          ) STORED
        SQL
      end
    end

    add_index :models, :name, unique: true, name: :unique_model_name_idx unless index_exists?(:models, :name, name: :unique_model_name_idx)
  end

  def down
    [:models, :options].each do |table|
      remove_column table, :name if column_exists?(table, :name)
    end
  end
end
