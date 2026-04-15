module Leihs
  module MigrationHelper
    extend ActiveSupport::Concern

    # Only unquoted PostgreSQL identifiers used by migrations (letters, digits, underscore).
    def validate_pg_identifier!(name, role = "identifier")
      s = name.to_s
      unless s.match?(/\A[a-z_][a-z0-9_]*\z/)
        raise ArgumentError, "invalid PostgreSQL #{role}: #{name.inspect}"
      end
      s
    end

    def quoted_table(name)
      connection.quote_table_name(validate_pg_identifier!(name, "table"))
    end

    def quoted_column(name)
      connection.quote_column_name(validate_pg_identifier!(name, "column"))
    end

    def create_trgm_index(t, c)
      tbl = quoted_table(t)
      col = quoted_column(c)
      execute "CREATE INDEX ON #{tbl} USING gin(#{col} gin_trgm_ops);"
    end

    def create_text_index(t, c)
      reversible do |dir|
        dir.up do
          tbl = quoted_table(t)
          col = quoted_column(c)
          execute "CREATE INDEX ON #{tbl} USING gin(to_tsvector('english',#{col}));"
        end
      end
    end

    def auto_update_searchable table_name, columns
      reversible do |dir|
        dir.up do
          tn = validate_pg_identifier!(table_name, "table")
          tbl = quoted_table(table_name)
          col_bares = columns.map { |c| validate_pg_identifier!(c, "column") }
          coalesce_old = col_bares.map { |b| "COALESCE(#{connection.quote_column_name(b)}::text, '')" }.join(" || ' ' || ")
          coalesce_new = col_bares.map { |b| "COALESCE(NEW.#{connection.quote_column_name(b)}::text, '')" }.join(" || ' ' || ")
          fn_name = "#{tn}_update_searchable_column"

          execute "ALTER TABLE #{tbl} DROP COLUMN IF EXISTS searchable;"
          execute "ALTER TABLE #{tbl} ADD COLUMN searchable text DEFAULT ''::text NOT NULL;"

          execute <<-SQL.strip_heredoc
            UPDATE #{tbl} SET searchable = ( #{coalesce_old} ) ;
          SQL

          create_trgm_index table_name, :searchable
          create_text_index table_name, :searchable

          execute <<-SQL.strip_heredoc
            CREATE OR REPLACE FUNCTION #{fn_name}()
            RETURNS TRIGGER AS $$
            BEGIN
               NEW.searchable = #{coalesce_new} ;
               RETURN NEW;
            END;
            $$ language 'plpgsql';
          SQL

          execute <<-SQL.strip_heredoc
            CREATE TRIGGER update_searchable_column_of_#{tn}
            BEFORE INSERT OR UPDATE ON #{tbl} FOR EACH ROW
            EXECUTE PROCEDURE
            #{fn_name}();
          SQL
        end

        dir.down do
          tbl = quoted_table(table_name)
          tn = validate_pg_identifier!(table_name, "table")
          execute " DROP TRIGGER  update_searchable_column_of_#{tn} ON #{tbl} "
        end
      end
    end

    def add_auto_timestamps(table_name,
      created_at: true, updated_at: true,
      created_at_null: true, updated_at_null: true,
      timezone: true, table_with_autogen_columns: false,
      updated_at_trigger: true)
      reversible do |dir|
        dir.up do
          tn = validate_pg_identifier!(table_name, "table")
          tbl = quoted_table(table_name)
          with_or_without_tz = timezone ? "timestamp with time zone" : "timestamp without time zone"

          if created_at
            unless column_exists? table_name, :created_at
              add_column(table_name, :created_at, with_or_without_tz, null: created_at_null)
            end
            execute "ALTER TABLE #{tbl} ALTER COLUMN created_at SET DEFAULT now()"
          end

          if updated_at
            unless column_exists? table_name, :updated_at
              add_column(table_name, :updated_at, with_or_without_tz, null: updated_at_null)
            end
            execute "ALTER TABLE #{tbl} ALTER COLUMN updated_at SET DEFAULT now()"

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
              CREATE TRIGGER update_updated_at_column_of_#{tn}
              BEFORE UPDATE ON #{tbl} FOR EACH ROW
              #{when_clause}
              EXECUTE PROCEDURE
              update_updated_at_column();
            SQL
          end
        end

        dir.down do
          tbl = quoted_table(table_name)
          tn = validate_pg_identifier!(table_name, "table")
          execute " DROP TRIGGER IF EXISTS update_updated_at_column_of_#{tn} ON #{tbl} "
          if created_at
            remove_column(table_name, :created_at)
          end
          if updated_at
            remove_column(table_name, :updated_at)
          end
        end
      end
    end

    def set_timestamps_defaults(table_name)
      reversible do |dir|
        dir.up do
          tbl = quoted_table(table_name)
          %w[created_at updated_at].each do |col|
            validate_pg_identifier!(col, "column")
            qcol = connection.quote_column_name(col)
            execute "ALTER TABLE #{tbl} ALTER COLUMN #{qcol} TYPE TIMESTAMP WITH TIME ZONE USING #{qcol}"
            # execute "ALTER TABLE #{tbl} ALTER COLUMN #{qcol} TYPE TIMESTAMP WITH TIME ZONE USING #{qcol} AT TIME ZONE 'UTC'"
            execute "ALTER TABLE #{tbl} ALTER COLUMN #{qcol} SET DEFAULT now()"
          end
        end
      end
    end

    def audit_table(table_name)
      reversible do |dir|
        dir.up do
          tn = validate_pg_identifier!(table_name, "table")
          tbl = quoted_table(table_name)
          execute <<-SQL.strip_heredoc
            CREATE TRIGGER audited_change_on_#{tn}
              AFTER DELETE OR INSERT OR UPDATE ON #{tbl}
              FOR EACH ROW 
              EXECUTE PROCEDURE audit_change();
          SQL
        end
      end
    end
  end
end
