class AddPublicImageCaching < ActiveRecord::Migration[6.1]
  def change
    add_column :system_and_security_settings, :public_image_caching_enabled, :boolean, default: true
  end
end
