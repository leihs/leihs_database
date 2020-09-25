class AddShortIdToProcurementRequests < ActiveRecord::Migration[5.0]
  class MigrationProcurementBudgetPeriod < ActiveRecord::Base
    self.table_name = 'procurement_budget_periods'
  end

  class MigrationProcurementRequest < ActiveRecord::Base
    self.table_name = 'procurement_requests'
  end

  SEPARATOR = '.'

  def up
    create_table :procurement_requests_counters, id: false do |t|
      t.uuid :budget_period_id, null: false, default: 0
      t.integer :counter, null: false, default: 0
    end

    add_foreign_key(:procurement_requests_counters,
                    :procurement_budget_periods,
                    column: :budget_period_id,
                    on_delete: :cascade)

    add_index(:procurement_requests_counters,
              :budget_period_id,
              unique: true)

    add_column(:procurement_requests, :short_id, :text)
    add_index(:procurement_requests, :short_id, unique: true)

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
            SELECT procurement_requests.id,
                   procurement_budget_periods.name,
                   procurement_requests.created_at
            FROM procurement_requests
            INNER JOIN procurement_budget_periods
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
        INSERT INTO procurement_requests_counters(budget_period_id, counter)
        VALUES ('#{bp.id}', #{c});
      SQL
    end

    execute <<~SQL
      CREATE FUNCTION set_short_id_for_new_procurement_request_f()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.short_id = (
          SELECT tmp.name || '#{SEPARATOR}' || CASE
                                                 WHEN tmp.counter > 999 THEN tmp.counter::text
                                                 ELSE lpad(tmp.counter::text, 3, '0')
                                               END
          FROM (
            SELECT pbp.name, prc.counter + 1 AS counter
            FROM procurement_budget_periods pbp
            JOIN procurement_requests_counters prc ON prc.budget_period_id = pbp.id
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
        SET counter = counter + 1
        WHERE budget_period_id = NEW.budget_period_id;

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
        INSERT INTO procurement_requests_counters(budget_period_id, counter)
        VALUES (NEW.id, 0);

        RETURN NULL;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER insert_counter_for_new_procurement_budget_period_t
      AFTER insert ON procurement_budget_periods
      FOR EACH ROW EXECUTE PROCEDURE insert_counter_for_new_procurement_budget_period_f();
    SQL
  end

  def down
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
    remove_index(:procurement_requests_counters, :budget_period_id)
    remove_foreign_key(:procurement_requests_counters, column: :budget_period_id)
    remove_index(:procurement_requests, :short_id)
    remove_column(:procurement_requests, :short_id)
    drop_table(:procurement_requests_counters)
  end
end
