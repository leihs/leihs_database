class AddConstraintsToReservations < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL.strip_heredoc
      ALTER TABLE reservations
      ADD CONSTRAINT check_non_null_start_date
      CHECK (
        (status = 'draft' AND (start_date IS NULL OR start_date IS NOT NULL))
        OR start_date IS NOT NULL
      );
    SQL

    execute <<-SQL.strip_heredoc
      ALTER TABLE reservations
      ADD CONSTRAINT check_non_null_end_date
      CHECK (
        (status = 'draft' AND (end_date IS NULL OR end_date IS NOT NULL))
        OR end_date IS NOT NULL
      );
    SQL

    execute <<-SQL.strip_heredoc
      ALTER TABLE reservations
      ADD CONSTRAINT check_non_null_quantity
      CHECK (
        (status = 'draft' AND (quantity IS NULL OR quantity IS NOT NULL))
        OR quantity IS NOT NULL
      );
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE reservations DROP CONSTRAINT check_non_null_start_date;
      ALTER TABLE reservations DROP CONSTRAINT check_non_null_end_date;
      ALTER TABLE reservations DROP CONSTRAINT check_non_null_quantity;
    SQL
  end
end
