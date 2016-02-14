function Export-Elastic {
<#
.SYNOPSIS

    Creates a JSON representation of an object or objects and indexes it into an elastic instance.
    
    License: BSD 3-Clause
    Author: Jesse Davis (@secabstraction)
    Required Dependencies: Elasticsearch.Net
    
.PARAMETER Node

    Specifies the uri of an elastic instance for the client to interact with.

.PARAMETER Configuration

    Specifies an existing Elasticsearch.Net connection configuration object.

.PARAMETER Client

    Specifies an existing Elasticsearch.Net client object.

.PARAMETER InputObject

    Specifies one or more objects.

.PARAMETER Index

    Specifies the elastic index the object(s) will be inserted into.

.PARAMETER Type

    Specifies the elastic type-name of the object(s).

.PARAMETER Size

    Specifies the maximum size of each bulk request sent to elastic. Adjust this to tweak efficiency. 

.EXAMPLE

    $MyObjects | Export-Elastic -Index myindex -Type mytype -Node http://localhost:9200

    Indexes objects stored in the $MyObjects collection.

    The objects in this example will be inserted into elastic at a default rate of 200 objects per request.
    
    e.g. http://localhost:9200/myindex/mytype/localhost-3232

.EXAMPLE

    Export-Elastic -InputObject $MyObjects -Type mytype -Size 50 -Node http://localhost:9200

    The objects in this example will be inserted into elastic at a rate of 50 objects per request.
    The elastic index will be inferred from each object's DateCreated property, as "powerstash-DateCreated".
    
    e.g. http://localhost:9200/powerstash-2016-02-02/mytype/localhost-3232
    
.EXAMPLE

    Export-Elastic -InputObject $MyObjects -Size 500 -Node http://localhost:9200

    The objects in this example will be inserted into elastic at a rate of 500 objects per request.
    The elastic index will be inferred from each object's DateCreated property, as "powerstash-DateCreated".
    The elastic type will be inferre from each object's primary typename. ($MyObject.PSObject.TypeName[0])
    
    e.g. http://localhost:9200/powerstash-2016-02-02/eventlogentry/localhost-3232

.LINK

    http://www.patch-tuesday.net/
#>
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

        [ValidateNotNullOrEmpty()]
        [String]
        $Index,
        
        [ValidateNotNullOrEmpty()]
        [String]
        $Type,
        
        [ValidateNotNullOrEmpty()]
        [Int32]
        $Size = 200
    )
    
    begin { 
        # Create an elastic client to send data
        $Client = switch ($PSCmdlet.ParameterSetName) { 
            'Node'          { New-ElasticClient -Node $Node }
            'Configuration' { New-ElasticClient -Configuration $Configuration }
            default         { $Client }
        }
        
        # Create a list we can add task objects to
        $Tasks = [Collections.Generic.List[Threading.Tasks.Task]]::new()
    }
    
    process {
        if ($InputObject.Count -gt $Size) { 
            
            # Split large collections for better processing
            $Collections = Split-Collection -Collection $InputObject -NewSize $Size 
            
            foreach ($Collection in $Collections) {
                
                # Create a bulk request from collection 
                $BulkRequest = New-BulkIndexRequest -InputObject $Collection -Index $Index -Type $Type
                
                # Index request & add async task to list
                $Tasks.Add($Client.BulkAsync($BulkRequest)) 
            } 
        }

        else { 
            $BulkRequest = New-BulkIndexRequest -InputObject $InputObject -Index $Index -Type $Type 
            $Tasks.Add($Client.BulkAsync($BulkRequest)) 
        }
    }

    end {
        # Wait for indexing operations to complete
        [Threading.Tasks.Task]::WaitAll($Tasks)

        # Return results of index operations
        foreach ($Task in $Tasks) { Write-Output $Task.Result }
        
        # Force garbage collection
        [GC]::Collect()
    }
}