require "spec_helper"

describe "item" do
  example "deletion is prohibited" do
    ip = FactoryBot.create(:inventory_pool)
    i = FactoryBot.create(:item, inventory_pool: ip)
    expect { i.delete }.to raise_error(/Deletion is forbidden on the items table./)
  end

  context "package retirement" do
    let(:ip) { FactoryBot.create(:inventory_pool) }
    let(:package_model) { FactoryBot.create(:leihs_model, is_package: true) }
    let(:package) { FactoryBot.create(:item, leihs_model: package_model, inventory_pool: ip) }
    let(:child) { FactoryBot.create(:item, inventory_pool: ip, parent_id: package.id) }

    example "removing last child retires package" do
      child  # ensure created
      child.update(parent_id: nil)
      expect(package.reload.retired).to eq(Date.today)
      expect(package.reload.retired_reason).to eq("package dissolved")
    end

    example "removing non-last child does not retire package" do
      child2 = FactoryBot.create(:item, inventory_pool: ip, parent_id: package.id)
      child.update(parent_id: nil)
      expect(package.reload.retired).to be_nil
      child2.update(parent_id: nil)
      expect(package.reload.retired).to eq(Date.today)
    end
  end
end
