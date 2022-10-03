class SettingsHomePageImageUrl < ActiveRecord::Migration[5.0]
  def up
    add_column(:settings, :home_page_image_url, :string, limit: 2000)

    execute <<~SQL
      ALTER TABLE settings 
      ADD CONSTRAINT no_whitespace_characters_for_home_page_image_url_check
      CHECK (home_page_image_url !~ '^\\s*$')
    SQL
  end

  def down
    remove_column(:settings, :home_page_image_url)
  end
end
