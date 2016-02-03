function New-BulkRequest {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String[]]$InputObject
    )

    begin { $List = New-Object Collections.ArrayList }
    
    process { foreach ($Object in $InputObject) { [void]$List.Add($Object) } }

    end { Write-Output (-join $List.ToArray()) }
}