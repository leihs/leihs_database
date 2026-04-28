module Leihs
  module MigrationHelper
    extend ActiveSupport::Concern

    def create_trgm_index(t, c)
      table = validated_identifier(t, :table)
      column = validated_identifier(c, :column)
      execute "CREATE INDEX ON #{quote_table_name(table)} USING gin(#{quote_column_name(column)} gin_trgm_ops);"
    end

    def create_text_index(t, c)
      table = validated_identifier(t, :table)
      column = validated_identifier(c, :column)
      reversible do |dir|
        dir.up do
          execute "CREATE INDEX ON #{quote_table_name(table)} USING gin(to_tsvector('english',#{quote_column_name(column)}));"
        end
      end
    end

    def auto_update_searchable table_name, columns
      table = validated_identifier(table_name, :table)
      quoted_table = quote_table_name(table)
      function_name = "#{table}_update_searchable_column"
      trigger_name = "update_searchable_column_of_#{table}"
      searchable_sql =
        columns.map { |c| "COALESCE(#{quote_column_name(validated_identifier(c, :column))}::text, '')" }
          .join(" || ' ' || ")
      new_searchable_sql =
        columns.map { |c| "COALESCE(NEW.#{quote_column_name(validated_identifier(c, :column))}::text, '')" }
          .join(" || ' ' || ")
      changed_when_sql =
        columns.map { |c| "(OLD.#{quote_column_name(validated_identifier(c, :column))} IS DISTINCT FROM NEW.#{quote_column_name(validated_identifier(c, :column))})" }
          .join(" OR ")

      reversible do |dir|
        dir.up do
          execute "ALTER TABLE #{quoted_table} DROP COLUMN IF EXISTS searchable;"
          execute "ALTER TABLE #{quoted_table} ADD COLUMN searchable text DEFAULT ''::text NOT NULL;"

          execute <<-SQL.strip_heredoc
            -- ALTER TABLE #{quoted_table} DISABLE TRIGGER update_updated_at_column_of_#{table};
            UPDATE #{quoted_table} SET searchable = ( #{searchable_sql} ) ;
            -- ALTER TABLE #{quoted_table}  ENABLE TRIGGER update_updated_at_column_of_#{table};
          SQL

          create_trgm_index table, :searchable
          create_text_index table, :searchable

          execute <<-SQL.strip_heredoc
            CREATE OR REPLACE FUNCTION #{function_name}()
            RETURNS TRIGGER AS $$
            BEGIN
               NEW.searchable = #{new_searchable_sql} ;
               RETURN NEW;
            END;
            $$ language 'plpgsql';
          SQL

          execute <<-SQL.strip_heredoc
            CREATE TRIGGER #{trigger_name}
            BEFORE INSERT OR UPDATE ON #{quoted_table} FOR EACH ROW
              -- WHEN ( #{changed_when_sql} )
            EXECUTE PROCEDURE
          #{function_name}();
          SQL
        end

        dir.down do
          execute " DROP TRIGGER  #{trigger_name} ON #{quoted_table} "
        end
      end
    end

    def add_auto_timestamps(table_name,
      created_at: true, updated_at: true,
      created_at_null: true, updated_at_null: true,
      timezone: true, table_with_autogen_columns: false,
      updated_at_trigger: true)
      table = validated_identifier(table_name, :table)
      quoted_table = quote_table_name(table)

      reversible do |dir|
        dir.up do
          with_or_without_tz = timezone ? "timestamp with time zone" : "timestamp without time zone"

          if created_at
            unless column_exists? table, :created_at
              add_column(table, :created_at, with_or_without_tz, null: created_at_null)
            end
            execute "ALTER TABLE #{quoted_table} ALTER COLUMN created_at SET DEFAULT now()"
          end

          if updated_at
            unless column_exists? table, :updated_at
              add_column(table, :updated_at, with_or_without_tz, null: updated_at_null)
            end
            execute "ALTER TABLE #{quoted_table} ALTER COLUMN updated_at SET DEFAULT now()"

            execute <<-SQL.strip_heredoc
              CREATE OR REPLACE FUNCTION update_updated_at_column()
              RETURNS TRIGGER AS $$
              BEGIN
                 NEW.updated_at = now();
                 RETURN NEW;
              END;
              $$ language 'plpgsql';
            SQL
          end

          if updated_at_trigger
            when_clause = table_with_autogen_columns ? "" : "WHEN (OLD.* IS DISTINCT FROM NEW.*)"

            execute <<-SQL.strip_heredoc
              CREATE TRIGGER update_updated_at_column_of_#{table}
              BEFORE UPDATE ON #{quoted_table} FOR EACH ROW
              #{when_clause}
              EXECUTE PROCEDURE
              update_updated_at_column();
            SQL
          end
        end

        dir.down do
          execute " DROP TRIGGER IF EXISTS update_updated_at_column_of_#{table} ON #{quoted_table} "
          if created_at
            remove_column(table, :created_at)
          end
          if updated_at
            remove_column(table, :updated_at)
          end
        end
      end
    end

    def set_timestamps_defaults(table_name)
      table = validated_identifier(table_name, :table)
      quoted_table = quote_table_name(table)
      reversible do |dir|
        dir.up do
          %w[created_at updated_at].each do |col|
            execute "ALTER TABLE #{quoted_table} ALTER COLUMN #{col} TYPE TIMESTAMP WITH TIME ZONE USING #{col}"
            # execute "ALTER TABLE #{table_name} ALTER COLUMN #{col} TYPE TIMESTAMP WITH TIME ZONE USING #{col} AT TIME ZONE 'UTC'"
            execute "ALTER TABLE #{quoted_table} ALTER COLUMN #{col} SET DEFAULT now()"
          end
        end
      end
    end

    def audit_table(table_name)
      table = validated_identifier(table_name, :table)
      quoted_table = quote_table_name(table)
      reversible do |dir|
        dir.up do
          execute <<-SQL.strip_heredoc
            CREATE TRIGGER audited_change_on_#{table}
              AFTER DELETE OR INSERT OR UPDATE ON #{quoted_table}
              FOR EACH ROW 
              EXECUTE PROCEDURE audit_change();
          SQL
        end
      end
    end

    private

    def validated_identifier(name, kind)
      id = name.to_s
      unless /\A[a-zA-Z_][a-zA-Z0-9_]*\z/.match?(id)
        raise ArgumentError, "Invalid #{kind} identifier: #{name.inspect}"
      end
      id
    end
  end
end
