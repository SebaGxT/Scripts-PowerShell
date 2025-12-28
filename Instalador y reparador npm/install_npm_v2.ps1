# ========================================
# Script: Instalador y Reparador de Node.js + npm con nvm
# Versión: 2.0.1
# Descripción: Instala versiones de Node.js con nvm y repara npm si está corrupto
# ========================================

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ========================================
# 0. VERIFICAR PERMISOS DE ADMINISTRADOR
# ========================================
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Instalador de Node.js + npm (nvm)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $isAdmin) {
    Write-Host "[ADVERTENCIA] Este script NO se está ejecutando como Administrador" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Si necesitas reparar npm corrupto, se requieren permisos elevados" -ForegroundColor Yellow
    Write-Host "para modificar archivos en C:\ProgramData\NVM\" -ForegroundColor Gray
    Write-Host ""
    $continue = Read-Host "¿continuar de todos modos? (S/N, Enter=No)"
    if ($continue -ne "S" -and $continue -ne "s") {
        Write-Host ""
        Write-Host "Para ejecutar como Administrador:" -ForegroundColor Cyan
        Write-Host "1. Click derecho en PowerShell" -ForegroundColor Gray
        Write-Host "2. Selecciona 'Ejecutar como administrador" -ForegroundColor Gray
        Write-Host "3. Ejecuta este script nuevamente" -ForegroundColor Gray
        Write-Host ""
        exit 0
    }
    Write-Host ""
} else {
    Write-Host "[OK] Ejecutando con permisos de Administrador" -ForegroundColor Green
    Write-Host ""
}

# ========================================
# 1. VERIFICAR QUE NVM ESTÉ INSTALADO Y EN PATH
# ========================================
$nvmInPath = $false
try {
    [void](nvm version 2>&1)
    if ($LASTEXITCODE -ne 0) { throw }
    $nvmInPath = $true
    Write-Host "[OK] nvm está instalado y accesible" -ForegroundColor Green
} catch {
    Write-Host "[ADVERTENCIA] nvm no responde al comando 'nvm'" -ForegroundColor Yellow
    Write-Host "Verificando si nvm está instalado pero no está en PATH..." -ForegroundColor Cyan

    # Buscar nvm.exe en ubicaciones comunes
    $nvmPossiblePaths = @(
        "$env:NVM_HOME\nvm.exe",
        "$env:ProgramFiles\nvm\nvm.exe",
        "$env:ProgramData\nvm\nvm.exe",
        "$env:LOCALAPPDATA\nvm\nvm.exe",
        "$env:USERPROFILE\AppData\Roaming\nvm\nvm.exe"
    )

    $nvmExePath = $null
    foreach ($path in $nvmPossiblePaths) {
        if ($path -and (Test-Path $path)) {
            $nvmExePath = $path
            $nvmDir = Split-Path $nvmExePath -Parent
            Write-Host "[OK] nvm encontrado en: $nvmDir" -ForegroundColor Green
            break
        }
    }

    if ($nvmExePath) {
        # nvm existe pero no está en PATH, agregarlo
        Write-Host "[ACCIÓN] Agregando nvm al PATH del usuario..." -ForegroundColor Cyan

        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $nvmDir = Split-Path $nvmExePath -Parent

        if ($userPath -notlike "*$nvmDir*") {
            $newPath = "$userPath;$nvmDir"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")

            # Actualizar PATH de la sesión actual
            $env:Path = "$env:Path,$nvmDir"

            Write-Host "[OK] nvm agregado al PATH del usuario" -ForegroundColor Green
            Write-Host "Variable NVM_HOME configurada como: $nvmDir" -ForegroundColor Gray

            # Configurar NVM_HOME si no existe
            if (-not $env:NVM_HOME) {
                [Environment]::SetEnvironmentVariable("NVM_HOME", $nvmDir, "User")
                $env:NVM_HOME = $nvmDir
            }

            # Verificar que ahora funcione
            try {
                [void](nvm version 2>&1)
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] nvm ahora está accesible" -ForegroundColor Green
                    $nvmInPath = $true
                }
            } catch {}
        }
    } else {
        Write-Host "[ERROR] nvm no está instalado en este sistema" -ForegroundColor Red
        Write-Host "Instala nvm-windows desde: https://github.com/coreybutler/nvm-windows/releases" -ForegroundColor Yellow
        exit 1
    }
}

if (-not $nvmInPath) {
    Write-Host "[ERROR] nvm no pudo ser configurado correctamente" -ForegroundColor Red
    Write-Host "Cierra esta ventana y abre una nueva terminal para que los cambios surtan efecto" -ForegroundColor Yellow
    exit 1
}

# ========================================
# 2. DETECTAR RUTA BASE DE NVM Y VERIFICAR PERMISOS
# ========================================

# PRIMERO: Verificar nvm root actual (lo que realmente está usando nvm)
Write-Host "[INFO] Detectando ubicación actual de nvm..." -ForegroundColor Cyan
$nvmBase = $null

