

    

    $RunspaceScript = { 
        Param([String]$Computer, [String]$LogName)

        try { $LogRecords = Get-WinEvent -ComputerName $Computer -LogName $LogName }
        catch { Write-Warning ("{0}: {1}" -f $Computer,$_.Exception.Message) ; break }
        
        $MyLogRecords = $LogRecords | % { [MyEventLogRecord]::new($_) }
        
        $BulkDescriptor = [Nest.BulkDescriptor]::new()

        foreach ($Record in $MyLogRecords) {  
            $BulkDescriptor.Operations.Add(
                (New-BulkIndexOperation $Record `
                    -Index ("powerstash-$($Record.TimeCreated.ToShortDateString().Replace('/','-'))") `
                    -Type ($Record.Provider + '-' + $Record.EventId)
                )
            )
        }
        
        $Client = [Nest.ElasticClient]::new()
        $Client.Bulk($BulkDescriptor)
    }

    Write-Verbose 'Creating runspace pool and session states.'
    $SessionState = [Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $ThrottleLimit, $SessionState, $Host)
    $RunspacePool.Open()  

    $Runspaces = New-Object Collections.ArrayList

    $LogNames = Get-WinEvent -ComputerName $Computer -ListLog * | ? { $_.RecordCount -gt 0 } | % { $_.LogName }

    foreach ($LogName in $LogNames) {
        
        # Create the powershell instance and supply the script/params 
        $PowerShell = [PowerShell]::Create()
        [void]$PowerShell.AddScript($RunspaceScript)
        [void]$PowerShell.AddArgument($Computer)
        [void]$PowerShell.AddArgument($LogName)
           
        # Assign instance to runspacepool
        $PowerShell.RunspacePool = $RunspacePool
           
        # Create an object for each runspace
        $Job = "" | Select-Object Computer,PowerShell,Result
        $Job.Computer = $Computer
        $Job.PowerShell = $PowerShell
        $Job.Result = $PowerShell.BeginInvoke()
        
        Write-Verbose ("Adding {0} to jobs." -f $Job.Computer)
        [void]$Runspaces.Add($Job)
    }