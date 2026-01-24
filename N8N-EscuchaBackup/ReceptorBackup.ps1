$port = 5004
$destPath = "E:\N8N-Workflows-Backup"
if (!(Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath }

$server = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
$server.Start()

Write-Host "🚀 RECEPTOR BACKUP ACTIVO (Presiona 'Q' para salir)" -ForegroundColor Green

while ($true) {
    if ([System.Console]::KeyAvailable -and [System.Console]::ReadKey($true).Key -eq 'Q') { break }
    if (!$server.Pending()) { Start-Sleep -Milliseconds 50; continue }

    $client = $server.AcceptTcpClient()
    $stream = $client.GetStream() 
    
    try {
        # --- PASO 1: RESPONDER INMEDIATAMENTE A N8N ---
        $msg = '{"status":"ok"}'
        $response = "HTTP/1.1 200 OK`r`nContent-Type: application/json`r`nContent-Length: $($msg.Length)`r`nConnection: close`r`n`r`n$msg"
        $responseBytes = [System.Text.Encoding]::ASCII.GetBytes($response)
        $stream.Write($responseBytes, 0, $responseBytes.Length)

        # --- PASO 2: LEER LOS DATOS ---
        $memoryStream = New-Object System.IO.MemoryStream
        $stream.CopyTo($memoryStream)
        $text = [System.Text.Encoding]::UTF8.GetString($memoryStream.ToArray())

        if ($text.Length -gt 0) {
            # Extraer nombre del archivo de los Headers
            $filename = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            if ($text -match "(?i)file-name:\s*(.+)") {
                $filename = $matches[1].Split("`r`n")[0].Trim()
                # Limpieza total de caracteres prohibidos en Windows
                $filename = $filename -replace '[\\\/\:\*\?\"<>\|]', '_'
            }

            # Extraer solo el contenido JSON
            $firstBrace = $text.IndexOf('{')
            $lastBrace = $text.LastIndexOf('}')
            
            if ($firstBrace -ge 0 -and $lastBrace -gt $firstBrace) {
                $cleanJson = $text.Substring($firstBrace, ($lastBrace - $firstBrace + 1))
                
                try {
                    # Intentar formatear el JSON para que sea legible
                    $jsonObj = $cleanJson | ConvertFrom-Json
                    $jsonPretty = $jsonObj | ConvertTo-Json -Depth 100
                    
                    $fullPath = Join-Path $destPath $filename
                    
                    # GUARDADO SEGURO: Reintenta si el archivo está bloqueado
                    $maxRetries = 3
                    $retryCount = 0
                    $saved = $false
                    while (!$saved -and $retryCount -lt $maxRetries) {
                        try {
                            $jsonPretty | Out-File -FilePath $fullPath -Encoding utf8 -Force
                            $saved = $true
                        } catch {
                            $retryCount++
                            Start-Sleep -Milliseconds 200
                        }
                    }
                    
                    Write-Host "✅ Guardado [$($jsonPretty.Length) bytes]: $filename" -ForegroundColor Cyan
                } catch {
                    # Si el JSON es demasiado pesado para ConvertFrom-Json, guardarlo en crudo
                    $fullPath = Join-Path $destPath "RAW_$filename"
                    $cleanJson | Out-File -FilePath $fullPath -Encoding utf8 -Force
                    Write-Host "⚠️ Guardado en crudo (JSON complejo): $filename" -ForegroundColor Yellow
                }
            }
        }
    } catch {
        Write-Host "❌ Error procesando petición: $_" -ForegroundColor Red
    } finally {
        $client.Close()
    }
}
$server.Stop()