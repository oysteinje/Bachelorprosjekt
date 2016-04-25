<#
# Generell modul for objekter
#>

Function Validate-Tall
{
    param
    (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [AllowNull()]
        $Tall
    )

    begin
    {}
    process
    {
        foreach ($n in $tall) 
        {
            
            if($n -notmatch '^\d+$')
            {
                [pscustomobject[]]$ReturObjekt += @{'Tall'=$n;'Integer'=$true}
            }
            else
            {
                [pscustomobject[]]$ReturObjekt += @{'Tall'=$n;'Integer'=$false}
            }
            
        }
    }
    end
    {
        if($ReturObjekt.Values -contains 'false')
        {
            return $false 
        }
        else 
        {
            return $true 
        }
    }
}

Function Convert-Size
{
    param(
        [parameter(mandatory=$true)]
        $Tall
    )

    try {
        $StørrelseType = $tall.substring($tall.length -2) 
    }catch{}

    if($StørrelseType -eq 'GB') {
        try {
            [int64]$tall = $tall.remove($tall.length -2, 2) 
            $tall = $tall * 1024 * 1024 * 1024
        }catch { }
    }elseif($StørrelseType -eq 'MB') {
        try {
            [int64]$tall = $tall.remove($tall.length -2, 2) 
            $tall = $tall * 1024 * 1024
        }catch {}
    }elseif($StørrelseType -eq 'KB') {
        try {
            [int64]$tall = $tall.remove($tall.length -2, 2) 
            $tall = $tall * 1024
        }catch {}
    }

    return $tall 
}

Function Read-Tall
{
    [CmdletBinding(DefaultParameterSetName='NotNull')]
    param
    (
        # Parameter Prompt 
        [Parameter(Position=0)]
        [string]$Prompt = 'Skriv inn ett tall',

        # Parameter Default 
        [
            Parameter(Mandatory=$false,
            ParameterSetName='DefaultVerdi')
        ]
        [int64]$DefaultVerdi,

        # Parameter NullAllowed
        [
            Parameter(Mandatory=$false,
            ParameterSetName='NullAllowed')
        ]
        [switch]$NullAllowed,
        
        # Parameter NotNull 
        [
            Parameter(Mandatory=$false,
            ParameterSetName='NotNull')
        ]
        [switch]$NotNull
    )

    # Velger parameterset 
    switch($PSCmdlet.ParameterSetName)
    {
        # Setter returverdi til verdien spesifisert i parameter defaultverdi hvis inndata er null 
        'DefaultVerdi'
        {
            do
            {
                # Les inn tall 
                $Tall = Read-Host -Prompt $Prompt

                # Forsøk å konverter tall til bytes hvis det slutter på KB/MB/GB
                $tall = Convert-Size $tall 

                # Sett default verdi hvis bruker ikke skriver inndata
                if($tall.Length -eq 0) {$tall = $DefaultVerdi}

            # Løkken kjører så lenge valideringen ikke går igjennom
            }while ((Validate-Tall -Tall $tall) -eq $false) 
        }
        # Inndata kan være null 
        'NullAllowed'
        {
            do
            {
                # Les inn tall 
                $Tall = Read-Host -Prompt $Prompt

                # Setter tall til null hvis brukeren ikke har skrevet noe 
                if($tall.Length -eq 0) {$tall = $null}

            # Løkken kjører så lenge valideringen ikke går igjennom
            }while ((Validate-Tall -Tall $tall) -eq $false -or $tall -ne $null)   
        }
        # Inndata kan ikke være null 
        'NotNull'
        {
            do
            {
                # Les inn tall 
                $Tall = Read-Host -Prompt $Prompt 

            }while((Validate-Tall -Tall $tall) -eq $false -or $tall.Length -eq 0)    
        }
    }

    # Returner tall 
    return $Tall 

}



