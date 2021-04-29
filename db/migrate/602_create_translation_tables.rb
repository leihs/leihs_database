class CreateTranslationTables < ActiveRecord::Migration[5.0]
  def change
    create_table :default_translations, id: :uuid do |t|
      t.text :key, null: false
      t.text :translation, null: false
      t.text :language_locale, null: false
    end

    add_foreign_key(:default_translations, :languages,
                    column: :language_locale,
                    primary_key: :locale,
                    on_delete: :cascade)

    add_index(:default_translations, [:key, :language_locale], unique: true)

    create_table :instance_translations, id: :uuid do |t|
      t.text :key, null: false
      t.text :translation, null: false
      t.text :language_locale, null: false
    end

    add_foreign_key(:instance_translations, :languages,
                    column: :language_locale,
                    primary_key: :locale,
                    on_delete: :cascade)

    add_index(:instance_translations, [:key, :language_locale], unique: true)

    create_table :user_translations, id: :uuid do |t|
      t.text :key, null: false
      t.text :translation, null: false
      t.text :language_locale, null: false
      t.uuid :user_id, null: false
    end

    add_foreign_key(:user_translations, :languages,
                    column: :language_locale,
                    primary_key: :locale,
                    on_delete: :cascade)

    add_foreign_key :user_translations, :users, on_delete: :cascade

    add_index(:user_translations, [:key, :language_locale, :user_id], unique: true)

    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE OR REPLACE FUNCTION leihs_translate(k text, l text, u_id uuid DEFAULT NULL)
          RETURNS text AS $$
          BEGIN
            RETURN COALESCE(
              ( SELECT translation FROM user_translations WHERE key = k AND user_id = u_id AND language_locale = l ),
              ( SELECT translation FROM instance_translations WHERE key = k AND language_locale = l ),
              ( SELECT translation FROM default_translations WHERE key = k AND language_locale = l )
            );
          END;
          $$ LANGUAGE plpgsql;
        SQL

        execute <<~SQL
          CREATE OR REPLACE FUNCTION get_translations(u_id uuid default null)
            RETURNS TABLE (key text, language_locale text, translation text) AS 
          $func$
          BEGIN
            RETURN QUERY
            SELECT rtw.key, rtw.language_locale, rtw.ranked_translation_winner[2]
            FROM (
              SELECT rt.key, rt.language_locale, MAX(rt.ranked_translation) AS ranked_translation_winner
              FROM (
                SELECT ut.key, ut.language_locale, ARRAY['3', ut.translation] AS ranked_translation
                FROM user_translations AS ut
                WHERE ut.user_id = u_id
                UNION
                SELECT it.key, it.language_locale, ARRAY['2', it.translation] as ranked_translation
                FROM instance_translations AS it
                UNION
                SELECT dt.key, dt.language_locale, ARRAY['1', dt.translation] AS ranked_translation
                FROM default_translations AS dt
              ) AS rt
              GROUP BY rt.key, rt.language_locale
            ) AS rtw;
          END
          $func$ LANGUAGE plpgsql;
        SQL
      end

      dir.down do
        execute <<~SQL
          DROP FUNCTION IF EXISTS leihs_translate(text, text, uuid);
        SQL

        execute <<~SQL
          DROP FUNCTION IF EXISTS get_translations(uuid);
        SQL
      end
    end
  end
end
