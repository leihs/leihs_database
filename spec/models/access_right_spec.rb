require 'spec_helper'

describe 'access_right' do
  example 'create' do
    @ar = FactoryBot.create(:access_right)
    expect(@ar.id).to be
  end
  context 'access_right' do
    before :each do
      @ar = FactoryBot.create(:access_right)
    end
  end
end
