class DropFieldsTrigger < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL.strip_heredoc
      DROP TRIGGER IF EXISTS trigger_restrict_operations_on_fields_function ON fields;
      DROP FUNCTION IF EXISTS restrict_operations_on_fields_function();
    SQL
  end
end
