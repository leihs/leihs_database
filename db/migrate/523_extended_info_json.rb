class ExtendedInfoJson < ActiveRecord::Migration[5.0]
  class User < ActiveRecord::Base
  end

  def up
    add_column :users, :extended_info_json, :jsonb

    User.where.not(extended_info: nil).in_batches do |users|
      users.each do |user|
        extended_info = YAML.load(user.extended_info).try do |m| 
          m.map do |k, v|
            [k, v.to_s.force_encoding('utf-8')]
          end.compact.to_h
        end
        user.update_columns extended_info_json: extended_info
      end
    end

    remove_column :users, :extended_info
    rename_column :users, :extended_info_json, :extended_info
  end
end
