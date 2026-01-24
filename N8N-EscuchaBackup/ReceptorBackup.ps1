$port = 5004
$destPath = "E:\N8N-Workflows-Backup"
if (!(Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath }

$server = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
$server.Start()

Write-Host "🚀 RECEPTOR ACTIVO en puerto $port" -ForegroundColor Green
Write-Host "Presiona 'Q' para detener el servidor de forma segura." -ForegroundColor Gray

while ($true) {
    # Verificar si se presionó 'Q'
    if ([System.Console]::KeyAvailable) {
        $key = [System.Console]::ReadKey($true)
        if ($key.Key -eq 'Q') { break }
    }

    # Esperar conexión sin bloquear el hilo por completo
    if (!$server.Pending()) {
        Start-Sleep -Milliseconds 100
        continue
    }

    $client = $server.AcceptTcpClient()
    $stream = $client.GetStream()
    
    # Respuesta rápida a n8n
    $response = "HTTP/1.1 200 OK`r`nContent-Length: 0`r`nConnection: close`r`n`r`n"
    $responseBytes = [System.Text.Encoding]::ASCII.GetBytes($response)
    $stream.Write($responseBytes, 0, $responseBytes.Length)

    # Guardar archivo
    $filename = "backup_$(Get-Date -Format 'HHmmss').json"
    $fullPath = Join-Path $destPath $filename
    
    try {
        $fileStream = [System.IO.File]::Create($fullPath)
        $stream.CopyTo($fileStream)
        $fileStream.Close()
        Write-Host "✅ Recibido: $filename" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
    }
    $client.Close()
}

$server.Stop()
Write-Host "🛑 Servidor detenido correctamente." -ForegroundColor Red