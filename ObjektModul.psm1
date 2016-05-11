$cred = Get-Credential $cred


Function Connect-Sesjoner
{
    param
    (
        [hashtable[]]$Servere,
        $Credentials
    )

    # Fjerner alle ødelagte sesjoner 
    (Get-PSSession | where {$_.state -match 'Broken'}) | Remove-PSSession

    foreach($server in $servere)
    {
        # Henter sesjonen 
        $sesjon = Get-PSSession | where {$_.Name -match $server.get_item('NAVN')}

        if($sesjon -eq $null)
        {   
            New-PSSession -ComputerName $server.get_item('IP') -port $server.get_item('PORT') -Name $server.get_item('NAVN') -Credential $Credentials -Verbose
        }else
        {            
             $sesjon | Connect-PSSession | Out-Null
        }
        
        $sesjon = $null   
    }
}



# Importer ServerManager modulen fra Virtuell Router
#if ((Get-Command "$PrefixVRouter`Get-WindowsFeature" -ErrorAction SilentlyContinue) -eq $null) 
#{
#    Write-Host "Laster inn moduler fra Hyper-V server. Vennligst vent. . ." -ForegroundColor Cyan
#    Invoke-Command -Session $SesjonVRouter -ScriptBlock {Import-Module ServerManager} -Verbose
#    Import-PSSession -Session $SesjonVRouter -Module ServerManager -Verbose -Prefix $PrefixVRouter
#}


# Henter ut ett eller flere objekter fra objekt 
function Get-Objekt
{
    param(
        [parameter(mandatory)]
        $objekt
    )

    $ValgtObjekt = $null 

    do
    {
        # Velg alternativ 
        $valg = (Read-Host "Velg et alternativ fra listen").split(“,”) | %{$_.trim()} 

        #$wshell = New-Object -ComObject Wscript.Shell
        #$wa = $valg.Length
        #$wshell.Popup("$wa ",0,"Done",0x1)

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

# Funksjonen bestemmer hvilke egenskaper som skal vises ved utdata når ikke annet er spesifisert
function Set-StandardUtData
{
    param 
    (
        [parameter(mandatory)]
        $Objekt,
        
        [parameter(mandatory)]
        [string[]]$defaultDisplaySet
        
    )
    
    $defaultDisplayPropertySet  = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
    
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    
    foreach ($o in $Objekt)
    {
        Add-Member -InputObject $o -MemberType MemberSet -name PSStandardMembers -Value $PSStandardMembers -Force
    }
    

    return $Objekt 

}

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
    return $objekt 
}

function Add-Reaksjon
{
    param(
        [object[]]$rObjekt,
        $reaksjon
    )
   
    return ($rObjekt | Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {$reaksjon} -PassThru)
}

function Set-MaksimumVirtueltMinne 
{
    Read-Host "Skriv inn minne"
    write-host (Get-VMMemory  -VMName * | ft name)
}

function Hent-VirtuelleMaskinerMinne 
{
   $vms = get-vm
   return $vms 
}

function Get-EndreVirtueltMinne
{
 
    [pscustomobject]@{'Nummer'=1; 'Alternativ'='Aktiver Dynamisk Minne'; 'Flervalg'=$false} |
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru

    [pscustomobject]@{'Nummer'=2; 'Alternativ'='Deaktiver Dynamisk Minne'; 'Flervalg'=$false} |
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru
    
    [pscustomobject]@{'Nummer'=3; 'Alternativ'='Sett Virtuelt Oppstartsminne'; 'Flervalg'=$false} |
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru        

    [pscustomobject]@{'Nummer'=4; 'Alternativ'='Sett Maksimum Virtuelt Minne'; 'Flervalg'=$false} |
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Set-MaksimumVirtueltMinne;Hent-VirtuelleMaskinerMinne} -PassThru   

    [pscustomobject]@{'Nummer'=5; 'Alternativ'='Sett Minimum Virtuelt Minne'; 'Flervalg'=$false} |
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru   

    <#
    # Henter ut minne for virtuelle maskiner 
    $vms = Get-VMMemory -VMName * 
    
    # Legger til flervalg lik true 
    foreach ($v in $vms)
    {
        #add-member -InputObject $v -MemberType NoteProperty -name Flervalg -Value $false 
    }

    # Legger til linjenummer i objekt 
    $vms = Add-LinjeNummer $vms 
    
    # Legg til reaksjon
    $vms = Add-Reaksjon -rObjekt $vms -reaksjon 'tom'

    # Sett standardverdier som skal vises når objektet skrives ut 
    $vms = Set-StandardUtData $vms "nummer", "vmname", "flervalg", "reaksjon"

    # Returner objekt med virtuelle maskiner 
    return $vms
    #>
}

