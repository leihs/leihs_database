class EntitlementGroupsGroupsGroupFkOnDeleteCascade < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      ALTER TABLE public.entitlement_groups_groups
        DROP CONSTRAINT fk_rails_35f9f6c9e0;
      ALTER TABLE public.entitlement_groups_groups
        ADD CONSTRAINT fk_rails_35f9f6c9e0
          FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE public.entitlement_groups_groups
        DROP CONSTRAINT fk_rails_35f9f6c9e0;
      ALTER TABLE public.entitlement_groups_groups
        ADD CONSTRAINT fk_rails_35f9f6c9e0
          FOREIGN KEY (group_id) REFERENCES public.groups(id);
    SQL
  end
end
