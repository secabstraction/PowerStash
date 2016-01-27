Class MyEventLogRecord {
    
    [DateTime]$TimeCreated
    [Int32]$EventId
    [Int64]$RecordId
    [String]$MachineName
    [String]$Level
    [String]$Provider
    [String]$Message
    [String]$ContainerLog
    [String]$LogName
    [String]$Opcode
    [String]$Keywords
    [String]$Task
    [Int32]$ProcessId
    [Int32]$ThreadId
    [String]$UserSid
    [Hashtable]$Properties
    [String]$Id             # Elastic Id

    MyEventLogRecord ([Diagnostics.Eventing.Reader.EventLogRecord]$Record) {

        $Props = New-Object hashtable
        $EventXml = [xml]$Record.ToXml()
        try { $EventXml.Event.EventData.Data | % { $Props.Add($_.Name, $_.'#text') } }
        catch { }
        
        $this.TimeCreated = $Record.TimeCreated
        $this.EventId = $Record.Id
        $this.RecordId = $Record.RecordId
        $this.MachineName = $Record.MachineName
        $this.Level = $Record.LevelDisplayName
        $this.Provider = $Record.ProviderName
        $this.Message = $Record.Message
        $this.ContainerLog = $Record.ContainerLog
        $this.LogName = $Record.LogName
        $this.Opcode = $Record.OpcodeDisplayName
        $this.Keywords = $Record.KeywordsDisplayNames
        $this.Task = $Record.TaskDisplayName
        $this.ProcessId = $Record.ProcessId
        $this.ThreadId = $Record.ThreadId
        $this.UserSid = $Record.UserId
        $this.Properties = $Props
        $this.Id = $this.MachineName + '-' + $this.RecordId
    }
}
