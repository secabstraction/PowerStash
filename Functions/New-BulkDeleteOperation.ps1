function New-BulkDeleteOperation {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Index,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Type
    )

    $Properties = @{
        delete = @{
            _index = $Index
            _type = $Type
            _id = $Id
        }
    }

    $Index = New-Object psobject -Property $Properties | ConvertTo-Json -Compress

    Write-Output ($Index + "`n")
}