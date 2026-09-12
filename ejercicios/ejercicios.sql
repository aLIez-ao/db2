-- ============================================================================
-- SEPOMEX CDMX · Serie de ejercicios (Enunciado + Solución)
-- Cubre reglas.md: comparadores [= != < <= > >=], LIKE / NOT LIKE,
-- IS NULL, BETWEEN / IN (+ negaciones), AND / OR / paréntesis,
-- INNER / LEFT JOIN, diferencia (LEFT + IS NULL), UNION / UNION ALL,
-- CROSS JOIN. Tablas: modelo 3FN + vista v_sepomex_plano.
-- "Resultado esperado" = verificado contra la BD real (lote 1531 filas).
-- Uso: mysql -u root -p sepomex < ejercicios/ejercicios.sql
-- ============================================================================
USE sepomex;

-- ==========================================================================
-- BLOQUE 1 · COMPARADORES DE TEXTO (LIKE / NOT LIKE) — reglas §3A
-- ==========================================================================

-- E01 [contains] Asentamientos cuyo nombre CONTIENE 'Sección'.
-- Resultado esperado: 111 filas.
SELECT codigo_postal, asentamiento, municipio
FROM v_sepomex_plano
WHERE asentamiento LIKE '%Sección%';

-- E02 [begin with] Asentamientos que INICIAN con 'Santa' (insensible a
-- mayúsculas por utf8mb4_spanish_ci).
-- Resultado esperado: 67 filas.
SELECT codigo_postal, asentamiento, municipio
FROM v_sepomex_plano
WHERE asentamiento LIKE 'Santa%';

-- E03 [does not contain] Asentamientos que NO contienen la letra 'a'.
-- Resultado esperado: 132 filas.
SELECT codigo_postal, asentamiento
FROM v_sepomex_plano
WHERE asentamiento NOT LIKE '%a%';

-- E04 [end with / does not end with] Asentamientos que TERMINAN en 'n'
-- y, aparte, los que NO terminan en 'n'. Compara ambos conteos.
-- Resultado esperado: 233 terminan en 'n'; 1298 no terminan en 'n'.
SELECT COUNT(*) AS terminan_en_n
FROM v_sepomex_plano WHERE asentamiento LIKE '%n';
SELECT COUNT(*) AS no_terminan_en_n
FROM v_sepomex_plano WHERE asentamiento NOT LIKE '%n';

-- ==========================================================================
-- BLOQUE 2 · RANGOS, LISTAS Y VACÍO — reglas §3B
-- ==========================================================================

-- E05 [is between] Filas con CP entre '01400' y '01600' (CHAR(5): el orden
-- lexicográfico equivale al numérico porque todos tienen 5 dígitos).
-- Resultado esperado: 49 filas.
SELECT codigo_postal, asentamiento, municipio
FROM v_sepomex_plano
WHERE codigo_postal BETWEEN '01400' AND '01600'
ORDER BY codigo_postal;

-- E06 [is not between] Filas con CP FUERA de ese rango.
-- Resultado esperado: 1482 filas (1531 - 49).
SELECT COUNT(*) AS fuera_de_rango
FROM v_sepomex_plano
WHERE codigo_postal NOT BETWEEN '01400' AND '01600';

-- E07 [is in list] Asentamientos de Coyoacán o Iztapalapa.
-- Resultado esperado: 295 filas.
SELECT municipio, codigo_postal, asentamiento
FROM v_sepomex_plano
WHERE municipio IN ('Coyoacán', 'Iztapalapa')
ORDER BY municipio, codigo_postal;

-- E08 [is not in list] Asentamientos cuyo tipo NO es Colonia ni Barrio
-- (Pueblo, Equipamiento, Campamento, Aeropuerto).
-- Resultado esperado: 100 filas (87 + 9 + 3 + 1).
SELECT tipo_asentamiento, COUNT(*) AS n
FROM v_sepomex_plano
WHERE tipo_asentamiento NOT IN ('Colonia', 'Barrio')
GROUP BY tipo_asentamiento;

-- ==========================================================================
-- BLOQUE 3 · RELACIONALES Y LÓGICA — reglas §3C
-- ==========================================================================

-- E09 [=, >, AND] Colonias con CP mayor a '09000'.
-- Resultado esperado: 585 filas.
SELECT codigo_postal, asentamiento, municipio
FROM v_sepomex_plano
WHERE tipo_asentamiento = 'Colonia' AND codigo_postal > '09000';

