$port = 5004
$destPath = "E:\N8N-Workflows-Backup"
if (!(Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath }

$server = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
$server.Start()

Write-Host "🚀 RECEPTOR BACKUP ACTIVO" -ForegroundColor Green

while ($true) {
    if ([System.Console]::KeyAvailable -and [System.Console]::ReadKey($true).Key -eq 'Q') { break }
    if (!$server.Pending()) { Start-Sleep -Milliseconds 100; continue }

    $client = $server.AcceptTcpClient()
    $stream = $client.GetStream() # Abrimos un hilo para no bloquear
    
    try {
        # --- PASO 1: RESPONDER INMEDIATAMENTE A N8N ---
        $msg = '{"status":"received"}'
        $response = "HTTP/1.1 200 OK`r`nContent-Type: application/json`r`nContent-Length: $($msg.Length)`r`nConnection: close`r`n`r`n$msg"
        $responseBytes = [System.Text.Encoding]::ASCII.GetBytes($response)
        $stream.Write($responseBytes, 0, $responseBytes.Length)
        $stream.Flush() # Forzamos el envío de la respuesta

        # --- PASO 2: LEER LOS DATOS DESPUÉS DE RESPONDER ---
        $memoryStream = New-Object System.IO.MemoryStream
        $stream.CopyTo($memoryStream)
        $bytes = $memoryStream.ToArray()
        $text = [System.Text.Encoding]::UTF8.GetString($bytes)

        if ($text.Length -gt 0) {
            # Buscar nombre en cabeceras
            $filename = "backup_$(Get-Date -Format 'HHmmss').json"
            if ($text -match "(?i)file-name:\s*(.+)") {
                $filename = $matches[1].Split("`r`n")[0].Trim()
                $filename = $filename -replace '[\\\/\:\*\?\"<>\|]', '_'
            }

            # Limpiar el JSON (quitar cabeceras HTTP)
            $firstBrace = $text.IndexOf('{')
            $lastBrace = $text.LastIndexOf('}')
            
            if ($firstBrace -ge 0 -and $lastBrace -gt $firstBrace) {
                $cleanJson = $text.Substring($firstBrace, ($lastBrace - $firstBrace + 1))
                # Convertimos el texto a objeto y luego otra vez a JSON con formato lindo
                $jsonPretty = $cleanJson | ConvertFrom-Json | ConvertTo-Json -Depth 100
                $fullPath = Join-Path $destPath $filename
                $jsonPretty | Out-File -FilePath $fullPath -Encoding utf8
                Write-Host "✅ Archivo guardado: $filename" -ForegroundColor Cyan
            }
        }
    } catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
    } finally {
        $client.Close()
    }
}
$server.Stop()