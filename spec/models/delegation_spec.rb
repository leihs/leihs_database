require 'spec_helper'

describe 'delegation' do
  it 'raises when responsible user of a delegation is a delegation' do
    delegation = FactoryBot.create(:delegation)
    expect {
      FactoryBot.create(:delegation, responsible_user: delegation)
    }.to raise_error /Responsible user of a delegation can't be a delegation\./
  end
end
