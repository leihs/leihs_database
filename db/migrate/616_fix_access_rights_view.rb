# NOTE: fixes 542_access_rights_view.rb
class FixAccessRightsView < ActiveRecord::Migration[5.0]
  def change
    execute IO.read(
      Pathname(__FILE__).dirname.join("616_fix_access_rights_view.sql")
    )
  end
end
