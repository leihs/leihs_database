# Fix: Restrict model assignment editing to item owners.
# Previously, inventory managers could change the model assignment of items
# not in their ownership. Setting permissions.owner to true on the model_id
# field ensures only the owning inventory pool can edit this field.
class SetModelIdFieldOwnerPermission < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      UPDATE fields SET data = jsonb_set(data::jsonb, '{permissions,owner}', 'true'::jsonb) WHERE id = 'model_id';
    SQL
  end

  def down
    execute <<~SQL
      UPDATE fields SET data = jsonb_set(data::jsonb, '{permissions,owner}', 'false'::jsonb) WHERE id = 'model_id';
    SQL
  end
end