-- E10 [OR] Asentamientos de Álvaro Obregón o de Coyoacán.
-- Resultado esperado: 318 filas (222 + 96).
SELECT municipio, codigo_postal, asentamiento
FROM v_sepomex_plano
WHERE municipio = 'Álvaro Obregón' OR municipio = 'Coyoacán';

-- E11 [>=, <=, !=, paréntesis] CPs del tramo 01000–02000 cuya oficina
-- NO sea la '01401'. Los paréntesis aíslan el rango del filtro !=.
-- Grano vista = asentamiento.
-- Resultado esperado: 91 filas (53 CP distintos en ese tramo y oficina).
SELECT codigo_postal, asentamiento, clave_oficina
FROM v_sepomex_plano
WHERE (codigo_postal >= '01000' AND codigo_postal <= '02000')
  AND clave_oficina != '01401';

-- ==========================================================================
-- BLOQUE 4 · JOINS Y CONJUNTOS — reglas §2
-- ==========================================================================

-- E12 [INNER JOIN] Cada asentamiento con su municipio y su tipo, subiendo
-- por la cadena asentamiento → codigo_postal → municipio.
-- Resultado esperado: 1531 filas (todo asentamiento tiene CP y municipio).
SELECT a.nombre AS asentamiento, m.nombre AS municipio, t.nombre AS tipo
FROM asentamiento a
INNER JOIN codigo_postal cp ON cp.cp = a.cp
INNER JOIN municipio m      ON m.id = cp.municipio_id
INNER JOIN tipo_asentamiento t ON t.id = a.tipo_id
ORDER BY m.nombre, a.nombre
LIMIT 20;

-- E13 [LEFT JOIN + IS NULL = diferencia] Municipios SIN ningún código postal
-- cargado. Es el patrón "inscritos en BD2 y NO en TE" de reglas §2C.
-- Resultado esperado: 0 filas (los 16 municipios tienen CP: cobertura total).
SELECT m.nombre AS municipio_sin_cp
FROM municipio m
LEFT JOIN codigo_postal cp ON cp.municipio_id = m.id
WHERE cp.cp IS NULL;

-- E14 [Diferencia práctica] Municipios que NO tienen ningún asentamiento
-- de tipo 'Aeropuerto' (solo 1 alcaldía lo tiene).
-- Resultado esperado: 15 filas.
SELECT m.nombre AS municipio
FROM municipio m
WHERE m.id NOT IN (
  SELECT DISTINCT cp.municipio_id
  FROM codigo_postal cp
  INNER JOIN asentamiento a      ON a.cp = cp.cp
  INNER JOIN tipo_asentamiento t ON t.id = a.tipo_id
  WHERE t.nombre = 'Aeropuerto'
)
ORDER BY m.nombre;

-- E15 [UNION vs UNION ALL] Nombres de asentamiento de Álvaro Obregón más
-- los de Coyoacán. UNION elimina duplicados; UNION ALL los conserva.
-- Resultado esperado: UNION = 314, UNION ALL = 318 (4 nombres en común).
SELECT a.nombre
FROM asentamiento a
INNER JOIN codigo_postal cp ON cp.cp = a.cp
INNER JOIN municipio m ON m.id = cp.municipio_id
WHERE m.nombre = 'Álvaro Obregón'
UNION
SELECT a.nombre
FROM asentamiento a
INNER JOIN codigo_postal cp ON cp.cp = a.cp
INNER JOIN municipio m ON m.id = cp.municipio_id
WHERE m.nombre = 'Coyoacán';

-- E16 [CROSS JOIN] Producto cartesiano tipos × oficinas (todas las
-- combinaciones posibles, existan o no en los datos).
-- Resultado esperado: 270 filas (6 × 45).
SELECT t.nombre AS tipo, o.clave AS oficina
FROM tipo_asentamiento t
CROSS JOIN oficina_postal o
ORDER BY t.nombre, o.clave
LIMIT 20;

-- ==========================================================================
-- E17 · INTEGRADOR (estilo reglas §3: todo combinado)
-- Colonias de Iztapalapa o Gustavo A. Madero, con CP entre 07000 y 09999,
-- cuyo asentamiento contenga 'San' pero NO termine en 'o'.
-- Resultado esperado: verifica tu query; la solución de referencia da 55.
-- ==========================================================================
SELECT codigo_postal, asentamiento, municipio
FROM v_sepomex_plano
WHERE tipo_asentamiento = 'Colonia'
  AND (municipio = 'Iztapalapa' OR municipio = 'Gustavo A. Madero')
  AND codigo_postal BETWEEN '07000' AND '09999'
  AND asentamiento LIKE '%San%'
  AND asentamiento NOT LIKE '%o';
