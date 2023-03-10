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
    expect { d.update(firstname: nil) }.to raise_error /A delegation must have a name/
  end

  it 'raises when responsible user is null' do
    d = FactoryBot.create(:delegation)
    expect { d.update(delegator_user_id: nil) }.to raise_error /A delegation must have a reponsible user/
  end

  context 'updates irt the responsible user' do
    it 'creation of a delegation must create a member for the responsible user also' do
      d = FactoryBot.create(:delegation)
      expect(d.members).to include d.responsible_user
    end

    it 'update of responsible user must update the members accordingly' do
      d = FactoryBot.create(:delegation)
      old_ru = d.responsible_user
      new_ru = FactoryBot.create(:user)
      d.responsible_user = new_ru
      d.save
      expect(d.responsible_user).to eq new_ru
      expect(d.members).to include new_ru
      expect(d.members).not_to include old_ru
      expect(d.members.count).to eq 1
    end

    it 'change of the responsible user to someone who is already member of the delegation' do
      d = FactoryBot.create(:delegation)
      old_ru = d.responsible_user
      new_ru = FactoryBot.create(:user)
      d.add_member(new_ru)
      d.responsible_user = new_ru
      d.save
      expect(d.responsible_user).to eq new_ru
      expect(d.members).to include new_ru
      expect(d.members).not_to include old_ru
      expect(d.members.count).to eq 1
    end

    it 'delete of a member who is also responsible user is not allowed' do
      d = FactoryBot.create(:delegation)
      d.add_member(FactoryBot.create(:user))
      expect { d.remove_member(d.responsible_user) }.to raise_error \
        /One cannot delete a member of a delegation if he is also the responsible user/
    end
  end
end
