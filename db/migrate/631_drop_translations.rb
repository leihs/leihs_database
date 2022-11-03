class DropTranslations < ActiveRecord::Migration[5.0]

  def up
    execute <<-SQL
      DROP TABLE IF EXISTS
          translations_default,
          translations_instance,
          translations_user
        CASCADE;
    SQL
  end

end

