# table `entitlement_groups_direct_users` was replaced by `entitlement_groups_users`
# bug before: users' assignment via groups was not considered

class FixVisitsView < ActiveRecord::Migration[7.2]
  def up
    dir = Pathname.new(__FILE__).dirname
    execute IO.read(dir.join("047_fix_visits_view.sql"))
  end
end
