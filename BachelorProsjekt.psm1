# Legger til linjenummer på objekter og lar brukeren velge ett eller flere av objektene
<#function Velg-Objekt {
    param (
        [parameter(mandatory=$true)]
        [Object[]]$Objekt,

        [string[]]$Egenskaper
    )


    # Legger til linjenummer på objektet  
    $LinjeNr = 1

    # Gjennomgår hver rad i objekt 
    $Objekt | ForEach-Object {
        # Legger til linjenummer som egenskap for hver rad 
        Add-Member -InputObject $_ -MemberType NoteProperty `
        -Name LinjeNr -Value $LinjeNr

        # Inkrementerer linjenummer
        $LinjeNr++
    }

    # Legger linjenummer fremst i egenskaper. Mao denne vises først i utdata 
    if($egenskaper.Length -ne 0) {
        $egenskaper = ([object[]]"LinjeNr") + $egenskaper
    }else{
        $egenskaper = "LinjeNr"
    }    

    # List ut objekt 
    write-output $Objekt | Format-Table -AutoSize -Property $Egenskaper

    # Sjekker at input er gyldig
    $valgt = valider-ObjektValg $Objekt
    
    write-output $valgt | ft $Egenskaper 
}
#>
# Validerer ett eller flere valg er gyldige tall
function Valider-ObjektValg {
    param(
        [object[]]$Objekt
    )
    
    do {
        # Løkken går så lenge error er lik false 
        $error = $false 

        # Her skal brukerens input legges
        [int[]]$valg = $null 

        # Valider at brukeren skriver inn tall
        try {
            [int[]]$Valg = (Read-Host -Prompt 'Skriv inn linjenummer på valgene du ønsker. Skill med komma [f.eks. 0,2]').split(“,”) | %{$_.trim()} 
        }catch{
            Write-Host "Ugyldig input"
            $error = $true
        }

        # Fjern eventuelle duplikate verdier 
        $Valg = $valg | Select-Object -Unique

        # Sjekk at input verdier ikke overstiger høyeste eller laveste verdi i objekt 
        foreach ($tall in $valg) {
            if ($tall -gt ($objekt.LinjeNr | select -Last 1) -or 
                $tall -lt ($objekt.LinjeNr | select -first 1)) {
                    $error = $true
            }
        }
    }while($error -eq $true)

    # Hent ut valgte objekter
    foreach ($tall in $valg) {
        [object[]]$valgteObjekter += ($objekt | where-object {$_.LinjeNr -eq $tall})
    }
    
    # Returner valgte objekter 
    return $valgteObjekter
}

# Funksjonen lar brukeren velge ett alternativ fra tabell 
Function Velg-FraTabell {
    param (
        [parameter(Mandatory=$true)]
        [string[]]$Alternativer
    )

    # Legger standardverdiene hjelp og avslutt til tabellen 

    # List ut alternativer 
    for ($i = 0; $i -lt $Alternativer.Length; $i++) {
        # Valget er '?' 
        if($i -eq ($Alternativer.Length - 1))
        {write "[?] Hjelp"}
        # Valget er 'x'
        elseif($i -eq ($Alternativer.Length)) 
        {write "[x] Avslutt"}
        else
        {Write-Host "[$i]" $Alternativer[$i]}
    }

    # Velg integer og sjekk at input er gyldig 
    $valg = Valider-ValgFraTabell -Tabell $Alternativer

    return $valg
}

# Funksjonen validerer at input er tall og tallet befinner seg innen en tabells lengde 
function Valider-ValgFraTabell {
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
            Mandatory = $true,
            ValueFromPipeline=$True
        )][string[]]$VMName,
        
        [Parameter(Mandatory)]
        [string]$VHDDestination,
        
        [parameter(Mandatory)]
        [string]$TemplatePath,

        [string]$MemoryStartupBytes = 1GB
    )


    begin{
        
        # Tester at stiene eksisterer 
        do
        {
            
            $error = $false

            if (Test-Path $VHDDestination -eq $false) 
            {
                $VHDDestination = read-host "Stien for VHD stemmer ikke, skriv inn ny"
                $error = $true
            }
            if (Test-Path $TemplatePath -eq $false) 
            {
                $TemplatePath = read-host "Stien for template stemmer ikke, skriv inn ny"
                $error = $true
            }
        }
        while ($error -eq $true)
    }

    process
    {
        foreach ($vm in $VMName)
        {
            # Sjekk at destinasjonen slutter med skråstrek (/), hvis ikke så legg det til 
            if ( ([char[]]$VHDDestination | select -last 1) -notmatch "/" ) 
            {
                $VHDDestination += '/'
            }

            # Opprett virtuell harddisk 
            New-VHD -Path ("$VHDDestination" + "$vm.vhdx") -ParentPath $TemplatePath -Verbose
            
            # Opprett virtuell maskin 
            New-VM -Name $vm -MemoryStartupBytes $MemoryStartupBytes -VHDPath ("$VHDDestination" + "$vm.vhdx") -Verbose
        }
    }
    end{}







    <#
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
            New-VHD -ParentPath $TemplatePath -Path $VhdPath 

            # Opprett virtuell maskin 
            New-VM -Name $vmName -VHDPath $vhdPath 

            # Legg til svitsjer 
            #foreach ($switch in $additionalSwitches) {
            #    Add-VMNetworkAdapter -VMName $vmName -SwitchName $switch
            #}
        }
    }
    End{}
    #>
}

# Lister ut detaljert (relevant) informasjon for virtuelle maskiner 
Function Get-VmDetaljert {
    param(
        [parameter(mandatory=$true)]
        [ValidateNotNullOrEmpty]
        $VMs
    )

    # Skriv ut virtuelle maskiner 
    $VMs | Format-Table -AutoSize -Property name, Status, @{Label='Memory(MB)';Expression={$_.memoryassigned/1MB}}, Version, Path, CheckpointFileLocation, Uptime
}

# Endrer minne på virtuelle maskiner 
Function Endre-Minne {
    param(
        [param(Mandatory)]
        [object[]]$VMs
    )

    $NyttMinne = Valider-Verdi (Read-Host "Skriv inn nytt minne [f.eks 512mb eller 2GB]")

    
}

# Validerer at input er et tall 
Function Valider-Verdi {
    param(
        [parameter(Mandatory)]
        $Verdi
    )

    # Sjekk at verdien er et gyldig tall
    do
    {
        $error = $false 

        if($Verdi -notmatch '^\d+$')
        {
            $Verdi = Read-Host "Verdien er ikke gyldig. Prøv på nytt" 
            $error = $true
        }

    } while ($error -eq $true)

    return $Verdi
}