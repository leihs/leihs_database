class VersionNotBlank < ActiveRecord::Migration[7.2]
  def up
    collisions = select_all(<<~'SQL')
      SELECT m.id, m.product FROM models m
      WHERE m.version ~ '^\s*$'
        AND EXISTS (SELECT 1 FROM models o
                    WHERE o.id <> m.id
                      AND m.product = CASE WHEN o.version ~ '^\s*$' THEN o.product
                                           ELSE o.name END)
    SQL

    if collisions.any?
      list = collisions.map { |row| "#{row["id"]} (#{row["product"]})" }.join("\n  ")
      raise <<~MSG
        Models with blank version clash with a model of the same product and no version.
        Merge or rename them manually before running this migration:
          #{list}
      MSG
    end

    execute <<~'SQL'
      UPDATE models SET version = NULL WHERE version ~ '^\s*$';
      UPDATE options SET version = NULL WHERE version ~ '^\s*$';

      ALTER TABLE models
      ADD CONSTRAINT models_version_not_blank
      CHECK (version IS NULL OR version !~ '^\s*$');

      ALTER TABLE options
      ADD CONSTRAINT options_version_not_blank
      CHECK (version IS NULL OR version !~ '^\s*$');
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE models DROP CONSTRAINT models_version_not_blank;
      ALTER TABLE options DROP CONSTRAINT options_version_not_blank;
    SQL
  end
end
