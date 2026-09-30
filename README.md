# Database Submodule for Leihs

## Development

See the scripts in `./bin/`.

### Migrations

After adding a migration, the `demo` and `personas` databases must be kept in sync. Run:

```bash
PGPORT=5432 RAILS_ENV=test bin/demo-remigrate
PGPORT=5432 RAILS_ENV=test bin/personas-remigrate
PGPORT=5432 RAILS_ENV=test bin/seeds-remigrate
```

This re-applies all migrations from the `_001.sql` baseline and regenerates the `.pgbin` and `.sql` snapshot files in `db/`. Commit the updated snapshots together with the migration file and the updated `structure.sql`.

### Formatting Code

#### Ruby

Use `./bin/rblint` and `./bin/rblint --fix`.
