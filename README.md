# db2-sepomex · Catálogos SEPOMEX por rama

Repositorio de la materia **Bases de Datos II**: cada rama construye, a partir
de su propio lote del Catálogo Nacional de Códigos Postales (SEPOMEX / Correos
de México), una base de datos normalizada en **MySQL 8.0** más su serie de
ejercicios SQL. Todas las ramas siguen la misma estructura y el mismo formato.

> **`main` es solo el índice.** El trabajo vive en las ramas.

## Ramas

| Rama | Lote | Contenido |
|---|---|---|
| [`ao`](https://github.com/aLIez-ao/db2-sepomex/tree/ao) | Ciudad de México · 1531 filas | BD 3FN (`estado→municipio→ciudad→codigo_postal→asentamiento` + catálogos, vista `v_sepomex_plano`), 17 ejercicios E01–E17 con solución y resultados verificados, diagrama ER, Docker opcional |
| `…` | — | Agrega aquí tu rama con el mismo formato: `\| [tu-rama](…/tree/tu-rama) \| lote \| descripción \|` |

## Estructura que sigue cada rama

```
<rama>/
├── db/            # 01_schema.sql (DDL), 02_load.sql (ETL), sepomex.dbml (modelo)
├── data/          # lote crudo (.xls) + CSV UTF-8 procesado
├── docs/          # diagrama ER (png/svg)
├── scripts/       # conversión cp1252→UTF-8 y carga local
├── docker/        # entorno reproducible (compose + seed)
├── ejercicios/    # serie enunciado+solución (cubre comparadores, LIKE,
│                  #   BETWEEN/IN/NULL, JOINs, UNION, CROSS JOIN)
├── soluciones/    # resultados verificados contra la BD viva
└── README.md      # cómo arrancar y cargar esa rama
```

## Ver una rama

```bash
git fetch origin
git checkout ao        # o cualquier otra rama de la tabla
```

En GitHub: botón de ramas (arriba a la izquierda) → elige la rama → su
`README.md` explica cómo levantar su base de datos y correr sus ejercicios.
