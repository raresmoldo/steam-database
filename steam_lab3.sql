
DROP TABLE IF EXISTS db_version_steps;

DROP PROCEDURE IF EXISTS do_alter_wallet_type();
DROP PROCEDURE IF EXISTS undo_alter_wallet_type();
DROP PROCEDURE IF EXISTS do_add_age_rating();
DROP PROCEDURE IF EXISTS undo_add_age_rating();
DROP PROCEDURE IF EXISTS do_add_country_default();
DROP PROCEDURE IF EXISTS undo_add_country_default();
DROP PROCEDURE IF EXISTS do_create_wishlist();
DROP PROCEDURE IF EXISTS undo_create_wishlist();
DROP PROCEDURE IF EXISTS do_add_wishlist_pk();
DROP PROCEDURE IF EXISTS undo_add_wishlist_pk();
DROP PROCEDURE IF EXISTS do_add_games_unique();
DROP PROCEDURE IF EXISTS undo_add_games_unique();
DROP PROCEDURE IF EXISTS do_add_wishlist_fks();
DROP PROCEDURE IF EXISTS undo_add_wishlist_fks();



CREATE TABLE IF NOT EXISTS db_version (
    id       BOOLEAN PRIMARY KEY DEFAULT TRUE CHECK (id),
    version  INT NOT NULL
);

INSERT INTO db_version (version)
SELECT 0 WHERE NOT EXISTS (SELECT 1 FROM db_version);

CREATE TABLE db_version_steps (
    step         INT  PRIMARY KEY,
    operation    TEXT NOT NULL CHECK (operation IN
                    ('ALTER_TYPE','ADD_COLUMN','SET_DEFAULT','CREATE_TABLE',
                     'ADD_PRIMARY_KEY','ADD_CANDIDATE_KEY','ADD_FOREIGN_KEY')),
    table_name   TEXT NOT NULL,
    object_name  TEXT,   
    new_value    TEXT,   
    old_value    TEXT,   
    ref_table    TEXT,   
    ref_columns  TEXT    
);



-- %I text
-- %s sql
CREATE OR REPLACE PROCEDURE do_alter_column_type(tbl TEXT, col TEXT, new_type TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ALTER COLUMN %I TYPE %s USING %I::%s',
                   tbl, col, new_type, col, new_type);
END $$;

CREATE OR REPLACE PROCEDURE undo_alter_column_type(tbl TEXT, col TEXT, old_type TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ALTER COLUMN %I TYPE %s USING %I::%s',
                   tbl, col, old_type, col, old_type);
END $$;