function Get-AdministrerVirtuelleMaskiner
{
    [pscustomobject]@{'Nummer'=1; 'Alternativ'='Endre Virtuelt Minne'; 'Flervalg'=$false} |
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Get-EndreVirtueltMinne} -PassThru

    [pscustomobject]@{'Nummer'=2; 'Alternativ'='Endre Størrelse på Virtuell Harddisk'; 'Flervalg'=$false} |
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru

    [pscustomobject]@{'Nummer'=3; 'Alternativ'='Opprett Virtuell Maskin'; 'Flervalg'=$false} |
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru

    [pscustomobject]@{'Nummer'=4; 'Alternativ'='Opprett Virtuell Harddisk'; 'Flervalg'=$false} |
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru
}

Function Prompt-JaNei
{
   param
   (
    $Tittel,
    $Beskjed 
   )

    $ja = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"

    $nei = New-Object System.Management.Automation.Host.ChoiceDescription "&No"

    $alternativer = [System.Management.Automation.Host.ChoiceDescription[]]($ja, $nei)

    $resultat = $host.ui.PromptForChoice($tittel, $beskjed, $alternativer, 0) 
    Write-Output $resultat
    return $resultat
}

function Get-Scope 
{
    # Hent ut scopes fra DHCP Server
    $scope = Invoke-Command -Session $SesjonVRouter `
            -ScriptBlock {Get-DhcpServerv4Scope}
    
    # Returner scopes
    return $scope
}
# Henter ut alle scopes
function Write-Scope
{
    # Objektet som skal returneres 
    $ReturnObjekt = Get-DHCPValg
    
    # Henter ut scopes fra server
    $scope = Get-Scope
    
    if($scope -notlike $null)
    {
        # Rensker skjermen
        Clear-Host

        # Skriver ut scopes
        Write-Host ($scope | ` 
                Format-Table -AutoSize `
                -Property SubnetMask, Name, State, StartRange, `
                EndRange, LeaseDuration | `
                out-string) 

        # Lar brukeren trykke enter før den blir sendt tilbake til tidligere meny    
        Read-Host -prompt 'Trykk [Enter] for å fortsette'
    }else
    {
        # Rydder skjermen 
        Clear-Host
        # Skriver ut tekst 
        Write-Host 'Det finnes ingen scopes på serveren'
        # Lar brukeren se teksten i fire sekunder 
        sleep -Seconds 4 
    }


    # Returner objekt som skal vises 
    return $ReturnObjekt
}

# Starter funksjonen som kalte denne funksjonen på nytt
function Invoke-FunksjonPåNytt
{ 
    param($FunksjonNavn)
    
    # Navn på gjeldende funksjon kan hentes med $MyInvocation.MyCommand 
    # I.e. denne kan brukes når du kaller funksjonen

    # Kjør funksjon
    & $FunksjonNavn
}

# Oppretter et scope 
function New-Scope
{
    # Lar brukeren skrive inn verdier 
    $StartRange = Read-Host "Start range"
    $EndRange = Read-Host "End range"
    $SubnetMask = Read-Host "Nettmaske"
    $Name = Read-Host "Navn på scope"
    $LeaseDuration = Read-Host "Lease Duration [timer:minutter:sekunder]"

    # Setter default leaseverdi
    if($LeaseDuration.GetType().FullName -notmatch 'System.TimeSpan') 
    {
        [timespan]$LeaseDuration = '08:00:00'
    }
echo "oopdas `" das "

    # Oppretter skope på DHCP server 
    $resultat = Invoke-Command -Session $SesjonVRouter `
    -ScriptBlock `
    {
        try {
             Add-DhcpServerv4Scope `
              -StartRange $using:startrange `
              -EndRange $using:endrange `
              -SubnetMask $using:subnetmask `
              -Name $using:name `
              -LeaseDuration $using:LeaseDuration

              Write-Host 'Scope opprettet'
        }catch{
               #Write-Host 'Feil i inndata. Prøv på nytt' -ForegroundColor Red
               Write-Host $_.Exception.Message -ForegroundColor Red
               sleep -Seconds 4
               return $false 
        }
    }

    if($resultat -eq $false)
    {
        return Get-DHCPValg
    }else
    {
        # Lister ut alle scopes på serveren
        return Write-Scope
    }

}
# Sletter scope 
function Delete-Scope
{
    # Hent ut alle scopes fra DHCP Server 
    $scopes = Get-Scope

    # Legg på linjenummer
    $scopes = Set-LinjeNummer $scopes
    
    # List ut alle scopes  
    write-host ($scopes | ft -AutoSize `
                -Property Nummer, SubnetMask, Name, State, `
                StartRange, EndRange, LeaseDuration | out-string)

    # Velg ett eller flere scopes 
    $Valg = Get-Objekt $scopes

    # Slett scopes 
    Invoke-Command -Session $SesjonVRouter -ScriptBlock `
    {
        $s = $using:Valg
        try {
            $s | Remove-DhcpServerv4Scope
            Write-Host "Scope er opprettet"
        }catch {
            Write-Host $_.Exception.Message -ForegroundColor red
        }
    }

    # Lister ut alle scopes på serveren
    return Write-Scope
}
# Aktiverer ett scope 
function Set-Scope
{
    param([switch]$Aktiver)
    
    # Avgjør om scope skal aktiveres eller ei
    $State = 'InActive'
    if($Aktiver)
    {
        $State = 'Active'
    }

    # Hent scopes 
    $scopes = get-scope 

    # Legg til linjenummer 
    $scopes = Set-LinjeNummer $scopes 

    # Skriv ut scopes 
    write-host ($scopes | `
        ft nummer, name, startrange, endrange, netmask, state | out-string)

    # Velg scope 
    $Valg = Get-Objekt $scopes

    # Aktiver Scope 
    Invoke-Command -Session $SesjonVRouter -ScriptBlock `
    {
        write-host $using:state
        $using:valg | Set-DhcpServerv4Scope -State $using:State -verbose
    }

    # Skriv ut at scope er aktivert
    Write-Host "Endringen er gjennomført. Du blir nå sendt tilbake til menyen"
    sleep -Seconds 2
    
    # Vis alle scopes
    return Write-Scope 
}

Function Get-DHCPValg
{
    $ReturObjekt = 
    ([pscustomobject]@{'Nummer'=1; 'Alternativ'='Vis scopes'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Write-Scope} -PassThru),
    
    ([pscustomobject]@{'Nummer'=2; 'Alternativ'='Nytt scope'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {New-Scope} -PassThru),
    
    ([pscustomobject]@{'Nummer'=3; 'Alternativ'='Slett scope'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Delete-Scope} -PassThru),

    ([pscustomobject]@{'Nummer'=4; 'Alternativ'='Aktiver scope'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Set-Scope -aktiver} -PassThru),

    ([pscustomobject]@{'Nummer'=5; 'Alternativ'='Deaktiver scope'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Set-Scope} -PassThru)

    Write-Host "Sjekker at DHCP er satt opp" -ForegroundColor Cyan

    $DhcpFeature = Invoke-Command -Session $SesjonVRouter `
                    -ScriptBlock {Get-WindowsFeature dhcp}

    # Installer DHCP hvis det ikke eksisterer 
    if ($DhcpFeature.installed -eq $false)
    {
        
        # Spør om DHCP skal installeres
        switch( (Prompt-JaNei -Tittel 'Installer DHCP' -Beskjed 'Du har ikke DHCP installert. Ønsker du å installere?'))
        {
            # Ja
            0{
                Invoke-Command -Session $SesjonVRouter -ScriptBlock {Install-WindowsFeature -name DHCP, RSAT-DHCP -Verbose -confirm -IncludeManagementTools | Out-Null}
                return $ReturObjekt
            }
            
            # Nei
            1{ 
                # Returner tidligere objekt i.e. send brukeren tilbake
                return Get-ObjKonfigurerDHCP 
            }
        }
        
    }
    
    # Returner objekt
    return $ReturObjekt
}

Function Get-ObjKonfigurerDHCP
{
    [pscustomobject]@{'Nummer'=1; 'Alternativ'='Konfigurer DHCP'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Get-DHCPValg} -PassThru
}

Function Get-ObjVirtuellRouter
{
    [pscustomobject]@{'Nummer'=1; 'Alternativ'='Virtuell Router'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Get-ObjKonfigurerDHCP} -PassThru
}

function Format-Brukernavn
{
    param([String]$String)

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
        $null
        $finnes = Invoke-Command -Session $SesjonADServer -ScriptBlock {
            Get-ADUser -Filter {SamAccountName -eq $MidlertidigBrukernavn}
        }
        
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
        
    # Sett et unit brukernavn 
    [String]$brukernavn = Set-Brukernavn $fornavn $etternavn
        
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
    
    # Sendes tilbake til meny 
    return Get-ObjOpprettBrukere
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
    
    # Sendes tilbake til meny 
    return Get-ObjOpprettBrukere
}

Function Get-ObjOpprettBrukere
{
    [pscustomobject]@{'Nummer'=1; 'Alternativ'='Opprett bruker manuelt'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {New-ADBruker} -PassThru    
    [pscustomobject]@{'Nummer'=2; 'Alternativ'='Opprett brukere fra CSV'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {New-ADBrukerCSV} -PassThru
}

Function Write-ADBruker
{
    param
    (
        [Object[]]$Brukere
    )
    # List ut AD brukere
 
    #$Resultat = Set-LinjeNummer $Brukere

    Write-Host ($Resultat | ft -autosize `
                -Property Nummer, userPrincipalName, Enabled, Name, SamAccountName | `
                out-string)

    #return $Resultat
}

Function Find-ADBruker
{

    $Hjelp = "Søk etter brukere. La stå tom for å liste ut alle.
    `nKommando           Beskrivelse
    `n!avbryt            Går tilbake til meny
    `n!ferdig            Går videre
    `n!velg              Bruk nummer for å velge brukere. [F.eks :velg 2,3,5]
    `n!?                 Lister ut denne hjelpemenyen
    "

    Write-Host $Hjelp  

    do
    {
        $Søk = $true 

        # Les inndata 
        [String]$SøkeTekst = Read-Host -Prompt ">"

        if($SøkeTekst.Substring(0,5) -match '!velg')
        {
            # Velg brukere
            #Get-Objekt $Resultat

        }elseif($SøkeTekst.Substring(0,7) -match '!ferdig')
        {
            # Utfør endring 

        }elseif($SøkeTekst.Substring(0,7) -match '!avbryt')
        {
            # Avbryt 
            $Søk = $false
            $Resultat = $null
        }else
        {
            # Utfør søk
            
            $Resultat = Invoke-Command -Session $SesjonADServer -ScriptBlock {
                Get-ADUser -Filter {UserPrincipalName -like '*'}
            }
            
            # Finner alle brukere som matcher søkeord 
            $Resultat = $Resultat | where {$_.UserPrincipalName -match $SøkeTekst}
            
            if($Resultat -notlike $null) 
            {
                # Legger til linjenummer 
                #$Resultat = Set-LinjeNummer $Resultat

                # Skriver ut brukere
                #Write-ADBruker $Resultat
                #write-host ($resultat | ft name | out-string)

            }else
            {
                Write-Host 'Ingen treff i søk'
            }
        }
        
    }while($Søk -eq $true)

   return $resultat
}

Function Set-ADBruker
{
    param
    (
        [Switch]$Passord,
        [Switch]$Aktiver,
        [Switch]$Deaktiver,
        [Switch]$EndreBrukerNavn
    )

    # Søk etter bruker
    $Brukere = Find-ADBruker

    if($Passord -and $brukere -notlike $null)
    {
        $NyttPassord = Read-Host -Prompt 'Skriv inn nytt passord'
        $NyttPassord = ConvertTo-SecureString -String $NyttPassord -AsPlainText -Force
        Invoke-Command -Session $SesjonADServer -ScriptBlock {
            $using:Brukere | Set-ADAccountPassword -Reset -NewPassword $using:NyttPassord
        }
        write-host 'Passord er endret' -ForegroundColor Green
        sleep -Seconds 3
    }

    return Get-ObjModifiserBrukere
}
Function Get-ObjModifiserBrukere
{
    [pscustomobject]@{'Nummer'=1; 'Alternativ'='Endre passord for bruker'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Set-ADBruker -passord} -PassThru
    [pscustomobject]@{'Nummer'=2; 'Alternativ'='Aktiver bruker'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Set-ADBruker -Aktiver} -PassThru
    [pscustomobject]@{'Nummer'=3; 'Alternativ'='Deaktiver bruker'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Set-ADBruker -Deaktiver} -PassThru
    [pscustomobject]@{'Nummer'=4; 'Alternativ'='Endre brukernavn'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Set-ADBruker -EndreBrukerNavn} -PassThru
}
Function Get-ObjBrukerKontoer
{
    [pscustomobject]@{'Nummer'=1; 'Alternativ'='Opprett brukere'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Get-ObjOpprettBrukere} -PassThru
    [pscustomobject]@{'Nummer'=2; 'Alternativ'='Søk opp og modifiser brukere'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Get-ObjModifiserBrukere} -PassThru
    [pscustomobject]@{'Nummer'=3; 'Alternativ'='List ut alle deaktiverte brukere'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Write-Deaktiverte} -PassThru
    [pscustomobject]@{'Nummer'=4; 'Alternativ'='List ut alle aktive brukere'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Write-Aktiverte} -PassThru
    [pscustomobject]@{'Nummer'=5; 'Alternativ'='List ut gruppemedlemskap for bruker'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Get-GruppeMedlemskap} -PassThru
}
Function Get-ObjActiveDirectory
{
    [pscustomobject]@{'Nummer'=1; 'Alternativ'='Brukerkontoer'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Get-ObjBrukerKontoer} -PassThru 
    
    [pscustomobject]@{'Nummer'=2; 'Alternativ'='Arbeidsstasjoner'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {''} -PassThru  

    [pscustomobject]@{'Nummer'=3; 'Alternativ'='Grupper'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {''} -PassThru  

    [pscustomobject]@{'Nummer'=4; 'Alternativ'='Konfigurer GPO'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {''} -PassThru     
}
Function Get-Meny
{
    Get-ObjVirtuellRouter
    [pscustomobject]@{'Nummer'=2; 'Alternativ'='Pull Server'}
    [pscustomobject]@{'Nummer'=3; 'Alternativ'='Filtjener'}
    [pscustomobject]@{'Nummer'=4; 'Alternativ'='Active Directory'} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Get-ObjActiveDirectory} -PassThru
    [pscustomobject]@{'Nummer'=5; 'Alternativ'='Hyper-V'}
}

Function Get-MenyGammel
{
    #$PSStandardMembers = Set-StandardUtData "Nummer", "Alternativ"

    [pscustomobject]@{'Nummer'=1; 'Alternativ'='Administrasjon av virtuelle maskiner'; 'Flervalg'=$false} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {Get-AdministrerVirtuelleMaskiner} -PassThru
    #Add-Member -MemberType MemberSet -Name PSStandardMembers  -Value $PSStandardMembers  -PassThru

    [pscustomobject]@{'Nummer'=2; 'Alternativ'='Administrasjon av Active Directory'; 'Flervalg'=$false} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru

    [pscustomobject]@{'Nummer'=3; 'Alternativ'='Administrasjon av Desired State Configuration'; 'Flervalg'=$false} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru

    [pscustomobject]@{'Nummer'=4; 'Alternativ'='Administrasjon av Filtjener'; 'Flervalg'=$false} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru

    [pscustomobject]@{'Nummer'=5; 'Alternativ'='Avslutt'; 'Flervalg'=$false} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru

    [pscustomobject]@{'Nummer'=6; 'Alternativ'='Hjelp'; 'Flervalg'=$false} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'tom'} -PassThru
    #Add-Member -MemberType MemberSet -Name PSStandardMembers  -Value $PSStandardMembers  -PassThru

    [pscustomobject]@{'Nummer'=7; 'Alternativ'='Avslutt'; 'Flervalg'=$false} | 
    Add-Member -MemberType ScriptMethod -Name "Reaksjon" -Value {'avslutt()'} -PassThru

    #Add-Member -MemberType MemberSet -Name PSStandardMembers  -Value $PSStandardMembers  -PassThru
}