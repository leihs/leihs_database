# Remigrate / Rails 8.1 Changes

This document summarizes the current repository changes made to unblock remigrate and test execution under Rails 8.1 / newer PostgreSQL dump behavior.

## Goal

- Make remigrate data restore and follow-up migrations robust when historical schema and current runtime tooling differ.
- Keep SQL dump consumption compatible with environments that execute dumps as plain SQL (without `psql` meta-command support).

## Changed Files (current working tree)

- `bin/data-migration`
  - Added compatibility SQL in `db_prepare_001` to ensure legacy columns needed by `*_001.sql` restores exist before import.
  - Added post-processing in `db_dump_data` to strip `\restrict` and `\unrestrict` lines from generated SQL dumps.
  - Reason: historical snapshots and modern dump formats diverge; this guarantees restore/import stability.

- `spec/config/database.rb`
  - `db_restore_data` now sanitizes incoming SQL text by removing `psql` meta-command lines (lines starting with `\`) before `Sequel#run`.
  - Reason: prevents `PG::SyntaxError` when specs execute dump text directly as SQL.

- `db/seeds.sql`
- `db/seeds.pgbin`
- `db/personas.sql`
- `db/personas.pgbin`
- `db/demo.sql`
- `db/demo.pgbin`
- `db/structure.sql`
  - Regenerated/updated during remigrate workflow validation.
  - Reason: reflects the normalized dump output and current schema state after successful migration flow.

## Validation Performed

- Ran targeted failing spec:
  - `bundle exec rspec ./spec/models/access_right_spec.rb`
  - Result: green (`1 example, 0 failures`).

