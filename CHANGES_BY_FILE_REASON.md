# Change Log by File and Reason

## Runtime / Script Changes

### `bin/data-migration`

- **What changed**
  - Added defensive `ALTER TABLE ... ADD COLUMN IF NOT EXISTS ...` statements in `db_prepare_001` for legacy columns used by `db/*_001.sql`.
  - Added a cleanup step in `db_dump_data`:
    - removes `\restrict` and `\unrestrict` from generated SQL dumps.
- **Why**
  - `db_restore_001_data` imports historical snapshots that assume older schema shape.
  - Newer PostgreSQL dump output includes `psql` meta commands that break plain SQL execution contexts.

### `spec/config/database.rb`

- **What changed**
  - `db_restore_data` now filters out lines starting with `\` before calling `database.run`.
- **Why**
  - Specs restore dump text through Sequel as SQL.
  - `psql` meta commands (`\restrict`, `\unrestrict`) are not valid SQL and caused:
    - `PG::SyntaxError: syntax error at or near "\"`.

## Generated Artifact Changes

### SQL and binary dumps

- `db/seeds.sql`
- `db/seeds.pgbin`
- `db/personas.sql`
- `db/personas.pgbin`
- `db/demo.sql`
- `db/demo.pgbin`

- **Why changed**
  - Rebuilt via remigrate workflow after script fixes.
  - Dumps now match current migration/runtime behavior.

### Structure dump

- `db/structure.sql`

- **Why changed**
  - Refreshed as part of migration runs.
  - Represents schema after successful migration path.

## Outcome

- The previously reported testserver failure path (`\restrict` syntax error) is mitigated by:
  - preventing those lines from entering new dump files, and
  - ignoring them during SQL restore in specs.

