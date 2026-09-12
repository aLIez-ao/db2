-- ============================================================================
-- SEPOMEX CDMX · 01_schema.sql
-- Motor objetivo : MySQL 8.0 (puerto 3306, servicio local en Manual)
-- Charset        : utf8mb4 + utf8mb4_spanish_ci en BD, tablas y columnas.
--                  spanish_ci ordena como el español (ñ tras n, acentos con
--                  peso secundario) y preserva Á/É/Í/Ó/Ú/Ü/Ñ del catálogo.
-- Origen         : data/CodigosPostales.xls (HTML cp1252 encubierto) -> CSV UTF-8
-- Estado         : sincronizado con la BD viva (mysqldump 2026-09-11, idéntico)
--                  ver scripts/conversor_xls_csv.py y data/*.csv
-- Modelo         : 3FN. Un CP pertenece a un solo municipio y una sola
--                  oficina (verificado: 0 violaciones en 1531 filas).
--                  Grano de asentamiento = (cp, nombre, tipo): hay 4 casos
--                  reales con igual nombre y distinto tipo (ej. CP 09870
--                  'San Andrés Tomatlán' como Colonia y como Pueblo).
-- Uso            : mysql -u root -p < db/01_schema.sql
-- ============================================================================

CREATE DATABASE IF NOT EXISTS sepomex
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_spanish_ci;
-- ============================================================================
-- SEPOMEX CDMX · 01_schema.sql (Corregido y Optimizado para 3FN)
-- Motor objetivo : MySQL 8.0
-- Charset        : utf8mb4 + utf8mb4_spanish_ci
-- ============================================================================

CREATE DATABASE IF NOT EXISTS sepomex
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_spanish_ci;

USE sepomex;

-- ----------------------------------------------------------------------------
-- Catálogos
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS estado (
  id     SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_estado_nombre (nombre)
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS municipio (
  id        SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  estado_id SMALLINT UNSIGNED NOT NULL,
  nombre    VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_municipio_estado_nombre (estado_id, nombre),
  CONSTRAINT fk_municipio_estado FOREIGN KEY (estado_id)
    REFERENCES estado (id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS ciudad (
  id           SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  municipio_id SMALLINT UNSIGNED NOT NULL,
  nombre       VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ciudad_municipio_nombre (municipio_id, nombre),
  CONSTRAINT fk_ciudad_municipio FOREIGN KEY (municipio_id)
    REFERENCES municipio (id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS tipo_asentamiento (
  id     TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(30) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tipo_nombre (nombre)
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS oficina_postal (
  clave CHAR(5) NOT NULL,
  PRIMARY KEY (clave)
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;

-- ----------------------------------------------------------------------------
-- Núcleo: 1 CP -> N asentamientos
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS codigo_postal (
  cp             CHAR(5) NOT NULL,
  municipio_id   SMALLINT UNSIGNED NOT NULL,
  ciudad_id      SMALLINT UNSIGNED NULL,
  oficina_clave  CHAR(5) NULL,
  PRIMARY KEY (cp),
  KEY ix_cp_municipio (municipio_id),
  KEY ix_cp_ciudad (ciudad_id),
  KEY ix_cp_oficina (oficina_clave),
  CONSTRAINT chk_cp_formato CHECK (cp REGEXP '^[0-9]{5}$'),
  CONSTRAINT fk_cp_municipio FOREIGN KEY (municipio_id)
    REFERENCES municipio (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cp_ciudad FOREIGN KEY (ciudad_id)
    REFERENCES ciudad (id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_cp_oficina FOREIGN KEY (oficina_clave)
    REFERENCES oficina_postal (clave) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS asentamiento (
  id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cp      CHAR(5) NOT NULL,
  tipo_id TINYINT UNSIGNED NOT NULL,
  nombre  VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_asent_cp_nombre_tipo (cp, nombre, tipo_id),
  KEY ix_asent_tipo (tipo_id),
  CONSTRAINT fk_asent_cp FOREIGN KEY (cp)
    REFERENCES codigo_postal (cp) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_asent_tipo FOREIGN KEY (tipo_id)
    REFERENCES tipo_asentamiento (id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;

-- ----------------------------------------------------------------------------
-- Staging de carga (ETL)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS stg_sepomex_raw (
  codigo_postal     VARCHAR(10)  NULL,
  estado            VARCHAR(60)  NULL,
  municipio         VARCHAR(60)  NULL,
  ciudad            VARCHAR(60)  NULL,
  tipo_asentamiento VARCHAR(30)  NULL,
  asentamiento      VARCHAR(80)  NULL,
  clave_oficina     VARCHAR(10)  NULL
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;

-- ----------------------------------------------------------------------------
-- Vista plana (Ajustada con COALESCE)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_sepomex_plano AS
SELECT
  cp.cp              AS codigo_postal,
  e.nombre           AS estado,
  m.nombre           AS municipio,
  COALESCE(c.nombre, '') AS ciudad,
  t.nombre           AS tipo_asentamiento,
  a.nombre           AS asentamiento,
  COALESCE(cp.oficina_clave, '') AS clave_oficina
FROM asentamiento a
INNER JOIN codigo_postal cp  ON cp.cp = a.cp
INNER JOIN municipio m       ON m.id = cp.municipio_id
INNER JOIN estado e          ON e.id = m.estado_id
LEFT JOIN ciudad c           ON c.id = cp.ciudad_id
INNER JOIN tipo_asentamiento t ON t.id = a.tipo_id;
USE sepomex;

-- ----------------------------------------------------------------------------
-- Catálogos
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS estado (
  id     SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_estado_nombre (nombre)
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
  COMMENT = 'Entidad federativa. En este lote: Ciudad de México (1 fila).';

CREATE TABLE IF NOT EXISTS municipio (
  id        SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  estado_id SMALLINT UNSIGNED NOT NULL,
  nombre    VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_municipio_estado_nombre (estado_id, nombre),
  CONSTRAINT fk_municipio_estado FOREIGN KEY (estado_id)
    REFERENCES estado (id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
  COMMENT = 'Alcaldía. Lote CDMX: 16 filas.';

-- Decisión de diseño: ciudad cuelga de municipio (no de estado) para
-- conservar la cadena jerárquica estado→municipio→ciudad→cp→asentamiento
-- y permitir ejercicios de 4 JOINs encadenados. En este lote la única
-- ciudad es 'Ciudad de México' (16 filas, una por alcaldía).
CREATE TABLE IF NOT EXISTS ciudad (
  id           SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  municipio_id SMALLINT UNSIGNED NOT NULL,
  nombre       VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ciudad_municipio_nombre (municipio_id, nombre),
  CONSTRAINT fk_ciudad_municipio FOREIGN KEY (municipio_id)
    REFERENCES municipio (id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;

CREATE TABLE IF NOT EXISTS tipo_asentamiento (
  id     TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(30) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tipo_nombre (nombre)
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
  COMMENT = 'Colonia, Barrio, Pueblo, Equipamiento, Campamento, Aeropuerto.';

CREATE TABLE IF NOT EXISTS oficina_postal (
  clave CHAR(5) NOT NULL,
  PRIMARY KEY (clave)
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
  COMMENT = 'Clave de oficina SEPOMEX (45 en el lote). Sin nombre en origen.';

-- ----------------------------------------------------------------------------
-- Núcleo: 1 CP -> N asentamientos
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS codigo_postal (
  cp             CHAR(5) NOT NULL,
  municipio_id   SMALLINT UNSIGNED NOT NULL,
  ciudad_id      SMALLINT UNSIGNED NOT NULL,
  oficina_clave  CHAR(5) NOT NULL,
  PRIMARY KEY (cp),
  KEY ix_cp_municipio (municipio_id),
  KEY ix_cp_ciudad (ciudad_id),
  KEY ix_cp_oficina (oficina_clave),
  CONSTRAINT chk_cp_formato CHECK (cp REGEXP '^[0-9]{5}$'),
  CONSTRAINT fk_cp_municipio FOREIGN KEY (municipio_id)
    REFERENCES municipio (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cp_ciudad FOREIGN KEY (ciudad_id)
    REFERENCES ciudad (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cp_oficina FOREIGN KEY (oficina_clave)
    REFERENCES oficina_postal (clave) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
  COMMENT = 'Lote: 1110 CP distintos. CHAR(5) preserva ceros a la izquierda.';

CREATE TABLE IF NOT EXISTS asentamiento (
  id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cp      CHAR(5) NOT NULL,
  tipo_id TINYINT UNSIGNED NOT NULL,
  nombre  VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_asent_cp_nombre_tipo (cp, nombre, tipo_id),
  KEY ix_asent_tipo (tipo_id),
  CONSTRAINT fk_asent_cp FOREIGN KEY (cp)
    REFERENCES codigo_postal (cp) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_asent_tipo FOREIGN KEY (tipo_id)
    REFERENCES tipo_asentamiento (id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
  COMMENT = 'Grano del Excel original. Lote: 1531 filas.';

-- ----------------------------------------------------------------------------
-- Staging de carga (ETL): recibe el CSV tal cual, todo texto
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS stg_sepomex_raw (
  codigo_postal     VARCHAR(10)  NULL,
  estado            VARCHAR(60)  NULL,
  municipio         VARCHAR(60)  NULL,
  ciudad            VARCHAR(60)  NULL,
  tipo_asentamiento VARCHAR(30)  NULL,
  asentamiento      VARCHAR(80)  NULL,
  clave_oficina     VARCHAR(10)  NULL
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
  COMMENT = 'Tabla cruda para LOAD DATA. Ver db/02_load.sql.';

-- ----------------------------------------------------------------------------
-- Vista plana: reconstruye el grano original (descomposición sin pérdida:
-- SELECT COUNT(*) FROM v_sepomex_plano debe dar 1531)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_sepomex_plano AS
SELECT
  cp.cp              AS codigo_postal,
  e.nombre           AS estado,
  m.nombre           AS municipio,
  c.nombre           AS ciudad,
  t.nombre           AS tipo_asentamiento,
  a.nombre           AS asentamiento,
  cp.oficina_clave   AS clave_oficina
FROM asentamiento a
INNER JOIN codigo_postal cp  ON cp.cp = a.cp
INNER JOIN municipio m       ON m.id = cp.municipio_id
INNER JOIN estado e          ON e.id = m.estado_id
INNER JOIN ciudad c          ON c.id = cp.ciudad_id
INNER JOIN tipo_asentamiento t ON t.id = a.tipo_id;
