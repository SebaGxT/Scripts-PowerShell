function Mostrar-Menu {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "          GESTOR INTEGRAL DE DOCKER" -ForegroundColor White
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "1. Listar Contenedores ACTIVOS"
    Write-Host "2. Vista Detallada (Todos los contenedores)"
    Write-Host "3. Instalar Nuevo Contenedor (Mapeo de Puertos)"
    Write-Host "4. Reiniciar Contenedor"
    Write-Host "5. Eliminar Contenedor (Con Confirmación)"
    Write-Host "6. Ver Consumo de Recursos (RAM/CPU)"
    Write-Host "7. Ver Logs en Tiempo Real (Ventana aparte)"
    Write-Host "8. Ayuda Detallada de Comandos"
    Write-Host "9. Salir"
    Write-Host "==============================================" -ForegroundColor Cyan
}

function Mostrar-Ayuda {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Yellow
    Write-Host "          GUÍA DE COMANDOS DEL GESTOR DOCKER" -ForegroundColor White
    Write-Host "==============================================" -ForegroundColor Yellow
    
    Write-Host "1. Listar Activos: " -NoNewline -ForegroundColor Cyan
    Write-Host "Muestra nombres, estado y puertos de los contenedores activos."
    
    Write-Host "2. Vista Detallada: " -NoNewline -ForegroundColor Cyan
    Write-Host "Muestra TODOS los contenedores (incluidos los apagados)."
    
    Write-Host "3. Instalar: " -NoNewline -ForegroundColor Cyan
    Write-Host "Crea un nuevo contenedor vinculando puertos de tu PC con el contenedor."
    Write-Host "          Formato: [Puerto PC]:[Puerto Interno del Software]"

    Write-Host "4. Reiniciar: " -NoNewline -ForegroundColor Cyan
    Write-Host "Refresca un contenedor. Útil si el software se queda colgado."
    
    Write-Host "5. Eliminar: " -NoNewline -ForegroundColor Cyan
    Write-Host "Borra el contenedor del sistema (pide confirmación de seguridad)."
    
    Write-Host "6. Recursos: " -NoNewline -ForegroundColor Cyan
    Write-Host "Abre una ventana con CPU/RAM en vivo. Ciérrala con 'Ctrl+C' o la 'X'."
    
    Write-Host "7. Logs: " -NoNewline -ForegroundColor Cyan
    Write-Host "Muestra la 'consola interna' del contenedor para ver errores."
    
    Write-Host "8. Ayuda: " -NoNewline -ForegroundColor Cyan
    Write-Host "Muestra este panel de instrucciones."
    
    Write-Host "9. Salir: " -NoNewline -ForegroundColor Cyan
    Write-Host "Cierra el gestor y limpia la pantalla."
    
    Write-Host "==============================================" -ForegroundColor Yellow
    Write-Host "TIP: Puedes tener el Monitor (6) y los Logs (7) abiertos al mismo" -ForegroundColor Gray
    Write-Host "tiempo en ventanas separadas mientras usas el menú principal." -ForegroundColor Gray
    Write-Host "==============================================" -ForegroundColor Yellow
    Pause
}


do {
    Mostrar-Menu
    $opcion = Read-Host "Seleccione una opción [1-9]"

    switch ($opcion) {
        "1" {
            Write-Host "`n--- Activos ---" -ForegroundColor Green
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            Pause
        }
        "2" {
            Write-Host "`n--- Todos ---" -ForegroundColor Cyan
            docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
            Pause
        }
        "3" {
            $img = Read-Host "Imagen (ej: nginx)"
            $nom = Read-Host "Nombre contenedor"
            $p_l = Read-Host "Puerto PC"
            $p_c = Read-Host "Puerto Contenedor"
            docker run -d -p ${p_l}:${p_c} --name $nom $img
            Pause
        }
        "4" {
            Write-Host "`n--- REINICIAR CONTENEDOR ---" -ForegroundColor Yellow
            Write-Host "Contenedores disponibles:" -ForegroundColor Gray
            docker ps -a --format "  > {{.Names}} ({{.Status}})"
            
            $nom = Read-Host "`nNombre del contenedor a reiniciar"
            $existe = docker ps -a --filter "name=$nom" --format "{{.Names}}"
            
            if ($existe -eq $nom) {
                Write-Host "Reiniciando..." -ForegroundColor Cyan
                docker restart $nom
                Write-Host "Contenedor '$nom' reiniciado." -ForegroundColor Green
            } else {
                Write-Host "[ERROR] El contenedor '$nom' no existe." -ForegroundColor Red
            }
            Pause
        }
        "5" {
            Write-Host "`n--- ELIMINAR CONTENEDOR ---" -ForegroundColor Red
            Write-Host "Contenedores actuales:" -ForegroundColor Gray
            docker ps -a --format "  > {{.Names}}"
            
            $nom = Read-Host "`nNombre del contenedor a ELIMINAR"
            $existe = docker ps -a --filter "name=$nom" --format "{{.Names}}"
            
            if ($existe -eq $nom) {
                $confirmacion = Read-Host "¿Estás SEGURO de eliminar '$nom'? (S/N)"
                if ($confirmacion -eq "s" -or $confirmacion -eq "S") {
                    docker rm -f $nom
                    Write-Host "Contenedor '$nom' eliminado correctamente." -ForegroundColor Green
                } else {
                    Write-Host "Operación cancelada." -ForegroundColor Yellow
                }
            } else {
                Write-Host "[ERROR] El contenedor '$nom' no existe." -ForegroundColor Red
            }
            Pause
        }
        "6" {
            $titulo = "Monitor_Docker"
            # Lanzamos la ventana
            cmd /c "start `"$titulo`" powershell -Command `"docker stats`""
            
            Write-Host "`n[OK] Monitor de recursos abierto en ventana independiente." -ForegroundColor Green
            Write-Host "Puedes mantener esa ventana abierta mientras sigues usando este menú." -ForegroundColor Gray
            
            # Agregamos el Pause para que el mensaje no desaparezca
            Pause 
        }
        "7" {
            Write-Host "`n--- VISOR DE LOGS ---" -ForegroundColor Magenta
            Write-Host "Ver logs de:" -ForegroundColor Gray
            docker ps -a --format "  > {{.Names}}"
            
            $nom = Read-Host "`nNombre del contenedor"
            $existe = docker ps -a --filter "name=$nom" --format "{{.Names}}"
            
            if ($existe -eq $nom) {
                $tituloLog = "Logs_$nom"
                cmd /c "start `"$tituloLog`" powershell -Command `"docker logs -f --tail 100 $nom`""
                Write-Host "[OK] Ventana de logs abierta para '$nom'." -ForegroundColor Green
            } else {
                Write-Host "[ERROR] El contenedor '$nom' no existe." -ForegroundColor Red
            }
            Pause
        }
        "8" {
            Mostrar-Ayuda
        }
        "9" {
            Write-Host "`nSaliendo del Gestor Docker..." -ForegroundColor Green
            break
        }
        Default {
            Write-Host "`n>>> OPCIÓN INVÁLIDA ($opcion). Por favor, elija entre 1 y 9." -ForegroundColor Red
            Pause
        }
    }
} while ($opcion -ne "9")