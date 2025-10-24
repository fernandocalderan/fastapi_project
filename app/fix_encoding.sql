-- ==============================================
-- fix_encoding.sql
-- Repara textos mal codificados (Latin1 → UTF8)
-- ==============================================

DO $$
DECLARE
    tbl text;
    col text;
    qry text;
BEGIN
    -- Lista de tablas que contienen texto
    FOR tbl IN SELECT unnest(ARRAY[
        'products',
        'clients',
        'providers',
        'orders'
    ])
    LOOP
        -- Para cada tabla, identificar columnas de texto y recodificarlas
        FOR col IN
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = tbl
              AND data_type IN ('character varying','text')
        LOOP
            qry := format($f$
                UPDATE public.%I
                SET %I = convert_from(convert_to(%I, 'LATIN1'), 'UTF8')
                WHERE %I IS NOT NULL;
            $f$, tbl, col, col, col);
            RAISE NOTICE 'Corrigiendo %.%', tbl, col;
            EXECUTE qry;
        END LOOP;
    END LOOP;
END$$;
