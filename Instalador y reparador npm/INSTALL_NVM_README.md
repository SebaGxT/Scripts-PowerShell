#  Instalador y Reparador de Node.js + npm con nvm

> **Versión:** 2.0.1  
> **Última actualización:** 11/12/2025  
> **Compatibilidad:** Windows + PowerShell 5.1+

---

##  Descripción

Script automatizado para instalar, configurar y reparar versiones de Node.js usando nvm-windows. Detecta automáticamente archivos .nvmrc y repara instalaciones de npm corruptas con múltiples estrategias de recuperación.

**Características Principales:**
-  Detecta y usa archivos .nvmrc automáticamente
-  Instala versiones de Node.js con nvm
-  **NUEVO:** Detecta y configura nvm en PATH automáticamente
-  **NUEVO:** Verifica permisos de administrador
-  **NUEVO:** 3 estrategias para reparar npm corrupto sin loops infinitos
-  **NUEVO:** Sobrescritura directa sin eliminar archivos (evita "Acceso denegado")
-  Valida que node y npm funcionen correctamente
-  Manejo robusto de errores con reintentos controlados
-  Interfaz visual con colores y feedback claro

---

##  Requisitos Previos

### Software Necesario

| Software | Versión Mínima | Instalación |
|----------|----------------|-------------|
| **Windows** | 10+ | - |
| **PowerShell** | 5.1+ | Incluido en Windows |
| **nvm-windows** | 1.1.9+ | [Descargar](https://github.com/coreybutler/nvm-windows/releases) |
| **tar** | Cualquiera | Incluido en Windows 10+ |

### Verificar Requisitos

\\\powershell
# Verificar PowerShell
$PSVersionTable.PSVersion

# Verificar nvm
nvm version

# Verificar tar
tar --version
\\\

---

##  Uso

### Opción 1: Con archivo .nvmrc (Recomendado)

Si tienes un proyecto con archivo .nvmrc:

\\\powershell
# 1. Navegar a la carpeta con .nvmrc
cd "C:\ruta\al\proyecto"

# 2. Ejecutar el script (ajusta la ruta según donde esté)
..\install_npm_version_v2.ps1

# 3. El script detectará .nvmrc automáticamente
# ¿Usar esta versión? (S/N, Enter=Sí)
#  Presiona Enter o escribe S

# 4. Opcionalmente agrega más versiones
# Ingresa versiones adicionales: 22.21.1,24.11.1
#  O presiona Enter para omitir

# 5. Elige versión de npm
# Versión de npm (ej: 10.9.4, Enter=latest)
#  Presiona Enter para usar la última
\\\

### Opción 2: Sin .nvmrc (Manual)

Si no tienes .nvmrc o quieres especificar versiones manualmente:

\\\powershell
# 1. Navegar a donde está el script
cd "C:\Users\tu_usuario\Scripts"

# 2. Ejecutar el script
.\install_npm_version_v2.ps1

# 3. Ingresar versiones separadas por coma
# Ingresa versiones: 24.11.0,24.11.1,22.21.1

# 4. Ingresar versión de npm
# Versión de npm: 10.9.4
#  O presiona Enter para la última
\\\

### Opción 3: Combinado (.nvmrc + Manual)

\\\powershell
# Usar .nvmrc + agregar versiones adicionales

.\install_npm_version_v2.ps1
# ¿Usar versión de .nvmrc (24.11.0)? S
# Versiones adicionales: 22.21.1,20.18.0
# Versión de npm: (Enter para latest)
\\\

---

##  Ejemplos de Uso

### Ejemplo 1: Instalar versión única desde .nvmrc

\\\powershell
PS C:\proyecto> ..\install_npm_version_v2.ps1

=====================================
  Instalador de Node.js + npm (nvm)
=====================================

[OK] nvm está instalado
[OK] Ruta de nvm detectada: C:\ProgramData\nvm
[INFO] Archivo .nvmrc encontrado con versión: 24.11.0
¿Usar esta versión? (S/N, Enter=Sí): 
[OK] Usando versión de .nvmrc: 24.11.0

Ingresa versiones adicionales (Enter para omitir): 
Versiones a procesar: 24.11.0

Versión de npm (Enter=latest): 
[OK] Última versión de npm: 10.9.4

=====================================
  Iniciando procesamiento...
=====================================


Procesando Node.js v24.11.0...

[OK] Node.js v24.11.0 ya está instalado
[ACCIÓN] Activando Node.js v24.11.0...
[OK] Node.js verificado: v24.11.0
[OK] npm verificado: v10.9.4
[ÉXITO] Node.js v24.11.0 configurado correctamente

=====================================
  Resumen Final
=====================================
Versiones procesadas: 1
Exitosas: 1
Fallidas: 0
\\\

### Ejemplo 2: Instalar múltiples versiones y reparar npm

\\\powershell
PS C:\> .\install_npm_version_v2.ps1

Ingresa versiones: 24.11.1,22.21.1
Versión de npm: 10.9.4


Procesando Node.js v24.11.1...

[INFO] Node.js v24.11.1 no está instalado
[ACCIÓN] Instalando con nvm...
[OK] Node.js v24.11.1 instalado correctamente
[ACCIÓN] Activando Node.js v24.11.1...
[OK] Node.js verificado: v24.11.1
[ADVERTENCIA] npm no funciona o está corrupto
[ACCIÓN] Reparando npm v10.9.4...
   Descargando npm v10.9.4...
   Extrayendo archivo...
   Reemplazando instalación corrupta...
   Preparando archivos para modificación...
   [INFO] 2 proceso(s) terminado(s), esperando 2 segundos...
   [INFO] 1547 archivo(s) desbloqueado(s)
   Estrategia 1: Sobrescribiendo archivos directamente...
   [OK] npm sobrescrito exitosamente
[OK] npm reparado exitosamente: v10.9.4
[ÉXITO] Node.js v24.11.1 configurado correctamente


Procesando Node.js v22.21.1...

[OK] Node.js v22.21.1 ya está instalado
[OK] Node.js verificado: v22.21.1
[OK] npm verificado: v10.9.0
[ÉXITO] Node.js v22.21.1 configurado correctamente

=====================================
  Resumen Final
=====================================
Versiones procesadas: 2
Exitosas: 2
Fallidas: 0
\\\

### Ejemplo 3: Versión no disponible

\\\powershell
Ingresa versiones: 99.99.99


Procesando Node.js v99.99.99...

[INFO] Node.js v99.99.99 no está instalado
[ACCIÓN] Instalando con nvm...
[ERROR] No se pudo instalar Node.js v99.99.99 (versión no disponible)

=====================================
  Resumen Final
=====================================
Versiones procesadas: 1
Exitosas: 0
Fallidas: 1
\\\

---

##  Qué Hace el Script Paso a Paso

### 0. Verificación de Permisos (Doble validación)

**A. Verificación de ejecución como Administrador:**
-  Detecta si se ejecuta como Administrador
-  Si no tiene permisos, advierte sobre limitaciones
-  Permite continuar sin permisos

**B. Verificación de permisos de escritura en nvm:**
-  **NUEVO:** Intenta crear archivo temporal en carpeta nvm
-  Detecta si puedes modificar archivos en la ubicación de nvm
-  Si no tiene permisos de escritura:
  - Muestra limitaciones específicas (no reparar, no desinstalar)
  - Ofrece opciones claras (contactar IT, usar otra PC, continuar en modo limitado)
  - Permite continuar solo para verificación
-  Da instrucciones claras según el nivel de restricción

### 1. Verificaciones Iniciales de nvm

**A. Verificación del comando nvm:**
-  Verifica que nvm responda al comando `nvm`
-  **NUEVO:** Si no responde, busca nvm.exe en ubicaciones comunes:
  - `C:\Program Files\nvm`
  - `C:\ProgramData\nvm`
  - `%LOCALAPPDATA%\nvm`
  - `%APPDATA%\nvm`
-  **NUEVO:** Si lo encuentra, agrega nvm automáticamente al PATH del usuario
-  **NUEVO:** Configura variable de entorno `NVM_HOME`

**B. Detección de ubicación de nvm (3 niveles):**
1. **Nivel 1 - nvm root (Prioridad):**
   - Ejecuta `nvm root` para obtener la ubicación actual
   - Esta es la **fuente de verdad** de dónde nvm guarda versiones
   - Detecta cambios si modificaste `nvm root` manualmente
2. **Nivel 2 - Variables y ubicaciones comunes:**
   - Solo si falla el nivel 1
   - Busca en `$env:NVM_HOME`, `C:\ProgramData\nvm`, etc.
3. **Nivel 3 - Manual:**
   - Solicita al usuario ingresar la ruta

-  Busca archivo .nvmrc en el directorio actual

### 2. Recopilación de Versiones
-  Si existe .nvmrc, ofrece usarlo
-  Permite ingresar versiones adicionales manualmente
-  Elimina duplicados automáticamente

### 3. Configuración de npm
-  Obtiene la última versión de npm desde npmjs.org
-  O usa la versión especificada manualmente

### 4. Procesamiento por Versión
Para cada versión de Node.js:

#### a) Instalación
-  **NUEVO:** Verifica si la versión ya existe (carpeta + archivos críticos)
-  **NUEVO:** Detecta instalaciones previas que se completaron después de timeout
-  Si archivos críticos existen (`node.exe`, `npm.cmd`): Usa la instalación
-  Si no existe: Ejecuta `nvm install <version>`
-  **NUEVO:** Espera inteligente hasta 150 segundos:
  - 0-120s: Verificación normal cada 2 segundos
  - 120-150s: Tiempo extra con advertencia
  - Verificación final después del timeout
-  **NUEVO:** Si falla por timeout, da instrucciones para reintentar el script

#### b) Activación
-  Ejecuta 
vm use <version>
-  Espera 500ms para cambio de PATH

#### c) Verificación de Node
-  Busca 
ode.exe en la ruta de instalación
-  Ejecuta 
ode -v para verificar que funciona

#### d) Verificación de npm
-  Busca 
pm.cmd
-  Ejecuta 
pm -v
-  Si funciona  Continúa
-  Si falla  Proceso de reparación

#### e) Reparación de npm (si es necesario)

**NUEVO: Proceso con 4 estrategias sin loops infinitos**

1. **Descarga:** `npm-<version>.tgz` desde npmjs.org
2. **Extrae:** Con tar a carpeta temporal (`$env:TEMP`)

**Fase de Preparación (🔧 Antes de cualquier estrategia):**
- **Termina procesos bloqueantes:** Busca y cierra `node.exe`, `npm.cmd`, `npx.cmd`
- **Libera archivos:** Cambia atributos de todos los archivos a Normal
- **Elimina bloqueos:** Quita atributos de Sistema, Oculto, Solo Lectura
- **Espera seguridad:** 2 segundos después de terminar procesos
- **Muestra diagnóstico:** Indica cuántos procesos y archivos fueron modificados

**Estrategia 1: Sobrescritura Directa (⭐ Preferida)**
- Intenta sobrescribir archivos existentes sin eliminar carpeta
- Usa `Copy-Item -Force` para reemplazar archivos en su lugar
- **Ventaja:** Evita errores de "Acceso denegado" al no eliminar
- No requiere permisos especiales en la mayoría de casos
- Ahora muestra el error específico si falla

**Estrategia 2: Eliminar y Copiar**
- Si la sobrescritura falla, intenta eliminar la carpeta completa
- Primero quita atributos de solo lectura
- Usa `-ErrorAction SilentlyContinue` (no se detiene en errores)
- **Ventaja:** Limpia archivos corruptos completamente

**Estrategia 3: Renombrar y Crear**
- Si no puede eliminar, renombra carpeta vieja a `npm.old.TIMESTAMP`
- Crea nueva carpeta npm limpia
- **Ventaja:** Preserva respaldo automático y evita conflictos

**Estrategia 4: Reinstalación Completa de Node.js (🔄 Penúltima opción)**
- Si todas las estrategias anteriores fallan Y tienes permisos de escritura
- Desinstala completamente Node.js con `nvm uninstall`
- Reinstala desde cero con `nvm install`
- Espera activamente hasta 2 minutos verificando archivos críticos
- Verifica cada 2 segundos: `node.exe` y `npm.cmd`
- **Ventaja:** Solución definitiva que elimina cualquier corrupción
- **Requisito:** Permisos de escritura en ubicación de nvm

**Estrategia 5: Cambio de Ubicación de nvm (🔄 Última opción)**
- Si todas las estrategias fallan (con o sin permisos)
- Pregunta al usuario si desea cambiar nvm root
- Sugiere ubicaciones con permisos: `%USERPROFILE%\nvm`, `%LOCALAPPDATA%\nvm`
- Valida permisos en nueva ubicación antes de cambiar
- Ejecuta `nvm root <nueva-ruta>` para cambiar ubicación
- Intenta desinstalar versión de ubicación anterior (opcional)
- Reinstala Node.js limpio en nueva ubicación
- Actualiza variables para versiones siguientes
- **Ventaja:** Funciona INCLUSO sin permisos en ubicación actual
- **Resultado:** Todas las futuras instalaciones usan la nueva ubicación

3. **Copia:** Archivos .cmd al root de Node.js
4. **Limpia:** Archivos temporales
5. **Verifica:** Ejecuta `npm -v` nuevamente

### 5. Resumen Final
-  Contador de versiones exitosas
-  Contador de versiones fallidas
-  Lista completa procesada

---

##  Códigos de Color

El script usa colores para facilitar la lectura:

| Color | Significado | Ejemplo |
|-------|-------------|---------|
|  **Verde** | Éxito, operación completada | [OK] npm verificado |
|  **Amarillo** | Advertencia, atención requerida | [ADVERTENCIA] npm corrupto |
|  **Rojo** | Error, operación falló | [ERROR] Versión no existe |
|  **Cyan** | Información, progreso | [INFO] Descargando... |
|  **Gris** | Detalles técnicos |  Extrayendo archivo... |

---

##  Troubleshooting

### Problema 0: "No se pudo cambiar nvm root" ✨ NUEVO

**Síntoma:**
\\\
[ERROR] No se pudo cambiar nvm root: nvm root no cambió correctamente
\\\

**Causa:**
- Versiones antiguas del script redirigían salida con `Out-Null`
- Esto puede interferir con la ejecución del comando `nvm root`

**Solución:**
El script v2.0.1 ahora maneja esto correctamente. Si aún falla:

\\\powershell
# Opción 1: Ejecutar manualmente el cambio
nvm root C:\Users\tu_usuario\nvm

# Verificar el cambio
nvm root
# Debe mostrar: Current Root: C:\Users\tu_usuario\nvm

# Luego ejecutar el script nuevamente
.\install_npm_version_v2.ps1
\\\

**Nota:** El comando `nvm root` en sí mismo no requiere permisos de admin, pero modifica el archivo `settings.txt` dentro de la instalación de nvm.

---

### Problema 1: "nvm no está instalado"

**Síntoma:**
\\\
[ERROR] nvm no está instalado en este sistema
\\\

**Solución:**
1. Descargar nvm-windows: https://github.com/coreybutler/nvm-windows/releases
2. Instalar con permisos de administrador
3. Cerrar y reabrir PowerShell
4. Verificar: `nvm version`

---

### Problema 1.5: "nvm instalado pero no en PATH" ✨ NUEVO

**Síntoma:**
\\\
[ADVERTENCIA] nvm no responde al comando 'nvm'
Verificando si nvm está instalado pero no está en PATH...
\\\

**Solución Automática:**
El script ahora detecta y configura automáticamente nvm en el PATH:
1. Busca `nvm.exe` en ubicaciones comunes
2. Agrega la ruta al PATH del usuario
3. Configura variable `NVM_HOME`
4. Actualiza la sesión actual

**Si falla la configuración automática:**
\\\powershell
# Agregar manualmente al PATH del usuario
$nvmPath = "C:\ProgramData\nvm"  # Ajusta según tu instalación
[Environment]::SetEnvironmentVariable("Path", "$env:Path;$nvmPath", "User")
[Environment]::SetEnvironmentVariable("NVM_HOME", $nvmPath, "User")

# Reinicia PowerShell para aplicar cambios
\\\

---

### Problema 2: "No se detectó la ruta de nvm"

**Síntoma:**
\\\
[ADVERTENCIA] No se detectó automáticamente la ruta de nvm
\\\

**Solución:**
1. Buscar la carpeta de nvm manualmente
2. Ubicaciones comunes:
   - C:\ProgramData\nvm
   - C:\Program Files\nvm
   - C:\Users\<tu_usuario>\AppData\Local\nvm
3. Ingresar la ruta cuando el script lo solicite

---

### Problema 3: "Error al extraer archivo"

**Síntoma:**
\\\
[ERROR] Error al extraer archivo
\\\

**Causas posibles:**
- Archivo descargado corrupto
- Versión de npm no existe
- tar no está disponible

**Solución:**
\\\powershell
# Verificar tar
tar --version

# Si no existe, instalar desde Windows Features
# O usar versión LTS de npm conocida (10.9.4)
\\\

---

### Problema 3.5: "Instalación no completó por timeout" ✨ NUEVO

**Síntoma:**
\\\
[ERROR] La instalación no completó en el tiempo esperado

IMPORTANTE:
La instalación de Node.js v24.11.1 puede seguir en proceso en segundo plano.
\\\

**Causa:**
- Conexión lenta
- Versión de Node.js muy grande
- Servidor de descarga lento

**Solución:**
1. **Espera 2-3 minutos** para que termine la descarga
2. **Ejecuta el script nuevamente:**
   \\\powershell
   .\install_npm_version_v2.ps1
   \\\
3. El script **detectará automáticamente** si la instalación se completó:
   \\\
   [OK] Node.js v24.11.1 encontrado (instalación previa completada)
   \\\

**Verificación manual:**
\\\powershell
# Ver versiones instaladas
nvm list

# Ver si los archivos críticos existen
Test-Path "C:\Users\tu_usuario\nvm\v24.11.1\node.exe"
Test-Path "C:\Users\tu_usuario\nvm\v24.11.1\npm.cmd"
\\\

**Nota:** El script ahora espera hasta 150 segundos (2.5 minutos) antes de timeout.

---

### Problema 4: "npm sigue sin funcionar"

**Síntoma:**
\\\
[ERROR] npm sigue sin funcionar después de la reparación
\\\

**Solución:**
\\\powershell
# Desinstalar y reinstalar la versión de Node.js
nvm uninstall 24.11.0
nvm install 24.11.0

# Ejecutar el script nuevamente
.\install_npm_version_v2.ps1
\\\

---

### Problema 5: "Acceso denegado" al reparar npm ✨ MEJORADO

**Síntoma:**
\\\
Remove-Item : No se puede quitar el elemento
Acceso denegado a la ruta de acceso
Copy-Item : El proceso no puede tener acceso al archivo porque está siendo utilizado
\\\

**Solución Automática (v2.0.1+):**

El script ahora tiene una **Fase de Preparación + 4 estrategias** para resolver esto:

**Fase de Preparación (Automática):**
- 🔧 Detecta y termina procesos de `node.exe`, `npm.cmd`, `npx.cmd`
- 🔧 Cambia atributos de TODOS los archivos a Normal
- 🔧 Elimina atributos de Sistema, Oculto, Solo Lectura
- 🔧 Espera 2 segundos para liberar bloqueos
- 🔧 Muestra cuántos procesos y archivos fueron modificados

**1. Estrategia 1 (Sobrescritura):**
   - Intenta sobrescribir archivos directamente sin eliminar
   - **No requiere permisos especiales** en la mayoría de casos
   - Evita el loop infinito de errores
   - Muestra error específico si falla

**2. Estrategia 2 (Eliminar con reintentos):**
   - Si falla #1, intenta eliminar después de preparación
   - Usa `-ErrorAction SilentlyContinue` para no detenerse

**3. Estrategia 3 (Renombrar):**
   - Si falla #2, renombra carpeta vieja a `npm.old.TIMESTAMP`
   - Crea instalación limpia en nueva carpeta

**4. Estrategia 4 (Reinstalación completa):**
   - Si fallan las 3 anteriores Y hay permisos de escritura
   - Desinstala y reinstala Node.js completamente
   - Espera activa verificando archivos cada 2 segundos
   - Solución definitiva que elimina cualquier corrupción

**5. Estrategia 5 (Cambio de ubicación nvm):**
   - Si todas las anteriores fallan (con o sin permisos)
   - Ofrece cambiar `nvm root` a ubicación con permisos
   - Sugiere: `%USERPROFILE%\nvm` o `%LOCALAPPDATA%\nvm`
   - Valida permisos antes de cambiar
   - Ejecuta `nvm root <nueva-ruta>` capturando la salida correctamente
   - Verifica el mensaje "Root has been set to" para confirmar éxito
   - Reinstala Node.js en nueva ubicación
   - **Funciona INCLUSO sin permisos en ubicación actual**
   - Solución definitiva para entornos corporativos restringidos
   - **Nota:** Si falla en el script, da instrucciones para hacerlo manualmente

**Si todas las estrategias fallan:**
\\\powershell
# Opción A: Ejecutar PowerShell como Administrador (Recomendado)
# 1. Click derecho en PowerShell → Ejecutar como administrador
# 2. Ejecutar el script nuevamente
.\install_npm_version_v2.ps1

# Opción B: Eliminar manualmente como admin
Remove-Item "C:\ProgramData\NVM\v24.11.1\node_modules\npm" -Recurse -Force

# Luego ejecutar el script
.\install_npm_version_v2.ps1
\\\

**Nota:** En la mayoría de casos, la Estrategia 1 funciona sin permisos de admin.

---

##  Notas Importantes

###  Advertencias

1. **Permisos de Administrador:** ✨ ACTUALIZADO
   - **NO requeridos** para instalación básica y reparación con Estrategia 1
   - Pueden ser necesarios si las 3 estrategias de reparación fallan
   - El script detecta automáticamente y sugiere alternativas
   - **Estrategia 5 (cambio de ubicación) funciona sin permisos en ubicación actual**
   
2. **Entornos Corporativos Restringidos:** ✨ NUEVO
   - El script detecta si no tienes permisos de escritura en nvm
   - Ofrece "modo limitado" para solo verificación
   - Estrategia 5 permite cambiar ubicación de nvm sin permisos actuales
   - Útil en PCs donde nvm fue instalado por IT con permisos de admin
   
3. **Conexión a Internet:** Necesaria para descargar versiones de Node.js y npm

4. **Tiempo de Ejecución:** Puede tomar varios minutos por versión
   - Instalación: 30-60 segundos por versión (hasta 150s con timeout extendido)
   - Reparación npm: 10-30 segundos adicionales
   - Reinstalación completa: 1-2 minutos por versión
   - **Si hay timeout:** Espera 2-3 minutos y reintenta el script

5. **Espacio en Disco:** Cada versión de Node.js ocupa ~50-100MB
   - Si usa Estrategia 3, mantiene backup en `npm.old.TIMESTAMP`
   - Si cambia ubicación de nvm, versiones viejas quedan en ubicación anterior

###  Tips

1. **Versiones LTS:** Usa versiones LTS para mayor estabilidad
   - 20.x.x (Active LTS)
   - 22.x.x (Active LTS)
   - 24.x.x (Active LTS)

2. **npm Recomendado:** Usa npm 10.9.4 o superior

3. **Backup:** El script hace backup automático eliminando la carpeta corrupta

4. **.nvmrc:** Coloca el archivo en la raíz del proyecto para automatizar

5. **Ubicación de nvm recomendada:** ✨ NUEVO
   - Para uso personal: `C:\Users\tu_usuario\nvm`
   - Evita: `C:\ProgramData\nvm` (requiere permisos de admin)
   - Ventaja: Control total sin necesidad de permisos elevados

6. **Entornos corporativos:** ✨ NUEVO
   - Si no puedes reparar npm, usa Estrategia 5 para cambiar ubicación
   - Solicita a IT que cambie `nvm root` a tu carpeta de usuario
   - O ejecuta el script que te guiará en el proceso

---

##  Enlaces Útiles

- **nvm-windows:** https://github.com/coreybutler/nvm-windows
- **Node.js releases:** https://nodejs.org/en/about/previous-releases
- **npm registry:** https://registry.npmjs.org/
- **Documentación Node.js:** https://nodejs.org/docs/

---

##  Casos de Uso Especiales ✨ NUEVO

### Entorno Corporativo con Permisos Muy Restringidos

**Escenario:**
- nvm instalado en `C:\ProgramData\nvm` por IT
- No puedes desinstalar ni modificar archivos
- npm está corrupto y no funciona
- No tienes permisos de administrador

**Solución con el script:**

1. Ejecuta el script normalmente:
   ```powershell
   .\install_npm_version_v2.ps1
   ```

2. El script detectará la ubicación actual de nvm:
   ```
   [INFO] Detectando ubicación actual de nvm...
   [OK] nvm root actual: C:\ProgramData\nvm
   ```

3. Detectará falta de permisos:
   ```
   [ADVERTENCIA] No tienes permisos de escritura en: C:\ProgramData\nvm
   ```

4. Elige continuar cuando te pregunte

5. Cuando detecte npm corrupto, te dirá que no puede repararlo

6. Al final, te ofrecerá cambiar ubicación de nvm:
   ```
   ¿Cambiar ubicación de nvm? (S/N): S
   Nueva ruta: C:\Users\tu_usuario\nvm
   
   Creando carpeta: C:\Users\tu_usuario\nvm
   [OK] Permisos de escritura verificados
   Cambiando nvm root a: C:\Users\tu_usuario\nvm
   [OK] nvm root cambiado exitosamente
   Salida: Root has been set to C:\Users\tu_usuario\nvm
   ```

6. El script cambiará la ubicación y reinstalará Node.js limpio

**Si el cambio de root falla:**

El script te dará instrucciones para hacerlo manualmente:
```powershell
# Ejecutar este comando (no requiere admin)
nvm root C:\Users\tu_usuario\nvm

# Verificar
nvm root
# Debe mostrar: Current Root: C:\Users\tu_usuario\nvm

# Ejecutar el script nuevamente
.\install_npm_version_v2.ps1
```

**Resultado:**
- ✅ nvm ahora usa tu carpeta de usuario
- ✅ Tienes control total sin permisos de admin
- ⚠️ Versiones viejas quedan en ubicación anterior (intactas)
- ✅ Futuras versiones se instalan en nueva ubicación con permisos completos

---

##  Soporte

Si encuentras problemas no documentados:

1. Revisar la sección [Troubleshooting](#-troubleshooting)
2. Verificar que cumples todos los [Requisitos Previos](#-requisitos-previos)
3. Si estás en entorno restringido, usa Estrategia 5 (cambio de ubicación)
4. Ejecutar el script con permisos de administrador (última opción)
5. Verificar conexión a internet

---

##  Licencia

Script de uso libre para automatización de entornos Node.js.

---

##  Changelog

### Versión 2.0.1 (11/12/2025)

**Nuevas Características:**
- ✨ **Detección inteligente de ubicación de nvm en 3 niveles:**
  1. Prioridad: `nvm root` (fuente de verdad)
  2. Variables de entorno y ubicaciones comunes
  3. Entrada manual
- ✨ Detección automática de nvm en PATH y configuración sin intervención manual
- ✨ **Doble verificación de permisos:**
  - Verificación de ejecución como Administrador
  - Verificación de permisos de escritura en ubicación de nvm
- ✨ **Modo limitado para entornos restringidos:**
  - Detecta si no hay permisos de escritura en nvm
  - Advierte limitaciones antes de intentar reparaciones
  - Permite continuar solo para verificación
  - Da opciones específicas según restricciones
- ✨ **Verificación de instalaciones previas:**
  - Detecta si Node.js se instaló después de un timeout anterior
  - No reinstala versiones que ya están completas
  - Verifica archivos críticos en lugar de solo carpetas
- ✨ **Fase de preparación automática:** Termina procesos y libera archivos ANTES de reparar
- ✨ 5 estrategias progresivas para reparar npm sin loops infinitos:
  1. Sobrescritura directa (sin eliminar archivos)
  2. Eliminación con reintentos controlados
  3. Renombrado de carpeta vieja + instalación limpia
  4. **Reinstalación completa de Node.js** (si hay permisos)
  5. **Cambio de ubicación de nvm** (funciona SIN permisos en ubicación actual)
- ✨ **Espera inteligente extendida:** verifica archivos cada 2s hasta 150 segundos (2.5 min)
  - Tiempo normal: 120 segundos
  - Tiempo extra: 30 segundos con advertencia
  - Verificación final adicional
- ✨ Detección y terminación automática de procesos `node`, `npm`, `npx`
- ✨ **Mensajes de timeout mejorados** con instrucciones claras para reintentar
- ✨ Estrategia 5 funciona en PCs con permisos muy restringidos

**Mejoras:**
- 🔧 Manejo robusto de errores "Acceso denegado"
- 🔧 **Cambio preventivo de atributos** en TODOS los archivos antes de modificar
- 🔧 **Mensajes de diagnóstico detallados:** Muestra error específico en cada estrategia
- 🔧 Liberación automática de bloqueos de archivos
- 🔧 Sin loops infinitos en errores de permisos
- 🔧 Configuración automática de variables de entorno (`NVM_HOME`, `PATH`)
- 🔧 Mensajes más claros y específicos por estrategia
- 🔧 Feedback de progreso durante reinstalaciones largas
- 🔧 Contador de procesos terminados y archivos desbloqueados

**Correcciones:**
- 🐛 Corregido loop infinito al encontrar archivos bloqueados
- 🐛 Corregido problema de nvm instalado pero no accesible
- 🐛 Mejorado manejo de permisos sin requerir admin en mayoría de casos
- 🐛 Script no continuaba si la reinstalación de Node.js tardaba más de lo esperado
- 🐛 **Fallos en sobrescritura por procesos activos o atributos de archivos**
- 🐛 Script intentaba reparaciones inútiles en entornos muy restringidos
- 🐛 No se podía usar el script en PCs corporativas con permisos limitados
- 🐛 **Comando `nvm root` fallaba por uso de `Out-Null` que interfería con la ejecución**
- 🐛 No se verificaba correctamente el mensaje de éxito al cambiar ubicación de nvm
- 🐛 **No detectaba cambios manuales en `nvm root` entre ejecuciones**
- 🐛 **Reinstalaba versiones que ya estaban completas después de timeout**
- 🐛 **Mensajes de timeout poco claros, no indicaban qué hacer**
- 🐛 Timeout demasiado corto (120s) para conexiones lentas

### Versión 2.0.0 (11/12/2024)
- 🎉 Versión inicial con soporte .nvmrc
- 🎉 Reparación manual de npm standalone
- 🎉 Interfaz con colores y feedback

---

**Última actualización:** 11/12/2025  
**Versión del script:** 2.0.1
