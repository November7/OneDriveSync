
function Sync-Paths {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ExternalPath,

        [Parameter(Mandatory = $true)]
        [string]$InternalPath,

        [ValidateSet("Both", "ExternalToInternal", "InternalToExternal")]
        [string]$Direction = "Both",

        [switch]$SafeMode = $true
    )

    function Check-IsOnlineOnly {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath
        )

        try {
            $file = Get-Item -LiteralPath $FilePath -ErrorAction Stop
            return ($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
        } catch {
            Write-Warning "Cannot check file attribute for: '$FilePath': $_"
            return $false
        }
    }

    function Set-OnlineOnly {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath
        )

    
        try {
            Start-Process -FilePath "attrib.exe" -ArgumentList "+U -P `"$FilePath`"" -NoNewWindow -Wait
            Write-Host "Set 'online only' to file: $FilePath" -ForegroundColor Cyan
        } catch {
            Write-Warning "Failed to set the 'online only' attribute for '$FilePath': $_"
        }        
    }    

    function Sync-OneWay {
        param (
            [string]$SourcePath,
            [string]$TargetPath,
            [bool]$Safe
        )

        $files = Get-ChildItem -Path $SourcePath -Recurse -File -Force
        $total = $files.Count
        $index = 0

        foreach ($file in $files) {
            $index++
            $percent = [int](($index / $total) * 100)
            $relativePath = $file.FullName.Substring($SourcePath.Length).TrimStart('\')
            $targetFilePath = Join-Path $TargetPath $relativePath

            Write-Progress -Activity "Synchronizing from '$SourcePath'" -Status "Processing: $relativePath" -PercentComplete $percent -Id 1

            $shouldCopy = $true

            if (Test-Path $targetFilePath) {
                if ($Safe) {
                    $shouldCopy = $false 
                } else {
                    try {
                        $sourceHash = Get-FileHash -Path $file.FullName -Algorithm SHA256
                        $targetHash = Get-FileHash -Path $targetFilePath -Algorithm SHA256

                        if ($sourceHash.Hash -ne $targetHash.Hash) {
                            Write-Warning "Conflict: '$relativePath' has different content. Skipping."
                            $shouldCopy = $false
                        } else {
                            $shouldCopy = $false
                        }
                    } catch {
                        Write-Warning "Hashing failed for '$relativePath'. Skipping."
                        $shouldCopy = $false
                    }
                }
            }

            if ($shouldCopy) {
                $destinationFolder = Split-Path $targetFilePath
                if (-not (Test-Path $destinationFolder)) {
                    New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
                }

                try {
                    Copy-Item -Path $file.FullName -Destination $targetFilePath -Force
                    Write-Host "Copied: $relativePath" -ForegroundColor Green

                    if ($Safe -and (Check-IsOnlineOnly -FilePath $file.FullName)) {
                        Set-OnlineOnly -FilePath $file.FullName
                    }
                    Set-OnlineOnly -FilePath $targetFilePath


                } catch {
                    Write-Warning "Failed to copy '$relativePath'"
                }
            }
        }

        Write-Progress -Activity "Synchronizing from '$SourcePath'" -Completed -Id 1
    }

    if (-not (Test-Path $ExternalPath)) {
        Write-Error "External path '$ExternalPath' does not exist."
        return
    }

    if (-not (Test-Path $InternalPath)) {
        Write-Error "Internal path '$InternalPath' does not exist."
        return
    }

    switch ($Direction) {
        "ExternalToInternal" {
            Sync-OneWay -SourcePath $ExternalPath -TargetPath $InternalPath -Safe:$SafeMode.IsPresent
        }
        "InternalToExternal" {
            Sync-OneWay -SourcePath $InternalPath -TargetPath $ExternalPath -Safe:$SafeMode.IsPresent
        }
        "Both" {
            Sync-OneWay -SourcePath $ExternalPath -TargetPath $InternalPath -Safe:$SafeMode.IsPresent
            Sync-OneWay -SourcePath $InternalPath -TargetPath $ExternalPath -Safe:$SafeMode.IsPresent
        }
    }

    Write-Host "Synchronization complete (Direction: $Direction, SafeMode: $($SafeMode.IsPresent))." -ForegroundColor Cyan
}