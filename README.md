# interop-analytics-deployment

## Materialized views
This repository contains the **/views** folder useful to create materialized views on Amazon Redshift.<br>
Specifically, materialized views are created by using a GitHub Actions workflow that deploys a Kubernetes job which runs Flyway migrations.<br>

In general, Flyway manages migrations through two types of .sql files: versioned and repeatable.<br>
Repeatable files (whose names adopt the R__ prefix) don't have a version number and can be executed an indefinite number of times.<br>
Flyway executes repeatable files every time their content changes: this is done by calculating a checksum.<br>
In other words, everytime a repeatable file changes, Flyway notices its checksum has changed and executes it again.<br><br>


### Folder structure
Repeatable files are executed in **alphabetical order** with respect to the name.<br>
Because of this, it's possible to apply an execution order by adding a cardinal number in the file name after the R__ prefix (e.g. R__00_mv.sql).<br>

However, multiple files in **different subfolders** having the **same name** will conflict when Flyway tries to execute them (e.g. /views/domains/R__mv.sql and /views/jwt/R__mv.sql).<br>
This problem can be solved by adding the name of the subfolder (in which the file is located) to the file name (e.g. /views/domains/R__domains_mv.sql and /views/jwt/R__jwt_mv.sql).<br>

Combining both solutions, the /views folder that stores the migration files has a structure like the following:<br>
- /views
    - /domains
        - R__domains_00_mv.sql
        - R__domains_01_mv.sql
    - /jwt
        - R__jwt_00_mv.sql
        - R__jwt_01_mv.sql
    - ...<br><br>



### Lifecycle
A materialized view can be: created, edited, dropped.<br>

1. In order to create a materialized view, you have to **create a new repeatable file** containing the following statements:<br>
    ```
    CREATE SCHEMA IF NOT EXISTS $SCHEMA_NAME;
    DROP MATERIALIZED VIEW IF EXISTS $SCHEMA_NAME.$MATERIALIZED_VIEW_NAME;
    CREATE MATERIALIZED VIEW $SCHEMA_NAME.$MATERIALIZED_VIEW_NAME AS ...;
    ```

2. Unfortunately, Amazon Redshift does not provide the capability to alter a materialized view.<br>
So, to alter a materialized view, it's necessary to drop it and create it again.<br>
This is automatically done by Flyway when you edit the repeatable file.<br>
In fact, everytime a repeatable file changes, Flyway notices its checksum has changed and executes it again.<br>
Since we use a strategy made of ```DROP MATERIALIZED VIEW IF EXISTS ...``` + ```CREATE MATERIALIZED VIEW ...``` statements, Flyway will drop the materialized view and creates a new one with the same name.<br>
You just have to **edit** the ```CREATE MATERIALIZED VIEW ...``` statement with the new one.<br>

3. To drop a materialized view, you have to edit the repeatable file by **removing** the ```CREATE MATERIALIZED VIEW ...``` statement and **keeping** only the ```DROP MATERIALIZED VIEW IF EXISTS ...``` statement.<br><br>


### Dropping a materialized view
Suppose you've created a materialized view called ```mv_1``` by running the ```R_domains_00_mv.sql``` file.<br>
Next, suppose you want to drop the ```mv_1``` view by modifying the ```R_domains_00_mv.sql``` file and keeping only the statement ```DROP MATERIALIZED VIEW IF EXISTS $SCHEMA_NAME.mv_1```;<br><br>
At this point, if you delete the ```R_domains_00_mv.sql``` file from the ```/views``` directory and re-run Flyway, you will get a validation error because the migration remains tracked in the flyway history table but the file is missing:
```
ERROR: Validate failed: Migrations have failed validation
Detected applied migration not resolved locally: domains 00 mv.
If you removed this migration intentionally, run repair to mark the migration as deleted.
```
So, when you drop a materialized view, you still need to keep the .sql file in the ```/views``` directory of the repository.<br><br>

As alternative, if you want to mandatory delete the .sql file from the repository, you must first act on the flyway history table by deleting all the records that reference such file.<br>
For example, if you want to delete the ```R_domains_00_mv.sql```, first run:
```
DELETE FROM $SCHEMA_NAME.flyway_schema_history WHERE script = 'domains/R__domains_00_mv.sql';
```
Then, you can re-deploy the automation that enables Flyway to run the migrations that create the materialized views.
