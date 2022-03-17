class RemoveDisableBorrowSection < ActiveRecord::Migration[5.0]
  def up
    remove_column(:settings, :disable_borrow_section)
    remove_column(:settings, :disable_borrow_section_message)
    remove_column(:settings, :disable_manage_section)
    remove_column(:settings, :disable_manage_section_message)
  end
end
