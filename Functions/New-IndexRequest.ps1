function New-IndexRequest {
    Param (
        [Parameter(ValueFromPipeline = $true)]
        [Object]$InputObject,

        [Parameter()]
        [String]$Index,

        [Parameter()]
        [String]$Type,

        [Parameter()]
        [String]$Id
    )
    
    $ObjectType = $InputObject.GetType()
    $IndexRequest = New-Object Nest.IndexRequest[$ObjectType] -ArgumentList @($InputObject)

    if ($PSBoundParameters.Index) { $IndexRequest.Index = $Index }
    if ($PSBoundParameters.Type) { $IndexRequest.Type = $Type }
    if ($PSBoundParameters.Id) { $IndexRequest.Id = $Id }

    Write-Output $IndexRequest
}