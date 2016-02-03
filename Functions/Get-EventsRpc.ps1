function Get-EventsRpc {
<#
.SYNOPSIS
Pull the specified Windows Events from the past 24 hours.

.DESCRIPTION
This commandlet uses Remote Procedure Call (Rpc) built-in to Get-WinEvent and runspaces to collect Windows Event Log information from remote systems.

This cmdlet requires systems be able to support Get-WinEvent (Vista+) Rpc errors are likely firewall related.

.PARAMETER TargetList 
Specify host(s) to retrieve data from.

.PARAMETER ConfirmTargets
Verify that targets exist in the network before attempting to retrieve data.

.PARAMETER ThrottleLimit 
Specify maximum number of simultaneous connections.

.PARAMETER LogName
Specify the name of the log to retrieve events from.

.PARAMETER EventId
Specify the ID number of the event to collect.

.PARAMETER StartTime
Specify a [DateTime] object at some point in the past to start from. Defaults to [DateTime]::Now.AddHours(-24), 24 hours in the past.

.PARAMETER EndTime
Specify a [DateTime] object at some point in time after specified StartTime. Defaults to [DateTime]::Now.

.PARAMETER Timeout 
Specify timeout length, defaults to 3 seconds.

.PARAMETER CSV 
Specify path to output file, output is formatted as comma separated values.

.PARAMETER TXT 
Specify path to output file, output formatted as text.

.EXAMPLE
The following example uses New-TargetList to create a list of targetable hosts and uses that list to collect cleared event logs over the past 24 hours and writes the output to the console.

PS C:\> $Targs = New-TargetList -Cidr 10.10.20.0/24
PS C:\> Get-SkullEventRpc -TargetList $Targs -LogName Security -EventId 1102

.EXAMPLE
The following example uses New-TargetList to create a list of targetable hosts and uses that list to collect failed logon attempts over the past 10 days and writes the output to a csv file.

PS C:\> $Targs = New-TargetList -Cidr 10.10.20.0/24
PS C:\> Get-SkullEventRpc -TargetList $Targs -LogName Security -EventId 4625 -StartTime ([DateTime]::Now.AddDays(-10)) -CSV C:\pathto\failed_logons.csv

.EXAMPLE
The following example uses New-TargetList to create a list of targetable hosts and uses that list to collect newly installed services over the past 10 days and writes the output to a csv file.

PS C:\> $Targs = New-TargetList -Cidr 10.10.20.0/24
PS C:\> Get-SkullEventRpc -TargetList $Targs -LogName System -EventId 7045 -StartTime ([DateTime]::Now.AddDays(-10)) -CSV C:\pathto\new_services.csv

.NOTES
Version: 0.1
Author : RBOT

.INPUTS

.OUTPUTS

.LINK
#>
[CmdLetBinding(SupportsShouldProcess = $false)]
    Param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]$ComputerName = 'localhost',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Int]$ThrottleLimit = 10,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$LogName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$ProviderName,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Int[]]$EventId,

        [Parameter()]
        [ValidateSet('Critical','Error','Warning','Information')]
        [String]$Level,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [DateTime]$StartTime,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [DateTime]$EndTime
    )

    $LevelValue = switch ($Level) {
        'Information' { 4 }
            'Warning' { 3 }
              'Error' { 2 }
           'Critical' { 1 }
              default { 0 }
    }
        
    $Filter = @{}
          if ($PSBoundParameters.LogName) { $Filter.Add('LogName', $LogName) }
     if ($PSBoundParameters.ProviderName) { $Filter.Add('ProviderName', $ProviderName) }
          if ($PSBoundParameters.EventId) { $Filter.Add('Id', $EventId) }
            if ($PSBoundParameters.Level) { $Filter.Add('Level', $LevelValue) }
        if ($PSBoundParameters.StartTime) { $Filter.Add('StartTime', $StartTime) }
          if ($PSBoundParameters.EndTime) { $Filter.Add('EndTime', $EndTime) }

    $Parameters = @{
        FilterHashtable = $Filter
        ErrorAction = 'Stop'
    }

    $RunspaceScript = {
        Param([String]$Computer, [Hashtable]$Parameters)

        $Parameters.ComputerName = $Computer

        try { 
            Get-WinEvent @Parameters | % {
                $EventProperties = New-Object Hashtable
                
                # Convert event to xml
                $EventXml = [xml]$_.ToXml()

                # Try to grab object properties from xml, 
                try { $EventXml.Event.EventData.Data | ForEach-Object { $EventProperties.Add($_.Name, $_.'#text') } }
                catch { }

                New-Object psobject -Property @{
                    TimeCreated = $_.TimeCreated.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffff00K")
                    EventId = $_.Id
                    MachineName = $_.MachineName
                    Level = $_.LevelDisplayName
                    Provider = $_.ProviderName
                    Log = $_.LogName
                    Opcode = $_.OpcodeDisplayName
                    Task = $_.TaskDisplayName
                    Properties = $EventProperties
                    Message = $_.Message
                    Id = $_.MachineName + '-' + $_.RecordId
                }
            }
        }
        catch { 
            Write-Warning ("{0}: {1}" -f $Computer,$_.Exception.Message)
            break
        }
    } 

    $OutputHandler = {
        Param([Management.Automation.PSDataCollection[psobject]]$Sender, [Management.Automation.DataAddedEventArgs]$e)

        $Objects = $Sender.ReadAll()
        $Counter += $Objects.Count
        <#$BulkRequest = $Objects | 
            ForEach-Object { 
                New-BulkIndexOperation $_ `
                    -Index "powerstash-$([DateTime]::Parse($_.TimeCreated).ToShortDateString().Replace('/','-'))" `
                    -Type ($_.Provider + '-' + $_.EventId.ToString()) 
            } | New-BulkRequest
        #$Client = New-ElasticClient
        $Response = $Client.Bulk($BulkRequest) #>

        Write-Host $Counter
    }

    $StateHandler = {
        Param([Object]$Sender, [Management.Automation.PSInvocationStateChangedEventArgs]$e)

        $MyP = [System.Management.Automation.PSDataCollection[psobject]]$Sender
        $Results = $MyP.ReadAll()

        foreach ($Result in $Results) { Write-Output $Result }
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
        #Register-ObjectEvent -InputObject $PowerShell -EventName InvocationStateChanged -Action $StateHandler
   
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
    Write-Progress -Activity 'Waiting for event queries to complete...' -Status "Hosts Remaining: $RemainingRunspaces" -PercentComplete 0
    
    do {
        $More = $false   
        foreach ($Job in $Runspaces) {
            
            if ($Job.Result.IsCompleted) {
                    
                $Job.PowerShell.Dispose()
                $Job.Result = $null
                $Job.PowerShell = $null
                
                $RemainingRunspaces--

                Unregister-Event -SourceIdentifier $Job.OutputSubscriber.Name
                Write-Progress -Activity 'Waiting for event queries to complete...' -Status "Hosts Remaining: $RemainingRunspaces" -PercentComplete (($TotalRunspaces - $RemainingRunspaces) / $TotalRunspaces * 100)
            } 

            if ($Job.Result) { $More = $true }
        }
                   
        # Remove completed jobs
        $Jobs = $Runspaces.Clone()
        $Jobs | where { $_.Result -eq $null } | foreach { Write-Verbose ("Removing {0}" -f $_.Computer) ; $Runspaces.Remove($_) }     
    } while ($More)
        
    Write-Progress -Activity 'Waiting for event queries to complete...' -Status 'Completed' -Completed

    $RunspacePool.Dispose()
    [GC]::Collect()
}