#requires -version 5

function New-ConnectionPool {
<#
.SYNOPSIS

    Constructs an Elasticsearch.Net ConnectionPool for configuring an elastic client.
    
    License: BSD 3-Clause
    Author: Jesse Davis (@secabstraction)
    Required Dependencies: Elasticsearch.Net
    
.PARAMETER UriPool
    
    Specifies one or more uris to include in the connection pool.

.PARAMETER SingleNode

    Specifies that the pool be created from a single uri.

.PARAMETER Sniffing

    Specifies the pool as a sniffing connection pool.

.PARAMETER Static

    Specifies the pool as a static connection pool. 

.PARAMETER Randomize

    Specifies that connections to a sniffing or static pool be randomized on startup.

.PARAMETER DateTimeProvider

    Specifies an Elasticsearch.Net IDateTimeProvider for sniffing or static pools.

.EXAMPLE

    $Pool = New-ConnectionPool

    Creates a connection pool with a single node at http://localhost:9200.

.EXAMPLE

    $Pool = New-ConnectionPool -Sniffing

    Creates a sniffing connection pool with a node at http://localhost:9200.
    
.EXAMPLE

    $Pool = New-ConnectionPool -UriPool @('http://test1:9200','http://test2:9200','http://test3:9200') -Sniffing

    Creates a sniffing connection pool consisting of 3 nodes.

.LINK

    http://www.patch-tuesday.net/
#>
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Uri[]]
        $UriPool = 'http://localhost:9200',

        [Parameter(ParameterSetName = 'Single')]
        [Switch]
        $SingleNode,
        
        [Parameter(ParameterSetName = 'Sniffing')]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $Sniffing,

        [Parameter(ParameterSetName = 'Static')]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $Static,
        
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
            try { [Elasticsearch.Net.ConnectionPool.SingleNodeConnectionPool]::new($UriPool[0]) }
            catch { throw $_ }
        }
        'Sniffing' {
            try { [Elasticsearch.Net.ConnectionPool.SniffingConnectionPool]::new($UriPool, $Randomize.IsPresent, $DateTimeProvider) }
            catch { throw $_ }
        }
        'Static' {
            try { [Elasticsearch.Net.ConnectionPool.StaticConnectionPool]::new($UriPool, $Randomize.IsPresent, $DateTimeProvider) }
            catch { throw $_ }
        }
    }
}