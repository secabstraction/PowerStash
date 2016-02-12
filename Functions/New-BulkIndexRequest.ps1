function New-BulkIndexRequest {
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

    begin { $List = New-Object Collections.Generic.List[String] }
    
    process { 
        foreach ($Object in $InputObject) { 
            
            if ($Object.Id) { $ElasticId = $Object.Id }
            else { throw "Input object does not contain the required Id property." }
            
            if (!$Type) { $ElasticType = $Object.PSObject.TypeNames[0].ToLower() }
            if (!$Index) { $ElasticIndex = "powerstash-$($Object.DateCreated)" }
            else { $ElasticIndex = $Index + $Object.DateCreated }

            $IndexProperties = @{
                index = @{
                    _index = $ElasticIndex
                    _type = $ElasticType
                    _id = $ElasticId
                }
            }
            
            $IndexMarker = [psobject]$IndexProperties | ConvertTo-Json -Compress
            $Document = $Object | ConvertTo-Json -Compress

            $List.Add("$IndexMarker`n$Document`n") 
        } 
    }

    end { Write-Output (-join $List.ToArray()) }
}
