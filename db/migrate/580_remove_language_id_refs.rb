class RemoveLanguageIdRefs < ActiveRecord::Migration[5.0]
  def up
    remove_column :users, :language_id
    remove_column :mail_templates, :language_id
  end
end
