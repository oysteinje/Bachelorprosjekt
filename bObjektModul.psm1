<#
# Generell modul for objekter
#>

function Set-LinjeNummer 
{
    param (
        [parameter(mandatory=$true)]
        [Object[]]$Objekt
    )


    # Legger til linjenummer på objektet  
    $Nummer = 1

    # Gjennomgår hver rad i objekt 
    $Objekt | ForEach-Object {
        # Legger til linjenummer som egenskap for hver rad 
        Add-Member -InputObject $_ -MemberType NoteProperty `
        -Name Nummer -Value $Nummer

        # Inkrementerer linjenummer
        $Nummer++
    }

    # Hvert objekt har nå et linjenummer 
    $objekt 
}

function Get-Objekt
{
    param(
        [parameter(mandatory)]
        $objekt,
        $valg
    )

    if($valg -notlike $null)
    {
        foreach($v in $valg)
        {
            [object[]]$valgtObjekt += ($objekt | where {$_.nummer -eq $v})
        }
    }
    $ValgtObjekt = $null 

    do
    {
        # Velg alternativ 
        $valg = (Read-Host "Velg et alternativ fra listen").split(“,”) | %{$_.trim()} 

        # Henter ut valgte objekter 
        foreach ($v in $valg)
        {
            [object[]]$valgtObjekt += ($objekt | where {$_.nummer -eq $v})
        }
        
        # Sjekker om det faktisk er lov å velge flere objekter 
        if($ValgtObjekt.length -gt 1) 
        {
            foreach ($obj in $ValgtObjekt)
            {
                # Setter valgt objekt til null hvis det ikke er lov å velge flere objekter
                if ($obj.flervalg -match $false)
                {
                    $ValgtObjekt = $null 
                }
            }
        }

        # Skriver ut melding hvis brukeren har ugyldig inndata 
        if($valgtObjekt -eq $null) 
        {
            write-host "Ugyldig input" -ForegroundColor Red
        }
    }while($ValgtObjekt -eq $null)
    

    return $ValgtObjekt
}

# Scriptet lar brukeren velge fra en liste ved å skrive inn et nummer 

Function Get-Valg {
    param (
        [parameter(Mandatory=$true)]
        [string[]]$alternativer,
        [string]$PromptTekst
    )

    Write-Host $PromptTekst

    # List ut alternativer 
    for ($i = 0; $i -lt $alternativer.Length; $i++) {
        Write-Host $i : $alternativer[$i]
    }

    # Sjekk at input er gyldig 
    $valg = Get-IntInput $alternativer

    return $alternativer[$valg]
}

# Scriptet validerer at input er tall og tallet befinner seg innen en tabells lengde 

function Get-IntInput($tabell) {
    
    do
    {
        $err = $false 

        $valg = read-host 'Velg et alternativ [0]' 

        if($tabell[$valg] -eq $null)
        {
            Write-Host 'Ugyldig input'
            $err = $true
        }

    }while($err -eq $true)

    # Sjekk at valg har gyldig input 
    <#do {

        $err = $false 
        $valg = $null 

        # Gjør et valg 
        try {
            [int]$valg = Read-Host "Velg et alternativ [f.eks. 0]"
        }catch{
            Write-Host "Ugyldig input"
            $err = $true 
        }

        # Fikser problem med tabeller hvor det kun er én verdi
        if($tabell -ne $null -and $tabell -isnot [system.array]) {
            $tabell.length = 1 
        }

    }while(($err -eq $true) -or ($valg -gt ($tabell.length-1)) -or ($valg.length -eq 0))
    #>
    return $valg 
}