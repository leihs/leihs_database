class NotNullableBooleansForItems < ActiveRecord::Migration[6.0]
  BOOLEAN_COLUMNS = [
    :is_borrowable,
    :is_incomplete,
    :is_broken,
    :is_inventory_relevant,
    :needs_permission
  ].freeze

  def up
    # Set default true for is_inventory_relevant
    BOOLEAN_COLUMNS.each do |column|
      execute "UPDATE items SET #{column} = false WHERE #{column} IS NULL;"
    end

    # Make boolean columns NOT NULL
    BOOLEAN_COLUMNS.each do |column|
      change_column_null :items, column, false
    end
  end

  def down
    # Allow NULL values again
    BOOLEAN_COLUMNS.each do |column|
      change_column_null :items, column, true
    end
  end
end
