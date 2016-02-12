function Export-Elastic {
    [CmdletBinding(DefaultParameterSetName = 'Client')]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Object[]]
        $InputObject,
        
        [Parameter(ParameterSetName = 'Node', Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Node = 'http://localhost:9200',
        
        [Parameter(ParameterSetName = 'Configuration', Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Elasticsearch.Net.Connection.ConnectionConfiguration]
        $Configuration,
        
        [Parameter(ParameterSetName = 'Client', Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Elasticsearch.Net.ElasticsearchClient]
        $Client,

        [Parameter(Position = 2)]
        [String]
        $Index,

        [Parameter(Position = 3)]
        [String]
        $Type,

        [Parameter()]
        [Int32]
        $Size = 200
    )
    
    begin { 
        $Client = switch ($PSCmdlet.ParameterSetName) { 
            'Node'          { New-ElasticClient -Node $Node }
            'Configuration' { New-ElasticClient -Configuration $Configuration }
            default         { $Client }
        }
        
        $Tasks = New-Object 'Collections.Generic.List[Threading.Tasks.Task]'
    }
    
    process {
        if ($InputObject.Count -gt $RequestSize) { 
            
            $Collections = Split-Collection -Collection $InputObject -NewSize $Size 
            
            foreach ($Collection in $Collections) { 
                $BulkRequest = $Collection | New-BulkIndexRequest -Index $Index -Type $Type
                $Tasks.Add($Client.BulkAsync($BulkRequest)) 
            } 
        }

        else { 
            $BulkRequest = $InputObject | New-BulkIndexRequest -Index $Index -Type $Type 
            $Tasks.Add($Client.BulkAsync($BulkRequest)) 
        }
    }

    end {
        [Threading.Tasks.Task]::WaitAll($Tasks)
        foreach ($Task in $Tasks) { Write-Output $Task.Result }
        [GC]::Collect()
    }
}
