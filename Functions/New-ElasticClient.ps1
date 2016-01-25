function New-ElasticClient {
    [CmdletBinding(DefaultParameterSetName = 'Settings')]
    Param (
        [Parameter(ParameterSetName = 'Node', Position = 0)]
        [String]$DefaultIndex,
        
        [Parameter(ParameterSetName = 'Node', Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Uri]$Node = 'http://localhost:9200',

        [Parameter(ParameterSetName = 'Settings', Position = 0)]
        [Nest.ConnectionSettings]$Settings
    )

    if ($PSCmdlet.ParameterSetName -eq 'Node') { 
        try { $Settings = [Nest.ConnectionSettings]::new($Node, $DefaultIndex) }
        catch { throw $_ }
    }
    
    try { $Client = [Nest.ElasticClient]::new($Settings) }
    catch { throw $_ }

    Write-Output $Client
}