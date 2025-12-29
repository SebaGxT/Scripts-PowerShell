# ========================================
# Script: Instalador y Reparador de Node.js + npm con nvm
# Versión: 2.0.3
# Descripción: Instala versiones de Node.js con nvm y repara npm si está corrupto
# ========================================

# ========================================
# Funciones
# ========================================

function Show-Message {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,

        [Parameter()]
        [ValidateSet("Info","Ok","Error","Custom")]
        [string]$Type = "Info",

        [string]$CustomColor = "White"
    )

    switch ($Type) {
        "Info"  { $color = "Cyan";   $prefix = "[INFO]" }
        "Ok"    { $color = "Green";  $prefix = "[OK]" }
        "Error" { $color = "Red";    $prefix = "[ERROR]" }
        "Custom"{ $color = $CustomColor; $prefix = "[MSG]" }
        "Advertencia" { $color = "Yellow"; $prefix = "[WARNING]" }
        default { $color = "White";  $prefix = "[MSG]" }
    }

    Write-Host "$prefix $Text" -ForegroundColor $color
}

function Get-ValidVersions {
    param(
        [string]$Prompt,
        [string]$Example,
        [string]$Enter
    )

    Show-Message ""
    Show-Message $Prompt Info
    Show-Message $Example Custom -CustomColor Gray
    Show-Message $Enter Custom -CustomColor Gray
    $input = Read-Host "Versiones"
    if ([string]::IsNullOrWhiteSpace($input)) { return @() }

    $versions = $input -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $valid = @()

    foreach ($v in $versions) {
        if ($v -match '^\d+\.\d+\.\d+$') {
            $valid += $v
            Show-Message "Versión válida: $v" Ok
        } else {
            Show-Message "Versión inválida: $v" Error
        }
    }

    return $valid | Select-Object -Unique
}


# ========================================

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ========================================
# 0. VERIFICAR PERMISOS DE ADMINISTRADOR
# ========================================
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Show-Message "========================================" Info
Show-Message " Instalador de Node.js + npm (nvm)" Info
Show-Message "========================================" Info
Show-Message ""

if (-not $isAdmin) {
    Show-Message "  Este script NO se está ejecutando como Administrador" Advertencia
    Show-Message ""
    Show-Message "Si necesitas reparar npm corrupto, se requieren permisos elevados" Advertencia
    Show-Message "para modificar archivos en C:\ProgramData\NVM\" Custom -CustomColor Gray
    Show-Message ""
    $continue = Read-Host "¿continuar de todos modos? (S/N, Enter=No)"
    if ($continue -ne "S" -and $continue -ne "s") {
        Show-Message ""
        Show-Message "Para ejecutar como Administrador:" Info
        Show-Message "1. Click derecho en PowerShell" Custom -CustomColor Gray
        Show-Message "2. Selecciona 'Ejecutar como administrador" Custom -CustomColor Gray
        Show-Message "3. Ejecuta este script nuevamente" Custom -CustomColor Gray
        Show-Message ""
        exit 0
    }
    Show-Message ""
} else {
    Show-Message "  Ejecutando con permisos de Administrador" Ok
    Show-Message ""
}

# ========================================
# 1. VERIFICAR QUE NVM ESTÉ INSTALADO Y EN PATH
# ========================================
$nvmInPath = $false
try {
    [void](nvm version 2>&1)
    if ($LASTEXITCODE -ne 0) { throw }
    $nvmInPath = $true
    Show-Message "  nvm está instalado y accesible" Ok
} catch {
    Show-Message "  nvm no responde al comando 'nvm'" Advertencia
    Show-Message "Verificando si nvm está instalado pero no está en PATH..." Info

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
            Show-Message "  nvm encontrado en: $nvmDir" Ok
            break
        }
    }

    if ($nvmExePath) {
        # nvm existe pero no está en PATH, agregarlo
        Show-Message "  Agregando nvm al PATH del usuario..." Info

        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $nvmDir = Split-Path $nvmExePath -Parent

        if ($userPath -notlike "*$nvmDir*") {
            $newPath = "$userPath;$nvmDir"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")

            # Actualizar PATH de la sesión actual
            $env:Path = "$env:Path,$nvmDir"

            Show-Message "  nvm agregado al PATH del usuario" Ok
            Show-Message "Variable NVM_HOME configurada como: $nvmDir" Custom -CustomColor Gray

            # Configurar NVM_HOME si no existe
            if (-not $env:NVM_HOME) {
                [Environment]::SetEnvironmentVariable("NVM_HOME", $nvmDir, "User")
                $env:NVM_HOME = $nvmDir
            }

            # Verificar que ahora funcione
            try {
                [void](nvm version 2>&1)
                if ($LASTEXITCODE -eq 0) {
                    Show-Message "  nvm ahora está accesible" Ok
                    $nvmInPath = $true
                }
            } catch {}
        }
    } else {
        Show-Message "  nvm no está instalado en este sistema" Error
        Show-Message "Instala nvm-windows desde: https://github.com/coreybutler/nvm-windows/releases" Advertencia
        exit 1
    }
}

