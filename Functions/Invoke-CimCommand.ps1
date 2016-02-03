function Invoke-CimSweep {
    [CmdLetBinding()]
    Param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]$ComputerName = 'localhost',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Int]$ThrottleLimit = 10,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Scriptblock]$Scriptblock,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Parameters
    )

    $OutputHandler = {
        Param([Management.Automation.PSDataCollection[psobject]]$Sender, [Management.Automation.DataAddedEventArgs]$e)

        $Objects = $Sender.ReadAll()
        $List = New-Object Collections.ArrayList

        if ($Objects.Count) { 
            $BulkRequest = $Objects | ForEach-Object {
                New-BulkIndexOperation $_ -Index "powerstash-$($_.DateCreated)" -Type ($_.Provider + '-' + $_.EventId.ToString()) 
            } | New-BulkRequest
            
            $Client = New-ElasticClient
            $Response = $Client.Bulk($BulkRequest)
            
            if ($Response.Response.errors) {
                Start-Sleep -Seconds 1
                $Response = $Client.Bulk($BulkRequest)
            }

            Write-Host $Response.Response.errors
        }
    }

    Write-Verbose "Creating runspace pool and session states."
    $SessionState = [Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $ThrottleLimit, $SessionState, $Host)
    $RunspacePool.Open()  

    $Runspaces = New-Object Collections.ArrayList

    $GenericBeginInvoke = ([powershell].GetMethods() | ? { $_.Name -eq 'BeginInvoke' -and $_.GetParameters().Count -eq 2 }).MakeGenericMethod([psobject],[psobject])
    
    foreach ($Computer in $ComputerName) {
        
        # Create a powershell "thread" 
        $PowerShell = [PowerShell]::Create()
        [void]$PowerShell.AddScript($RunspaceScript)
        [void]$PowerShell.AddArgument($Computer)
        [void]$PowerShell.AddArgument($Parameters)

        # Create output collection and register output-processing callback
        $Output = [Management.Automation.PSDataCollection[psobject]]::new()
        $OutputSubscriber = Register-ObjectEvent -InputObject $Output -EventName DataAdded -Action $OutputHandler
   
        # Assign instance to threadpool
        $PowerShell.RunspacePool = $RunspacePool
           
        # Create an object for each thread
        $Job = "" | Select-Object Computer,PowerShell,Result,OutputSubscriber
        $Job.Computer = $Computer
        $Job.PowerShell = $PowerShell
        $Job.OutputSubscriber = $OutputSubscriber
        $Job.Result = $GenericBeginInvoke.Invoke($PowerShell, @($null,$Output))
        
        Write-Verbose ("Adding {0} to jobs." -f $Job.Computer)
        [void]$Runspaces.Add($Job)
    }
    # Counters for progress bar
    $TotalRunspaces = $RemainingRunspaces = $Runspaces.Count         
    
    Write-Verbose 'Checking status of runspace jobs.'
    Write-Progress -Activity 'Waiting for queries to complete...' -Status "Hosts Remaining: $RemainingRunspaces" -PercentComplete 0
    
    do {
        $More = $false   
        foreach ($Job in $Runspaces) {
            
            if ($Job.Result.IsCompleted) {
                    
                $Job.PowerShell.Dispose()
                $Job.Result = $null
                $Job.PowerShell = $null
                
                $RemainingRunspaces--

                Unregister-Event -SourceIdentifier $Job.OutputSubscriber.Name
                Write-Progress -Activity 'Waiting for queries to complete...' -Status "Hosts Remaining: $RemainingRunspaces" -PercentComplete (($TotalRunspaces - $RemainingRunspaces) / $TotalRunspaces * 100)
            } 

            if ($Job.Result) { $More = $true }
        }
                   
        # Remove completed jobs
        $Jobs = $Runspaces.Clone()
        $Jobs | where { $_.Result -eq $null } | foreach { Write-Verbose ("Removing {0}" -f $_.Computer) ; $Runspaces.Remove($_) }     
    } while ($More)
        
    Write-Progress -Activity 'Waiting for queries to complete...' -Status 'Completed' -Completed

    $RunspacePool.Dispose()
    [GC]::Collect()
}