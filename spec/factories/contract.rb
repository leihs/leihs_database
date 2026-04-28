require "uuidtools"
require "base32/crockford"

class Contract < Sequel::Model
  many_to_one(:user)
  many_to_one(:inventory_pool)
  one_to_many(:reservations)

  def self.create_with_disabled_triggers(id,
    user_id,
    inventory_pool_id,
    state = :open,
    compact_id = id,
    purpose = Faker::Lorem.word)
    db_with_disabled_triggers do
      database[:contracts].insert(
        id: id,
        user_id: user_id,
        inventory_pool_id: inventory_pool_id,
        compact_id: compact_id,
        purpose: purpose,
        created_at: Sequel.lit("now()"),
        updated_at: Sequel.lit("now()"),
        state: state.to_s
      )
    end

    def self.update_with_disabled_triggers(id, column, value) # standard:disable Lint/NestedMethodDefinition
      allowed_columns = %i[created_at updated_at state purpose compact_id user_id inventory_pool_id]
      safe_column = column.to_sym
      raise ArgumentError, "Unsupported column #{column}" unless allowed_columns.include?(safe_column)

      # Existing callers sometimes pass SQL-style quoted strings like "'2026-01-01'".
      normalized_value = value.is_a?(String) ? value.sub(/\A'(.*)'\z/m, '\1') : value
      with_disabled_triggers do
        database[:contracts].where(id: id).update(safe_column => normalized_value)
      end
    end

    find(id: id)
  end
end

FactoryBot.define do
  factory :contract do
    user
    inventory_pool
    purpose { Faker::Lorem.sentence }
    state { "open" }
    created_at { DateTime.now }
    updated_at { DateTime.now }

    transient do
      uuid { UUIDTools::UUID.random_create }
    end

    after(:build) do |contract, trans|
      contract.id = trans.uuid.to_s
      b32 = Base32::Crockford.encode(contract.id.to_i)
      contract.compact_id ||=
        (3..26)
          .lazy
          .map { |i| b32[0..i] }
          .map { |c_id| !Contract.find(compact_id: c_id) && c_id }
          .find(&:itself)
    end
  end
end
