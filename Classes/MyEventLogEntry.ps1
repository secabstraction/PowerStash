Class MyEventLogEntry {
    
    [DateTime]$TimeCreated
    [Int32]$EventId
    [Int32]$RecordId
    [String]$MachineName
    [String]$Level
    [String]$Source
    [String]$Message
    [String]$UserName
    [String]$Id             # Elastic Id

    MyEventLogEntry ([Diagnostics.EventLogEntry]$Entry) {
        
        $this.TimeCreated = $Entry.TimeGenerated
        $this.EventId = $Entry.EventId
        $this.RecordId = $Entry.Index
        $this.MachineName = $Entry.MachineName
        $this.Level = $Entry.EntryType
        $this.Source = $Entry.Source
        $this.Message = $Entry.Message
        $this.UserName = $Entry.UserName
        $this.Id = $this.MachineName + '-' + $this.RecordId
    }
}
