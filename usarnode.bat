param(
  [Parameter(Mandatory=$true)][ValidateSet('12','14','22','restore')]
  [string]$version,
  [switch]$SessionOnly  # si lo usas, NO persiste; solo cambia la sesión actual
)

# === RUTAS (ajústalas si cambian) ===
$node12 = 'C:\node\v12.18.2'
$node14 = 'C:\node\v14.21.3'
$node22 = 'C:\Program Files\nodejs'

# --- Helpers: SOLO USER PATH (HKCU) ---
function Get-UserPath {
  (Get-ItemProperty -Path 'HKCU:\Environment' -Name Path -ErrorAction SilentlyContinue).Path
}
function Set-UserPath([string]$newPath) {
  Set-ItemProperty -Path 'HKCU:\Environment' -Name Path -Value $newPath
}

# --- Backup/Restore de USER PATH ---
$backupFile = "$env:USERPROFILE\usarnode_userpath_backup.txt"
if ($version -eq 'restore') {
  if (Test-Path $backupFile) {
    $old = Get-Content $backupFile -Raw
    Set-UserPath $old
    Write-Host "[OK] PATH de usuario restaurado desde $backupFile"
  } else {
    Write-Host "[WARN] No existe backup en $backupFile"
  }
  exit 0
}

# Selección de target (solo rutas existentes)
$target = switch ($version) {
  '12' { $node12 }
  '14' { $node14 }
  '22' { $node22 }
}
if (-not (Test-Path (Join-Path $target 'node.exe'))) {
  Write-Error "No se encontró node.exe en '$target'"; exit 1
}

# Conjunto de rutas Node que queremos sacar del USER PATH si estuvieran
$knownNodes = @($node12, $node14, $node22) | Where-Object { $_ -and (Test-Path $_) }

# 1) Leer SOLO USER PATH actual (sin mezclar con PATH de sistema)
$userPath = Get-UserPath
$userParts = @()
if ($userPath) { $userParts = $userPath -split ';' | Where-Object { $_.Trim() -ne '' } }

# 2) Filtrar entradas de Node (solo las conocidas) del USER PATH
$filteredUserParts = $userParts | Where-Object {
  $p = $_.Trim()
  -not ($knownNodes | Where-Object { $p -ieq $_ })
}

# 3) Construir nuevo USER PATH (target primero, luego todo lo que ya tenías)
$newUserPathParts = @($target) + $filteredUserParts
$newUserPath = ($newUserPathParts -join ';')

# 4) Cambiar la sesión actual SIN LEER HKLM (solo quitamos duplicados de Node en la sesión)
$sessionParts = ($env:PATH -split ';') | Where-Object { $_.Trim() -ne '' }
$sessionFiltered = $sessionParts | Where-Object {
  $p = $_.Trim()
  -not ($knownNodes | Where-Object { $p -ieq $_ })
}
$env:PATH = ($target + ';' + ($sessionFiltered -join ';'))

# 5) Persistir SOLO si no es SessionOnly (y guardar backup la primera vez o si cambia)
if (-not $SessionOnly) {
  if (-not (Test-Path $backupFile)) {
    $userPath | Out-File -Encoding UTF8 $backupFile
  }
  Set-UserPath $newUserPath
  Write-Host "[OK] USER PATH actualizado en HKCU (no se leyó ni tocó HKLM). Abre nueva consola para verlo aplicado." -ForegroundColor Green
} else {
  Write-Host "[INFO] Cambio aplicado SOLO a esta ventana. HKCU no fue modificado." -ForegroundColor Yellow
}

# 6) Mostrar versiones
& "$target\node.exe" -v
try {
  & "$target\node.exe" "$target\node_modules\npm\bin\npm-cli.js" -v
} catch { Write-Host "(npm no encontrado en esa carpeta)" -ForegroundColor DarkYellow }s