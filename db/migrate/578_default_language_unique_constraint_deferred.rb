class DefaultLanguageUniqueConstraintDeferred < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      DROP TRIGGER IF EXISTS trigger_check_exactly_one_default_language ON languages;
      DROP FUNCTION IF EXISTS check_exactly_one_default_language();

      CREATE OR REPLACE FUNCTION check_exactly_one_default_language()
      RETURNS TRIGGER AS $$
      BEGIN
        IF ((SELECT count(*) FROM languages WHERE "default") != 1 OR
            EXISTS (SELECT TRUE FROM languages WHERE "default" and not active))
        THEN
          RAISE EXCEPTION 'There must be exactly one default language which is also active.';
        END IF;
        RETURN NEW;
      END;
      $$ language 'plpgsql';

      CREATE CONSTRAINT TRIGGER trigger_check_exactly_one_default_language
      AFTER INSERT OR UPDATE OR DELETE
      ON languages
      INITIALLY DEFERRED
      FOR EACH ROW EXECUTE PROCEDURE check_exactly_one_default_language();
    SQL
  end

  def down
    execute <<-SQL.strip_heredoc
      DROP TRIGGER IF EXISTS trigger_check_exactly_one_default_language ON languages;
      DROP FUNCTION IF EXISTS check_exactly_one_default_language();
    SQL
  end
end
