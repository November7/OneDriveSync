function Compare-Paths {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ExternalPath,

        [Parameter(Mandatory = $true)]
        [string]$InternalPath,

        [ValidateSet("Classic", "Table")]
        [string]$ViewMode = "Classic"
    )

    if (-Not (Test-Path -Path $ExternalPath)) {
        Write-Error "External path '$ExternalPath' does not exist."
        return
    }

    if (-Not (Test-Path -Path $InternalPath)) {
        Write-Error "Local path '$InternalPath' does not exist."
        return
    }

    $externalItems = Get-ChildItem -Path $ExternalPath -Recurse -Force | Where-Object { -not $_.PSIsContainer }
    $internalItems = Get-ChildItem -Path $InternalPath -Recurse -Force | Where-Object { -not $_.PSIsContainer }

    # Create hashtables with relative paths as keys
    $externalMap = @{}
    foreach ($item in $externalItems) {
        $relative = $item.FullName.Substring($ExternalPath.Length).TrimStart('\')
        $externalMap[$relative] = $item.FullName
    }

    $internalMap = @{}
    foreach ($item in $internalItems) {
        $relative = $item.FullName.Substring($InternalPath.Length).TrimStart('\')
        $internalMap[$relative] = $item.FullName
    }

    $allKeys = $externalMap.Keys + $internalMap.Keys | Sort-Object -Unique

    if ($ViewMode -eq "Classic") {
        foreach ($key in $allKeys) {
            $inExternal = $externalMap.ContainsKey($key)
            $inInternal = $internalMap.ContainsKey($key)

            if ($inExternal -and $inInternal) {
                Write-Host "Both: $key" -ForegroundColor Green
            } elseif ($inExternal) {
                Write-Host "External only: $key" -ForegroundColor Yellow
            } elseif ($inInternal) {
                Write-Host "Internal only: $key" -ForegroundColor Cyan
            }
        }
    }
    elseif ($ViewMode -eq "Table") {
        $table = @()

        foreach ($key in $allKeys) {
            $externalPath = $externalMap[$key]
            $internalPath = $internalMap[$key]

            $shortExternal = if ($externalPath -and $externalPath.Length -gt 60) {
                "..." + $externalPath.Substring($externalPath.Length - 57)
            } else {
                $externalPath
            }

            $shortInternal = if ($internalPath -and $internalPath.Length -gt 60) {
                "..." + $internalPath.Substring($internalPath.Length - 57)
            } else {
                $internalPath
            }

            $table += [PSCustomObject]@{
                External = $shortExternal
                Internal = $shortInternal
            }
        }

        $table | Format-Table -AutoSize
    }
}