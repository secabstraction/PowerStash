function New-DeleteRequest {
    [CmdletBinding(DefaultParameterSetName = 'None')]
    Param (
        [Parameter(ParameterSetName = 'None')]
        [ValidateNotNullOrEmpty()]
        [String]$Index,

        [Parameter(ParameterSetName = 'None')]
        [ValidateNotNullOrEmpty()]
        [String]$Type,

        [Parameter(ParameterSetName = 'None')]
        [Parameter(ParameterSetName = 'Object')]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [Parameter(ParameterSetName = 'Object', ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object]$InputObject
    )

    if ($PSCmdlet.ParameterSetName -eq 'Object') {
        $ObjectType = $InputObject.GetType()
        $DeleteRequest = New-Object Nest.DeleteRequest[$ObjectType] -ArgumentList @($Id)
    }
    else { $DeleteRequest = [Nest.DeleteRequest]::new($Index, $Type, $Id) }

    Write-Output $DeleteRequest
}
