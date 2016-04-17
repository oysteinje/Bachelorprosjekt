<#
# Modul for Active Directory 
#>

function Format-Brukernavn
{
    param([String]$brukernavn)

    #sett brukernavn til små bokstaver
    $brukernavn=$brukernavn.ToLower()
    
    #Erstatt æøå med eoa
    $brukernavn=$brukernavn.replace('æ','e')
    $brukernavn=$brukernavn.replace('ø','o')
    $brukernavn=$brukernavn.replace('å','a')
    
    #Returnere det formatere brukernavnet    
    return $brukernavn
} 

Function Set-Brukernavn
{
    param(
        [string]$Fornavn,
        [string]$Etternavn
    )

    # Setter midlertidig variabel til $null slik at den ikke inneholder noe fra tidligere 
    $midlertidigBrukernavn = $null 
    $sjekk = $true 
    
    # Hvis fornavn eller etternavn er på to bokstaver blir disse to brukt i brukernavnet istedet for tre bokstaver 
    if($fornavn.length -eq 2)
    {
        $brukernavn = $fornavn.substring(0,2) 
    }else
    {
        $brukernavn = $fornavn.substring(0,3)
    }
    

    if($etternavn.length -eq 2)
    {
        $brukernavn += $etternavn.substring(0,2) 
    }else
    {
        $brukernavn += $etternavn.substring(0,3)
    }

    # Telleren bli satt til en. Den skal brukes hvis brukernavnet allerede er i bruk
    $teller = 1

    # Bruker Format-Brukernavn
    $navn = Format-Brukernavn $brukernavn
    $MidlertidigBrukernavn = $navn

    do{
        # Sjekk om brukernavnet er i bruk. Hvis brukernavn ikke finnes er resultatet
        $finnes = Invoke-Command -Session $SesjonADServer -ScriptBlock {
            Get-ADUser -Filter * #{SamAccountName -eq $using:MidlertidigBrukernavn}
        }
        
        $finnes = $finnes | where {$_.SamAccountName -eq $MidlertidigBrukernavn}

        # Hvis brukernavnet ikker er i bruk 
        if($finnes -eq $null){
            $sjekk = $false
            $navn = $MidlertidigBrukernavn
        }else{
            # Hvis det er to like brukernavn vil teller bli lagt til slutten av
            # brukernavnet for å skille de.
            $MidlertidigBrukernavn = $navn + $teller 
            
            #inkrementerer teller slik at en får et annet brukernavn neste gang.
            $teller +=1
        }
    }while($sjekk -eq $true)
    
    return $navn
} 

