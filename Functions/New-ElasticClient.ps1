function New-ElasticClient {
    [CmdletBinding(DefaultParameterSetName = 'Node')]
    Param (
        [Parameter(ParameterSetName = 'Node', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Node = 'http://localhost:9200',

        [Parameter(ParameterSetName = 'Config', Position = 0, Mandatory = $true)]
        [Elasticsearch.Net.Connection.ConnectionConfiguration]
        $Configuration,
        
        [Parameter(ParameterSetName = 'Pool', Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri[]]
        $Pool,
        
        [Parameter(ParameterSetName = 'Pool')]
        [Switch]
        $Sniffing,
        
        [Parameter(ParameterSetName = 'Pool')]
        [Switch]
        $Static,
        
        [Parameter(ParameterSetName = 'Pool')]
        [Switch]
        $Randomize,
        
        [Parameter(ParameterSetName = 'Pool')]
        [Elasticsearch.Net.Providers.IDateTimeProvider]
        $DateTimeProvider
    )

    $Confirguration = switch ($PSCmdlet.ParameterSetName) { 
        'Node' {
            try { New-Object Elasticsearch.Net.Connection.ConnectionConfiguration -ArgumentList @($Node) }
            catch { throw $_ }
        }
        'Pool' {
            if ($Sniffing.IsPresent) {
                try { 
                    $ConnectionPool = New-Object Elasticsearch.Net.ConnectionPool.SniffingConnectionPool -ArgumentList @($Pool, $Randomize.IsPresent, $DateTimeProvider) 
                    New-Object Elasticsearch.Net.Connection.ConnectionConfiguration -ArgumentList @($ConnectionPool)
                }
                catch { throw $_ }
            }
            elseif ($Static.IsPresent) {
                try { 
                    $ConnectionPool = New-Object Elasticsearch.Net.ConnectionPool.StaticConnectionPool -ArgumentList @($Pool, $Randomize.IsPresent, $DateTimeProvider) 
                    New-Object Elasticsearch.Net.Connection.ConnectionConfiguration -ArgumentList @($ConnectionPool)
                }
                catch { throw $_ } 
            }
            else {
                try { 
                    $ConnectionPool = New-Object Elasticsearch.Net.ConnectionPool.SingleNodeConnectionPool -ArgumentList @($Pool) 
                    New-Object Elasticsearch.Net.Connection.ConnectionConfiguration -ArgumentList @($ConnectionPool)
                }
                catch { throw $_ } 
            }
        }
        default { continue }
    }
    
    try { $Client = New-Object Elasticsearch.Net.ElasticsearchClient -ArgumentList @($Confirguration) }
    catch { throw $_ }

    Write-Output $Client
}
