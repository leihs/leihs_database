class ModelGroupLinksLabelNotBlank < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      UPDATE model_group_links SET label = NULL WHERE label ~ '^\s*$';

      ALTER TABLE model_group_links
      ADD CONSTRAINT model_group_links_label_not_blank
      CHECK (label IS NULL OR label !~ '^\s*$')
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE model_group_links
      DROP CONSTRAINT model_group_links_label_not_blank
    SQL
  end
end
