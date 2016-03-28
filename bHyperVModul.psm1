# HYPER-V FUNKSJONER 

# Funksjonen oppretter en eller flere virtuelle maskiner 
Function New-VMFromTemplate {
<#
.SYNOPSIS

.DESCRIPTION

.PARAMETER VMName

.PARAMETER VhdPath

.PARAMETER ParentPath

.PARAMETER MemoryStartupBytes

.EXAMPLE

.EXAMPLE

#>


    [CmdletBinding()]
    param(
        [Parameter(
            Position = 1,
            Mandatory = $false
        )][string[]]$VMName,
        
        [Parameter( 
            Mandatory = $true
        )][string]$VhdPath,
        
        [parameter(
            Mandatory = $true
        )][string]$TemplatePath,

        [parameter(
            Mandatory = $false
        )][string]$MemoryStartupBytes = "1GB"
    )

    Begin{
        # Hent inn eksisterende svitsjer
        $svitsjer = Get-VMSwitch | select -ExpandProperty name
         
        # Sjekker at valgt(e) svitsj(er) eksisterer
        do {
            $err = $false 
            $valgteSvitsjer = $null 

            # List ut tilgjengelige svitsjer
            Write-Host “Velg svitsjer. Separere med komma. (La det stå tomt hvis du ikke ønsker å legge til noen). Du kan velge blant”
            $svitsjer 

            # Velg svitsj(er)
            [string[]]$valgteSvitsjer = (Read-Host).split(“,”) | %{$_.trim()}
            
            # Sjekk at innskrevet svitsj faktisk eksisterer 
            foreach($valg in $valgteSvitsjer) {
                if ( ($svitsjer -notcontains $valg) -and ($valgteSvitsjer -ne "")) 
                {$err = $true}
            }
        }while ($err -eq $true)
      
    }

    Process{
        foreach ($vm in $VMName) {
            # Opprett virtuell disk 
            New-VHD -ParentPath $TemplatePath + "$vm.vhd" -Path $VhdPath 

            # Opprett virtuell maskin 
            New-VM -Name $vmName -VHDPath $vhdPath -MemoryStartupBytes $MemoryStartupBytes

            # Legg til svitsjer 
            foreach ($switch in $additionalSwitches) {
                Add-VMNetworkAdapter -VMName $vmName -SwitchName $switch
            }
        }
    }
    End{}
}

# Lister ut detaljert (relevant) informasjon for virtuelle maskiner 
Get-VmDetaljert {
    $VirtuelleMaskiner = Get-VM # | Format-Table -AutoSize -Property name, Path, CheckpointFileLocation,  Status, Uptime, Version, MemoryAssigned
    $obj = new-object -TypeName psobject
    $obj | Add-Member -MemberType NoteProperty -Name mb -Value $VirtuelleMaskiner.MemoryAssigned
    $obj.mb
}