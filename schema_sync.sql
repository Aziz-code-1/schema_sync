WITH common_tables AS (
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'schema_a'
    INTERSECT
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'schema_b'
),
cols_a AS (
    SELECT
        table_name,
        column_name,
        data_type,
        character_maximum_length,
        is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'schema_a'
),
cols_b AS (
    SELECT
        table_name,
        column_name,
        data_type,
        character_maximum_length,
        is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'schema_b'
)
SELECT
    CASE
        WHEN b.column_name IS NULL THEN
            'ALTER TABLE schema_b.' || a.table_name ||
            ' ADD COLUMN ' || a.column_name || ' ' ||
            a.data_type ||
            COALESCE('(' || a.character_maximum_length || ')', '') ||
            CASE
                WHEN a.is_nullable = 'NO'
                THEN ' NOT NULL;'
                ELSE ';'
            END
        WHEN a.data_type <> b.data_type
          OR COALESCE(a.character_maximum_length, -1)
             <> COALESCE(b.character_maximum_length, -1)
        THEN
            'ALTER TABLE schema_b.' || a.table_name ||
            ' ALTER COLUMN ' || a.column_name ||
            ' TYPE ' || a.data_type ||
            COALESCE('(' || a.character_maximum_length || ')', '') ||
            ';'
        WHEN a.is_nullable <> b.is_nullable THEN
            CASE
                WHEN a.is_nullable = 'NO' THEN
                    'ALTER TABLE schema_b.' || a.table_name ||
                    ' ALTER COLUMN ' || a.column_name ||
                    ' SET NOT NULL;'
                ELSE
                    'ALTER TABLE schema_b.' || a.table_name ||
                    ' ALTER COLUMN ' || a.column_name ||
                    ' DROP NOT NULL;'
            END
    END AS generated_sql
FROM cols_a a
LEFT JOIN cols_b b
    ON a.table_name = b.table_name
   AND a.column_name = b.column_name
JOIN common_tables t
    ON a.table_name = t.table_name
WHERE
       b.column_name IS NULL
    OR a.data_type <> b.data_type
    OR COALESCE(a.character_maximum_length, -1)
       <> COALESCE(b.character_maximum_length, -1)
    OR a.is_nullable <> b.is_nullable
ORDER BY
    a.table_name,
    a.column_name;
