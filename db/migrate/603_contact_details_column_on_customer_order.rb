class ContactDetailsColumnOnCustomerOrder < ActiveRecord::Migration[5.0]
  def change
    add_column(:customer_orders, :contact_details, :string, limit: 1000)
    add_column(:settings, :show_contact_details_on_customer_order, :boolean, default: false)
  end
end
