class CreateTranslationTables < ActiveRecord::Migration[5.0]
  def change
    create_table :translations_default, id: :uuid do |t|
      t.text :key, null: false
      t.text :translation, null: false
      t.text :language_locale, null: false
    end

    add_foreign_key(:translations_default, :languages,
                    column: :language_locale,
                    primary_key: :locale,
                    on_delete: :cascade)

    add_index(:translations_default, [:key, :language_locale], unique: true)

    create_table :translations_instance, id: :uuid do |t|
      t.text :key, null: false
      t.text :translation, null: false
      t.text :language_locale, null: false
    end

    add_foreign_key(:translations_instance, :languages,
                    column: :language_locale,
                    primary_key: :locale,
                    on_delete: :cascade)

    add_index(:translations_instance, [:key, :language_locale], unique: true)

    create_table :translations_user, id: :uuid do |t|
      t.text :key, null: false
      t.text :translation, null: false
      t.text :language_locale, null: false
      t.uuid :user_id, null: false
    end

    add_foreign_key(:translations_user, :languages,
                    column: :language_locale,
                    primary_key: :locale,
                    on_delete: :cascade)

    add_foreign_key :translations_user, :users, on_delete: :cascade

    add_index(:translations_user, [:key, :language_locale, :user_id], unique: true)

    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE OR REPLACE FUNCTION leihs_translate(k text, l text, u_id uuid DEFAULT NULL)
          RETURNS text AS $$
          BEGIN
            RETURN COALESCE(
              ( SELECT translation FROM translations_user WHERE key = k AND user_id = u_id AND language_locale = l ),
              ( SELECT translation FROM translations_instance WHERE key = k AND language_locale = l ),
              ( SELECT translation FROM translations_default WHERE key = k AND language_locale = l )
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
                FROM translations_user AS ut
                WHERE ut.user_id = u_id
                UNION
                SELECT it.key, it.language_locale, ARRAY['2', it.translation] as ranked_translation
                FROM translations_instance AS it
                UNION
                SELECT dt.key, dt.language_locale, ARRAY['1', dt.translation] AS ranked_translation
                FROM translations_default AS dt
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
