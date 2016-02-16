function Get-CimEvents {
    [CmdLetBinding(DefaultParameterSetName = 'Filter')]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Session')]
        [Microsoft.Management.Infrastructure.CimSession[]]
        $CimSession,

        [Parameter(ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Filter,
        
        [Parameter(ParameterSetName = 'Properties')]
        [ValidateNotNullOrEmpty()]
        [String]
        $LogName,

        [Parameter(ParameterSetName = 'Properties')]
        [ValidateNotNullOrEmpty()]
        [Alias('Source')]
        [String]
        $Provider,
        
        [Parameter(ParameterSetName = 'Properties')]
        [ValidateNotNullOrEmpty()]
        [Int32]
        $EventId,

        [Parameter(ParameterSetName = 'Properties')]
        [ValidateSet('Error','Warning','Information','SuccessAudit','FailureAudit')]
        [String]
        $EventType
    )
    if ($PSCmdlet.ParameterSetName -eq 'Properties') {
        
        # Enumerate type value
        $Type = switch ($EventType) {
            'FailureAudit' { 5 }
            'SuccessAudit' { 4 }
             'Information' { 3 }
                 'Warning' { 2 }
                   'Error' { 1 }
                   default { 0 }
        }

        # Build a filter from parameters
        $Filters = New-Object Collections.Generic.List[String]

        if ($PSBoundParameters.LogName)   { $Filters.Add("LogFile='$LogName'") }
        if ($PSBoundParameters.Provider)  { $Filters.Add("SourceName='$Provider'") }
        if ($PSBoundParameters.EventId)   { $Filters.Add("EventCode='$EventId'") }
        if ($PSBoundParameters.EventType) { $Filters.Add("EventType='$Type'") }

        $Filter = $Filters -join ' AND '
    }
    
    $Parameters = @{
        CimSession = $CimSession
        ClassName = 'Win32_NTLogEvent'
        Filter = $Filter
        ErrorAction = 'Continue'
        ErrorVariable = 'Errors'
    }

    Get-CimInstance @Parameters | foreach {
        
        # Convert the TimeGenerated property to an elastic compatible format        
        $TimeCreated = $_.TimeGenerated.ToString("yyyy-MM-ddTHH:mm:ss.fffffff00K")

        # DateCreated property used for elastic indexing
        $DateCreated = $_.TimeGenerated.ToString("yyyy-MM-dd")

        # Enumerate event type from value
        $EventType = switch ($_.EventType) {
                5 { 'FailureAudit' }
                4 { 'SuccessAudit' }
                3 { 'Information' }
                2 { 'Warning' }
                1 { 'Error' }
          default { 'None' }
        }

        # Create a custom object
        $EventLogEntry = [pscustomobject]@{
            Id = $_.ComputerName + '-' + $_.RecordNumber # faster and more relevant than [Guid]::NewGuid()
            TimeCreated = $TimeCreated
            DateCreated = $DateCreated
            EventId = $_.EventCode
            ComputerName = $_.ComputerName
            Level = $EventType
            Provider = $_.SourceName
            LogName = $_.LogFile
            Category = $_.CategoryString
            Type = $_.Type
            InsertionStrings = $_.InsertionStrings
            Message = $_.Message
            User = $_.User
        }
        
        # Give object a TypeName for indexing into elastic    
        $EventLogEntry.PSObject.TypeNames.Insert(0, 'eventlogentry')

        Write-Output $EventLogEntry
    }

    # Write errors to warning stream
    $Errors | foreach { Write-Warning ("{0}: {1}" -f $_.OriginInfo.PSComputerName,$_.Exception.Message) }
}