# Validerer at input er et tall 
<#
Function Validate-Int {
    param(
        [switch]$NotNull,
        [string]$prompt = '>',
        [int]$Default
    )

    
    # Les inndata
    $Int = Read-Host -Prompt $prompt

   do
   {
        $err = $false 


   }while($err -eq $true)

    # Sjekk at verdien er et gyldig tall
    do
    {
        $error = $false 

        # Hvis Null verdi er godtatt 
        if($NotNull)
        {
            if($Int -notmatch '^\d+$')
            {
                $Int = Read-Host "Tallet er ikke gyldig. Prøv på nytt" 
                $error = $true
            }

        }
        else
        {
            
            if($Int -notmatch '^\d+$' -and $Int.Length -ne 0)
            {
                $Int = Read-Host "Tallet er ikke gyldig. Prøv på nytt" 
                $error = $true
            }
        }
    } while ($error -eq $true)

    if(!$NotNull -and $int.Length -eq 0)
    {
        $int = $null
    }
    return $Int
}
#>
function Set-LinjeNummer 
{
    param (
        [parameter(mandatory=$true,
        ValueFromPipeline=$true)]
        [Object[]]$Objekt
    )


    begin {
        # Legger til linjenummer på objektet  
        $Nummer = 1
    }

    Process {

        # Gjennomgår hver rad i objekt 
        $Objekt | ForEach-Object {
            # Legger til linjenummer som egenskap for hver rad 
            Add-Member -InputObject $_ -MemberType NoteProperty `
            -Name Nummer -Value $Nummer

            # Inkrementerer linjenummer
            $Nummer++
        }
    }

    end {
        # Hvert objekt har nå et linjenummer 
        return $objekt 
    }
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

Function Select-Alternativ
{
    param(
        [parameter(mandatory,
        position=0)]
        [object[]]$Alternativer, 
        [string]$Prompt = '>',
        [int]$Default
    )


    $Alternativer = Set-LinjeNummer $Alternativer 
    
    write-host ($Alternativer| format-table |out-string)

    do {
        $Valg = read-Host -Prompt $Prompt
        if($valg.Length -eq 0 -and $Default -ne $null){
            $valg = $Default
        }
        $Valg = $Alternativer | where {$_.nummer -eq $Valg} 
    }while($valg -eq $null)

    return ($valg | Select-Object -ExpandProperty value)
}

Function Read-String
{
    param(
        [string]$Prompt = '>'
    )

    
    do {
        
        $err = $false 

        [string]$InnData = Read-Host -Prompt $Prompt

        if($InnData.Length -eq 0) {
            $err = $true 
            Write-Host 'Inndata kan ikke være null'
        }
    }while($err -eq $true)

    return $InnData
}

Function Select-EgenDefinertObjekt 
{
  <#
  .SYNOPSIS
  Henter ut objekt basert på verdien brukeren skriver inn.
  .EXAMPLE
  $Prosesser = Get-Process 
  $Valg = Select-EgenDefinertObjekt -Objekt $Prosesser -Parameter ProcessName -Prompt 'Skriv inn navnet på prosessen du ønsker å hente ut' 
  .PARAMETER objekt
  Objektsamling. 
  .PARAMETER parameter
  Bestemmer hvilket parameter som skal brukes for å hente ut objekt.
  .PARAMETER prompt
  Spesifiser tekst som skal vises når bruker skal skrive inn verdi
  #>
    [cmdletbinding()]
    param(
        [parameter(mandatory=$true,
        position=0)]
        $Objekt,
        [parameter(mandatory=$true,
        position=1)]
        [string]$Parameter,
        [String]$Prompt = '>'
    )

    Begin {}
    Process
    {
        do{
            $Valg = Read-Host $Prompt 
            $ValgtObjekt = $Objekt | where {$_.$parameter -eq $Valg}
        }while($ValgtObjekt -eq $null)        
    }
    End
    {
        return $ValgtObjekt
    }
}

Function Read-JaNei
{
 <#
 .SYNOPSIS
 Returnerer $true hvis bruker svarer 'j'
 Returnerer $false hvis bruker svarer 'n'
 #>
    [cmdletbinding()]
    param([string]$prompt = '>')

    do {
        $svar = read-host -Prompt $prompt
    }while($svar -ne 'j' -and $svar -ne 'n')

    if($svar -eq 'j') {$svar = $true}
    else {$svar -eq $false}

    return $svar 
}