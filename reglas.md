# Guía Completa de Referencia: SQL, Comparadores y Joins

```sql
-- ============================================================================
-- 1. ESTRUCTURA Y COMPONENTES VISUALES
-- ============================================================================

-- MENÚ DESPLEGABLE DE FILTROS (UI)
-- [=] Igual | [!=] Diferente | [<] Menor | [<=] Menor o Igual | [>] Mayor | [>=] Mayor o Igual
-- [contains] | [does not contain] | [begin with] | [does not begin with]
-- [end with] | [does not end with] | [is null] | [is not null] | [is empty]
-- [is not empty] | [is between] | [is not between] | [is in list] | [is not in list]

-- TABLAS DE EJEMPLO DE CONJUNTOS
-- CONJUNTO A: {1, 2, 3}
-- CONJUNTO B: {'A', 'B', 'C'}


-- ============================================================================
-- 2. TIPOS DE JOIN Y OPERACIONES DE CONJUNTOS
-- ============================================================================

-- A. INNER JOIN (Intersección)
-- Devuelve únicamente los registros que coinciden en ambas tablas.
SELECT 
    t1.columna_a,
    t2.columna_b
FROM tabla1 t1
INNER JOIN tabla2 t2 
    ON t1.id = t2.tabla1_id;

-- B. LEFT JOIN (Tabla Izquierda Completa)
-- Devuelve todos los registros de T1 y los coincidentes de T2.
SELECT 
    t1.columna_a,
    t2.columna_b
FROM tabla1 t1
LEFT JOIN tabla2 t2 
    ON t1.id = t2.tabla1_id;

-- C. DIFERENCIA DE CONJUNTOS (Caso Práctico)
-- ¿Quiénes están inscritos en BD2 y NO inscritos en TE?
SELECT 
    bd2.estudiante_id,
    bd2.nombre
FROM inscritos_bd2 bd2
LEFT JOIN inscritos_te te 
    ON bd2.estudiante_id = te.estudiante_id
WHERE te.estudiante_id IS NULL;

-- D. CONCEPTOS Y OTROS JOINS
-- - JOINS: Combinación de filas de dos o más tablas vía una clave común.
-- - INTERSECCIÓN: Coincidencia exacta de elementos entre conjuntos.
-- - UNIÓN: Combinación del resultado de dos consultas (UNION / UNION ALL).
-- - CROSS JOIN: Producto cartesiano (combina cada fila de T1 con todas las de T2).
SELECT * 
FROM tabla1 
CROSS JOIN tabla2;


-- ============================================================================
-- 3. COMPARADORES, PATRONES Y FILTROS EN CONSULTA REAL
-- Texto base de evaluación en los apuntes: 'bienvenidos a la clase de bd2'
-- ============================================================================

SELECT 
    id,
    texto_evaluar,
    fecha_registro,
    estado,
    monto
FROM datos_ejemplo
WHERE 
    -- A. COMPARACIÓN DE TEXTO (PATRONES LIKE / NOT LIKE)
    texto_evaluar LIKE '%bien%'                      -- Contains (Contiene) -> COINCIDE
    AND texto_evaluar NOT LIKE '%a%'                 -- Does not contain (NO contiene) -> NO COINCIDE
    AND texto_evaluar LIKE 'clase%'                  -- Begin with (Inicie con) -> NO COINCIDE
    AND texto_evaluar NOT LIKE 'clase%'              -- Does not begin with (NO inicie con) -> COINCIDE
    AND texto_evaluar LIKE '%d2'                     -- End with (Termine con) -> COINCIDE
    AND texto_evaluar NOT LIKE '%d3'                 -- Does not end with (NO termine con) -> COINCIDE

    -- B. NULOS, VACÍOS, RANGOS Y LISTAS
    AND estado IS NOT NULL                           -- Is not null (NO es nulo)
    AND estado IS NULL                               -- Is null (Es nulo)
    AND texto_evaluar <> ''                          -- Is not empty (NO está vacío)
    AND texto_evaluar = ''                           -- Is empty (Está vacío)
    AND fecha_registro BETWEEN '2026-01-01' AND '2026-12-31'     -- Is between (Entre dos fechas)
    AND fecha_registro NOT BETWEEN '2026-01-01' AND '2026-12-31' -- Is not between (NO entre dos fechas)
    AND estado IN ('ACTIVO', 'PENDIENTE', 'REVISADO')-- Is in list (En lista de valores)
    AND estado NOT IN ('INACTIVO', 'ELIMINADO')      -- Is not in list (NO en lista de valores)

    -- C. OPERADORES RELACIONALES, LÓGICOS Y AGRUPADORES
    AND (
        monto = 100.00                               -- Igual a
        OR monto != 0.00                             -- Diferente de (Desigualdad)
        OR (monto > 50.00 AND monto <= 500.00)       -- Mayor que AND Menor o igual que
        OR (monto < 10.00 AND monto >= 0.00)         -- Menor que AND Mayor o igual que
    );