function New-ConnectionConfiguration {
<#
.SYNOPSIS

    Constructs a configuration object for granular control of an elastic client.
    
    License: BSD 3-Clause
    Author: Jesse Davis (@secabstraction)
    Required Dependencies: Elasticsearch.Net
    
.PARAMETER Node

    Specifies the uri of an elastic instance.

.PARAMETER Pool

    Specifies an Elasticsearch.Net ConnectionPool object. 

.EXAMPLE

    $Config = New-ConnectionConfiguration -Node http://test.net:9200
    $Config.SetBasicAuthentication('username','password')
    
    $Client = New-ElasticClient -Configuration $Config

    Creates a connection configuration object and sets the authentication credentials.
    Then the configuration is used to construct an elastic client.

.EXAMPLE

    $Config = New-ConnectionConfiguration -Node http://test.net:9200
    $Config.SetProxy('http://myproxy:8080','username','password')
    
    $Client = New-ElasticClient -Configuration $Config

    Creates a connection configuration object and sets the configuration for a web proxy.
    Then the configuration is used to construct an elastic client.
    
.LINK

    http://www.patch-tuesday.net/
#>
    [CmdletBinding(DefaultParameterSetName = 'Node')]
    param (
        [Parameter(ParameterSetName = 'Node', Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Node = 'http://localhost:9200',

        [Parameter(ParameterSetName = 'Pool', Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Elasticsearch.Net.ConnectionPool.IConnectionPool]
        $Pool
    )

    switch ($PSCmdlet.ParameterSetName) { 
        'Node' {
            try { [Elasticsearch.Net.Connection.ConnectionConfiguration]::new($Node) }
            catch { throw $_ }
        }
        'Pool' {
            try { [Elasticsearch.Net.Connection.ConnectionConfiguration]::new($Pool) }
            catch { throw $_ }
        }
    }
}