# Oppretter en ny AD bruker
Function New-ADBruker
{   
   
    # Skriv inn fornavn 
    $fornavn = Read-Host "Skrv inn brukerens fornavn" 
        
    # Skriv inn etternavn 
    $etternavn = Read-Host "Skriv inn brukerens etternavn" 

    # Sjekk at fornavn og etternavn ikke er for kort 
    do
    {
        $err = $false
        if($Fornavn.Length -lt 2)
        {
            $Fornavn = Read-Host `
             -prompt 'Fornavnet må minst være på to bokstaver. Skriv inn fornavn på nytt'
             $err = $true
        }

        if($Etternavn.Length -lt 2)
        {
            $Etternavn = Read-Host `
            -Prompt 'Etternavnet må være på minst to bokstaver. Skriv inn etternavn på nytt'
            $err = $true
        }
    }while($err -eq $true)
   
    # Opprett fullt ut fra fornavn og etternavn 
    $fulltNavn = "$fornavn $etternavn"  

    # Skriv inn e-post 
    $epost = Read-Host "Skriv inn brukerens e-post" 
        
    # Sett et unikt brukernavn 
    $brukernavn = Set-Brukernavn $fornavn $etternavn
        
    # Ta bort mellomrom ol. 
    $brukernavn = $brukernavn.Trim() 
    
    # Les inn og konverter passordet over til sikker tekst 
    $passord = Read-Host "Skriv inn brukerens passord:" -AsSecureString
    $passord = ConvertTo-SecureString $passord -AsPlainText -Force 
        
    # Forsøk å opprett AD bruker 
    Invoke-Command -Session $SesjonADServer -ScriptBlock {
        try
        {    
            New-ADUser  -SamAccountName $using:brukernavn `
                        -UserPrincipalName $using:brukernavn `
                        -Name $using:fulltNavn `
                        -Surname $using:etternavn `
                        -AccountPassword $using:passord `
                        -ChangePasswordAtLogon $true `
                        -EmailAddress $using:epost `
                        -Enabled $true

            Write-Host "Brukeren $brukernavn er opprettet" -ForegroundColor Green
            sleep -Seconds 2 
        }catch{
            Write-Host $_.Exception.Message -ForegroundColor red
        }
    }
}

# Scriptet oppretter brukere fra CSV fil 
#
# Fungerer følgende: 
# Hent inn CSV fil, hent ut informasjon fra CSV fil, opprett og valider brukernavn, opprett bruker 
#
# Format 
# Fornavn;Etternavn;OU;Passord;epost;
#
# Eksempel 
# Loyd;Hebump;OU=Administrasjon,OU=GaMe,DC=grp14,DC=local;aannoo8899;loyheb@game.no;

Function New-ADBrukerCSV 
{

    do {
        # Dialogboks for å åpne CSV-fil 
        $csvFil = New-Object System.Windows.Forms.OpenFileDialog
        $csvFil.Filter = "csv files (*.csv)|*.csv|txt files (*.txt)|*.txt|All files (*.*)|*.*"
        $csvFil.Title = "Åpne opp CSV fil som inneholder brukere"
        $csvFil.ShowDialog()
    }until ($csvFil.FileName -ne "")

    # Importer brukere fra CSV
    $brukere = Import-Csv $csvFil.FileName -Delimiter ";"
    write-host 'csv importert'

    # Gå igjennom alle brukere 
    foreach ($bruker in $brukere) {

        # Konvert passord over til sikker tekst 
        $passord = ConvertTo-SecureString $bruker.Passord -AsPlainText -Force 
        # Hent ut etternavn 
        $etternavn = $bruker.Etternavn 
        # Hent ut fornavn 
        $fornavn = $bruker.Fornavn 
        # Hent ut epost 
        $epost = $bruker.Epost 
        # Hent ut OU-sti 
        $OU = $bruker.OU 

        # Sett et unikt brukernavn 
        [String]$brukernavn = Set-Brukernavn $fornavn $etternavn 
        # Ta bort mellomrom ol. 
        $brukernavn = $brukernavn.Trim() 
        # Opprett fullt navn ut fra fornavn og etternavn 
        $fulltNavn = $fornavn + " " + $etternavn
        
        # Opprett bruker 
        Invoke-Command -Session $SesjonADServer -ScriptBlock {
            Try {
                New-ADUser  -SamAccountName $using:brukernavn `
                            -UserPrincipalName $using:brukernavn `
                            -Name $using:fulltNavn `
                            -Surname $using:etternavn `
                            -AccountPassword $using:passord `
                            -ChangePasswordAtLogon $using:true `
                            -EmailAddress $using:epost `
                            -Enabled $true
                            #-Path $using:OU

                Write-Host "Brukeren $using:brukernavn er opprettet" -ForegroundColor Green
            }catch{
                Write-Host $_.Exception.Message 
            }
        }
    }
}

# Skriver ut alle aktive AD brukere
Function Write-ADAktivBruker
{
    $brukere = Invoke-Command -Session $SesjonADServer `
                -ScriptBlock {
                    get-aduser -filter *
                } | where {$_.enabled -eq $true}

    Write-Host ($brukere | Format-Table `
        -Property userprincipalname, name, enabled | out-string)
        
    read-host 'Trykk enter for å fortsette. . .'           
}
# Skriver ut alle deaktiverte AD brukere
Function Write-ADDeaktivBruker
{
    $brukere = Invoke-Command -Session $SesjonADServer `
                -ScriptBlock {
                    get-aduser -filter *
                } | where {$_.enabled -eq $false}
    
    Write-Host ($brukere | Format-Table `
        -Property userprincipalname, name, enabled | Out-String)

    read-host 'Trykk enter for å fortsette. . .'
}
# Skriver ut alle AD brukere i innsendt objekt
Function Write-ADBruker
{
    param($bruker)

    # Legg til linjenummer 
    Set-LinjeNummer $bruker 
    
    Write-Host ($bruker | Format-Table `
        -Property nummer, @{expression={$_.UserPrincipalName};Label='UserName'}, `
        name, enabled | out-string) #DistinguishedName,
}


