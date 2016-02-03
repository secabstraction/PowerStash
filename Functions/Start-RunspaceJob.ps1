function Start-RunspaceJob {
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Scriptblock]
        $Scriptblock,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Int32]
        $ThrottleLimit = 10,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $JobArguments,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $ArgumentList
    )

    Write-Verbose 'Creating runspace pool and session states.'
    $SessionState = [Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $ThrottleLimit, $SessionState, $Host)
    $RunspacePool.Open()  

    $Runspaces = New-Object Collections.ArrayList

    foreach ($JobArgument in $JobArguments) {
        
        # Create the powershell instance and supply the script/params 
        $PowerShell = [PowerShell]::Create()
        
        [void]$PowerShell.AddScript($Scriptblock)
        [void]$PowerShell.AddArgument($JobArgument)

        foreach ($Argument in $ArgumentList) { [void]$PowerShell.AddArgument($Argument) }
           
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

    Write-Output $Runspaces
}