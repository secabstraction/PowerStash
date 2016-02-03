function New-BulkCreateOperation {
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Object]$InputObject,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Index,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Type
    )

    if (!$PSBoundParameters.Id) { 
        if ($InputObject.Id) { $Id = $InputObject.Id }
        else { throw "No Id specified or found for object." }
    }

    $Properties = @{
        create = @{
            _index = $Index
            _type = $Type
            _id = $Id
        }
    }

    $Index = New-Object psobject -Property $Properties | ConvertTo-Json -Compress
    
    $Json = $InputObject | ConvertTo-Json -Compress

    Write-Output ($Index + "`n" + $Json + "`n")
}