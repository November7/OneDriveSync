<####################################################################################################

                                    Loading functions

#####################################################################################################>

$functions  = @( Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue )

Foreach($import in @($functions))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function Compare-Paths, Sync-Paths