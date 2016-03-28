# Funksjonen lar brukeren velge et alternativ fra tabell 
Function Velg-Alternativ {
    param (
        [parameter(Mandatory=$true)]
        [string[]]$Alternativer
    )

    # List ut alternativer 
    for ($i = 0; $i -lt $Alternativer.Length; $i++) {
        Write-Host $i : $Alternativer[$i]
    }

    # Velg integer og sjekk at input er gyldig 
    $valg = Valider-Integer -Tabell $Alternativer

    return $valg
}

# Funksjonen validerer at input er tall og tallet befinner seg innen en tabells lengde 
function Valider-Integer {
    param(
        [parameter(mandatory=$true)]
        [string[]]$Tabell
    )

 

    # Sjekk at valg har gyldig input 
    do {

        $error = $false 
        $valg = $null 

        # Gjør et valg 
        try {
            [int]$valg = Read-Host "Velg et alternativ [f.eks. 0]"
        }catch{
            Write-Host "Ugyldig input"
            $error = $true 
        }

        # Fikser problem med tabeller hvor det kun er én verdi
        if($tabell -ne $null -and $tabell -isnot [system.array]) {
            $tabell.length = 1 
        }

    }while(($error -eq $true) -or ($valg -gt ($tabell.length-1)) -or ($valg -eq $null))

    return $valg 
}








<# Hyper-V funksjoner #>
# Funksjonen oppretter en eller flere virtuelle maskiner 
Function New-VMFromTemplate {
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
        )][string]$ParentPath
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
            #New-VHD -ParentPath $ParentPath + "$vm.vhd" -Path $VhdPath

            # Opprett virtuell maskin 
            #New-VM -Name $vmName -VHDPath $vhdPath 

        }
    }
    End{}

    # Opprett virtuell disk
    #New-VHD -ParentPath $parentPath -Path $vhdPath

    # Opprett virtuell maskin
    #New-VM -Name $vmName -VHDPath $vhdPath 

    # Legg til svitsjer 
    #foreach ($switch in $additionalSwitches) {
    #    Add-VMNetworkAdapter -VMName $vmName -SwitchName $switch
    #}

}
