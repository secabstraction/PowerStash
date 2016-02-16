#requires -version 5

function New-BulkIndexRequest {
<#
.SYNOPSIS

    Constructs a bulk index request for indexing a collection of objects into elastic.
    
    License: BSD 3-Clause
    Author: Jesse Davis (@secabstraction)
    Required Dependencies: None
    
.PARAMETER InputObject

    Specifies one or more objects.

.PARAMETER Index

    Specifies the elastic index with which the object(s) will be affiliated.

.PARAMETER Type

    Specifies the elastic type-name of the object(s). 

.EXAMPLE

    $BulkRequest = $MyObjects | New-BulkIndexRequest -Index myindex -Type mytype

    Creates a bulk index request from objects stored in the $MyObjects collection.

    The objects in this example will be converted to their JSON representation and
    configured for insertion into elastic. Only the uuid will be inferred from each
    object's Id property

    e.g. http://localhost:9200/myindex/mytype/localhost-3232

.EXAMPLE

    $BulkRequest = $MyObjects | New-BulkIndexRequest -Type mytype
    
    Creates a bulk index request from objects stored in the $MyObjects collection.

    Since no elastic index has been specified, it will be inferred from each object's 
    DateCreated property as "powerstash-DateCreated".
    
    e.g. http://localhost:9200/powerstash-2016-02-02/mytype/localhost-3232

.EXAMPLE

    $BulkRequest = New-BulkIndexRequest -InputObject $MyObjects

    Creates a bulk index request from objects stored in the $MyObjects collection.

    Since no elastic index has been specified, it will be inferred from each object's 
    DateCreated property as "powerstash-DateCreated". Likewise, since no elastic type
    has been specified it will also be inferred from each object's primary typename.

    $MyObject.PSObject.TypeNames.Insert(0, 'eventlogentry')
    
    e.g. http://localhost:9200/powerstash-2016-02-02/eventlogentry/localhost-3232
    
.LINK

    http://www.patch-tuesday.net/
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [Object[]]$InputObject,

        [Parameter(Position = 1)]
        [String]$Index,

        [Parameter(Position = 2)]
        [String]$Type
    )

    begin { $JsonStrings = [Collections.Generic.List[String]]::new() }
    
    process { 
        foreach ($Object in $InputObject) { 
            
            if ($Object.Id) { $Id = $Object.Id }
            else { throw "Input object does not contain the required Id property." }
            
            if (!$Type) { $Type = $Object.PSObject.TypeNames[0] }
            if (!$Index) { $Index = "powerstash-$($Object.DateCreated)" }

            $IndexProperties = @{
                index = @{
                    _index = $Index
                    _type = $Type
                    _id = $Id
                }
            }
            
            $IndexMarker = $IndexProperties | ConvertTo-Json -Compress
            $Document = $Object | ConvertTo-Json -Compress

            # Elastic bulk index format
            $JsonStrings.Add("$IndexMarker`n$Document`n") 
        } 
    }

    end { Write-Output (-join $JsonStrings) }
}