try {
    $nvmRootOutput = nvm root 2>&1
    $currentRootLine = $nvmRootOutput | Select-String "Current Root:"
    if ($currentRootLine) {
        $nvmBase = $currentRootLine.ToString().Replace("Current Root:", "").Trim()
        if (Test-Path $nvmBase) {
            Write-Host "[OK] nvm root actual: $nvmBase" -ForegroundColor Green
        } else {
            Write-Host "[ADVERTENCIA] nvm root apunta a ubicación inexistente: $nvmBase" -ForegroundColor Yellow
            $nvmBase = $null
        }
    }
} catch {
    Write-Host "[ADVERTENCIA] No se pudo obtener nvm root" -ForegroundColor Yellow
}

# SEGUNDO: Si no se obtuvo de nvm root, buscar en ubicaciones comunes
if (-not $nvmBase) {
    Write-Host "[INFO] No se pudo obtener nvm root" -ForegroundColor Cyan
    $nvmPossibleBases = @(
        "$env:NVM_HOME",
        "$env:ProgramFiles\nvm",
        "$env:ProgramData\nvm",
        "$env:LOCALAPPDATA\nvm",
        "$env:USERPROFILE\AppData\Roaming\nvm"
    )

    foreach ($base in $nvmPossibleBases) {
        if ($base -and (Test-Path $base)) {
            $nvmBase = $base
            Write-Host "[OK] Ruta de nvm detectada: $nvmBase" -ForegroundColor Green
            break
        }
    }
}

# TERCERO: Si aún no se encontró, solicitar manualmente
if (-not $nvmBase) {
    Write-Host "[ADVERTENCIA] No se detectó automáticamente la ruta de nvm" -ForegroundColor Yellow
    $nvmBase = Read-Host "Ingresa la ruta base de nvm (ej: C:\ProgramData\nvm)"
    if (-not (Test-Path $nvmBase)) {
        Write-Host "[ERROR] La ruta ingresada no existe" -ForegroundColor Red
        exit 1
    }
}

# Verificar permisos de escritura en la ubicación de nvm
Write-host "[INFO] Verificando permisos de escritura en nvm..." -ForegroundColor Cyan
$testFile = "$nvmBase\test-write-permissions-$([Guid]::NewGuid()).tmp"
$hasWritePermissions = $false
try {
    "test" | Out-File $testFile -ErrorAction Stop
    Remove-Item $testFile -Force -ErrorAction Stop
    $hasWritePermissions = $true
    Write-Host "[OK] Tienes permisos de escritura en la ubicacion de nvm" -ForegroundColor Green
} catch {
    Write-Host "[ADVERTENCIA] No tienes permisos de escritura en: $nvmBase" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "LIMITACIONES DETECTADAS:" -ForegroundColor Red
    Write-Host "- No podrás reparar instalaciones corruptas de npm" -ForegroundColor Gray 
    Write-Host "- No podrás desinstalar versiones de Node.js" -ForegroundColor Gray
    Write-Host "- Solo podrás verificar versiones existentes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "OPCIONES DISPONIBLES:" -ForegroundColor Cyan
    Write-Host "1. Contactar al administrador de IT para:" -ForegroundColor Gray
    Write-Host "    - Cambiar permisos de la carpeta nvm" -ForegroundColor Gray
    Write-Host "    - Cambiar nvm root a tu carpeta de usuario" -ForegroundColor Gray
    Write-Host "    - Ejecutar este script como administrador" -ForegroundColor Gray
    Write-Host "2. Usar otra PC/ambiente con permisos completos" -ForegroundColor Gray
    Write-Host "3. Continuar solo para verificar versiones existentes (sin reparaciones)" -ForegroundColor Gray
    Write-Host ""
    $continuar = Read-Host "¿Deseas continuar de todos modos? (S/N, Enter=No)"
    if ($continuar -ne "S" -and $continuar -ne "s") {
        Write-Host ""
        Write-Host "Script cancelado. Para usar todas las funcionalidades:" -ForegroundColor Yellow
        Write-Host "- Solicita permisos de administrador" -ForegroundColor Gray
        Write-Host "- o pide que cambien nvm root a: $env:USERPROFILE\nvm" -ForegroundColor Gray
        exit 0
    }
    Write-Host ""
    Write-Host "[INFO] Continuando en modo limitado (solo verificación)..." -ForegroundColor Cyan
}

# ========================================
# 3. OBTENER VERSIONES DE NODE.JS
# ========================================
$nodeVersions = @()

# Opción 1: Buscar archivo .nvmrc en directorio actual
if (Test-Path ".nvmrc") {
    $nvmrcContent = Get-Content ".nvmrc" -Raw
    $nvmrcVersion = $nvmrcContent.Trim()
    Write-Host "[INFO] Archivo .nvmrc encontrado con versión: $nvmrcVersion" -ForegroundColor Cyan
    $useNvmrc = Read-Host "¿Usar esta versión? (S/N, Enter=Sí)"
    if ([string]::IsNullOrWhiteSpace($useNvmrc) -or $useNvmrc -eq "S" -or $useNvmrc -eq "s") {
        if ($nvmrcVersion -match '^\d+\.\d+\.\d+$') {
            $nodeVersions += $nvmrcVersion
            Write-Host "[OK] Usando versión de .nvmrc: $nvmrcVersion" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] La versión en .nvmrc no es válida: $nvmrcVersion" -ForegroundColor Red
        }
    }
}

