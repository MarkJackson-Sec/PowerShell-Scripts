<#
.SYNOPSIS
    A PowerShell script to scan a given IP range for webpages running on ports 80 and 443.

.DESCRIPTION
    This script scans a specified IP range for hosts with open ports 80 and 443, indicating a running web service.
    It supports a verbose mode for detailed scanning information.

.PARAMETER IpRange
    The IP range to scan, in CIDR notation (e.g., 192.168.0.1/24).

.PARAMETER Verbose
    If set, the script will run in verbose mode, providing detailed output during the scan process.

.EXAMPLE
    .\webscan.ps1 -IpRange 192.168.0.1/24 -Verbose
    Scans the IP range 192.168.0.1 through 192.168.0.254 with detailed output.

.EXAMPLE
    .\webscan.ps1 -IpRange 192.168.0.1/24
    Scans the IP range 192.168.0.1 through 192.168.0.254 with minimal output.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$IpRange,
    
    [switch]$Verbose
)

function Test-Port {
    param(
        [string]$ip,
        [int]$port
    )
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient($ip, $port)
        $tcp.Close()
        return $true
    } catch {
        return $false
    }
}

function Scan-Range {
    param(
        [string]$range,
        [switch]$verbose
    )
    $ips = $range -split '/'
    $baseIp = $ips[0]
    $subnet = [math]::Pow(2, (32 - $ips[1]))
    $baseIpNum = [BitConverter]::ToUInt32([System.Net.IPAddress]::Parse($baseIp).GetAddressBytes()[::-1], 0)
    $endIpNum = $baseIpNum + $subnet - 1

    $results = @()

    Write-Host "Scan Started."

    for ($i = $baseIpNum; $i -le $endIpNum; $i++) {
        $ip = [System.Net.IPAddress]::new($i -band 0xFFFFFFFF).GetAddressBytes()[::-1] -join '.'
        if ($verbose) {
            Write-Host "Scanning $ip..."
        }
        if (Test-Port -ip $ip -port 80 -or Test-Port -ip $ip -port 443) {
            $results += $ip
            if ($verbose) {
                Write-Host "$ip has an open port."
            }
        }
    }

    Write-Host "Scan Complete."
    Write-Host "The following Addresses are hosting something on Port 80 or 443:"
    $results | ForEach-Object { Write-Host $_ }
}

Scan-Range -range $IpRange -verbose:$Verbose
