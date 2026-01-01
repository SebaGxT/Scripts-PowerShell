Get-NetTCPConnection -State Listen | Select-Object `
    @{Name="Puerto Local"; Expression={$_.LocalPort}}, `
    @{Name="PID"; Expression={$_.OwningProcess}}, `
    @{Name="Proceso"; Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}}, `
    @{Name="Direccion IP"; Expression={$_.LocalAddress}} | `
    Sort-Object "Puerto Local" | Out-GridView -Title "Mapa de Puertos de Mi PC"

¿Qué hace este comando?
Get-NetTCPConnection -State Listen: Busca solo los puertos que están "esperando" conexiones (como tu Open WebUI o Portainer).

@{Name=...}: Esto crea los nombres de las columnas que tú querías (Puerto, PID, Nombre del Proceso).

Get-Process: Va y busca el nombre real del programa (ej: Docker Desktop, ollama, svchost) para que no tengas que adivinar por el PID.

Out-GridView: (Opcional) Esta es la joya de la corona. En lugar de sacarlo en la terminal, te abre una ventana flotante de Windows donde puedes filtrar y buscar puertos con el mouse.

vista de consola unicamente

Get-NetTCPConnection -State Listen | Select-Object `
    LocalPort, OwningProcess, `
    @{Name="ProcessName"; Expression={(Get-Process -Id $_.OwningProcess).Name}} | `
    Format-Table -AutoSize