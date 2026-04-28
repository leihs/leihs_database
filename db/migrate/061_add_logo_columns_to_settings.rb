class AddLogoColumnsToSettings < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      ALTER TABLE settings
        ADD COLUMN logo_light text,
        ADD COLUMN logo_dark text,
        ADD CONSTRAINT logo_light_max_size CHECK (octet_length(logo_light) <= 1572864),
        ADD CONSTRAINT logo_dark_max_size CHECK (octet_length(logo_dark) <= 1572864);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE settings
        DROP CONSTRAINT IF EXISTS logo_light_max_size,
        DROP CONSTRAINT IF EXISTS logo_dark_max_size,
        DROP COLUMN IF EXISTS logo_light,
        DROP COLUMN IF EXISTS logo_dark;
    SQL
  end
end
