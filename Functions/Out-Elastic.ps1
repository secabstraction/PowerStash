function Out-Elastic {
    [CmdLetBinding()]
    Param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Server = 'localhost',
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Port = '9200',

        [Parameter(Mandatory = $true)]
        [String]$Index,

        [Parameter(Mandatory = $true)]
        [Object[]]$InputObject,

        [Parameter()]
        [Switch]$Bulk
    )
    
    try { $ElasticClient = [Nest.ElasticClient] }
    catch {
        $NestDll = (Resolve-Path .\Nest.dll -ErrorAction Stop).Path
        $JsonDll = (Resolve-Path .\Newtonsoft.Json.dll -ErrorAction Stop ).Path
        $ElasticDll = (Resolve-Path .\Elasticsearch.Net.dll -ErrorAction Stop).Path

        [void][Reflection.Assembly]::LoadFile($NestDll)
        [void][Reflection.Assembly]::LoadFile($JsonDll)
        [void][Reflection.Assembly]::LoadFile($ElasticDll)
    }

    $Uri = New-Object Uri "http://$($Server):$($Port)"
    $Settings = [Nest.ConnectionSettings]::new($Uri, $Index)
    $Client = [Nest.ElasticClient]::new($Settings)

    if (!$Client.CatHealth().IsValid) { throw 'bad config' }

    if ($Bulk.IsPresent) {
        $Descriptor = New-BulkIndexDescriptor -Objects $InputObject
        $Client.Bulk($Descriptor)
    }

    else {
        foreach ($Object in $InputObject) {     
            $IndexRequest = New-Object Nest.IndexRequest[$($ObjectType)] $Object 
            $Client.Index($IndexRequest) 
        }
    }
}