if (-not $nvmInPath) {
    Show-Message "  nvm no pudo ser configurado correctamente" Error
    Show-Message "Cierra esta ventana y abre una nueva terminal para que los cambios surtan efecto" Advertencia
    exit 1
}

# ========================================
# 2. DETECTAR RUTA BASE DE NVM Y VERIFICAR PERMISOS
# ========================================

# PRIMERO: Verificar nvm root actual (lo que realmente está usando nvm)
Show-Message "  Detectando ubicación actual de nvm..." Info
$nvmBase = $null

try {
    $nvmRootOutput = nvm root 2>&1
    $currentRootLine = $nvmRootOutput | Select-String "Current Root:"
    if ($currentRootLine) {
        $nvmBase = $currentRootLine.ToString().Replace("Current Root:", "").Trim()
        if (Test-Path $nvmBase) {
            Show-Message "  nvm root actual: $nvmBase" Ok
        } else {
            Show-Message "  nvm root apunta a ubicación inexistente: $nvmBase" Advertencia
            $nvmBase = $null
        }
    }
} catch {
    Show-Message "  No se pudo obtener nvm root" Advertencia
}

# SEGUNDO: Si no se obtuvo de nvm root, buscar en ubicaciones comunes
if (-not $nvmBase) {
    Show-Message "  No se pudo obtener nvm root" Info
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
            Show-Message "  Ruta de nvm detectada: $nvmBase" Ok
            break
        }
    }
}

# TERCERO: Si aún no se encontró, solicitar manualmente
if (-not $nvmBase) {
    Show-Message "  No se detectó automáticamente la ruta de nvm" Advertencia
    $nvmBase = Read-Host "Ingresa la ruta base de nvm (ej: C:\ProgramData\nvm)"
    if (-not (Test-Path $nvmBase)) {
        Show-Message "  La ruta ingresada no existe" Error
        exit 1
    }
}

# Verificar permisos de escritura en la ubicación de nvm
Show-Message "  Verificando permisos de escritura en nvm..." Info
$testFile = "$nvmBase\test-write-permissions-$([Guid]::NewGuid()).tmp"
$hasWritePermissions = $false
try {
    "test" | Out-File $testFile -ErrorAction Stop
    Remove-Item $testFile -Force -ErrorAction Stop
    $hasWritePermissions = $true
    Show-Message "  Tienes permisos de escritura en la ubicacion de nvm" Ok
} catch {
    Show-Message "  No tienes permisos de escritura en: $nvmBase" Advertencia
    Show-Message ""
    Show-Message "LIMITACIONES DETECTADAS:" Error
    Show-Message "- No podrás reparar instalaciones corruptas de npm" Custom -CustomColor Gray 
    Show-Message "- No podrás desinstalar versiones de Node.js" Custom -CustomColor Gray
    Show-Message "- Solo podrás verificar versiones existentes" Custom -CustomColor Gray
    Show-Message ""
    Show-Message "OPCIONES DISPONIBLES:" Info
    Show-Message "1. Contactar al administrador de IT para:" Custom -CustomColor Gray
    Show-Message "    - Cambiar permisos de la carpeta nvm" Custom -CustomColor Gray
    Show-Message "    - Cambiar nvm root a tu carpeta de usuario" Custom -CustomColor Gray
    Show-Message "    - Ejecutar este script como administrador" Custom -CustomColor Gray
    Show-Message "2. Usar otra PC/ambiente con permisos completos" Custom -CustomColor Gray
    Show-Message "3. Continuar solo para verificar versiones existentes (sin reparaciones)" Custom -CustomColor Gray
    Show-Message ""
    $continuar = Read-Host "¿Deseas continuar de todos modos? (S/N, Enter=No)"
    if ($continuar -ne "S" -and $continuar -ne "s") {
        Show-Message ""
        Show-Message "Script cancelado. Para usar todas las funcionalidades:" Advertencia
        Show-Message "- Solicita permisos de administrador" Custom -CustomColor Gray
        Show-Message "- o pide que cambien nvm root a: $env:USERPROFILE\nvm" Custom -CustomColor Gray
        exit 0
    }
    Show-Message ""
    Show-Message "  Continuando en modo limitado (solo verificación)..." Info
}

