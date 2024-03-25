class CreateMailTemplatesTrigger < ActiveRecord::Migration[6.1]
  def up
    change_column(:mail_templates, :created_at, "timestamp without time zone", default: -> { "now()" })
    change_column(:mail_templates, :updated_at, "timestamp without time zone", default: -> { "now()" })

    execute <<~SQL
      CREATE FUNCTION insert_mail_templates_for_new_inventory_pool_f() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        INSERT INTO mail_templates (
          inventory_pool_id,
          name,
          format,
          body,
          is_template_template,
          "type",
          language_locale
        )
        SELECT
          NEW.id,
          name,
          format,
          body,
          FALSE,
          "type",
          language_locale
        FROM mail_templates
        WHERE is_template_template = TRUE;

        RETURN NEW;
      END;
      $$;

      CREATE TRIGGER insert_mail_templates_for_new_inventory_pool_t
      AFTER INSERT ON inventory_pools
      FOR EACH ROW
      EXECUTE FUNCTION insert_mail_templates_for_new_inventory_pool_f();
    SQL
  end

  def down
    change_column(:mail_templates, :created_at, "timestamp without time zone")
    change_column(:mail_templates, :updated_at, "timestamp without time zone")

    execute <<~SQL
      DROP TRIGGER IF EXISTS insert_mail_templates_for_new_inventory_pool_t ON inventory_pools;
      DROP FUNCTION IF EXISTS insert_mail_templates_for_new_inventory_pool_f();
    SQL
  end
end
