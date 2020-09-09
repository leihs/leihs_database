class AddSecondaryEmailToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :secondary_email, :text
    add_index :users, 'lower(secondary_email)',
      name: :users_secondary_email_idx

    # extract ZHdK specific "private" email from extended_info if available
    reversible do |dir|
      dir.up do
        User.where.not(extended_info: nil).in_batches do |users|
          users.each do |user|
            if secondary_email = \
                (user.extended_info.try(:[],'email_alt').presence \
                 or user.extended_info.try(:[],'personal_contact').try(:[],'email_private').presence)
              user.update_attribute(:secondary_email, secondary_email)
            end
          end
        end
      end
    end
  end
end
