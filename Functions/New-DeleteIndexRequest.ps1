function New-DeleteIndexRequest {
    [CmdletBinding(DefaultParameterSetName = 'One')]
    Param (
        [Parameter(ParameterSetName = 'One', Mandatory = $true)]
        [String]$Index,

        [Parameter(ParameterSetName = 'List', Mandatory = $true)]
        [Collections.Generic.List[Nest.IndexNameMarker]]$IndexList
    )

    if ($PSCmdlet.ParameterSetName -eq 'List') { Write-Output ([Nest.DeleteIndexRequest]::new($IndexList)) }
    else { Write-Output ([Nest.DeleteIndexRequest]::new($Index)) }
}
