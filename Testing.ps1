#$Uri = New-Object Uri "http://localhost:9200"
#$Settings = New-Object Nest.ConnectionSettings ($Uri, $Index)
#$Settings.MapDefaultTypeNames( { param($m) $m.Add([Type][MyEventLogEntry], "System-7045") } )

$MySys2 = $MySys | Sort-Object -Property TimeCreated

$CurrentDate = ([DateTime]::Now).ToShortDateString()
$MySys2 | % { 
            if ($_.TimeCreated.ToShortDateString() -ne $CurrentDate) {
                $CurrentDate = $_.TimeCreated.ToShortDateString()
                $LogCollection = New-Object System.Collections.Generic.List[MyEventLogRecord]
                $Index = "PowerStash-" + $CurrentDate.Replace('/','-')
            }
            $LogCollection.Add($_)
            $client.
        }