-- ============================================================================
-- SEPOMEX CDMX · 02_load.sql — Carga ETL (staging -> modelo 3FN)
-- ============================================================================

USE sepomex;

-- 1) Staging limpio
TRUNCATE TABLE stg_sepomex_raw;

-- 2) Carga cruda
LOAD DATA LOCAL INFILE 'M:/_Documentos/.Proyectos/_universidad/db2/sepomex/data/codigos_postales_cdmx.csv'
INTO TABLE stg_sepomex_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(codigo_postal, estado, municipio, ciudad, tipo_asentamiento, asentamiento, clave_oficina);

-- 3) Normalización
INSERT IGNORE INTO estado (nombre)
SELECT DISTINCT TRIM(estado) FROM stg_sepomex_raw WHERE TRIM(estado) <> '';

INSERT IGNORE INTO municipio (estado_id, nombre)
SELECT DISTINCT e.id, TRIM(s.municipio)
FROM stg_sepomex_raw s
INNER JOIN estado e ON e.nombre = TRIM(s.estado)
WHERE TRIM(s.municipio) <> '';

INSERT IGNORE INTO ciudad (municipio_id, nombre)
SELECT DISTINCT m.id, TRIM(s.ciudad)
FROM stg_sepomex_raw s
INNER JOIN estado e ON e.nombre = TRIM(s.estado)
INNER JOIN municipio m ON m.estado_id = e.id AND m.nombre = TRIM(s.municipio)
WHERE TRIM(s.ciudad) <> '';

INSERT IGNORE INTO tipo_asentamiento (nombre)
SELECT DISTINCT TRIM(tipo_asentamiento) FROM stg_sepomex_raw WHERE TRIM(tipo_asentamiento) <> '';

INSERT IGNORE INTO oficina_postal (clave)
SELECT DISTINCT TRIM(clave_oficina) FROM stg_sepomex_raw WHERE TRIM(clave_oficina) <> '';

-- ATENCIÓN: Uso de LEFT JOIN para CPs sin ciudad asignada y NULLIF para oficinas vacías
INSERT IGNORE INTO codigo_postal (cp, municipio_id, ciudad_id, oficina_clave)
SELECT DISTINCT
  TRIM(s.codigo_postal), 
  m.id, 
  c.id, 
  NULLIF(TRIM(s.clave_oficina), '')
FROM stg_sepomex_raw s
INNER JOIN estado e    ON e.nombre = TRIM(s.estado)
INNER JOIN municipio m ON m.estado_id = e.id AND m.nombre = TRIM(s.municipio)
LEFT JOIN ciudad c     ON c.municipio_id = m.id AND c.nombre = TRIM(s.ciudad)
WHERE TRIM(s.codigo_postal) REGEXP '^[0-9]{5}$';

INSERT IGNORE INTO asentamiento (cp, tipo_id, nombre)
SELECT DISTINCT TRIM(s.codigo_postal), t.id, TRIM(s.asentamiento)
FROM stg_sepomex_raw s
INNER JOIN tipo_asentamiento t ON t.nombre = TRIM(s.tipo_asentamiento)
INNER JOIN codigo_postal cp ON cp.cp = TRIM(s.codigo_postal)
WHERE TRIM(s.asentamiento) <> '';

-- 4) Verificación post-carga
SELECT 'stg' AS tabla, COUNT(*) AS filas FROM stg_sepomex_raw
UNION ALL SELECT 'estado', COUNT(*) FROM estado
UNION ALL SELECT 'municipio', COUNT(*) FROM municipio
UNION ALL SELECT 'ciudad', COUNT(*) FROM ciudad
UNION ALL SELECT 'tipo_asentamiento', COUNT(*) FROM tipo_asentamiento
UNION ALL SELECT 'oficina_postal', COUNT(*) FROM oficina_postal
UNION ALL SELECT 'codigo_postal', COUNT(*) FROM codigo_postal
UNION ALL SELECT 'asentamiento', COUNT(*) FROM asentamiento
UNION ALL SELECT 'v_sepomex_plano', COUNT(*) FROM v_sepomex_plano;