# ========================================
# 3. OBTENER VERSIONES DE NODE.JS
# ========================================
$nodeVersions = @()

# Opción 1: Buscar archivo .nvmrc en directorio actual
if (Test-Path ".nvmrc") {
    $nvmrcContent = Get-Content ".nvmrc" -Raw
    $nvmrcVersion = $nvmrcContent.Trim()
    Show-Message "  Archivo .nvmrc encontrado con versión: $nvmrcVersion" Info
    $useNvmrc = Read-Host "¿Usar esta versión? (S/N, Enter=Sí)"
    if ([string]::IsNullOrCustomSpace($useNvmrc) -or $useNvmrc -eq "S" -or $useNvmrc -eq "s") {
        if ($nvmrcVersion -match '^\d+\.\d+\.\d+$') {
            $nodeVersions += $nvmrcVersion
            Show-Message "  Usando versión de .nvmrc: $nvmrcVersion" Ok
        } else {
            Show-Message "  La versión en .nvmrc no es válida: $nvmrcVersion" Error
        }
    }
}

# Opción 2: Ingresar versiones manualmente
if ($nodeVersions.Count -eq 0) {
    Show-Message ""
    Show-Message "No se usó .nvmrc o no existe." Advertencia
}

$nodeVersions = Get-ValidVersions -Prompt "Ingresa versiones adicionales de Node.js separadas por coma" `
                                   -Example "Ejemplos: 24.11.1,24.11.0,22.21.1" `
                                   -Enter "(Presiona Enter para omitir)"

if ($nodeVersions.Count -eq 0) {
    Show-Message "No se ingresaron versiones válidas para procesar" Error
    exit 1
}

# Eliminar duplicados
$nodeVersions = $nodeVersions | Select-Object -Unique

Show-Message ""
Show-Message "Versiones a procesar: $($nodeVersions -join ', ')" Info

# ========================================
# 4. OBTENER VERSIÓN DE NPM
# ========================================
Show-Message ""
$npmVersion = Read-Host "Versión de npm a usar si falta (ej: 10.9.4, Enter=latest)"

if ([string]::IsNullOrCustomSpace($npmVersion)) {
    Show-Message "  Obteniendo última versión de npm..." Info
    try {
        $npmLatestInfo = Invoke-RestMethod -Uri "https://registry.npmjs.org/npm/latest" -TimeoutSec 10
        $npmVersion = $npmLatestInfo.version
        Show-Message "  Última version de npm: $npmVersion" Ok
    } catch {
        Show-Message "  No se pudo obtener la última versión de npm" Error
        $npmVersion = Read-Host "Ingresa versión de npm manualmente (ej: 10.9.4)"
    }
}

# Validar formato de versión de npm o aceptar 'latest'
if (-not [string]::IsNullOrCustomSpace($npmVersion)) {
    if ($npmVersion -eq "latest") {
        Show-Message "  Usando la última versión de npm (latest)" Info
        try {
            $npmLatestInfo = Invoke-RestMethod -Uri "https://registry.npmjs.org/npm/latest" -TimeoutSec 10
            $npmVersion = $npmLatestInfo.version
            Show-Message "  Última versión de npm: $npmVersion" Ok
        } catch {
            Show-Message "  No se pudo obtener la última versión de npm" Error
            exit 1
        }
    } elseif ($npmVersion -notmatch '^\d+\.\d+\.\d+$') {
        Show-Message "  Versión de npm inválida: $npmVersion" Error
        exit 1
    }
}

Show-Message ""
Show-Message "========================================" Info
Show-Message " Iniciando procesamiento..." Info
Show-Message "========================================" Info

# ========================================
# 5. PROCESAR CADA VERSIÓN
# ========================================
$successCount = 0
$failCount = 0

