class LanguagesPkey < ActiveRecord::Migration[5.0]

  def up
    rename_column :languages, :locale_name, :locale
    add_column :mail_templates, :language_locale, :text
    add_column :users, :language_locale, :text

    execute <<-SQL

      UPDATE users
      SET language_locale = languages.locale
      FROM languages
      WHERE language_id = languages.id;

      UPDATE mail_templates
      SET language_locale = languages.locale
      FROM languages
      WHERE language_id = languages.id;

    SQL

    remove_foreign_key :users, :languages
    remove_foreign_key :mail_templates, :languages

    remove_column :languages, :id

    execute 'ALTER TABLE languages ADD PRIMARY KEY (locale)'

    add_foreign_key :users, :languages, column: :language_locale, primary_key: :locale
    add_foreign_key :mail_templates, :languages, column: :language_locale, primary_key: :locale

    change_column :mail_templates, :language_locale, :text, null: false

  end

end
