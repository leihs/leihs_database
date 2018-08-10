class ProcurementUploadsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :procurement_uploads, id: :uuid do |t|
      t.string :filename, null: false
      t.string :content_type
      t.integer :size, null: false
      t.text :content, null: false
      t.json :metadata, null: false
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end
  end
end
