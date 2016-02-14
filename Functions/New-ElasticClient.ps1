function New-ElasticClient {
<#
.SYNOPSIS

    Constructs a client for interacting with elastic.
    
    License: BSD 3-Clause
    Author: Jesse Davis (@secabstraction)
    Required Dependencies: Elasticsearch.Net
    
.PARAMETER Node

    Specifies the uri of an elastic instance for the client to interact with.

.PARAMETER Configuration

    Specifies an existing Elasticsearch.Net Connection Configuration.

.PARAMETER Pool

    Specifies one or more elastic uris for the client to interact with. 

.PARAMETER Randomize

    Specifies that connections to the pool be randomized on startup.

.EXAMPLE

    $Client = New-ElasticClient

    Creates a client configured to interact with a single node at http://localhost:9200

.EXAMPLE

    $Client = New-ElasticClient -Node http://test:9200

    Creates a client configured to interact with a single node at http://test:9200
    
.EXAMPLE

    $Client = New-ElasticClient -Configuration $ConnectionConfiguration

    Creates a client from an existing Elasticsearch.Net connection configuration.
    This option should be used for more granular control of the client's confiuration.
    
.EXAMPLE

    $Client = New-ElasticClient -Pool @('http://test1:9200','http://test2:9200','http://test3:9200') -Randomize
    
    Creates a client configured to connect to a sniffing-connection-pool of elastic instances, in a randomized fashion.

.LINK

    http://www.patch-tuesday.net/
#>
    [CmdletBinding(DefaultParameterSetName = 'Node')]
    param (
        [Parameter(ParameterSetName = 'Node', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Node = 'http://localhost:9200',

        [Parameter(ParameterSetName = 'Config', Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Elasticsearch.Net.Connection.ConnectionConfiguration]
        $Configuration,
        
        [Parameter(ParameterSetName = 'Pool', Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri[]]
        $Pool,
        
        [Parameter(ParameterSetName = 'Pool')]
        [Switch]
        $Randomize
    )

    $Confirguration = switch ($PSCmdlet.ParameterSetName) { 
        'Node' {
            try { [Elasticsearch.Net.Connection.ConnectionConfiguration]::new($Node) }
            catch { throw $_ }
        }
        'Pool' {
            try { 
                $ConnectionPool = [Elasticsearch.Net.ConnectionPool.SniffingConnectionPool]::new($Pool, $Randomize.IsPresent, $null) 
                [Elasticsearch.Net.Connection.ConnectionConfiguration]::new($ConnectionPool)
            }
            catch { throw $_ }
        }
        default { $Configuration }
    }
    
    try { [Elasticsearch.Net.ElasticsearchClient]::new($Confirguration) }
    catch { throw $_ }
}