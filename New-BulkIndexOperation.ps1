function New-BulkIndexOperation {
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Object]$InputObject,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Index,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Type,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Id
    )

    $ObjectType = $InputObject.GetType()
    
    $BulkIndexOperation = New-Object Nest.BulkIndexOperation[$ObjectType] -ArgumentList $InputObject 
    
    if ($PSBoundParameters.Index) { $BulkIndexOperation.Index = $Index }
    if ($PSBoundParameters.Type) { $BulkIndexOperation.Type = $Type }
    if ($PSBoundParameters.Id) { $BulkIndexOperation.Id = $Id }

    Write-Output $BulkIndexOperation
}