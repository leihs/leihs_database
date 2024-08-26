class AutoDeleteStaleProcurementUploads < ActiveRecord::Migration[6.1]

  def up
    execute <<~SQL
      DELETE FROM procurement_uploads
      WHERE created_at < NOW() - INTERVAL '6 months';
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION delete_stale_procurement_uploads_f()
      RETURNS TRIGGER AS $$
      BEGIN
        DELETE FROM procurement_uploads
        WHERE created_at < NOW() - INTERVAL '6 months';
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER delete_stale_procurement_uploads_t
      AFTER INSERT ON procurement_uploads
      FOR EACH ROW
      EXECUTE FUNCTION delete_stale_procurement_uploads_f();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS delete_stale_procurement_uploads_t ON procurement_uploads;
      DROP FUNCTION IF EXISTS delete_stale_procurement_uploads_f();
    SQL
  end

end
