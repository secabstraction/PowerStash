function New-DeleteByQueryRequest {
    [CmdletBinding(DefaultParameterSetName = 'None')]
    Param (
        [Parameter(ParameterSetName = 'One', Mandatory = $true)]
        [String]$Index,

        [Parameter(ParameterSetName = 'One')]
        [ValidateNotNullOrEmpty()]
        [String]$Type,

        [Parameter(ParameterSetName = 'List', Mandatory = $true)]
        [Collections.Generic.List[Nest.IndexNameMarker]]$IndexList,

        [Parameter(ParameterSetName = 'List')]
        [Collections.Generic.List[Nest.TypeNameMarker]]$TypeList,

        [Parameter(Mandatory = $true)]
        [Type]$ObjectType
    )

    $DeleteByQueryRequest = switch ($PSCmdlet.ParameterSetName) {
         'None' { New-Object Nest.DeleteByQueryRequest[$ObjectType] }
         'One'  { New-Object Nest.DeleteByQueryRequest[$ObjectType] -ArgumentList @($Index, $Type) }
         'List' { New-Object Nest.DeleteByQueryRequest[$ObjectType] -ArgumentList @($IndexList, $TypeList) }
    }
    
    Write-Output $DeleteByQueryRequest
}
