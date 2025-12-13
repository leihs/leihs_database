require "securerandom"

class BackfillImageFilenamesAndConstraint < ActiveRecord::Migration[7.2]
  EXT_BY_MIME = {
    "image/jpeg" => "jpg",
    "image/png" => "png",
    "image/gif" => "gif",
    "image/webp" => "webp",
    "image/svg+xml" => "svg",
    "image/bmp" => "bmp",
    "image/tiff" => "tiff"
  }.freeze

  def up
    say_with_time "Backfilling missing image filenames with shared M50_ base" do
      # Iterate over all parent images; ensure same base for image & thumbnails
      parents = select_all(<<~SQL)
        SELECT p.id, p.filename, p.content_type
        FROM images p
        WHERE p.parent_id IS NULL
          AND (
            p.filename IS NULL OR p.filename = '' OR
            EXISTS (
              SELECT 1 FROM images c
              WHERE c.parent_id = p.id
                AND (c.filename IS NULL OR c.filename = '')
            )
          )
      SQL

      parents_updated_ids = []
      thumbs_updated_ids = []

      parents.each do |p|
        ext = EXT_BY_MIME[p["content_type"]] || "jpg"
        base = if p["filename"] && p["filename"].to_s.strip != ""
          p["filename"].sub(/\.[^.]+$/, "")
        else
          "M50_#{SecureRandom.hex(5)}" # 10 chars
        end

        # Set parent filename if missing
        if p["filename"].nil? || p["filename"].to_s.strip == ""
          execute <<~SQL
            UPDATE images SET filename = #{quote("#{base}.#{ext}")} WHERE id = #{quote(p["id"])}
          SQL
          parents_updated_ids << p["id"]
        end

        # Set all missing child filenames under the same parent
        execute <<~SQL
          UPDATE images
          SET filename = #{quote("#{base}_thumb.#{ext}")}
          WHERE parent_id = #{quote(p["id"])}
            AND (filename IS NULL OR filename = '')
        SQL

        child_rows = select_all(<<~SQL)
          SELECT id FROM images
          WHERE parent_id = #{quote(p["id"])}
            AND (filename IS NULL OR filename = '')
        SQL
        thumbs_updated_ids.concat(child_rows.map { |r| r["id"] })
      end

      total = parents_updated_ids.size + thumbs_updated_ids.size
      say <<~LOG
        Image filename backfill summary:
        total modified=#{total} rows
        parent_ids (#{parents_updated_ids.size}):
        #{parents_updated_ids.any? ? parents_updated_ids.map { |id| "  #{id}" }.join("\n") : "  (none)"}

        thumb_ids (#{thumbs_updated_ids.size}):
        #{thumbs_updated_ids.any? ? thumbs_updated_ids.map { |id| "  #{id}" }.join("\n") : "  (none)"}
      LOG
    end

    # Enforce NOT NULL on filename
    change_column_null :images, :filename, false
  end

  def down
    # Remove NOT NULL constraint
    change_column_null :images, :filename, true

    say_with_time "Reverting image filenames (M50_*) to NULL" do
      reverted_rows = select_all(<<~SQL)
        SELECT id FROM images WHERE filename LIKE 'M50_%'
      SQL

      execute <<~SQL
        UPDATE images SET filename = NULL WHERE filename LIKE 'M50_%'
      SQL

      reverted_ids = reverted_rows.map { |r| r["id"] }
      say <<~LOG
        Image filename revert summary:
        total reverted=#{reverted_ids.size} rows
        reverted_ids:
        #{reverted_ids.any? ? reverted_ids.map { |id| "  #{id}" }.join("\n") : "  (none)"}
      LOG
    end
  end
end
