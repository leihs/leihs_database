class InventoryViewTemplate < ActiveRecord::Migration[7.2]
  def up
    say_with_time "Removing duplicate rows from inventory_pools_model_groups" do
      deleted = execute(<<~SQL).cmd_tuples
        WITH ranked AS (
          SELECT
            ctid,
            ROW_NUMBER() OVER (
              PARTITION BY inventory_pool_id, model_group_id
              ORDER BY ctid
            ) AS rn
          FROM inventory_pools_model_groups
        )
        DELETE FROM inventory_pools_model_groups t
        USING ranked r
        WHERE t.ctid = r.ctid
          AND r.rn > 1;
      SQL

      say "Deleted #{deleted} duplicate rows"
    end

    say_with_time "Adding unique constraint on (inventory_pool_id, model_group_id)" do
      execute <<~SQL
        ALTER TABLE inventory_pools_model_groups
        ADD CONSTRAINT inventory_pools_model_groups_unique
        UNIQUE (inventory_pool_id, model_group_id);
      SQL
    end
  end

  def down
    say_with_time "Dropping unique constraint on (inventory_pool_id, model_group_id)" do
      execute <<~SQL
        ALTER TABLE inventory_pools_model_groups
        DROP CONSTRAINT IF EXISTS inventory_pools_model_groups_unique;
      SQL
    end
  end
end
