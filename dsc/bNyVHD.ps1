Configuration bNyVHD {
    param
    (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [String]$Path,

        [Parameter(Mandatory)]
        [Uint64]$MaximumSizeBytes,

        [ValidateSet("Vhd","Vhdx")]
        [string]$Generation = "Vhd",

        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present"
    )

    Import-DscResource -Module xHyper-V

    node localhost
    {
        xVHD NewVHD
        {
            Ensure = $Ensure
            Name = $Name
            Path = $Path
            Generation = $Generation
            MaximumSizeBytes = $MaximumSizeBytes
        }
    }
}
bNyVHD -Name "dscHDD" -Path "E:\VM\dscHDD.vhd" -MaximumSizeBytes 15