# Opción 2: Ingresar versiones manualmente
if ($nodeVersions.Count -eq 0) {
    Write-Host ""
    Write-Host "No se usó .nvmrc o no existe." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Ingresa versiones adicionales de Node.js separadas por coma" -ForegroundColor Cyan
Write-Host "Ejemplos: 24.11.1,24.11.0,22.21.1" -ForegroundColor Gray
Write-Host "(Presiona Enter para omitir)" -ForegroundColor Gray
$manualInput = Read-Host "Versiones"

if (-not [string]::IsNullOrWhiteSpace($manualInput)) {
    $manualVersions = $manualInput -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    foreach ($ver in $manualVersions) {
        if ($ver -match '^\d+\.\d+\.\d+$') {
            $nodeVersions += $ver
        } else {
            Write-Host "[ERROR] Versión inválida: $ver" -ForegroundColor Red
        }
    }
}

if ($nodeVersions.Count -eq 0) {
    Write-Host "[ERROR] No se ingresaron versiones para procesar" -ForegroundColor Red
    exit 1
}

# Eliminar duplicados
$nodeVersions = $nodeVersions | Select-Object -Unique

Write-Host ""
Write-Host "Versiones a procesar: $($nodeVersions -join ', ')" -ForegroundColor Cyan

# ========================================
# 4. OBTENER VERSIÓN DE NPM
# ========================================
Write-Host ""
$npmVersion = Read-Host "Versión de npm a usar si falta (ej: 10.9.4, Enter=latest)"

if ([string]::IsNullOrWhiteSpace($npmVersion)) {
    Write-Host "[INFO] Obteniendo última versión de npm..." -ForegroundColor Cyan
    try {
        $npmLatestInfo = Invoke-RestMethod -Uri "https://registry.npmjs.org/npm/latest" -TimeoutSec 10
        $npmVersion = $npmLatestInfo.version
        Write-Host "[OK] Última version de npm: $npmVersion" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] No se pudo obtener la última versión de npm" -ForegroundColor Red
        $npmVersion = Read-Host "Ingresa versión de npm manualmente (ej: 10.9.4)"
    }
}