Function Find-ADBruker
{
    #Write-Host `
    $Hjelp = 
    'Søk etter brukere. Velg én eller flere brukere
    Ved å skrive nummeret etterfulgt av komma. [f.eks. 2,5].
    Skriv ut dette ved å skrive ?!
    Avslutt søk ved å skrive x!
    Når du er ferdig, skriv f!'
    
    write-host $Hjelp

    [object[]]$ValgteBrukere = $null

    do 
    {
        $avslutt = $false 
        [int]$tall = $null                
        
        # Skriver ut valgte brukere
        if($ValgteBrukere -notlike $null)
        {
            # Fjerner doble forekomster
            $ValgteBrukere = $ValgteBrukere | Sort -Property userprincipalname -Unique

            [string]$ut = $ValgteBrukere.userprincipalname
            $ut = $ut.Replace(' ', ',')
            Write-Host "Du har valgt: $ut" 
        }

        $SøkeTekst = Read-Host '>'

        # Sjekker søkeord 

        if($SøkeTekst.Length -eq 2 -and $SøkeTekst -eq 'x!')
        {
            # Avslutt søk
            Write-Warning 'Avbryter. . .' 
            return $null 
        }
        elseif($SøkeTekst.Length -eq 2 -and $SøkeTekst -eq 'f!')
        {            
            # Returnerer valgte brukere
            return $ValgteBrukere
        }
        elseif($SøkeTekst.Length -eq 2 -and $SøkeTekst -eq '?!')
        {
            write-host $Hjelp 
        }
        # Tester om brukeren har skrevet inn tall         
        # Hvis det er valgt kun ett objekt 
        elseif([int32]::TryParse($SøkeTekst,[ref]$tall))
        {
            # Velg objekter
            Write-Host 'Velger ett objekt'
            [object[]]$ValgteBrukere += $resultat | where{$_.nummer -eq $SøkeTekst}      
        }
        elseif($SøkeTekst.Contains(','))
        {
            $SøkeTekst = $SøkeTekst.Split(',') | %{$_.Trim()}            
            [object[]]$ValgteBrukere += $resultat | where{$_.nummer -in $SøkeTekst}            
        }
        else
        {
            # Hent ut alle brukere
            $resultat = Invoke-Command -Session $SesjonADServer -ScriptBlock {
                Get-ADUser -Filter *
            } 

            # Finn brukere som matcher søketekst 
            $resultat = $resultat | where {$_.userprincipalname -match $SøkeTekst}

            # Skriver ut resultat  
            if($resultat -notlike $null)
            {
                Write-ADBruker $resultat | out-null
            }
            else
            {
                Write-Host 'Ingen treff i søk'
            }            
        }
    }while($avslutt -eq $false)
}


Function Set-ADBruker
{
    param
    (
        [switch]$Passord,
        [switch]$Aktiver,
        [switch]$Deaktiver,
        [switch]$Brukernavn
    )

    # Søk etter brukere og hent ut valgte brukere
    $brukere = Find-ADBruker
    
    # Setter nytt passord for valgte brukere
    if($passord -and $brukere -notlike $null)
    {
        $NyttPassord = Read-Host -Prompt 'Skriv inn nytt passord' -AsSecureString
        Invoke-Command -Session $SesjonADServer -ScriptBlock {
            $using:Brukere.objectguid | Set-ADAccountPassword `
            -Reset -NewPassword $using:NyttPassord
        }
        write-host 'Passord er endret' -ForegroundColor Green
        sleep -Seconds 3
    }
    elseif($Aktiver -and $brukere -notlike $null)
    {
        Invoke-Command -Session $SesjonADServer -ScriptBlock {
            $using:brukere.objectguid | Set-ADUser -Enabled $true
        }
        write-host 'Brukerne er nå aktiverte'
        sleep -Seconds 3
    }
    elseif($Deaktiver -and $brukere -notlike $null)
    {
        Invoke-Command -Session $SesjonADServer -ScriptBlock {
            $using:brukere.objectguid | Set-ADUser -Enabled $false
        }
        write-host 'Brukerne er nå deaktiverte'
        sleep -Seconds 3
    }
    elseif($Brukernavn -and $brukere -notlike $null)
    {
        foreach($bruker in $brukere)
        {
            $userprincipalname = $bruker.userprincipalname 
            $NyttUserPName = Read-Host "Skriv nytt brukernavn for $userprincipalname"
            # Sjekker at brukernavn ikke eksisterer 
            do
            {
                $Godkjent = $true
                
                $sjekk = Invoke-Command -Session $SesjonADServer -ScriptBlock {
                    Get-ADUser -Filter *
                } | where {$_.userprincipalname -eq $NyttUserPName}

                if($sjekk -notlike $null)
                {
                    Write-Warning 'Brukernavnet eksisterer allerede. Prøv et annet'
                    $godkjent = $false 
                }
            }while($Godkjent -eq $false)

            # Setter nytt brukernavn
            try
            {
                Invoke-Command -Session $SesjonADServer -ScriptBlock {
                    Set-ADUser `
                        -Identity $using:bruker.objectguid `
                        -UserPrincipalName $using:NyttUserPName `
                        -SamAccountName $using:NyttUserPName
                }

                Write-Host 'Brukernavn endret' -ForegroundColor Green
            }catch{
                Write-Host $_.Exception.Message -ForegroundColor Red
            }

            sleep -Seconds 2
        }
    }   
}


