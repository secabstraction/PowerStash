function New-BulkDescriptor {
    [CmdletBinding(DefaultParameterSetName = 'None')]
    Param (
        [Parameter(ParameterSetName = 'Index')]
        [Switch]$IndexMany,

        [Parameter(ParameterSetName = 'Create')]
        [Switch]$CreateMany,

        [Parameter(ParameterSetName = 'Delete')]
        [Switch]$DeleteMany,

        [Parameter(ParameterSetName = 'Index', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Create', Mandatory = $true)]
        [Type]$Type,
        
        [Parameter(ValueFromPipeline = $true)]
        [Object]$InputObject
    )

    begin {
        $List = switch ($PSCmdlet.ParameterSetName) {
            'Index'  { New-Object Collections.Generic.List[$Type] }
            'Create' { New-Object Collections.Generic.List[$Type] }
            'Delete' { New-Object Collections.Generic.List[Int64] }
            'None'   { $null }
        }
        
        $BulkDescriptor = [Nest.BulkDescriptor]::new()
    }
    
    process { foreach ($Object in $InputObject) { $List.Add($Object) } }

    end {
        switch ($PSCmdlet.ParameterSetName) {
        
            'Index' {
                $GenericIndexMany = $BulkDescriptor.GetType().GetMethod('IndexMany').MakeGenericMethod($Type)
                $BulkDescriptor = $GenericIndexMany.Invoke($BulkDescriptor, @(($List -as $List.GetType()), $null))
            
                Write-Output $BulkDescriptor
            }
            'Create' {
                $GenericCreateMany = $BulkDescriptor.GetType().GetMethod('CreateMany').MakeGenericMethod($Type)
                $BulkDescriptor = $GenericCreateMany.Invoke($BulkDescriptor, @(($List -as $List.GetType()), $null))

                Write-Output $BulkDescriptor
            }
            'Delete' {   
                $GenericDeleteMany = $BulkDescriptor.GetType().GetMethod('DeleteMany').MakeGenericMethod($Type)
                $BulkDescriptor = $GenericDeleteMany.Invoke($BulkDescriptor, @(($List -as $List.GetType()), $null))

                Write-Output $BulkDescriptor
            }
            'None' { Write-Output $BulkDescriptor }
        }
    }
}