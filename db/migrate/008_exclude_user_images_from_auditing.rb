class ExcludeUserImagesFromAuditing < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL.strip_heredoc

      CREATE OR REPLACE FUNCTION jsonb_changed(jold jsonb, jnew jsonb) RETURNS jsonb
          LANGUAGE plpgsql
          AS $$
      DECLARE
        result JSONB := '{}'::JSONB;
        k TEXT;
        v_new JSONB;
        v_old JSONB;
      BEGIN
        FOR k IN SELECT * FROM jsonb_object_keys(jold || jnew) LOOP
          IF k = 'img256_url' THEN CONTINUE; END IF;
          if k = 'img32_url' THEN CONTINUE; END IF;
          IF k = 'updated_at' THEN CONTINUE; END IF;
          if jnew ? k
            THEN v_new := jnew -> k;
            ELSE v_new := 'null'::JSONB; END IF;
          if jold ? k
            THEN v_old := jold -> k;
            ELSE v_old := 'null'::JSONB; END IF;
          IF v_new = v_old THEN CONTINUE; END IF;
          result := result || jsonb_build_object(k, jsonb_build_array(v_old, v_new));
        END LOOP;
        RETURN result;
      END;
      $$;

    SQL
  end
end
