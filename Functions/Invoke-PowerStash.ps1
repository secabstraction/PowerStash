#requires -version 5

function Invoke-PowerStash {
    [CmdLetBinding(DefaultParameterSetName = 'Node')]
    param (        
        [Parameter(ParameterSetName = 'Node', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Node = 'http://localhost:9200',
        
        [Parameter(ParameterSetName = 'Configuration', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Elasticsearch.Net.Connection.ConnectionConfiguration]
        $Configuration,
        
        [Parameter(ParameterSetName = 'Client', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Elasticsearch.Net.ElasticsearchClient]
        $Client,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Scriptblock]
        $Scriptblock,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Parameters = @{},

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Int32]
        $BulkSize = 200
    )

    $Stopwatch = [Diagnostics.Stopwatch]::StartNew()

    $Elastic = switch ($PSCmdlet.ParameterSetName) { 
        'Node'          { $Node }
        'Configuration' { $Configuration }
        default         { $Client }
    }

    $MessageData = @{
        Size = $BulkSize
        Elastic = $Elastic
    }

    $OutputHandler = {
        $PSObjects = $Sender.ReadAll()
        
        if ($PSObjects.Count) { 
            
            Export-Elastic $PSObjects $Event.MessageData.Elastic -Size $Event.MessageData.Size |
            
            # Warn about failures
            foreach { 
                $_.Response.items.Value | where { $_.Values.status -ne 200 -and $_.Values.status -ne 201 } | 
                foreach { Write-Warning ( -join $_.Values ) } 
            }
        }
    }

    $BeginInvoke = [powershell].GetMethods() | where { $_.Name -eq 'BeginInvoke' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 2 }
    $GenericBeginInvoke = $BeginInvoke.MakeGenericMethod([psobject],[psobject])

    # Add scriptblock to new powershell runspace
    $PowerShell = [PowerShell]::Create().AddScript($Scriptblock)
    
    # Add parameters to runspace
    foreach ($Key in $Parameters.Keys) { [void]$PowerShell.AddParameter($Key, $Parameters[$Key]) }

    # Create output collection and register event handler
    $Output = [Management.Automation.PSDataCollection[psobject]]::new()
    $OutputSubscriber = Register-ObjectEvent -InputObject $Output -EventName DataAdded -Action $OutputHandler -MessageData $MessageData
    
    # Run script          
    $Result = $GenericBeginInvoke.Invoke($PowerShell, @($null,$Output))
    
    # Wait for script to complete
    [void]$Result.AsyncWaitHandle.WaitOne()

    # Stupid hack, because $OutputSubscriber.Finished.WaitOne() blocks indefinitely
    do { Start-Sleep -Milliseconds 100 ; continue } until ($OutputSubscriber.State -ne 'Running')
    
    if ($OutputSubscriber.Error.Count) { $OutputSubscriber.Error | foreach { Write-Warning $_.Exception.Message } }

    # Cleanup
    $Stopwatch.Stop()
    $PowerShell.Dispose()
    Unregister-Event -SourceIdentifier $OutputSubscriber.Name
    Write-Verbose $Stopwatch.Elapsed
    [GC]::Collect()
}