class AddUsersProtectedField < ActiveRecord::Migration[5.0]
  def change
    add_column(:users, :protected, :boolean, null: false, default: false)
    add_column(:groups, :protected, :boolean, null: false, default: false)
  end
end