# Oppretter ny AD gruppe
Function New-ADGruppe
{
    param
    (
        [switch]$FraFil
    )

    if($FraFil)
    {
        do {
            # Dialogboks for å fil
            $TekstFil = New-Object System.Windows.Forms.OpenFileDialog
            $TekstFil.Filter = "txt files (*.txt)|*.txt"
            $TekstFil.Title = "Åpne opp fil som inneholder navneliste med grupper"
            $TekstFil.ShowDialog()
        }until ($TekstFil.FileName -ne "")

        # Importer brukere fra tekstfil
        $Name = Get-Content $TekstFil.FileName
        
    }
    else
    {
        # Les inn verdier 
        [string[]]$Name = (Read-Host 'Skriv inn navn. Skill med komma for å opprette flere').Split(',') | %{$_.Trim()}  
        $Description = Read-Host 'Gruppens beskrivelse. Denne kan stå tom'
    }
    

    # Velg scopes
    $GroupScope = Get-Valg $('DomainLocal','Global', 'Universal') 'Velg GroupScope'
    
    # Hent ut alle grupper 
    $AlleGrupper = Invoke-Command -Session $SesjonADServer -ScriptBlock {
        Get-ADGroup -filter *
    }
    
    # Sjekk om gruppenavn ikke ekisterer fra før og opprett gruppe
    foreach ($n in $Name)
    {
        do
        {
            $Godkjent = $true 
            if($n -in $AlleGrupper.name)
            {
                # Ber brukeren skrive et annet gruppenavn
                $n = Read-Host "Gruppen $n finnes allerede. Skriv et annet"
                $godkjent = $false
            }
        }while($Godkjent -eq $false)

        # Opprett gruppe
        Invoke-Command -Session $SesjonADServer -ScriptBlock {
            New-ADGroup -name $using:n -GroupScope $using:groupscope 
        }

        Write-Host "Gruppen $n er opprettet"
    }

    sleep -Seconds 3
}

