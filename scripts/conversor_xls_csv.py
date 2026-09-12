#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convierte el catalogo SEPOMEX distribuido como .xls a CSV UTF-8 limpio.

Contexto de codificacion (IMPORTANTE):
  - El archivo `CodigosPostales.xls` NO es un BIFF de Excel real: es una tabla
    HTML (`<table>...`) guardada con extension .xls (practica comun de SEPOMEX).
  - Esta codificado en Windows-1252 (cp1252), NO en UTF-8: contiene bytes como
    0xE1 (a con acento) que rompen cualquier lector UTF-8 / lector XLS real.
  - Este script lo lee como cp1252 y escribe CSV estrictamente en UTF-8
    (sin BOM), con salto de linea LF, para que MySQL lo ingiera con
    `CHARACTER SET utf8mb4` sin corrupcion de acentos ni enes.

Uso:
    python scripts/convertir_xls_a_csv.py [entrada] [salida]

Idempotente: misma entrada -> misma salida (filas en orden de origen).
"""
from __future__ import annotations

import csv
import html as ihtml
import re
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
ENTRADA_DEFAULT = BASE / "data" / "CodigosPostales.xls"
SALIDA_DEFAULT = BASE / "data" / "codigos_postales_cdmx.csv"

ORIGEN_ENCODING = "cp1252"   # encoding real del .xls (HTML encubierto)
DESTINO_ENCODING = "utf-8"   # encoding exigido del CSV

COLUMNAS = [
    "codigo_postal",
    "estado",
    "municipio",
    "ciudad",
    "tipo_asentamiento",
    "asentamiento",
    "clave_oficina",
]

FILA_RE = re.compile(r'<tr class=.dgNormal.>(.*?)</tr>', re.S)
CELDA_RE = re.compile(r"<td>(.*?)</td>", re.S)


def limpiar(texto: str) -> str:
    """Quita entidades HTML y espacios redundantes sin alterar acentos."""
    texto = ihtml.unescape(texto)
    texto = re.sub(r"\s+", " ", texto).strip()
    return texto


def extraer_filas(html: str) -> list[list[str]]:
    filas: list[list[str]] = []
    for m in FILA_RE.finditer(html):
        celdas = [limpiar(c) for c in CELDA_RE.findall(m.group(1))]
        if len(celdas) != 7:
            raise ValueError(f"Fila inesperada con {len(celdas)} celdas: {celdas!r}")
        filas.append(celdas)
    if not filas:
        raise ValueError("No se encontraron filas dgNormal: ¿cambio el formato del .xls?")
    return filas


def main(entrada: Path = ENTRADA_DEFAULT, salida: Path = SALIDA_DEFAULT) -> None:
    crudo = entrada.read_bytes()
    try:
        crudo.decode("utf-8")
        print("AVISO: la entrada ya decodifica como UTF-8; se lee igual como cp1252 por compatibilidad SEPOMEX.")
    except UnicodeDecodeError:
        pass  # caso esperado: el .xls es cp1252
    html = crudo.decode(ORIGEN_ENCODING)
    filas = extraer_filas(html)

    salida.parent.mkdir(parents=True, exist_ok=True)
    with salida.open("w", encoding=DESTINO_ENCODING, newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(COLUMNAS)
        w.writerows(filas)

    # Verificacion de round-trip UTF-8
    with salida.open("r", encoding=DESTINO_ENCODING, newline="") as f:
        n = sum(1 for _ in f) - 1
    assert n == len(filas), f"round-trip UTF-8 inconsistente: {n} != {len(filas)}"
    print(f"OK: {len(filas)} filas {ORIGEN_ENCODING} -> {DESTINO_ENCODING}: {salida}")


if __name__ == "__main__":
    ent = Path(sys.argv[1]) if len(sys.argv) > 1 else ENTRADA_DEFAULT
    sal = Path(sys.argv[2]) if len(sys.argv) > 2 else SALIDA_DEFAULT
    main(ent, sal)
