Get-NetTCPConnection -State Listen | Select-Object `
    @{Name="Puerto Local"; Expression={$_.LocalPort}}, `
    @{Name="PID"; Expression={$_.OwningProcess}}, `
    @{Name="Proceso"; Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}}, `
    @{Name="Direccion IP"; Expression={$_.LocalAddress}} | `
    Sort-Object "Puerto Local" | Out-GridView -Title "Mapa de Puertos de Mi PC"