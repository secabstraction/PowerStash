function Split-Collection {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [Collections.ICollection]
        $Collection,

        [Parameter(Mandatory = $true)]
        [Int32]
        $NewSize
    )

    $Count = $Collection.Count
    for ($i = 0; $i -lt $Count; $i += $NewSize) { ,($Collection[$i..($i + $NewSize - 1)]) }
}
