class RenameQuantityAllocationsLocationToRoom < ActiveRecord::Migration[7.2]
  def up
    say_with_time "Rewriting quantity_allocations[].location to room" do
      execute <<~SQL
        UPDATE items
        SET properties = jsonb_set(
          properties,
          '{quantity_allocations}',
          (
            SELECT COALESCE(jsonb_agg(
              CASE
                WHEN elem ? 'location' AND NOT (elem ? 'room')
                  THEN (elem - 'location') || jsonb_build_object('room', elem->'location')
                WHEN elem ? 'location'
                  THEN elem - 'location'
                ELSE elem
              END
              ORDER BY ord), '[]'::jsonb)
            FROM jsonb_array_elements(properties->'quantity_allocations')
              WITH ORDINALITY AS t(elem, ord)
          )
        )
        WHERE properties ? 'quantity_allocations'
          AND jsonb_typeof(properties->'quantity_allocations') = 'array'
          AND EXISTS (
            SELECT 1
            FROM jsonb_array_elements(properties->'quantity_allocations') e
            WHERE e ? 'location'
          );
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
