function Get-EventLogRecord {
    [CmdLetBinding()]
    Param(
        [Parameter(ParameterSetName = 'LogName', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$LogName,

        [Parameter(ParameterSetName = 'Provider', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ProviderName,
        
        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [Int[]]$EventId,

        [Parameter()]
        [ValidateSet('Critical','Error','Warning','Information')]
        [String]$Level,

        [Parameter()]
        [ValidateScript( { [DateTime]::Parse($_) } )]
        [String]$Since,

        [Parameter()]
        [Diagnostics.Eventing.Reader.EventLogSession]$Session
    )

    if ($PSCmdlet.ParameterSetName -eq 'Provider') { $Path = $ProviderName }
    else { $Path = $LogName }

    $QueryString = "*"

    if ($PSBoundParameters.EventId) {
        
        $QueryString += "[$Path/EventID = $($EventId[0])"

        if ($EventId.Count -gt 1) {
            for ($i = 1; $i -lt $EventId.Count; $i++) {
                $QueryString += " or $Path/EventID = $($EventId[$i])"
            }
        }

        if ($PSBoundParameters.Since) {
            $Since = ([DateTime]::Parse($Since)).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffff00K", [CultureInfo]::InvariantCulture)
            $QueryString += " and $Path/TimeCreated/@SystemTime >= '$Since'"
        }
        $QueryString += "]"
    }

    if ($PSBoundParameters.Level) { 
        $LevelValue = switch ($Level) {
             'Information' { 4 }
                 'Warning' { 3 }
                   'Error' { 2 }
                'Critical' { 1 }
                   default { 0 }
        }

        $QueryString = "*[$Path/Level = $LevelValue"

        if ($PSBoundParameters.Since) {
            $Since = ([DateTime]::Parse($Since)).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffff00K", [CultureInfo]::InvariantCulture)
            $QueryString += " and $Path/TimeCreated/@SystemTime >= '$Since'"
        }
        $QueryString += "]"
    }
    
    # Xpath query
    $Query = New-Object Diagnostics.Eventing.Reader.EventLogQuery -ArgumentList ($Path, [Diagnostics.Eventing.Reader.PathType]::LogName, $QueryString)
    
    if ($PSBoundParameters.Session) { $Query.Session = $Session }

    $Reader = New-Object Diagnostics.Eventing.Reader.EventLogReader -ArgumentList @($Query)

    while ($true) { try { $Reader.ReadEvent() } catch { break } }
}