Function Write-ADGruppe
{
    param
    (
        [parameter(mandatory)]$Gruppe
    )

    # Legg til linjenummer
    Set-LinjeNummer $Gruppe | Out-Null

    # Skriv ut gruppe
    Write-Host ($Gruppe | Format-Table -AutoSize `
        -Property nummer,name,groupscope | Out-String)
}
Function Find-ADGruppe
{
    #Write-Host `
    $Hjelp = 
    'Søk etter grupper.
    Skriv ut dette ved å skrive ?!
    Avslutt søk ved å skrive x!
    Velg ved å skrive nummer
    Fjern val ved å skrive r!
    Skriv f! når du er ferdig med å velge'
    
    write-host $Hjelp

    [object[]]$ValgtGruppe = $null

    do 
    {
        $avslutt = $false 
        [int]$tall = $null                
        
        # Skriv ut valgte grupper
        if($ValgtGruppe -notlike $null)
        {
            # Fjerner doble forekomster
            $ValgtGruppe = $ValgtGruppe | Sort -Property name -Unique

            [string]$ut = $ValgtGruppe.name
            $ut = $ut.Replace(' ', ',')
            Write-Host "Du har valgt: $ut" 
        }

        $SøkeTekst = Read-Host '>'

        # Avslutter
        if($SøkeTekst.Length -eq 2 -and $SøkeTekst -eq 'x!')
        {
            # Avslutt søk
            Write-Host 'Avbryter. . .' -ForegroundColor Yellow
            return $null 
        }
        # Ferdigstiller valg
        elseif($SøkeTekst.Length -eq 2 -and $SøkeTekst -eq 'f!')
        {            
            # Returnerer valgte brukere
            return $ValgtGruppe
        }
        # Rensker alle valg
        elseif($SøkeTekst.Length -eq 2 -and $SøkeTekst -eq 'r!')
        {            
            $ValgtGruppe = $null
        }
        # Skriver ut hjelp
        elseif($SøkeTekst.Length -eq 2 -and $SøkeTekst -eq '?!')
        {
            write-host $Hjelp 
        }
        # Tester om brukeren har skrevet inn tall. Henter ut gruppe om det er tilfellet.      
        elseif([int32]::TryParse($SøkeTekst,[ref]$tall))
        {
            # Velg objekter
            [object[]]$ValgtGruppe += $resultat | where{$_.nummer -eq $SøkeTekst}      
        }
        # Tester om brukeren har foretatt flere valg
        elseif($SøkeTekst.Contains(','))
        {
            $SøkeTekst = $SøkeTekst.Split(',') | %{$_.Trim()}            
            [object[]]$ValgtGruppe += $resultat | where{$_.nummer -in $SøkeTekst}            
        }
        # Foretar søk
        else
        {
            # Hent ut alle grupper
            $resultat = Invoke-Command -Session $SesjonADServer -ScriptBlock {
                Get-ADGroup -Filter *
            } 

            # Finn grupper som matcher søketekst 
            $resultat = $resultat | where {$_.name -match $SøkeTekst}

            # Skriver ut resultat  
            if($resultat -notlike $null)
            {
                Write-ADGruppe $resultat
            }
            else
            {
                Write-Host 'Ingen treff i søk'
            }            
        }
    }while($avslutt -eq $false)
}

Function Set-ADGruppe
{
    param
    (
        [switch]$Navn,
        [switch]$Scope,
        [switch]$Slett
    )

    # Hent ut én eller flere grupper
    $Gruppe = Find-ADGruppe

    if($Navn -and $Gruppe -notlike $null)
    {
        # Hent inn alle grupper
        $EksisterendeGrupper = Invoke-Command -Session $SesjonADServer -ScriptBlock {
                    Get-ADGroup -Filter *
        }
        
        [string[]]$NavneSamling

        foreach($g in $Gruppe)
        {
            # Skriv nytt navn 
            $NyttNavn = Read-Host "Skriv nytt navn for gruppe " $g.name
            
            # Sjekk at navn ikke eksisterer 
            while($nyttNavn -in $EksisterendeGrupper.name -or $NyttNavn -in $NavneSamling -or $NyttNavn -eq $null)
            {
                $NyttNavn = Read-Host `
                     "Navnet på gruppen $NyttNavn eksisterer allerede. Skriv et annet"
            }

            # Gjennomfører endring
            Invoke-Command -Session $SesjonADServer -ScriptBlock {
                Rename-ADObject -Identity $using:g.ObjectGUID -NewName $using:NyttNavn
            }

            # Skriv ut endring til brukeren
            Write-Host $g.name " er endret til " $NyttNavn -ForegroundColor Green

            # Brukes for å sjekke at bruker ikke skriver like gruppenavn
            $NavneSamling += $NyttNavn
        }

        sleep -seconds 2
    }
    # Endre gruppescope for AD gruppe
    elseif($Scope -and $Gruppe -notlike $null)
    {
        foreach($g in $gruppe)
        {
            Write-Host "Gruppen " $g.name" har sco "$g.groupscope
            $NyttScope = Get-Valg $('DomainLocal', 'Global', 'Universal') "Velg nytt scope"

            # Må først endre til universal for å endre fra global til local eller vice versa
            if(($g.groupscope -eq 'domainlocal' -and $NyttScope -eq 'global') -or `
            ($NyttScope -eq 'domainlocal' -and $g.groupscope -eq 'global'))
            {
                $GlobTilFraLocal = $true
            }

            # Utfør endring
            Invoke-Command -Session $SesjonADServer -ScriptBlock {
                if($using:GlobTilFraLocal) 
                {
                    Set-ADGroup -Identity $using:g.ObjectGuid -GroupScope 'universal'
                }
                Set-ADGroup -Identity $using:g.ObjectGuid -GroupScope $using:NyttScope
            }

            # Skriv ut endring
            Write-Host "Gruppe " $g.name " har endret scope fra " $g.groupscope " til " $NyttScope
        }
        sleep 3      
    }
    elseif($Slett -and $Gruppe -notlike $null)
    {

    }
}