foreach ($version in $nodeVersions) {
    Show-Message ""
    Show-Message "" Custom -CustomColor DarkGray
    Show-Message "Procesando Node.js v$version..." Advertencia
    Show-Message "" Custom -CustomColor DarkGray

    $nodePath = "$nvmBase\v$version"
    $nodeInstalled = Test-Path $nodePath

    # 5.1 Verificar si la versión está instalada
    if (-not $nodeInstalled) {
        Show-Message "  Node.js v$version no está en la ubicación actual" Advertencia
        
        # Verificar si hay una instalación en progreso (archivos parciales)
        if (Test-Path $nodePath) {
            Show-Message "  Carpeta detectada, verificando si instalación está en progreso..." Info
            Start-Sleep -Seconds 5
        }

        # Verificar archivos críticos por si la instalación se completó después de un timeout previo
        $nodeExeExists = Test-Path "$nodePath\node.exe"
        $npmCmdExists = Test-Path "$nodePath\npm.cmd"

        if ($nodeExeExists -and $npmCmdExists) {
            Show-Message "  Node.js v$version encontrado (instalación previa completada)" Ok
            $nodeInstalled = $true
        } else {
            Show-Message "  Instalando con nvm..." Info

            nvm install $version 2>&1 | Out-Null

            if ($LASTEXITCODE -ne 0) {
                Show-Message "  No se pudo instalar Node.js v$version (versión no disponible)" Error
                $failCount++
                continue
            }

            # Esperar con verificación inteligente
            Show-Message "   Esperando confirmación de instalación..." Custom -CustomColor Gray
            $maxWait = 150 # 2.5 minutos total
            $elapsed = 0
            $installComplete = $false

            while ($elapsed -lt $maxWait) {
                Start-Sleep -Seconds 2
                $elapsed += 2

                if ((Test-Path "$nodePath\node.exe") -and (Test-Path "$nodePath\npm.cmd")) {
                    $installComplete = $true
                    Show-Message "   Instalación confirmada ($elapsed segundos)" Ok
                    break
                }

                if($elapsed % 10 -eq 0 -and $elapsed -le 120) {
                    Show-Message "   Instalando... ($elapsed segundos)" Ok
                } elseif ($elapsed -gt 120 -and $elapsed % 10 -eq 0) {
                    Show-Message "   Aún instalando... ($elapsed segundos)" Advertencia
                }
            }

            # Verificación final si alcanzó timeout
            if (-not $installComplete) {
                Show-Message "   Timeout de 150 segundos alcanzado" Advertencia
                Show-Message "   Esperando 5 segundos adicionales para verificación final..." Custom -CustomColor Gray
                Start-Sleep -Seconds 5

                if ((Test-Path "$nodePath\node.exe") -and (Test-Path "$nodePath\npm.cmd")) {
                    Show-Message "   Instalacion completada (verificación final)" Ok
                    $nodeInstalled = $true
                } else {
                    Show-Message "  La instalación no completó en el tiempo esperado" Error
                    Show-Message ""
                    Show-Message "IMPORTANTE:" Advertencia
                    Show-Message "La instalación de Node.js v$version puede seguir en proceso en segundo plano." Advertencia
                    Show-Message ""
                    Show-Message "SOLUCIÓN:" Info
                    Show-Message "1. Espera 2-3 minutos para que termina la descarga/instalación" Custom -CustomColor Gray
                    Show-Message "2. Ejecuta este script nuevamente: .\install_npm_version_v2.ps1" Custom -CustomColor Gray
                    Show-Message "3. El script detectará si la instalación se completó y continuará" Custom -CustomColor Gray
                    Show-Message ""
                    Show-Message "Alternativamente, verífica manualmente con:" Custom -CustomColor Gray
                    Show-Message "  nvm list" Custom
                    Show-Message ""
                    $failCount++
                    continue
                }
            } else {
                $nodeInstalled = $true
            }

            if ($nodeInstalled) {
                Show-Message "  Node.js v$version instalado correctamente" Ok
            }
        }
    } else {
        Show-Message "  Node.js v$version ya está instalado" Ok
    }

    # 5.2 Activar versión
    Show-Message "  Activando Node.js v$version..." Info
    nvm use $version 2>&1 | Out-Null
    Start-Sleep -Milliseconds 500

    # 5.3 Verificar node.exe
    $nodeExe = "$nodePath\node.exe"
    if (-not (Test-Path $nodeExe)) {
        Show-Message "  node.exe no existe en $nodePath" Error
        $failCount++
        continue
    }

    try {
        $nodeVer = & $nodeExe -v 2>&1
        Show-Message "  Node.js verificado: $nodeVer" Ok
    } catch {
        Show-Message "  node.exe no ejecuta correctamente" Error
        $failCount++
        continue
    }

    # 5.4 Verificar npm
    $npmCmd = "$nodePath\npm.cmd"
    $npmFixed = $false

    try {
        $npmVer = & $npmCmd -v 2>&1
        if ($LASTEXITCODE -eq 0 -and $npmVer -match "^\d+\.\d+\.\d+") {
            Show-Message "  npm verificado: v$npmVer" Ok
            $npmFixed = $true
        } else {
            throw "npm corrupto"
        }
    } catch {
        Show-Message "  npm no funciona o está corrupto" Advertencia

        # Verificar si tenemos permisos antes de intentar reparar
        if (-not $hasWritePermissions) {
            Show-Message "-[BLOQUEADO] No se puede reparar npm sin permisos de escritura" Error
            Show-Message "Esta versión está corrupta y la ubicación de nvm está protegida" Advertencia
            Show-Message ""
            Show-Message "SOLUCIONES:" Info
            Show-Message "1. Contacta al administrador de IT para:" Custom -CustomColor Gray
            Show-Message "    - Desinstalar manualmente: $nodePath" Custom -CustomColor Gray
            Show-Message "    - Reinstalar Node.js v$version limpio" Custom -CustomColor Gray
            Show-Message "    - O cambia nvm root a tu carpeta de usuario" Custom -CustomColor Gray
            Show-Message "2. Ejecuta este script como Administrador" Custom -CustomColor Gray
            Show-Message "3. Usa una pc con permisos completos" Custom -CustomColor Gray
            Show-Message ""
            $failCount++
            continue
        }

        Show-Message "  Reparando npm con descarga standalone v$npmVersion..." Info

        $npmTgz = "$env:TEMP\npm-$npmVersion.tgz"
        $npmUrl = "https://registry.npmjs.org/npm/-/npm-$npmVersion.tgz"

        try {
            Show-Message "  Descargando npm v$npmVersion..." Custom -CustomColor Gray
            Invoke-WebRequest -Uri $npmUrl -OutFile $npmTgz -TimeoutSec 30 -ErrorAction Stop

            if (-not (Test-Path $npmTgz)) {
                throw "Archivo no descargado"
            }

            Show-Message "  Extrayendo archivo..." Custom -CustomColor Gray
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

            Show-Message "   Reemplazando instalación corrupta..." Custom -CustomColor Gray
            $npmModulePath = "$nodePath\node_modules\npm"

            if (Test-Path $npmModulePath) {
                # PREPARACIÓN: Liberar archivos bloqueados y cambiar atributos
                Show-Message "   Preparando archivos para modificación..." Custom -CustomColor Gray

                # Terminar procesos de node/npm que puedan estar usando los archivos
                $processesKilled = 0
                Get-Process | Where-Object { $_.ProcessName -match "^(node|npm|npx)$" } -ErrorAction SilentlyContinue |
                    ForEach-Object {
                        try {
                            $procName = $_.ProcessName
                            $_.kill()
                            $_.WaitForExit(2000)
                            $processesKilled++
                            Show-Message "   Proceso $procName terminado" Custom -CustomColor Gray
                        } catch {}
                    }
                
                if ($processesKilled -gt 0) {
                    Show-Message "   $processesKilled proceso(s) terminado(s), esperando 2 segundos..." Custom -CustomColor Gray
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
                        Show-Message "   $filesChanged archivo(s) desbloqueado(s)" Custom -CustomColor Gray
                    }
                } catch {}

                # ESTRATEGIA 1: Intentar sobrescribir directamente sin eliminar
                Show-Message "   Estrategia 1: Sobrescribiendo archivos directamente..." Custom -CustomColor Gray
                try {
                    Copy-Item "$packagePath\*" $npmModulePath -Recurse -Force -ErrorAction Stop
                    Show-Message "   npm sobrescrito exitosamente" Ok
                } catch {
                    Show-Message "   Falló sobrescritura: $($_.Exception.Message)" Advertencia
                    Show-Message "   No se pudo sobrescribir directamente" Advertencia

                    # ESTRATEGIA 2: Eliminar y copiar
                    Show-Message "   Estrategia 2: Eliminando carpeta corrupta..." Custom -CustomColor Gray

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
                        Show-Message "   Estrategia 3: Renombrando carpeta vieja..." Custom -CustomColor Gray
                        $backupPath = "$nodePath\node_modules\npm.old.$([DateTime]::Now.ToString('yyyyMMddHHmmss'))"
                        try {
                            Rename-Item $npmModulePath $backupPath -Force -ErrorAction Stop
                            Show-Message "   Carpeta antigua renombrada" Ok
                        } catch {
                            Show-Message "   No se pudo eliminar ni renombrar" Error
                            throw "Permisos insuficientes para modificar $npmModulePath"
                        }
                    } else {
                        Show-Message "   Carpeta eliminada" Ok
                    }

                    # Copiar nueva versión
                    Show-Message "   Copiando nueva version de npm..." Custom -CustomColor Gray
                    Copy-Item $packagePath $npmModulePath -Recurse -Force -ErrorAction Stop
                }
            } else {
                # No existe, copiar directamente
                Show-Message "   Copiando nueva versión de npm..." Custom -CustomColor Gray
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
            Show-Message "   Verificando instalación..." Custom -CustomColor Gray
            $npmVer = & $npmCmd -v 2>&1
            if ($LASTEXITCODE -eq 0 -and $npmVer -match "^\d+\.\d+\.\d+") {
                Show-Message "  npm reparado exitosamente: v$npmVer" Ok
                $npmFixed = $true
            } else {
                Show-Message "  npm sigue sin funcionar después de la reparación" Error
            }

        } catch {
            Show-Message "  No se pudo reparar npm: $_" Error
            if ($_ -match "Permisos insuficientes") {
                Show-Message ""
                Show-Message "   SOLUCIÓN:" Advertencia
                Show-Message "   1. Ejecuta PowerShell como Administrador" Custom -CustomColor Gray
                Show-Message "   2. Vuelve a ejecutar este script" Custom -CustomColor Gray
                Show-Message ""
            }
        }
    }
    
    # 5.5 última alternativa: Reinstalar Node.js completo si npm no funciona
    if (-not $npmFixed -and $hasWritePermissions) {
        Show-Message ""
        Show-Message "-[ÚLTIMA OPCIÓN] Intentando reinstalar Node.js v$version completamente..." Custom -CustomColor Magenta

        try {
            # Desinstalar versión actual
            Show-Message "   Paso 1/4: Desinsatalando versión corrupta..." Custom -CustomColor Gray
            nvm uninstall $version 2>&1 | Out-Null
            Start-Sleep -Seconds 3

            # Verificar que se desinstaló
            if (Test-Path $nodePath) {
                Show-Message "   Carpeta no eliminada por nvm, intentando limpieza..." Advertencia
                try {
                    Remove-Item $nodePath -Recurse -Force -ErrorAction Stop
                    Show-Message "   Carpeta eliminada manualmente" Ok
                } catch {
                    Show-Message "   No se puede eliminar. Requiere permisos de admin" Error
                    throw "No se pudo desinstalar completamente"
                }
            } else {
                Show-Message "   Versión desinstalada correctamente" Ok
            }

            # Reinstalar versión limpia
            Show-Message "   Paso 2/4: Descagando e instalando versión limpia (puede tardar 1-2 minutos)..." Custom -CustomColor Gray
            nvm install $version 2>&1 | Out-Null

            if ($LASTEXITCODE -ne 0) {
                throw "Error al reinstalar Node.js v$version"
            }

            # Esperar a que la instalación complete completamente
            Show-Message "   Esperando a que la instalación finalice..." Custom -CustomColor Gray
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
                    Show-Message "   Instalación completada ($elapsedTime segundos)" Ok
                    break
                }

                # Mostrar progreso cada 10 segundos
                if ($elapsedTime % 10 -eq 0) {
                    Show-Message "   Esperando... ($elapsedTime/$maxWaitTime segundos)" Custom -CustomColor Gray
                }
            }

            # Si alcanzó el timeout, dar tiempo extra y verificar una vez más
            if (-not $installComplete) {
                Show-Message "   Timeout de $maxWaitTime segundos alcanzados" Advertencia
                Show-Message "    Dando 30 segundos adicionales por si la instalación está finalizando..." Custom -CustomColor Gray

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
                        Show-Message "   Instalación completada después de $totalTime segundos" Ok
                        break
                    }

                    if ($extraElapsed % 10 -eq 0) {
                        Show-Message "   Tiempo extra: $extraElapsed/$extraWaitTime segundos..." Custom -CustomColor Gray
                    }
                }
            }

            # Verficación final
            if (-not $installComplete) {
                # una última verificación por si los archivos aparecieron justo ahora
                $nodeExeExists = Test-Path "$nodePath\node.exe"
                $npmCmdExists = Test-Path "$nodePath\npm.cmd"

                if ($nodeExeExists -and $npmCmdExists) {
                    Show-Message "   Instalación verificada en verificación final" Ok
                    $installComplete = $true
                } else {
                    throw "La instalación no completó después de 150 segundos o archivos faltantes"
                }
            }

            # Espera adicional de seguridad para que se escriban todos los archivos
            Start-Sleep -Seconds 2

            Show-Message "   Node.js v$version reinstalado completamente" Ok

            # Activar versión
            Show-Message "   Paso 3/4: Activando versión reinstalada..." Custom -CustomColor Gray
            nvm use $version 2>&1 | Out-Null
            Start-Sleep -Seconds 1

            # Verificar npm nuevamente
            Show-Message "   Paso 4/4: Verificando npm..." Custom -CustomColor Gray
            $npmVer = & $npmCmd -v 2>&1

            if ($LASTEXITCODE -eq 0 -and $npmVer -match "^\d+\.\d+\.\d+") {
                Show-Message "-[ÉXITO] npm ahora funciona correctamente: v$npmVer" Ok
                Show-Message "-[ÉXITO] Node.js v$version reinstalado y configurado exitosamente" Ok
                $npmFixed = $true
            } else {
                Show-Message "  No se pudo reinstalar Node.js v$version" Error
                Show-Message "   Es posible que nvm-windows esté corrupto o la versión de Node.js tenga problemas" Advertencia
            }

        } catch {
            Show-Message "  No se pudo reinstalar Node.js v$version" Error
            Show-Message "   Detalles: $_" Error
            Show-Message ""
            Show-Message "   Intenta manualmente:" Advertencia
            Show-Message "   nvm uninstall $version" Custom -CustomColor Gray
            Show-Message "   nvm install $version" Custom -CustomColor Gray
            Show-Message "   nvm use $version" Custom -CustomColor Gray
        }
    }

    # 5.6 Última opción extrema: Cambiar nvm root
    if (-not $npmFixed) {
        Show-Message ""
        if ($hasWritePermissions) {
            Show-Message "-[OPCIÓN FINAL] Todas las estrategias de reparación fallaron" Error
            Show-Message "Esto puede ser un problema de permisos o corrupción severa" Advertencia
        } else {
            Show-Message "-[OPCIÓN FINAL] npm corrupto en ubicación sin permisos" Error
            Show-Message "No se puede reparar sin permisos de escritura en: $nvmBase" Advertencia
        }
        Show-Message ""
        Show-Message "Ubicación actual de nvm: $nvmBase" Custom -CustomColor Gray
        Show-Message ""
        Show-Message "¿Deseas cambiar nvm a una ubicación con permisos completos?" Info
        Show-Message "Recomendado: $env:USERPROFILE\nvm (tu carpeta de usuario)" Custom -CustomColor Gray
        Show-Message ""
        $cambiarRoot = Read-Host "¿Cambiar ubicación de nvm? (S/N, Enter=No)"

        if ($cambiarRoot -eq "S" -or $cambiarRoot -eq "s") {
            Show-Message ""
            Show-Message "Ingresa la NUEVA ubicación para nvm:" Info
            Show-Message "Ejemplos:" Custom -CustomColor Gray
            Show-Message "  - $env:USERPROFILE\nvm" Custom -CustomColor Gray
            Show-Message "  - $env:LOCALAPPDATA\nvm" Custom -CustomColor Gray
            Show-Message "  - C:\Dev\nvm" Custom -CustomColor Gray
            Show-Message ""
            $newNvmRoot = Read-Host "Nueva ruta"

            if (-not [string]::IsNullOrCustomSpace($newNvmRoot)) {
                try {
                    # Crear carpeta si no existe
                    if (-not (Test-Path $newNvmRoot)) {
                        Show-Message "   Creando carpeta: $newNvmRoot" Custom -CustomColor Gray
                        New-Item -ItemType Directory -Path $newNvmRoot -Force | Out-Null
                    }

                    # Verificar que tenemos permisos de escritura
                    $testFile = "$newNvmRoot\test-write-permissions.tmp"
                    try {
                        "test" | Out-File $testFile -ErrorAction Stop
                        Remove-Item $testFile -Force
                        Show-Message "   Permisos de escritura verificados" Ok
                    } catch {
                        throw "No tienes permisos de escritura en: $newNvmRoot"
                    }

                    # Cambiar nvm root
                    Show-Message "   Cambiando nvm root a: $newNvmRoot" Custom -CustomColor Gray
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

                    Show-Message "   nvm root cambiado exitosamente" Ok
                    Show-Message "   Salida: $nvmRootOutput" Custom -CustomColor Gray
                    Show-Message ""

                    # Actualizar variables para próximas versiones
                    $nvmBase = $newNvmRoot
                    $hasWritePermissions = $true # Nueva ubicación tiene permisos

                    # Reinstalar esta versión en nueva ubicación
                    Show-Message "-[REINTENTO] Instalado Node.js v$version en nueva ubicación..." Custom -CustomColor Magenta
                    Show-Message "Nota: La versión corrupta en ubicación anterior quedará intacta" Custom -CustomColor Gray
                    $nodePath = "$nvmBase\v$version"

                    # Intentar desinstalar de ubicación vieja (puede fallar sin permisos)
                    Show-Message "   Intentado desinstalar de ubicación anterior..." Custom -CustomColor Gray
                    nvm uninstall $version 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0) {
                        Show-Message "   No se pudo desinstalar de ubicación anterior (sin permisos)" Custom -CustomColor Gray
                        Show-Message "   La versión corrupta quedará en: $(Split-Path $nodePath -Parent)" Custom -CustomColor Gray
                    }
                    Start-Sleep -Seconds 2

                    # Instalar en nueva ubicación
                    Show-Message "   Instalando Node.js v$version en nueva ubicación..." Custom -CustomColor Gray
                    nvm install $version 2>&1 | Out-Null

                    if ($LASTEXITCODE -ne 0) {
                        throw "Error al instalar Node.js en nueva ubicación"
                    }

                    # Esperar instalación
                    Show-Message "   Esperando a que complete la instalación..." Custom -CustomColor Gray
                    $maxWait = 120
                    $elapsed = 0
                    while ($elapsed -lt $maxWait) {
                        Start-Sleep -Seconds 2
                        $elapsed += 2
                        if ((Test-Path "$nodePath\node.exe") -and (Test-Path "$nodePath\npm.cmd")) {
                            break
                        }
                        if ($elapsed % 10 -eq 0) {
                            Show-Message "   Esperando... ($elapsed/$maxWait seg)" Custom -CustomColor Gray
                        }
                    }

                    # Activar versión
                    Show-Message "   Activando Node.js v$version..." Custom -CustomColor Gray
                    nvm use $version 2>&1 | Out-Null
                    Start-Sleep -Seconds 1

                    # Verificar npm
                    $npmCmd = "$nodePath\npm.cmd"
                    $npmVer = & $npmCmd -v 2>&1

                    if ($LASTEXITCODE -eq 0 -and $npmVer -match "^\d+\.\d+\.\d+") {
                        Show-Message "-[ÉXITO] Node.js v$version isntalado correctamente en nueva ubicación" Ok
                        Show-Message "-[ÉXITO] npm funciona: v$npmVer" Ok
                        $npmFixed = $true
                    } else {
                        Show-Message "  npm sigue sin funcionar en nueva ubicación" Error
                    }

                } catch {
                    Show-Message "  No se pudo cambiar nvm root: $_" Error
                    Show-Message ""
                    Show-Message "   Intenta manualmente:" Advertencia
                    Show-Message "   1. Ejecuta PowerShell como Administrador" Custom -CustomColor Gray
                    Show-Message "   2. Ejecuta: nvm root $newNvmRoot" Custom -CustomColor Gray
                    Show-Message "   3. Vuelve a ejecutar este script" Custom -CustomColor Gray
                }
            }
        }
    }

    # 5.7 Resumen de la versión
    if ($npmFixed) {
        Show-Message "-[ÉXITO] Node.js v$version configurado correctamente" Ok
        $successCount++
    } else {
        Show-Message "-[FALLO] Node.js v$version instalado pero npm no funciona" Error
        Show-Message "Considera cambiar la ubicación de nvm manualmente o ejecutar como admin" Advertencia
        $failCount++
    }
}

# ========================================
# 6. RESUMEN FINAL
# ========================================
Show-Message ""
Show-Message "========================================" Info
Show-Message "  Resumen Final" Info
Show-Message "========================================" Info
Show-Message "Versiones procesadas: $($nodeVersions.Count)" Custom
Show-Message "Exitosas: $successCount" Ok
Show-Message "Fallidas: $failCount" Error
Show-Message ""
Show-Message "Proceso completado." Info
