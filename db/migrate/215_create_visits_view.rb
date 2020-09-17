class CreateVisitsView < ActiveRecord::Migration
  def up
    execute IO.read(
      Pathname(__FILE__).dirname.join("215_create_visits_view.sql")
    )
  end

  def down
    execute 'DROP VIEW visits;'
  end
end
