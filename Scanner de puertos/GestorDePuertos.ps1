function Mostrar-Menu {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "   GESTOR DE PUERTOS Y DIAGNÓSTICO DE RED" -ForegroundColor White
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "1. Ver mapa de puertos (Ventana Flotante)"
    Write-Host "2. Listar puertos activos (Consola con Nombres)"
    Write-Host "3. Consultar puerto específico"
    Write-Host "4. Vista cruda (netstat -ano)"
    Write-Host "5. Ayuda / Descripción de comandos"
    Write-Host "6. Salir"
    Write-Host "==============================================" -ForegroundColor Cyan
}

function Mostrar-Ayuda {
    Clear-Host
    Write-Host "--- AYUDA Y DESCRIPCIÓN ---" -ForegroundColor Yellow
    Write-Host "Opción 1: Usa 'Out-GridView'. Ideal para filtrar y buscar visualmente."
    Write-Host "Opción 2: Muestra el proceso real (ej. Ollama.exe) al lado del puerto."
    Write-Host "Opción 3: Te permite ver el estado y el PID de un puerto que elijas."
    Write-Host "Opción 4: El comando clásico de red. Rápido y directo."
    Write-Host ""
    Pause
}

do {
    Mostrar-Menu
    $opcion = Read-Host "Seleccione una opción [1-6]"

    switch ($opcion) {
        "1" {
            Write-Host "Abriendo ventana visual..." -ForegroundColor Green
            Get-NetTCPConnection -State Listen | Select-Object `
                @{Name="Puerto"; Expression={$_.LocalPort}}, `
                @{Name="PID"; Expression={$_.OwningProcess}}, `
                @{Name="Proceso"; Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} | `
                Sort-Object Puerto | Out-GridView -Title "Mapa de Puertos"
        }
        "2" {
            Get-NetTCPConnection -State Listen | Select-Object `
                LocalPort, OwningProcess, `
                @{Name="ProcessName"; Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name}} | `
                Format-Table -AutoSize
            Pause
        }
        "3" {
            $p = Read-Host "Ingrese el número de puerto a consultar"
            try {
                Get-NetTCPConnection -LocalPort $p -ErrorAction Stop | Select-Object `
                    LocalPort, OwningProcess, State, `
                    @{Name="NombreProceso"; Expression={(Get-Process -Id $_.OwningProcess).Name}} | `
                    Format-Table -AutoSize
            } catch {
                Write-Host "No se encontró nada en el puerto $p" -ForegroundColor Red
            }
            Pause
        }
        "4" {
            netstat -ano | findstr LISTENING
            Pause
        }
        "5" {
            Mostrar-Ayuda
        }
        "6" { 
            Write-Host "`nSaliendo del programa... ¡Hasta luego!" -ForegroundColor Green
            # No hace falta hacer nada más, el 'while' al final se encargará de romper el bucle
        }
        Default {
            Write-Host "`n>>> OPCIÓN INVÁLIDA ($opcion). Elija un número del 1 al 6." -ForegroundColor Red
            Write-Host "Presione una tecla para continuar..." -ForegroundColor Gray
            $null = [System.Console]::ReadKey($true)
        }
    }
} while ($opcion -ne "6")