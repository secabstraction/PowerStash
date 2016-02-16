PowerStash
==========
######A PowerShell module for stashing all the things into [Elastic](https://www.elastic.co/).

Installation
------------
PowerStash is packaged as a PowerShell module.  You must import the module to use its functions.
###
```powershell
  # Import the functions via the psd1 file:
  Import-Module PowerStash.psd1
```
### Functions:
```powershell    
  New-ElasticClient             # Creates a client for interacting with Elastic.
  New-ConnectionPool            # Creates an Elasticsearch.Net connection pool.
  New-ConnectionConfiguration   # Creates a customizeable configuration for a client.
  New-BulkIndexRequest          # Creates a bulk request for faster indexing.
  Export-Elastic                # Indexes objects into Elastic.
  Invoke-PowerStash             # Runs an object producing script and indexes its output.
	
```
Client Configuration
-----------------------------------
By default, PowerStash uses http://localhost:9200 as the Uri for Elastic.
###
```powershell
  # Default client:
  $Client = New-ElasticClient
      
  # Specific node client:
  $Client = New-ElasticClient -Node http://MyElasticUri:9200
  
  # Fully configured client:
  $Pool = New-ConnectionPool -Nodes ('http://node1:9200','http://node2:9200') -Sniffing
  $Config = New-ConnectionConfiguration -Pool $Pool
  $Config.SetProxy('http://proxy:8080','user','pass')
  $Client = New-ElasticClient -Configuration $Config
```
Basic Indexing
--------------
PowerStash asynchronously indexes object(s) and returns the results. 

Elastic's response(s) to index requests, such as errors, are conatined in the results.
###
```powershell
  # Exporting to a single-node instance:
  $Results = Export-Elastic -InputObject $MyObjects -Node http://MyElasticUri:9200
      
  # Exporting with a fully configured client:
  $Results = Export-Elastic -InputObject $MyObjects -Client $Client
```
Heavy-Lifting
------
Invoke-PowerStash can be used to produce objects in a separate runspace and asynchronously export them.
###
```powershell
  Invoke-PowerStash -Scriptblock ${function:Get-Objects} -Parameters $Params -Client $Client
```