# Validar formato de versión de npm o aceptar 'latest'
if (-not [string]::IsNullOrWhiteSpace($npmVersion)) {
    if ($npmVersion -eq "latest") {
        Write-Host "[INFO] Usando la última versión de npm (latest)" -ForegroundColor Cyan
        try {
            $npmLatestInfo = Invoke-RestMethod -Uri "https://registry.npmjs.org/npm/latest" -TimeoutSec 10
            $npmVersion = $npmLatestInfo.version
            Write-Host "[OK] Última versión de npm: $npmVersion" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] No se pudo obtener la última versión de npm" -ForegroundColor Red
            exit 1
        }
    } elseif ($npmVersion -notmatch '^\d+\.\d+\.\d+$') {
        Write-Host "[ERROR] Versión de npm inválida: $npmVersion" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Iniciando procesamiento..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ========================================
# 5. PROCESAR CADA VERSIÓN
# ========================================
$successCount = 0
$failCount = 0

foreach ($version in $nodeVersions) {
    Write-Host ""
    Write-Host "" -ForegroundColor DarkGray
    Write-Host "Procesando Node.js v$version..." -ForegroundColor Yellow
    Write-Host "" -ForegroundColor DarkGray

    $nodePath = "$nvmBase\v$version"
    $nodeInstalled = Test-Path $nodePath

    # 5.1 Verificar si la versión está instalada
    if (-not $nodeInstalled) {
        Write-Host "[INFO] Node.js v$version no está en la ubicación actual" -ForegroundColor Yellow
        
        # Verificar si hay una instalación en progreso (archivos parciales)
        if (Test-Path $nodePath) {
            Write-Host "[INFO] Carpeta detectada, verificando si instalación está en progreso..." -ForegroundColor Cyan
            Start-Sleep -Seconds 5
        }

        # Verificar archivos críticos por si la instalación se completó después de un timeout previo
        $nodeExeExists = Test-Path "$nodePath\node.exe"
        $npmCmdExists = Test-Path "$nodePath\npm.cmd"

        if ($nodeExeExists -and $npmCmdExists) {
            Write-Host "[OK] Node.js v$version encontrado (instalación previa completada)" -ForegroundColor Green
            $nodeInstalled = $true
        } else {
            Write-Host "[ACCIÓN] Instalando con nvm..." -ForegroundColor Cyan

            nvm install $version 2>&1 | Out-Null

            if ($LASTEXITCODE -ne 0) {
                Write-Host "[ERROR] No se pudo instalar Node.js v$version (versión no disponible)" -ForegroundColor Red
                $failCount++
                continue
            }

            # Esperar con verificación inteligente
            Write-Host "   Esperando confirmación de instalación..." -ForegroundColor Gray
            $maxWait = 150 # 2.5 minutos total
            $elapsed = 0
            $installComplete = $false

            while ($elapsed -lt $maxWait) {
                Start-Sleep -Seconds 2
                $elapsed += 2

                if ((Test-Path "$nodePath\node.exe") -and (Test-Path "$nodePath\npm.cmd")) {
                    $installComplete = $true
                    Write-Host "   [OK] Instalación confirmada ($elapsed segundos)" -ForegroundColor Green
                    break
                }

                if($elapsed % 10 -eq 0 -and $elapsed -le 120) {
                    Write-Host "   Instalando... ($elapsed segundos)" -ForegroundColor Green
                } elseif ($elapsed -gt 120 -and $elapsed % 10 -eq 0) {
                    Write-Host "   Aún instalando... ($elapsed segundos)" -ForegroundColor Yellow
                }
            }

            # Verificación final si alcanzó timeout
            if (-not $installComplete) {
                Write-Host "   [ADVERTENCIA] Timeout de 150 segundos alcanzado" -ForegroundColor Yellow
                Write-Host "   Esperando 5 segundos adicionales para verificación final..." -ForegroundColor Gray
                Start-Sleep -Seconds 5

                if ((Test-Path "$nodePath\node.exe") -and (Test-Path "$nodePath\npm.cmd")) {
                    Write-Host "   [OK] Instalacion completada (verificación final)" -ForegroundColor Green
                    $nodeInstalled = $true
                } else {
                    Write-Host "[ERROR] La instalación no completó en el tiempo esperado" -ForegroundColor Red
                    Write-Host ""
                    Write-Host "IMPORTANTE:" -ForegroundColor Yellow
                    Write-Host "La instalación de Node.js v$version puede seguir en proceso en segundo plano." -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "SOLUCIÓN:" -ForegroundColor Cyan
                    Write-Host "1. Espera 2-3 minutos para que termina la descarga/instalación" -ForegroundColor Gray
                    Write-Host "2. Ejecuta este script nuevamente: .\install_npm_version_v2.ps1" -ForegroundColor Gray
                    Write-Host "3. El script detectará si la instalación se completó y continuará" -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "Alternativamente, verífica manualmente con:" -ForegroundColor Gray
                    Write-Host "  nvm list" -ForegroundColor White
                    Write-Host ""
                    $failCount++
                    continue
                }
            } else {
                $nodeInstalled = $true
            }

            if ($nodeInstalled) {
                Write-Host "[OK] Node.js v$version instalado correctamente" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "[OK] Node.js v$version ya está instalado" -ForegroundColor Green
    }

    # 5.2 Activar versión
    Write-Host "[ACCIÓN] Activando Node.js v$version..." -ForegroundColor Cyan
    nvm use $version 2>&1 | Out-Null
    Start-Sleep -Milliseconds 500

    # 5.3 Verificar node.exe
    $nodeExe = "$nodePath\node.exe"
    if (-not (Test-Path $nodeExe)) {
        Write-Host "[ERROR] node.exe no existe en $nodePath" -ForegroundColor Red
        $failCount++
        continue
    }

    try {
        $nodeVer = & $nodeExe -v 2>&1
        Write-Host "[OK] Node.js verificado: $nodeVer" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] node.exe no ejecuta correctamente" -ForegroundColor Red
        $failCount++
        continue
    }

    # 5.4 Verificar npm
    $npmCmd = "$nodePath\npm.cmd"
    $npmFixed = $false

    try {
        $npmVer = & $npmCmd -v 2>&1
        if ($LASTEXITCODE -eq 0 -and $npmVer -match "^\d+\.\d+\.\d+") {
            Write-Host "[OK] npm verificado: v$npmVer" -ForegroundColor Green
            $npmFixed = $true
        } else {
            throw "npm corrupto"
        }
    } catch {
        Write-Host "[ADVERTENCIA] npm no funciona o está corrupto" -ForegroundColor Yellow

        # Verificar si tenemos permisos antes de intentar reparar
        if (-not $hasWritePermissions) {
            Write-Host "[BLOQUEADO] No se puede reparar npm sin permisos de escritura" -ForegroundColor Red
            Write-Host "Esta versión está corrupta y la ubicación de nvm está protegida" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "SOLUCIONES:" -ForegroundColor Cyan
            Write-Host "1. Contacta al administrador de IT para:" -ForegroundColor Gray
            Write-Host "    - Desinstalar manualmente: $nodePath" -ForegroundColor Gray
            Write-Host "    - Reinstalar Node.js v$version limpio" -ForegroundColor Gray
            Write-Host "    - O cambia nvm root a tu carpeta de usuario" -ForegroundColor Gray
            Write-Host "2. Ejecuta este script como Administrador" -ForegroundColor Gray
            Write-Host "3. Usa una pc con permisos completos" -ForegroundColor Gray
            Write-Host ""
            $failCount++
            continue
        }

        Write-Host "[ACCIÓN] Reparando npm con descarga standalone v$npmVersion..." -ForegroundColor Cyan

        $npmTgz = "$env:TEMP\npm-$npmVersion.tgz"
        $npmUrl = "https://registry.npmjs.org/npm/-/npm-$npmVersion.tgz"

        try {
            Write-Host "  Descargando npm v$npmVersion..." -ForegroundColor Gray
            Invoke-WebRequest -Uri $npmUrl -OutFile $npmTgz -TimeoutSec 30 -ErrorAction Stop

            if (-not (Test-Path $npmTgz)) {
                throw "Archivo no descargado"
            }

            Write-Host "  Extrayendo archivo..." -ForegroundColor Gray
            $extractPath = "$env:TEMP\npm-extract-$version"
            if (-not (Test-Path $extractPath)) {
                Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

            tar -xf $npmTgz -C $extractPath 2>&1 | Out-Null
            
            if ($LASTEXITCODE -ne 0) {
                throw "Error al extraer archivo"
            }
            
            $packagePath = "$extractPath\package"
            if (-not (Test-Path $packagePath)) {
                throw "No se encontró carpeta 'package' en el archivo extraído"
            }

            Write-Host "   Reemplazando instalación corrupta..." -ForegroundColor Gray
            $npmModulePath = "$nodePath\node_modules\npm"

            if (Test-Path $npmModulePath) {
                # PREPARACIÓN: Liberar archivos bloqueados y cambiar atributos
                Write-Host "   Preparando archivos para modificación..." -ForegroundColor Gray

                # Terminar procesos de node/npm que puedan estar usando los archivos
                $processesKilled = 0
                Get-Process | Where-Object { $_.ProcessName -match "^(node|npm|npx)$" } -ErrorAction SilentlyContinue |
                    ForEach-Object {
                        try {
                            $procName = $_.ProcessName
                            $_.kill()
                            $_.WaitForExit(2000)
                            $processesKilled++
                            Write-Host "   [INFO] Proceso $procName terminado" -ForegroundColor Gray
                        } catch {}
                    }
                
                if ($processesKilled -gt 0) {
                    Write-Host "   [INFO] $processesKilled proceso(s) terminado(s), esperando 2 segundos..." -ForegroundColor Gray
                    Start-Sleep -Seconds 2
                }
                
                # Cambiar todos los atributos de archivos ANTES de intentar modificar
                try {
                    $filesChanged = 0
                    Get-ChildItem -Path $npmModulePath -Recurse - Force -File -ErrorAction SilentlyContinue |
                        ForEach-Object {
                            try {
                                if ($_.Attributes -ne 'Normal') {
                                    $_.Attributes = 'Normal'
                                    $filesChanged++
                                }
                            } catch {}
                        }
                    if ($filesChanged -gt 0) {
                        Write-Host "   [INFO] $filesChanged archivo(s) desbloqueado(s)" -ForegroundColor Gray
                    }
                } catch {}

                # ESTRATEGIA 1: Intentar sobrescribir directamente sin eliminar
                Write-Host "   Estrategia 1: Sobrescribiendo archivos directamente..." -ForegroundColor Gray
                try {
                    Copy-Item "$packagePath\*" $npmModulePath -Recurse -Force -ErrorAction Stop
                    Write-Host "   [OK] npm sobrescrito exitosamente" -ForegroundColor Green
                } catch {
                    Write-Host "   [ERROR] Falló sobrescritura: $($_.Exception.Message)" -ForegroundColor Yellow
                    Write-Host "   [ADVERTENCIA] No se pudo sobrescribir directamente" -ForegroundColor Yellow

                    # ESTRATEGIA 2: Eliminar y copiar
                    Write-Host "   Estrategia 2: Eliminando carpeta corrupta..." -ForegroundColor Gray

                    # Eliminar atributos de solo lectura primero
                    Get-ChildItem -Path $npmModulePath -Recurse -Force -ErrorAction SilentlyContinue |
                    ForEach-Object {
                        try { $_.Attributes = 'Normal' } catch {}
                    }

                    # Intentar eliminar
                    Remove-Item $npmModulePath -Recurse -Force -ErrorAction SilentlyContinue

                    # Verificar si se eliminó
                    if (Test-Path $npmModulePath) {
                        # ESTRATEGIA 3: Renombrar carpeta vieja
                        Write-Host "   Estrategia 3: Renombrando carpeta vieja..." -ForegroundColor Gray
                        $backupPath = "$nodePath\node_modules\npm.old.$([DateTime]::Now.ToString('yyyyMMddHHmmss'))"
                        try {
                            Rename-Item $npmModulePath $backupPath -Force -ErrorAction Stop
                            Write-Host "   [OK] Carpeta antigua renombrada" -ForegroundColor Green
                        } catch {
                            Write-Host "   [ERROR] No se pudo eliminar ni renombrar" -ForegroundColor Red
                            throw "Permisos insuficientes para modificar $npmModulePath"
                        }
                    } else {
                        Write-Host "   [OK] Carpeta eliminada" -ForegroundColor Green
                    }

                    # Copiar nueva versión
                    Write-Host "   Copiando nueva version de npm..." -ForegroundColor Gray
                    Copy-Item $packagePath $npmModulePath -Recurse -Force -ErrorAction Stop
                }
            } else {
                # No existe, copiar directamente
                Write-host "   Copiando nueva versión de npm..." -ForegroundColor Gray
                Copy-Item $packagePath $npmModulePath -Recurse -Force -ErrorAction Stop
            }

            # Copiar archivos .cmd si existen
            $binFiles = Get-ChildItem "$npmModulePath\bin" -Filter "*.cmd" -ErrorAction SilentlyContinue
            if ($binFiles) {
                Copy-Item "$npmModulePath\bin\npm.cmd" "$nodePath\" -Force -ErrorAction SilentlyContinue
                Copy-Item "$npmModulePath\bin\npx.cmd" "$nodePath\" -Force -ErrorAction SilentlyContinue
            }

            # Limpiar archivos temporales
            Remove-Item $npmTgz -Force -ErrorAction SilentlyContinue
            Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

            # Verificar que npm funciona
            Write-Host "   Verificando instalación..." -ForegroundColor Gray
            $npmVer = & $npmCmd -v 2>&1
            if ($LASTEXITCODE -eq 0 -and $npmVer -match "^\d+\.\d+\.\d+") {
                Write-Host "[OK] npm reparado exitosamente: v$npmVer" -ForegroundColor Green
                $npmFixed = $true
            } else {
                Write-Host "[ERROR] npm sigue sin funcionar después de la reparación" -ForegroundColor Red
            }

        } catch {
            Write-Host "[ERROR] No se pudo reparar npm: $_" -ForegroundColor Red
            if ($_ -match "Permisos insuficientes") {
                Write-Host ""
                Write-Host "   SOLUCIÓN:" -ForegroundColor Yellow
                Write-Host "   1. Ejecuta PowerShell como Administrador" -ForegroundColor Gray
                Write-Host "   2. Vuelve a ejecutar este script" -ForegroundColor Gray
                Write-Host ""
            }
        }
    }
    
    # 5.5 última alternativa: Reinstalar Node.js completo si npm no funciona
    if (-not $npmFixed -and $hasWritePermissions) {
        Write-Host ""
        Write-Host "[ÚLTIMA OPCIÓN] Intentando reinstalar Node.js v$version completamente..." -ForegroundColor Magenta

        try {
            # Desinstalar versión actual
            Write-Host "   Paso 1/4: Desinsatalando versión corrupta..." -ForegroundColor Gray
            nvm uninstall $version 2>&1 | Out-Null
            Start-Sleep -Seconds 3

            # Verificar que se desinstaló
            if (Test-Path $nodePath) {
                Write-Host "   [ADVERTENCIA] Carpeta no eliminada por nvm, intentando limpieza..." -ForegroundColor Yellow
                try {
                    Remove-Item $nodePath -Recurse -Force -ErrorAction Stop
                    Write-Host "   [OK] Carpeta eliminada manualmente" -ForegroundColor Green
                } catch {
                    Write-Host "   [ERROR] No se puede eliminar. Requiere permisos de admin" -ForegroundColor Red
                    throw "No se pudo desinstalar completamente"
                }
            } else {
                Write-Host "   [OK] Versión desinstalada correctamente" -ForegroundColor Green
            }

            # Reinstalar versión limpia
            Write-Host "   Paso 2/4: Descagando e instalando versión limpia (puede tardar 1-2 minutos)..." -ForegroundColor Gray
            nvm install $version 2>&1 | Out-Null

            if ($LASTEXITCODE -ne 0) {
                throw "Error al reinstalar Node.js v$version"
            }

            # Esperar a que la instalación complete completamente
            Write-Host "   Esperando a que la instalación finalice..." -ForegroundColor Gray
            $maxWaitTime = 120 # 2 minutos tiempo normal
            $checkInterval = 2 # Revisar cada 2 segundos
            $elapsedTime = 0
            $installComplete = $false

            while ($elapsedTime -lt $maxWaitTime) {
                Start-Sleep -Seconds $checkInterval
                $elapsedTime += $checkInterval

                # Verificar que existan los archivos críticos
                $nodeExeExists = Test-Path "$nodePath\node.exe"
                $npmCmdExists = Test-Path "$nodePath\npm.cmd"

                if ($nodeExeExists -and $npmCmdExists) {
                    $installComplete = $true
                    Write-Host "   [OK] Instalación completada ($elapsedTime segundos)" -ForegroundColor Green
                    break
                }

                # Mostrar progreso cada 10 segundos
                if ($elapsedTime % 10 -eq 0) {
                    Write-Host "   Esperando... ($elapsedTime/$maxWaitTime segundos)" -ForegroundColor Gray
                }
            }

            # Si alcanzó el timeout, dar tiempo extra y verificar una vez más
            if (-not $installComplete) {
                Write-Host "   [ADVERTENCIA] Timeout de $maxWaitTime segundos alcanzados" -ForegroundColor Yellow
                Write-Host "    Dando 30 segundos adicionales por si la instalación está finalizando..." -ForegroundColor Gray

                $extraWaitTime = 30
                $extraElapsed = 0
                while ($extraElapsed -lt $extraWaitTime) {
                    Start-Sleep -Seconds 2
                    $extraElapsed += 2

                    $nodeExeExists = Test-Path "$nodePath\node.exe"
                    $npmCmdExists = Test-Path "$nodePath\npm.cmd"

                    if ($nodeExeExists -and $npmCmdExists) {
                        $installComplete = $true
                        $totalTime = $elapsedTime + $extraElapsed
                        Write-Host "   [OK] Instalación completada después de $totalTime segundos" -ForegroundColor Green
                        break
                    }

                    if ($extraElapsed % 10 -eq 0) {
                        Write-Host "   Tiempo extra: $extraElapsed/$extraWaitTime segundos..." -ForegroundColor Gray
                    }
                }
            }

            # Verficación final
            if (-not $installComplete) {
                # una última verificación por si los archivos aparecieron justo ahora
                $nodeExeExists = Test-Path "$nodePath\node.exe"
                $npmCmdExists = Test-Path "$nodePath\npm.cmd"

                if ($nodeExeExists -and $npmCmdExists) {
                    Write-Host "   [OK] Instalación verificada en verificación final" -ForegroundColor Green
                    $installComplete = $true
                } else {
                    throw "La instalación no completó después de 150 segundos o archivos faltantes"
                }
            }

            # Espera adicional de seguridad para que se escriban todos los archivos
            Start-Sleep -Seconds 2

            Write-Host "   [OK] Node.js v$version reinstalado completamente" -ForegroundColor Green

            # Activar versión
            Write-Host "   Paso 3/4: Activando versión reinstalada..." -ForegroundColor Gray
            nvm use $version 2>&1 | Out-Null
            Start-Sleep -Seconds 1

            # Verificar npm nuevamente
            Write-Host "   Paso 4/4: Verificando npm..." -ForegroundColor Gray
            $npmVer = & $npmCmd -v 2>&1

            if ($LASTEXITCODE -eq 0 -and $npmVer -match "^\d+\.\d+\.\d+") {
                Write-Host "[ÉXITO] npm ahora funciona correctamente: v$npmVer" -ForegroundColor Green
                Write-Host "[ÉXITO] Node.js v$version reinstalado y configurado exitosamente" -ForegroundColor Green
                $npmFixed = $true
            } else {
                Write-Host "[ERROR] No se pudo reinstalar Node.js v$version" -ForegroundColor Red
                Write-Host "   Es posible que nvm-windows esté corrupto o la versión de Node.js tenga problemas" -ForegroundColor Yellow
            }

        } catch {
            Write-Host "[ERROR] No se pudo reinstalar Node.js v$version" -ForegroundColor Red
            Write-Host "   Detalles: $_" -ForegroundColor Red
            Write-Host ""
            Write-Host "   Intenta manualmente:" -ForegroundColor Yellow
            Write-Host "   nvm uninstall $version" -ForegroundColor Gray
            Write-Host "   nvm install $version" -ForegroundColor Gray
            Write-Host "   nvm use $version" -ForegroundColor Gray
        }
    }

    # 5.6 Última opción extrema: Cambiar nvm root
    if (-not $npmFixed) {
        Write-Host ""
        if ($hasWritePermissions) {
            Write-Host "[OPCIÓN FINAL] Todas las estrategias de reparación fallaron" -ForegroundColor Red
            Write-Host "Esto puede ser un problema de permisos o corrupción severa" -ForegroundColor Yellow
        } else {
            Write-Host "[OPCIÓN FINAL] npm corrupto en ubicación sin permisos" -ForegroundColor Red
            Write-Host "No se puede reparar sin permisos de escritura en: $nvmBase" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "Ubicación actual de nvm: $nvmBase" -ForegroundColor Gray
        Write-Host ""
        Write-Host "¿Deseas cambiar nvm a una ubicación con permisos completos?" -ForegroundColor Cyan
        Write-Host "Recomendado: $env:USERPROFILE\nvm (tu carpeta de usuario)" -ForegroundColor Gray
        Write-Host ""
        $cambiarRoot = Read-Host "¿Cambiar ubicación de nvm? (S/N, Enter=No)"

        if ($cambiarRoot -eq "S" -or $cambiarRoot -eq "s") {
            Write-Host ""
            Write-Host "Ingresa la NUEVA ubicación para nvm:" -ForegroundColor Cyan
            Write-Host "Ejemplos:" -ForegroundColor Gray
            Write-Host "  - $env:USERPROFILE\nvm" -ForegroundColor Gray
            Write-Host "  - $env:LOCALAPPDATA\nvm" -ForegroundColor Gray
            Write-Host "  - C:\Dev\nvm" -ForegroundColor Gray
            Write-Host ""
            $newNvmRoot = Read-Host "Nueva ruta"

            if (-not [string]::IsNullOrWhiteSpace($newNvmRoot)) {
                try {
                    # Crear carpeta si no existe
                    if (-not (Test-Path $newNvmRoot)) {
                        Write-Host "   Creando carpeta: $newNvmRoot" -ForegroundColor Gray
                        New-Item -ItemType Directory -Path $newNvmRoot -Force | Out-Null
                    }

                    # Verificar que tenemos permisos de escritura
                    $testFile = "$newNvmRoot\test-write-permissions.tmp"
                    try {
                        "test" | Out-File $testFile -ErrorAction Stop
                        Remove-Item $testFile -Force
                        Write-Host "   [OK] Permisos de escritura verificados" -ForegroundColor Green
                    } catch {
                        throw "No tienes permisos de escritura en: $newNvmRoot"
                    }

                    # Cambiar nvm root
                    Write-Host "   Cambiando nvm root a: $newNvmRoot" -ForegroundColor Gray
                    $nvmRootOutput = nvm root $newNvmRoot 2>&1

                    # Verificar que el comando se ejectuó correctamente
                    if ($LASTEXITCODE -ne 0) {
                        throw "Error al cambiar nvm root. Puede requerir permisos de admin."
                    }

                    # Verificar el mensaje de éxito
                    $successMessage = $nvmRootOutput | Select-String "Root has been set to"
                    if (-not $successMessage) {
                        # Si no hay mensaje de éxito, verificar con nvm root
                        Start-Sleep -Milliseconds 500
                        $currentRoot = (nvm root 2>&1 | Select-String "Current Root:").ToString().Replace("Current Root:", "").Trim()
                        if ($currentRoot -ne $newNvmRoot) {
                            throw "nvm root no cambió correctamente. Salida: $nvmRootOutput"
                        }
                    }

                    Write-Host "   [OK] nvm root cambiado exitosamente" -ForegroundColor Green
                    Write-Host "   Salida: $nvmRootOutput" -ForegroundColor Gray
                    Write-Host ""

                    # Actualizar variables para próximas versiones
                    $nvmBase = $newNvmRoot
                    $hasWritePermissions = $true # Nueva ubicación tiene permisos

                    # Reinstalar esta versión en nueva ubicación
                    Write-Host "[REINTENTO] Instalado Node.js v$version en nueva ubicación..." -ForegroundColor Magenta
                    Write-Host "Nota: La versión corrupta en ubicación anterior quedará intacta" -ForegroundColor Gray
                    $nodePath = "$nvmBase\v$version"

                    # Intentar desinstalar de ubicación vieja (puede fallar sin permisos)
                    Write-Host "   Intentado desinstalar de ubicación anterior..." -ForegroundColor Gray
                    nvm uninstall $version 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0) {
                        Write-Host "   [INFO] No se pudo desinstalar de ubicación anterior (sin permisos)" -ForegroundColor Gray
                        Write-Host "   [INFO] La versión corrupta quedará en: $(Split-Path $nodePath -Parent)" -ForegroundColor Gray
                    }
                    Start-Sleep -Seconds 2

                    # Instalar en nueva ubicación
                    Write-Host "   Instalando Node.js v$version en nueva ubicación..." -ForegroundColor Gray
                    nvm install $version 2>&1 | Out-Null

                    if ($LASTEXITCODE -ne 0) {
                        throw "Error al instalar Node.js en nueva ubicación"
                    }

                    # Esperar instalación
                    Write-Host "   Esperando a que complete la instalación..." -ForegroundColor Gray
                    $maxWait = 120
                    $elapsed = 0
                    while ($elapsed -lt $maxWait) {
                        Start-Sleep -Seconds 2
                        $elapsed += 2
                        if ((Test-Path "$nodePath\node.exe") -and (Test-Path "$nodePath\npm.cmd")) {
                            break
                        }
                        if ($elapsed % 10 -eq 0) {
                            Write-Host "   Esperando... ($elapsed/$maxWait seg)" -ForegroundColor Gray
                        }
                    }

                    # Activar versión
                    Write-Host "   Activando Node.js v$version..." -ForegroundColor Gray
                    nvm use $version 2>&1 | Out-Null
                    Start-Sleep -Seconds 1

                    # Verificar npm
                    $npmCmd = "$nodePath\npm.cmd"
                    $npmVer = & $npmCmd -v 2>&1

                    if ($LASTEXITCODE -eq 0 -and $npmVer -match "^\d+\.\d+\.\d+") {
                        Write-Host "[ÉXITO] Node.js v$version isntalado correctamente en nueva ubicación" -ForegroundColor Green
                        Write-Host "[ÉXITO] npm funciona: v$npmVer" -ForegroundColor Green
                        $npmFixed = $true
                    } else {
                        Write-Host "[ERROR] npm sigue sin funcionar en nueva ubicación" -ForegroundColor Red
                    }

                } catch {
                    Write-Host "[ERROR] No se pudo cambiar nvm root: $_" -ForegroundColor Red
                    Write-Host ""
                    Write-Host "   Intenta manualmente:" -ForegroundColor Yellow
                    Write-Host "   1. Ejecuta PowerShell como Administrador" -ForegroundColor Gray
                    Write-Host "   2. Ejecuta: nvm root $newNvmRoot" -ForegroundColor Gray
                    Write-Host "   3. Vuelve a ejecutar este script" -ForegroundColor Gray
                }
            }
        }
    }

    # 5.7 Resumen de la versión
    if ($npmFixed) {
        Write-Host "[ÉXITO] Node.js v$version configurado correctamente" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "[FALLO] Node.js v$version instalado pero npm no funciona" -ForegroundColor Red
        Write-Host "Considera cambiar la ubicación de nvm manualmente o ejecutar como admin" -ForegroundColor Yellow
        $failCount++
    }
}

# ========================================
# 6. RESUMEN FINAL
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Resumen Final" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Versiones procesadas: $($nodeVersions.Count)" -ForegroundColor White
Write-Host "Exitosas: $successCount" -ForegroundColor Green
Write-Host "Fallidas: $failCount" -ForegroundColor Red
Write-Host ""
Write-Host "Proceso completado." -ForegroundColor Cyan
