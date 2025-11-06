param(
  [Parameter(Mandatory=$true)][ValidateSet('12','14','22')] [string]$version,
  [switch]$SessionOnly  # si lo usas, cambia solo esta ventana; si NO, también deja persistente (usuario)
)

# === AJUSTA ESTAS RUTAS SI CAMBIAN EN TU PC ===
$node12 = 'C:\node\v12.18.2'
$node14 = 'C:\node\v14.21.3'
$node22 = 'C:\Program Files\nodejs'  # instalación por defecto

$target = switch ($version) {
  '12' { $node12 }
  '14' { $node14 }
  '22' { $node22 }
}

if (-not (Test-Path (Join-Path $target 'node.exe'))) {
  Write-Error "No se encontró node.exe en '$target'. Ajusta la ruta o revisa la instalación."
  exit 1
}

# --- Helpers: leer/escribir PATH de usuario sin tocar el del sistema ---
function Get-UserPath {
  [Environment]::GetEnvironmentVariable('Path','User')
}
function Set-UserPath($newPath) {
  [Environment]::SetEnvironmentVariable('Path',$newPath,'User')
}

# Rutas de Node a limpiar del PATH de usuario (para no duplicar/mezclar)
$knownNodeDirs = @($node12, $node14, $node22) | Where-Object { $_ -and (Test-Path $_) }

# 1) Construye el nuevo PATH de usuario preservando TODO lo demás
$userPath = Get-UserPath
$parts = @()
if ($userPath) {
  $parts = $userPath -split ';' | Where-Object { $_ -ne '' }
}

# filtra cualquier entrada que sea una de las rutas de Node conocidas (case-insensitive)
$filtered = $parts | Where-Object {
  $p = $_.Trim()
  -not ($knownNodeDirs | Where-Object { $p -ieq $_ })
}

# Prepend el target y recompón
$newUserPath = @($target) + $filtered
$newUserPathStr = ($newUserPath -join ';')

# 2) Aplica a la SESIÓN ACTUAL siempre
$env:PATH = "$target;" + ($env:PATH -split ';' | Where-Object {
  $p = $_.Trim()
  -not ($knownNodeDirs | Where-Object { $p -ieq $_ })
} | ForEach-Object { $_ } -join ';')

# 3) Si NO es solo sesión, también deja persistente en el PATH de usuario
if (-not $SessionOnly) {
  Set-UserPath $newUserPathStr
  Write-Host "[OK] PATH de USUARIO actualizado (persistente). Abre una nueva consola para verlo aplicado." -ForegroundColor Green
} else {
  Write-Host "[INFO] Cambio aplicado SOLO a esta ventana (sesión actual)." -ForegroundColor Yellow
}

# 4) Comprobación
$nodeVer = & "$target\node.exe" -v 2>$null
$npmVer  = ''
if (Test-Path (Join-Path $target 'node_modules\npm\bin\npm-cli.js')) {
  $npmVer = & "$target\node.exe" (Join-Path $target 'node_modules\npm\bin\npm-cli.js') -v 2>$null
}
Write-Host ("Usando Node desde: " + $target)
Write-Host ("  node " + $nodeVer)
if ($npmVer) { Write-Host ("  npm  " + $npmVer) } else { Write-Host "  npm  (no encontrado en esa carpeta)" }