class AddShortIdToProcurementRequests < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  class MigrationProcurementBudgetPeriod < ActiveRecord::Base
    self.table_name = 'procurement_budget_periods'
  end

  class MigrationProcurementRequest < ActiveRecord::Base
    self.table_name = 'procurement_requests'
  end

  SEPARATOR = '.'

  def up
    create_table :procurement_requests_counters, id: :uuid do |t|
      t.text :prefix, null: false
      t.integer :counter, null: false, default: 0
      t.uuid :created_by_budget_period_id, null: false
    end

    add_auto_timestamps :procurement_requests_counters, null: false

    add_index(:procurement_requests_counters, :prefix, unique: true)
    add_column(:procurement_requests, :short_id, :text)
    add_index(:procurement_requests, :short_id, unique: true)
    add_foreign_key(:procurement_requests_counters,
                    :procurement_budget_periods,
                    column: :created_by_budget_period_id,
                    on_delete: :cascade)

    MigrationProcurementBudgetPeriod.all.each do |bp|
      execute <<~SQL
        UPDATE procurement_requests
        SET short_id = tmp2.short_id
        FROM (
          SELECT tmp.id,
                 tmp.name || '#{SEPARATOR}' ||
                   CASE
                     WHEN row_number() OVER () > 999 THEN row_number() OVER ()::text
                     ELSE lpad(row_number() OVER ()::text, 3, '0')
                   END AS short_id
          FROM (
            SELECT procurement_requests.id, procurement_budget_periods.name
            FROM procurement_requests
            JOIN procurement_budget_periods
              ON procurement_budget_periods.id = procurement_requests.budget_period_id
            WHERE procurement_budget_periods.id = '#{bp.id}'
            ORDER BY procurement_requests.created_at ASC
          ) AS tmp
        ) AS tmp2
        WHERE procurement_requests.id = tmp2.id;
      SQL

      r =
        MigrationProcurementRequest
        .where(budget_period_id: bp.id)
        .order('created_at DESC')
        .first

      c = ( r ? r.short_id.split(SEPARATOR)[1].to_i : 0 )

      execute <<~SQL
        INSERT INTO procurement_requests_counters(prefix, counter, created_by_budget_period_id)
        VALUES ('#{bp.name}', #{c}, '#{bp.id}');
      SQL
    end

    execute <<~SQL
      CREATE FUNCTION set_short_id_for_new_procurement_request_f()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.short_id = (
          SELECT tmp.prefix || '#{SEPARATOR}' || CASE
                                                   WHEN tmp.counter > 999 THEN tmp.counter::text
                                                   ELSE lpad(tmp.counter::text, 3, '0')
                                                 END
          FROM (
            SELECT prc.prefix, prc.counter + 1 AS counter
            FROM procurement_requests_counters AS prc
            JOIN procurement_budget_periods AS pbp ON prc.prefix = pbp.name
            WHERE pbp.id = NEW.budget_period_id
          ) AS tmp
        );

        RETURN NEW;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER set_short_id_for_new_procurement_request_t
      BEFORE insert ON procurement_requests
      FOR EACH ROW EXECUTE PROCEDURE set_short_id_for_new_procurement_request_f();
    SQL

    execute <<~SQL
      CREATE FUNCTION increase_counter_for_new_procurement_request_f()
      RETURNS TRIGGER AS $$
      BEGIN
        UPDATE procurement_requests_counters
        SET counter = tmp.counter + 1
        FROM (
          SELECT prc.counter, pbp.id AS budget_period_id
          FROM procurement_requests_counters AS prc
          JOIN procurement_budget_periods AS pbp ON prc.prefix = pbp.name
        ) AS tmp 
        WHERE tmp.budget_period_id = NEW.budget_period_id;

        RETURN NULL;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER increase_counter_for_new_procurement_request_t
      AFTER insert ON procurement_requests
      FOR EACH ROW EXECUTE PROCEDURE increase_counter_for_new_procurement_request_f();
    SQL

    execute <<~SQL
      CREATE FUNCTION insert_counter_for_new_procurement_budget_period_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NOT EXISTS (
          SELECT true
          FROM procurement_requests_counters
          WHERE prefix = NEW.name
        ) THEN
          INSERT INTO procurement_requests_counters(prefix, counter, created_by_budget_period_id)
          VALUES (NEW.name, 0, NEW.id);
        END IF;

        RETURN NULL;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER insert_counter_for_new_procurement_budget_period_t
      AFTER insert OR update ON procurement_budget_periods
      FOR EACH ROW EXECUTE PROCEDURE insert_counter_for_new_procurement_budget_period_f();
    SQL

    execute <<~SQL
      ALTER TABLE procurement_budget_periods
      ADD CONSTRAINT procurement_budget_periods_name
      CHECK (name ~* '^[\-\_a-zA-Z0-9]+$');
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE procurement_budget_periods DROP CONSTRAINT procurement_budget_periods_name
    SQL
    execute <<~SQL
      DROP TRIGGER insert_counter_for_new_procurement_budget_period_t ON procurement_budget_periods;
      DROP FUNCTION insert_counter_for_new_procurement_budget_period_f();
    SQL
    execute <<~SQL
      DROP TRIGGER increase_counter_for_new_procurement_request_t ON procurement_requests;
      DROP FUNCTION increase_counter_for_new_procurement_request_f();
    SQL
    execute <<~SQL
      DROP TRIGGER set_short_id_for_new_procurement_request_t ON procurement_requests;
      DROP FUNCTION set_short_id_for_new_procurement_request_f();
    SQL
    remove_foreign_key(:procurement_requests_counters, column: :created_by_budget_period_id)
    remove_index(:procurement_requests_counters, :prefix)
    remove_index(:procurement_requests, :short_id)
    remove_column(:procurement_requests, :short_id)
    drop_table(:procurement_requests_counters)
  end
end
