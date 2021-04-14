class ZhdkSyncCleanup < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  class SystemAndSecuritySettings < ActiveRecord::Base
  end

  def up

    remove_foreign_key(:entitlement_groups_direct_users, :users)
    add_foreign_key(:entitlement_groups_direct_users, :users, on_delete: :cascade)

    remove_foreign_key(:entitlement_groups_direct_users, :entitlement_groups)
    add_foreign_key(:entitlement_groups_direct_users, :entitlement_groups, on_delete: :cascade)

    execute <<-SQL.strip_heredoc

      UPDATE users SET last_sign_in_at = sub.ts
      FROM ( SELECT MAX(ts) ts, user_id FROM
        ( SELECT MAX(updated_at) ts, user_id user_id FROM reservations GROUP BY user_id
          UNION SELECT MAX(created_at) ts, user_id user_id FROM contracts GROUP BY user_id
          UNION SELECT MAX(updated_at) ts, user_id user_id FROM contracts GROUP BY user_id
          UNION SELECT MAX(created_at) ts, user_id user_id FROM orders GROUP BY user_id
          UNION SELECT MAX(updated_at) ts, user_id user_id FROM orders GROUP BY user_id
          UNION SELECT MAX(created_at) ts, user_id user_id FROM customer_orders GROUP BY user_id
          UNION SELECT MAX(updated_at) ts, user_id user_id FROM customer_orders GROUP BY user_id
          UNION SELECT MAX(created_at) ts, user_id user_id FROM reservations GROUP BY user_id
          UNION SELECT MAX(updated_at) ts, user_id user_id FROM reservations GROUP BY user_id
          UNION SELECT MAX(created_at) ts, delegated_user_id user_id FROM reservations GROUP BY delegated_user_id
          UNION SELECT MAX(updated_at) ts, delegated_user_id user_id FROM reservations GROUP BY delegated_user_id
        ) stuff GROUP BY user_id ) AS sub
      WHERE sub.user_id = users.id
      AND users.last_sign_in_at IS NULL;

    SQL

    if sss = SystemAndSecuritySettings.first.try(:external_base_url) \
        and (sss.end_with?(".zhdk.ch") or /localhost/ =~ sss)
      execute <<-SQL.strip_heredoc
        UPDATE users SET extended_info = NULL, img_digest = 'TODO'
          WHERE organization = 'zhdk.ch';
      SQL
    end
  end

  def down

  end

end
