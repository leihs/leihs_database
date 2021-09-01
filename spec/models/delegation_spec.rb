require 'spec_helper'

describe 'delegation' do
  it 'raises when responsible user of a delegation is a delegation' do
    delegation = FactoryBot.create(:delegation)
    expect {
      FactoryBot.create(:delegation, responsible_user: delegation)
    }.to raise_error /Responsible user of a delegation can't be a delegation/
  end

  it 'raises when name is blank' do
    d = FactoryBot.create(:delegation)
    d.add_member(FactoryBot.create(:user))
    expect { d.update(firstname: nil) }.to raise_error /A delegation must have a name/
  end

  it 'raises when responsible user is null' do
    d = FactoryBot.create(:delegation)
    d.add_member(FactoryBot.create(:user))
    expect { d.update(delegator_user_id: nil) }.to raise_error /A delegation must have a reponsible user/
  end
end
