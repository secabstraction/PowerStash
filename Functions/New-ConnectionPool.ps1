function New-ConnectionPool {
<#
.SYNOPSIS

    Constructs a ConnectionPool for configuring an elastic client.
    
    License: BSD 3-Clause
    Author: Jesse Davis (@secabstraction)
    Required Dependencies: Elasticsearch.Net
    
.PARAMETER SingleNode

    Specifies a single elastic uri for the client to interact with.

.PARAMETER SniffingPool

    Specifies one or more elastic uris that make up a sniffing connection pool.

.PARAMETER StaticPool

    Specifies one or more elastic uris that make up a static connection pool. 

.PARAMETER Randomize

    Specifies that connections to a sniffing or static pool be randomized on startup.

.PARAMETER DateTimeProvider

    Specifies an Elasticsearch.Net IDateTimeProvider to sniffing or static pools.

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
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param (
        [Parameter(ParameterSetName = 'Single', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $SingleNode = 'http://localhost:9200',

        [Parameter(ParameterSetName = 'Sniffing', Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri[]]
        $SniffingPool,
        
        [Parameter(ParameterSetName = 'Static', Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri[]]
        $StaticPool,
        
        [Parameter(ParameterSetName = 'Sniffing')]
        [Parameter(ParameterSetName = 'Static')]
        [Switch]
        $Randomize,
        
        [Parameter(ParameterSetName = 'Sniffing')]
        [Parameter(ParameterSetName = 'Static')]
        [ValidateNotNullOrEmpty()]
        [Elasticsearch.Net.Providers.IDateTimeProvider]
        $DateTimeProvider
    )

    switch ($PSCmdlet.ParameterSetName) { 
        'Single' {
            try { [Elasticsearch.Net.ConnectionPool.SingleNodeConnectionPool]::new($SingleNode) }
            catch { throw $_ }
        }
        'Sniffing' {
            try { [Elasticsearch.Net.ConnectionPool.SniffingConnectionPool]::new($SniffingPool, $Randomize.IsPresent, $DateTimeProvider) }
            catch { throw $_ }
        }
        'Static' {
            try { [Elasticsearch.Net.ConnectionPool.StaticConnectionPool]::new($StaticPool, $Randomize.IsPresent, $DateTimeProvider) }
            catch { throw $_ }
        }
    }
}