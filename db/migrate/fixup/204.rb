ActiveRecord::Base.transaction do
  rs = Reservation.where(status: :closed).where(contract_id: nil)
  c = Contract.new(note: 'MISSING CONTRACT; created through migration script')
  c.save(validate: false)
  rs.update_all(contract_id: c.id)
end
