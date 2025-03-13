require "spec_helper"

describe "inventory pool" do
  example "creates mail templates for new pool" do
    ip = FactoryBot.create(:inventory_pool)
    mtt = MailTemplate.where(is_template_template: true)
    expect(mtt.count).to eq(Language.count * 6)
    mts = MailTemplate.where(inventory_pool_id: ip.id,
      is_template_template: false)
    expect(mts.count).to eq(Language.count * 6)
    expect(MailTemplate.count).to eq(Language.count * 6 * 2)
  end
end
