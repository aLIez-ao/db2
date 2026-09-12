# SEPOMEX CDMX · Resultados verificados (E01–E17)

Capturados del servicio real **MySQL 8.0.46, BD `sepomex`** tras `db/02_load.sql`.
Soluciones en `ejercicios/ejercicios.sql`. Reproduce con:

```powershell
mysql -h 127.0.0.1 -P 3306 -u root -p sepomex < ejercicios\ejercicios.sql
```

## Tabla de resultados

| Ej | Tema (reglas.md) | Resultado |
|---|---|---|
| E01 | `LIKE '%Sección%'` (contains) | 111 filas |
| E02 | `LIKE 'Santa%'` (begin with) | 67 filas |
| E03 | `NOT LIKE '%a%'` (does not contain) | 132 filas |
| E04 | `LIKE '%n'` / `NOT LIKE '%n'` (end with) | 233 / 1298 (233+1298 = 1531 ✔) |
| E05 | `BETWEEN '01400' AND '01600'` | 49 filas |
| E06 | `NOT BETWEEN` | 1482 filas (1531−49 ✔) |
| E07 | `IN ('Coyoacán','Iztapalapa')` | 295 filas |
| E08 | `NOT IN ('Colonia','Barrio')` | 100 filas (87 Pueblo + 9 Equip. + 3 Camp. + 1 Aerop. ✔) |
| E09 | `= + > + AND` (Colonias, CP > 09000) | 585 filas |
| E10 | `OR` (Álvaro Obregón o Coyoacán) | 318 filas (222 + 96) |
| E11 | `(rango) AND !=` (01000–02000, of. ≠ 01401) | **91 filas** a grano asentamiento (53 CP distintos) |
| E12 | `INNER JOIN` ×4 tablas | 1531 filas (integridad total ✔) |
| E13 | `LEFT JOIN + IS NULL` (diferencia) | **0 filas**: los 16 municipios tienen CP (cobertura total) |
| E14 | Diferencia (municipios sin 'Aeropuerto') | 15 filas |
| E15 | `UNION` vs `UNION ALL` | 314 vs 318 → **4 nombres en común** entre ambas alcaldías |
| E16 | `CROSS JOIN` tipos × oficinas | 270 filas (6 × 45 ✔) |
| E17 | Integrador (§3: `= AND OR BETWEEN LIKE NOT LIKE`) | 55 filas |

## Lecturas didácticas

- **E04/E06**: los conteos complementarios suman 1531; si no, hay `NULL` ocultos.
- **E13 = 0** no es error: es cobertura total, el caso base del patrón diferencia.
- **E15**: `UNION ALL − UNION = 4` revela 4 nombres de asentamiento compartidos.
- **E11**: el grano importa — 91 asentamientos vs 53 CP; misma condición, distinta tabla.
- **E08**: la suma por tipo (87+9+3+1 = 100) valida el `NOT IN`.
