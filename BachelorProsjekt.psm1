# Funksjonen lar brukeren velge ett eller flere alternativer fra en tabell 
Function Velg-Alternativer {
    param (
        [parameter(mandatory=true)]
        [string[]]$Alternativer
    )

    # List ut alternativer 
    for ($i = 0; $i -lt $Alternativer.Length; $i++) {
        Write-Host $i : $Alternativer[$i]
    }


}

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

    # Sjekk at valg har gyldig input 
    do {

        $error = $false 
        $valg = $null 

        # Gj�r et valg 
        try {
            [int[]]$valg = Read-Host ("Velg ett eller flere alternativer [f.eks. 0,1]").split(�,�) | %{$_.trim()}
        }catch{
            Write-Host "Ugyldig input"
            $error = $true 
        }

        # Fikser problem med tabeller hvor det kun er �n verdi
        if($tabell -ne $null -and $tabell -isnot [system.array]) {
            $tabell.length = 1 
        }

    }while(($error -eq $true) -or ($valg -gt ($tabell.length-1)) -or ($valg -eq $null))

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

        # Gj�r et valg 
        try {
            [int]$valg = Read-Host "Velg et alternativ [f.eks. 0]"
        }catch{
            Write-Host "Ugyldig input"
            $error = $true 
        }

        # Fikser problem med tabeller hvor det kun er �n verdi
        if($tabell -ne $null -and $tabell -isnot [system.array]) {
            $tabell.length = 1 
        }

    }while(($error -eq $true) -or ($valg -gt ($tabell.length-1)) -or ($valg -eq $null))

    return $valg 
}








