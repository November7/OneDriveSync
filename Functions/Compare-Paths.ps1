function Compare-Paths {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ExternalPath,

        [Parameter(Mandatory = $true)]
        [string]$InternalPath,

        [ValidateSet("ExternalOnly", "InternalOnly", "Full", "DifferencesOnly", "Space")]
        [string]$DisplayMode = "DifferencesOnly"
    )

    if (-Not (Test-Path -Path $ExternalPath)) {
        Write-Error "External path '$ExternalPath' does not exist."
        return
    }

    if (-Not (Test-Path -Path $InternalPath)) {
        Write-Error "Internal path '$InternalPath' does not exist."
        return
    }

    $externalItems = Get-ChildItem -Path $ExternalPath -Recurse -Force | Where-Object { -not $_.PSIsContainer }
    $internalItems = Get-ChildItem -Path $InternalPath -Recurse -Force | Where-Object { -not $_.PSIsContainer }

    $externalMap = @{}
    foreach ($item in $externalItems) {
        $relative = $item.FullName.Substring($ExternalPath.Length).TrimStart('\')
        $externalMap[$relative] = $item
    }

    $internalMap = @{}
    foreach ($item in $internalItems) {
        $relative = $item.FullName.Substring($InternalPath.Length).TrimStart('\')
        $internalMap[$relative] = $item
    }

    $allKeys = $externalMap.Keys + $internalMap.Keys | Sort-Object -Unique

    switch ($DisplayMode) {
        "ExternalOnly" {
            foreach ($key in $allKeys) {
                if ($externalMap.ContainsKey($key) -and -not $internalMap.ContainsKey($key)) {
                    [PSCustomObject]@{
                        External = $externalMap[$key].FullName
                        Internal = $null
                    }
                }
            }
        }
        "InternalOnly" {
            foreach ($key in $allKeys) {
                if ($internalMap.ContainsKey($key) -and -not $externalMap.ContainsKey($key)) {
                    [PSCustomObject]@{
                        External = $null
                        Internal = $internalMap[$key].FullName
                    }
                }
            }
        }
        "Full" {
            foreach ($key in $allKeys) {
                [PSCustomObject]@{
                    External = if ($externalMap.ContainsKey($key)) { $externalMap[$key].FullName } else { $null }
                    Internal = if ($internalMap.ContainsKey($key)) { $internalMap[$key].FullName } else { $null }
                }
            }
        }
        "DifferencesOnly" {
            foreach ($key in $allKeys) {
                $inExternal = $externalMap.ContainsKey($key)
                $inInternal = $internalMap.ContainsKey($key)

                if ($inExternal -xor $inInternal) {
                    [PSCustomObject]@{
                        External = if ($inExternal) { $externalMap[$key].FullName } else { $null }
                        Internal = if ($inInternal) { $internalMap[$key].FullName } else { $null }
                    }
                }
            }
        }
        "Space" {
            $externalTotal = ($externalItems | Measure-Object -Property Length -Sum).Sum
            $internalTotal = ($internalItems | Measure-Object -Property Length -Sum).Sum

            $externalOnlySize = ($allKeys | Where-Object { $externalMap.ContainsKey($_) -and -not $internalMap.ContainsKey($_) } |
                ForEach-Object { $externalMap[$_].Length }) | Measure-Object -Sum
            $internalOnlySize = ($allKeys | Where-Object { $internalMap.ContainsKey($_) -and -not $externalMap.ContainsKey($_) } |
                ForEach-Object { $internalMap[$_].Length }) | Measure-Object -Sum

            [PSCustomObject]@{
                ExternalTotal  = "{0:N2} GB" -f ($externalTotal / 1GB)
                InternalTotal  = "{0:N2} GB" -f ($internalTotal / 1GB)
                ExternalOnly   = "{0:N2} GB" -f ($externalOnlySize.Sum / 1GB)
                InternalOnly   = "{0:N2} GB" -f ($internalOnlySize.Sum / 1GB)
            }
        }
    }
}