
# Notes on Migrating Data from PG10 to PG15


### Restore latest leihs 6.9.x version on PG10

    createdb leihs_demo
    pg_restore --single-transaction --no-owner --no-privileges --disable-triggers -d leihs_demo ../features/personas/demo.pgbin

### Dump data-only from PG10

    pg_dump  -f db/demo_001.sql -d leihs_demo -x -O --data-only --insert --column-inserts -T schema_migrations  -T ar_internal_metadata  -T audits -T audited_changes -T audited_requests -T audited_responses 
    pg_dump  -f db/personas_001.sql -d leihs_personas -x -O  --data-only --insert --column-inserts -T schema_migrations  -T ar_internal_metadata  -T audits -T audited_changes -T audited_requests -T audited_responses
    pg_dump  -f db/seeds_001.sql -d leihs_seeds -x -O --data-only --insert --column-inserts -T schema_migrations  -T ar_internal_metadata  -T audits -T audited_changes -T audited_requests -T audited_responses


### Prepare DB on PG15

    VERSION=001 ./bin/structure-remigrate

### Restore data on top of that 

    pg_restore --single-transaction --no-owner --no-privileges --disable-triggers -d leihs tmp/demo_data.pgbin


### Finally dump the 001 version

    pg_dump -d leihs --no-owner --no-privileges  --insert --column-inserts -T ar_internal_metadata > db/demo_001.sql


