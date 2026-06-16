class AddTemplateToEmails < ActiveRecord::Migration[6.1]
  def change
    add_column :emails, :template, :text
  end
end