CREATE OR REPLACE PROCEDURE do_add_column(tbl TEXT, col TEXT, col_type TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ADD COLUMN %I %s', tbl, col, col_type);
END $$;

CREATE OR REPLACE PROCEDURE undo_add_column(tbl TEXT, col TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I DROP COLUMN %I', tbl, col);
END $$;

CREATE OR REPLACE PROCEDURE do_set_default(tbl TEXT, col TEXT, default_expr TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ALTER COLUMN %I SET DEFAULT %s', tbl, col, default_expr);
END $$;

CREATE OR REPLACE PROCEDURE undo_set_default(tbl TEXT, col TEXT, old_default TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    IF old_default IS NULL THEN
        EXECUTE format('ALTER TABLE %I ALTER COLUMN %I DROP DEFAULT', tbl, col);
    ELSE
        EXECUTE format('ALTER TABLE %I ALTER COLUMN %I SET DEFAULT %s', tbl, col, old_default);
    END IF;
END $$;

CREATE OR REPLACE PROCEDURE do_create_table(tbl TEXT, column_defs TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('CREATE TABLE %I (%s)', tbl, column_defs);
END $$;

CREATE OR REPLACE PROCEDURE undo_create_table(tbl TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('DROP TABLE %I', tbl);
END $$;

CREATE OR REPLACE PROCEDURE do_add_primary_key(tbl TEXT, constraint_name TEXT, cols TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I PRIMARY KEY (%s)', tbl, constraint_name, cols);
END $$;

CREATE OR REPLACE PROCEDURE undo_add_primary_key(tbl TEXT, constraint_name TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I', tbl, constraint_name);
END $$;

CREATE OR REPLACE PROCEDURE do_add_candidate_key(tbl TEXT, constraint_name TEXT, cols TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I UNIQUE (%s)', tbl, constraint_name, cols);
END $$;

CREATE OR REPLACE PROCEDURE undo_add_candidate_key(tbl TEXT, constraint_name TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I', tbl, constraint_name);
END $$;

CREATE OR REPLACE PROCEDURE do_add_foreign_key(tbl TEXT, constraint_name TEXT, cols TEXT,
                                               parent_tbl TEXT, parent_cols TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (%s) REFERENCES %I (%s)',
                   tbl, constraint_name, cols, parent_tbl, parent_cols);
END $$;

CREATE OR REPLACE PROCEDURE undo_add_foreign_key(tbl TEXT, constraint_name TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I', tbl, constraint_name);
END $$;



CREATE OR REPLACE PROCEDURE run_step(step_no INT, going_up BOOLEAN)
LANGUAGE plpgsql AS $$
DECLARE
    s db_version_steps%ROWTYPE;
BEGIN
    SELECT * INTO s FROM db_version_steps WHERE step = step_no;

    IF going_up THEN
        CASE s.operation
            WHEN 'ALTER_TYPE' THEN
                CALL do_alter_column_type(s.table_name, s.object_name, s.new_value);
            WHEN 'ADD_COLUMN' THEN
                CALL do_add_column(s.table_name, s.object_name, s.new_value);
            WHEN 'SET_DEFAULT' THEN
                CALL do_set_default(s.table_name, s.object_name, s.new_value);
            WHEN 'CREATE_TABLE' THEN
                CALL do_create_table(s.table_name, s.new_value);
            WHEN 'ADD_PRIMARY_KEY' THEN
                CALL do_add_primary_key(s.table_name, s.object_name, s.new_value);
            WHEN 'ADD_CANDIDATE_KEY' THEN
                CALL do_add_candidate_key(s.table_name, s.object_name, s.new_value);
            WHEN 'ADD_FOREIGN_KEY' THEN
                CALL do_add_foreign_key(s.table_name, s.object_name, s.new_value,
                                        s.ref_table, s.ref_columns);
            ELSE
                RAISE EXCEPTION 'Unknown operation %', s.operation;
        END CASE;
    ELSE
        CASE s.operation
            WHEN 'ALTER_TYPE' THEN
                CALL undo_alter_column_type(s.table_name, s.object_name, s.old_value);
            WHEN 'ADD_COLUMN' THEN
                CALL undo_add_column(s.table_name, s.object_name);
            WHEN 'SET_DEFAULT' THEN
                CALL undo_set_default(s.table_name, s.object_name, s.old_value);
            WHEN 'CREATE_TABLE' THEN
                CALL undo_create_table(s.table_name);
            WHEN 'ADD_PRIMARY_KEY' THEN
                CALL undo_add_primary_key(s.table_name, s.object_name);
            WHEN 'ADD_CANDIDATE_KEY' THEN
                CALL undo_add_candidate_key(s.table_name, s.object_name);
            WHEN 'ADD_FOREIGN_KEY' THEN
                CALL undo_add_foreign_key(s.table_name, s.object_name);
            ELSE
                RAISE EXCEPTION 'Unknown operation %', s.operation;
        END CASE;
    END IF;
END $$;



CREATE OR REPLACE PROCEDURE go_to_version(target_version INT)
LANGUAGE plpgsql AS $$
DECLARE
    cur_version  INT;
    max_version  INT;
BEGIN
    SELECT version INTO cur_version FROM db_version;
    SELECT COALESCE(MAX(step), 0) INTO max_version FROM db_version_steps;

    IF target_version < 0 OR target_version > max_version THEN
        RAISE EXCEPTION 'Invalid version %. Choose a value between 0 and %.',
                        target_version, max_version;
    END IF;

    WHILE cur_version < target_version LOOP
        cur_version := cur_version + 1;
        CALL run_step(cur_version, TRUE);
        UPDATE db_version SET version = cur_version;
        RAISE NOTICE 'Now at version %', cur_version;
    END LOOP;

    WHILE cur_version > target_version LOOP
        CALL run_step(cur_version, FALSE);
        cur_version := cur_version - 1;
        UPDATE db_version SET version = cur_version;
        RAISE NOTICE 'Now at version %', cur_version;
    END LOOP;
END $$;

CREATE OR REPLACE PROCEDURE undo_last_change()
LANGUAGE plpgsql AS $$
DECLARE
    cur_version INT;
BEGIN
    SELECT version INTO cur_version FROM db_version;
    IF cur_version = 0 THEN
        RAISE EXCEPTION 'Already at version 0, nothing to undo.';
    END IF;
    CALL go_to_version(cur_version - 1);
END $$;



CREATE OR REPLACE PROCEDURE new_version(op TEXT, tbl TEXT, obj TEXT, new_val TEXT,
                                        old_val TEXT DEFAULT NULL,
                                        ref_tbl TEXT DEFAULT NULL,
                                        ref_cols TEXT DEFAULT NULL)
LANGUAGE plpgsql AS $$
DECLARE
    next_step  INT;
    removed    INT;
BEGIN
    SELECT version + 1 INTO next_step FROM db_version;

    DELETE FROM db_version_steps WHERE step >= next_step;
    GET DIAGNOSTICS removed = ROW_COUNT;
    IF removed > 0 THEN
        RAISE NOTICE 'Discarded % undone step(s) above version %', removed, next_step - 1;
    END IF;

    INSERT INTO db_version_steps
        (step, operation, table_name, object_name, new_value, old_value, ref_table, ref_columns)
    VALUES (next_step, op, tbl, obj, new_val, old_val, ref_tbl, ref_cols);

    CALL go_to_version(next_step);
END $$;

CREATE OR REPLACE PROCEDURE alter_column_type(tbl TEXT, col TEXT, new_type TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    old_type TEXT;
BEGIN
    SELECT format_type(a.atttypid, a.atttypmod) INTO old_type
    FROM pg_attribute a
    WHERE a.attrelid = to_regclass(quote_ident(tbl))
      AND a.attname = col AND a.attnum > 0 AND NOT a.attisdropped;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Column %.% does not exist', tbl, col;
    END IF;

    CALL new_version('ALTER_TYPE', tbl, col, new_type, old_type);
END $$;

CREATE OR REPLACE PROCEDURE add_column(tbl TEXT, col TEXT, col_type TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    CALL new_version('ADD_COLUMN', tbl, col, col_type);
END $$;

CREATE OR REPLACE PROCEDURE set_column_default(tbl TEXT, col TEXT, new_default TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    old_default TEXT;
BEGIN
    SELECT pg_get_expr(d.adbin, d.adrelid) INTO old_default
    FROM pg_attribute a
    LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
    WHERE a.attrelid = to_regclass(quote_ident(tbl))
      AND a.attname = col AND a.attnum > 0 AND NOT a.attisdropped;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Column %.% does not exist', tbl, col;
    END IF;

    CALL new_version('SET_DEFAULT', tbl, col, new_default, old_default);
END $$;

CREATE OR REPLACE PROCEDURE create_table(tbl TEXT, column_defs TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    CALL new_version('CREATE_TABLE', tbl, NULL, column_defs);
END $$;

CREATE OR REPLACE PROCEDURE add_primary_key(tbl TEXT, constraint_name TEXT, cols TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    CALL new_version('ADD_PRIMARY_KEY', tbl, constraint_name, cols);
END $$;

CREATE OR REPLACE PROCEDURE add_candidate_key(tbl TEXT, constraint_name TEXT, cols TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    CALL new_version('ADD_CANDIDATE_KEY', tbl, constraint_name, cols);
END $$;

CREATE OR REPLACE PROCEDURE add_foreign_key(tbl TEXT, constraint_name TEXT, cols TEXT,
                                            parent_tbl TEXT, parent_cols TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    CALL new_version('ADD_FOREIGN_KEY', tbl, constraint_name, cols, NULL, parent_tbl, parent_cols);
END $$;
