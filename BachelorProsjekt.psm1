# Funksjonen lar brukeren velge ett eller flere alternativer fra en tabell 
Function Velg-Objekt {
    param (
        [parameter(mandatory=$true)]
        [Object[]]$Objekt,

        [Object[]]$Egenskaper
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
    $Objekt | Format-Table -AutoSize -Property $Egenskaper
   
    # Les inn valg 
    $ValgteObjekter = Valider-Valg ($Objekt)
    #Valider-Valg $objekt
    
    $ValgteObjekter
}

function Valider-Valg {
    param(
        [object[]]$Objekt
    )
    
    do {
        $error = $false 
        [int[]]$valg = $null 

        # Valider at brukeren skriver inn tall
        try {
            [int[]]$Valg = (Read-Host -Prompt "Skriv inn linjenummer på valgene du ønsker. Skill med komma [f.eks. 0,2]").split(“,”) | %{$_.trim()} 
        }catch{
            Write-Host "Ugyldig input"
            $error = $true
        }

        # Fjern duplikate verdier 
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








