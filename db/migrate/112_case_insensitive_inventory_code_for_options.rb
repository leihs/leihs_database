class CaseInsensitiveInventoryCodeForOptions < ActiveRecord::Migration
  class MigrationOption < ActiveRecord::Base
    self.table_name = 'options'
  end

  def up
    MigrationOption.where("inventory_code IS NULL").each_with_index do |mo, idx|
      mo.update_attributes! inventory_code: sprintf("%05d",idx)
    end

    MigrationOption.select("lower(inventory_code) AS lic") \
      .group("lower(inventory_code)").having("count(*) > 1").map(&:lic).each do |lic|
      MigrationOption.where("lower(inventory_code) = ?", lic).each_with_index do |mo,idx|
        mo.update_attributes! inventory_code: "#{mo.inventory_code}_#{idx}"
      end
    end

    execute <<-SQL
      ALTER TABLE options ALTER COLUMN inventory_code SET NOT NULL;
      ALTER TABLE options ALTER COLUMN inventory_code SET default uuid_generate_v4()::text;
      CREATE UNIQUE INDEX case_insensitive_inventory_code_for_options
        ON options (lower(inventory_code));
    SQL
  end
end
