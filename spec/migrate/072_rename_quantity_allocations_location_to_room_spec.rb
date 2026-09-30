require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require_relative "../../config/environment"
require_relative "../../db/migrate/072_rename_quantity_allocations_location_to_room"

describe RenameQuantityAllocationsLocationToRoom do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: "postgresql",
      host: database_host,
      port: database_port,
      database: database_name,
      username: database_user,
      password: database_password
    )
  end

  def run_migration
    ActiveRecord::Migration.suppress_messages do
      described_class.new.up
    end
  end

  def set_allocations!(item, allocations)
    database.fetch(
      "UPDATE items SET properties = jsonb_build_object('quantity_allocations', ?::jsonb) WHERE id = ?",
      JSON.generate(allocations),
      item.id
    ).all
  end

  def quantity_allocations_for(item)
    allocations = database.fetch(
      "SELECT properties->'quantity_allocations' AS allocations FROM items WHERE id = ?",
      item.id
    ).first[:allocations]

    case allocations
    when Array
      allocations.map { |entry| entry.transform_keys(&:to_s) }
    when String
      JSON.parse(allocations)
    else
      JSON.parse(JSON.generate(allocations))
    end
  end

  let(:pool) { FactoryBot.create(:inventory_pool) }

  example "rewrites location to room and removes location key" do
    item = FactoryBot.create(:item, inventory_pool: pool, owner: pool)
    set_allocations!(item, [
      {"quantity" => 10, "location" => "Server room A"}
    ])

    run_migration

    allocation = quantity_allocations_for(item).first
    expect(allocation["room"]).to eq("Server room A")
    expect(allocation["quantity"]).to eq(10)
    expect(allocation).not_to have_key("location")
  end

  example "preserves quantity_allocations order" do
    item = FactoryBot.create(:item, inventory_pool: pool, owner: pool)
    set_allocations!(item, [
      {"quantity" => 1, "location" => "First"},
      {"quantity" => 2, "location" => "Second"},
      {"quantity" => 3, "location" => "Third"}
    ])

    run_migration

    rooms = quantity_allocations_for(item).map { |a| a["room"] }
    expect(rooms).to eq(["First", "Second", "Third"])
  end

  example "leaves room-only allocations unchanged" do
    item = FactoryBot.create(:item, inventory_pool: pool, owner: pool)
    set_allocations!(item, [
      {"quantity" => 5, "room" => "Existing room"}
    ])

    run_migration

    allocation = quantity_allocations_for(item).first
    expect(allocation).to eq({"quantity" => 5, "room" => "Existing room"})
  end

  example "drops location when room is already present" do
    item = FactoryBot.create(:item, inventory_pool: pool, owner: pool)
    set_allocations!(item, [
      {"quantity" => 7, "room" => "Keep me", "location" => "Drop me"}
    ])

    run_migration

    allocation = quantity_allocations_for(item).first
    expect(allocation["room"]).to eq("Keep me")
    expect(allocation).not_to have_key("location")
  end
end
