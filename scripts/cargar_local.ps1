# =====================================================================
# SEPOMEX · Carga local en MySQL 8.0 del equipo (servicio en Manual)
# Arranca MySQL80 si está detenido, habilita LOAD DATA LOCAL y ejecuta
# db/01_schema.sql + db/02_load.sql (sustituyendo <RUTA_CSV> solo).
# Uso:  powershell -ExecutionPolicy Bypass -File .\scripts\cargar_local.ps1
#       .\scripts\cargar_local.ps1 -User root -Port 3306
# =====================================================================
[CmdletBinding()]
param(
  [string]$User = 'root',
  [int]$Port = 3306,
  [switch]$SkipStart
)

$ErrorActionPreference = 'Stop'
$Base = Split-Path -Parent $PSScriptRoot
$Csv  = Join-Path $Base 'data\codigos_postales_cdmx.csv'

if (-not (Test-Path -LiteralPath $Csv)) {
  throw "No existe el CSV UTF-8: $Csv (generalo con scripts/convertir_xls_a_csv.py)"
}

if (-not $SkipStart) {
  $svc = Get-Service -Name 'MySQL80' -ErrorAction SilentlyContinue
  if ($null -ne $svc -and $svc.Status -ne 'Running') {
    Write-Host 'Arrancando servicio MySQL80 (Manual)...'
    Start-Service -Name 'MySQL80'
    $svc.WaitForStatus('Running', '00:01:00')
  }
}

$mysql = Get-Command 'mysql.exe' -ErrorAction SilentlyContinue
if ($null -eq $mysql) {
  $mysql = Get-ChildItem 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe' -ErrorAction SilentlyContinue
  if ($null -eq $mysql) { throw 'No se encontró mysql.exe (¿MySQL 8.0 instalado?)' }
  $mysql = $mysql.FullName
} else { $mysql = $mysql.Source }

# LOAD DATA LOCAL requiere flag de cliente + variable de servidor
& $mysql --protocol=tcp -h 127.0.0.1 -P $Port -u $User -p `
  -e "SET GLOBAL local_infile = 1;"
if ($LASTEXITCODE -ne 0) { throw 'Falló SET GLOBAL local_infile (revisa usuario/clave)' }

& $mysql --protocol=tcp -h 127.0.0.1 -P $Port -u $User -p --local-infile=1 `
  -e "SOURCE $($Base -replace '\\','/')/db/01_schema.sql;"
if ($LASTEXITCODE -ne 0) { throw 'Falló 01_schema.sql' }

# Sustitución de <RUTA_CSV> (MySQL exige literal en LOAD DATA)
$rutaSql = ($Csv -replace '\\', '/')
$sql = Get-Content -LiteralPath (Join-Path $Base 'db\02_load.sql') -Raw -Encoding utf8
$sql = $sql.Replace('<RUTA_CSV>', $rutaSql)
$tmp = Join-Path ([IO.Path]::GetTempPath()) 'sepomex_02_load_tmp.sql'
[IO.File]::WriteAllText($tmp, $sql, (New-Object Text.UTF8Encoding $false))  # UTF-8 sin BOM (PS 5.1 no tiene utf8NoBOM)

try {
  & $mysql --protocol=tcp -h 127.0.0.1 -P $Port -u $User -p --local-infile=1 --default-character-set=utf8mb4 sepomex -e "SOURCE $($tmp -replace '\\','/');"
  if ($LASTEXITCODE -ne 0) { throw 'Falló 02_load.sql' }
} finally {
  Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
}

Write-Host 'Carga OK: verifica arriba los conteos (stg 1531, cp 1110, asent 1531).'
