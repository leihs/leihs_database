class CreateFieldsRakeTaskForTheLastTime < ActiveRecord::Migration[5.0]

	class MigrationField < ActiveRecord::Base
		self.table_name = 'fields'
		serialize :data, JSON
	end

	def up

		Leihs::Fields.load \
			.map(&:with_indifferent_access) \
			.map{|f| f.except(:dynamic)}.each do |field|

			if mf = MigrationField.find_by_id(field[:id])
				mf.update_attributes! field.except(:id)
			else
				MigrationField.create!(field)
			end

		end

	end

end
