require 'spec_helper'

describe 'reservation' do
  it 'raises if start date is not the same for same contract' do
    id = UUIDTools::UUID.random_create.to_s
    user = FactoryBot.create(:user)
    inventory_pool = FactoryBot.create(:inventory_pool)
    c = Contract.create_with_disabled_triggers(id, user.id, inventory_pool.id)
    m = FactoryBot.create(:leihs_model)
    i1 = FactoryBot.create(:item,
                           leihs_model: m,
                           inventory_pool: inventory_pool,
                           owner: inventory_pool)

    sd = Date.today
    ed = Date.tomorrow

    r1 = FactoryBot.create(:reservation,
                           user_id: user.id,
                           inventory_pool_id: inventory_pool.id,
                           leihs_model: m,
                           item: i1,
                           status: :signed,
                           start_date: sd,
                           end_date: ed,
                           contract: c)

    expect do
      FactoryBot.create(:reservation,
                        user_id: user.id,
                        inventory_pool_id: inventory_pool.id,
                        leihs_model: m,
                        item: i1,
                        status: :signed,
                        start_date: r1.start_date + 1.day,
                        end_date: r1.end_date + 1.day,
                        contract: c)
    end.to raise_error /Start date must be same for all reservations of the same contract/

    r2 = FactoryBot.create(:reservation,
                           user_id: user.id,
                           inventory_pool_id: inventory_pool.id,
                           leihs_model: m,
                           item: i1,
                           status: :signed,
                           start_date: sd,
                           end_date: r1.end_date + 1.day,
                           contract: c)

    expect { r2.update(start_date: sd + 1.day) }
      .to raise_error /Start date must be same for all reservations of the same contract/
  end
end

