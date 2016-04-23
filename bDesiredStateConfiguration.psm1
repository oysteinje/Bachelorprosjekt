Function New-IPAdresse
{
    param
    (
        [string]$Prompt = 'Skriv inn IP-adresse',
        [ipaddress]$DefaultIP
    )

    do
    {
        # Les inn IP-adresse 
        [string]$IPAdresse = Read-Host $Prompt

        # Sett standard IP hvis brukeren ikke skrev inn noe 
        if($IPAdresse.length -eq 0) {$IPAdresse = $DefaultIP}

        # Forsøker å konvertere inndata til ip 
        try
        {   
            [ipaddress]$IPAdresse = $IPAdresse
        }
        catch
        {
            Write-Host 'Ugyldig format på IP-adresse. Prøv på nytt'
        }
    # Løkken går så lenge formatet ikke er av IPadresse
    }while($IPAdresse.GetType().name -ne 'IPAddress')
    
    return $IPAdresse 
}

Function Start-EksternDscKonfigurasjon {
    [cmdletbinding()]
    param(
        [parameter(mandatory)]
        $DscKode,
        [parameter(mandatory)]
        $Sesjon,
        [parameter(mandatory)]
        [string]$DscSti,
        [parameter(mandatory)]
        [string]$DscKonfigurasjonsNavn,
        [parameter(mandatory)]
        [ipaddress]$IPAdresse
    )

    begin{
        $DscKonfigurasjonFil = "$DscKonfigurasjonsNavn.ps1"
    }
    process{
        Invoke-Command -Session $Sesjon -ScriptBlock {
            
            # Opprett mappe hvis den ikke eksisterer 
            if (!(Test-Path $using:DscSti)) {mkdir $using:DscSti}

            # Legg kode i fil 
            Set-Content -Value $using:DSCKode -Path "$using:DscSti\$using:dscKonfigurasjonsfil"

            # Kjør konfigurasjon for å generere .mof fil 
            & "$using:dscSti\$using:dscKonfigurasjonsFil"

            # Flytt mof filen til dsc mappen 
            Move-Item -path "$env:USERPROFILE\Documents\$using:dscKonfigurasjonsNavn\localhost.mof" -dest "$using:dscSti\$using:guid.mof" -Force
        
            # Opprett cim session. Dette er den "letteste" måten for at alt skal fungere. 
            $cs = New-CimSession -Credential $cred -ComputerName $using:IPAdresse -port (get-item WSMan:\localhost\Listener\*\Port).value
        
            
            # Fjern eventuelle konfigurasjoner som venter 
            #if(Test-Path "$env:windir\System32\Configuration\Pending.mof")
            #{
            #    rm "$env:windir\System32\Configuration\Pending.mof"
            #}
        
            # Start konfigurasjonen
            Start-DscConfiguration -Path $using:dscSti -Wait -Verbose -CimSession $cs

            # Skriv ut beskjed hvis alt har gått bra 
            if($?) 
            {
                Write-Host 
                "DSC konfigurasjon er satt opp på $using:ipaddress"
            }

            # Fjern cim sesjonen
            Remove-CimSession -CimSession $cs 
        }
    }
    end{}
}

Function New-PullServer
{
    # Sjekk om Pull Server ikke allerede er satt opp 
    $Sjekk = Invoke-Command -Session $sesjonPullServer -ScriptBlock {
        Get-DscConfiguration | where {$_.ResourceId -eq '[xDSCWebService]PSDSCPullServer'}
    }

    #if ($Sjekk -ne $null) 
    #{
        #return "Serveren med IP $IPAdresse er allerede satt opp som pull server"
    #}
    

    ###############################
    # Setter opp Pull Server. . . #
    ###############################

    # Hent inn DSC kode fra lokal maskin
    $DSCKode = Get-Content .\dsc\CreatePullServer.ps1 

    # Les inn port 
    $Port = Read-Tall -prompt 'Skriv inn port Pull Server skal bruke for HTTP [8080]' -DefaultVerdi 8080 

    # Gjør endringer på Pull Server 
    Invoke-Command -Session $sesjonPullServer -ScriptBlock {
        # Sti til mappe der DSC konfigurasjon skal lagres
        $Sti = "$env:HOMEDRIVE\DSC"

        # KonfigurasjonsNavn 
        $KonfigurasjonsNavn = 'CreatePullServer'
        
        # Konfigurasjonsfil 
        $KonfigurasjonsFil = "$KonfigurasjonsNavn.ps1"

        # Opprett mappe hvis den ikke eksisterer 
        if (!(Test-Path $Sti)) {mkdir DSC}

        # Kopier over kode til Pull Server konfigurasjon 
        Set-Content -Value $using:DSCKode -Path "$Sti\$Konfigurasjonsfil"

        # Legger til linjen som initerer funksjonen 
        Add-Content -Value "$KonfigurasjonsNavn -Port $using:Port" -Path "$Sti\$Konfigurasjonsfil"
        
        # Kjør konfigurasjon for å generere .mof fil 
        & "$Sti\$KonfigurasjonsFil"
        
        # Flytt mof filen til dsc mappen 
        Move-Item -path "$env:USERPROFILE\Documents\$KonfigurasjonsNavn\localhost.mof" -dest "$sti\localhost.mof" -Force
        
        # Opprett cim session. Dette er den "letteste" måten for at alt skal fungere. 
        $cs = New-CimSession -Credential $cred -ComputerName localhost -port (get-item WSMan:\localhost\Listener\*\Port).value
        
        # Fjern eventuelle konfigurasjoner som venter 
        if(Test-Path "$env:windir\System32\Configuration\Pending.mof")
        {
            rm "$env:windir\System32\Configuration\Pending.mof"
        }
        
        # Start konfigurasjonen
        Start-DscConfiguration -Path $Sti -Wait -Verbose -CimSession $cs

        # Skriv ut beskjed hvis alt har gått bra 
        if($?) 
        {
            Write-Host 
            "Pull Server er satt opp på $($using:sesjonPullServer.ComputerName).
            Gå inn på http://$($using:sesjonPullServer.ComputerName):$using:port/PSDSCPullServer.svc/ for å teste om Pull Serveren er tilgjengelig"
        }

        # Fjern cim sesjonen
        Remove-CimSession -CimSession $cs 

    }
}

Function New-GUID
{
    return [guid]::NewGuid()
}

Function Find-Value
{
    param(
    [object[]]$Objekt,
    [string]$Søkeord)

    return ($Objekt | where {$_ -match $Søkeord})
}

Function Get-GUID {
    param(
        [string]$CSVSti, 
        [ipaddress]$IPAdresse,
        $Sesjon
    )

    # Hent ut IP-adressens tildelte GUID 
    $GUID = Invoke-Command -Session $Sesjon -ScriptBlock {
        # Hent ut GUID som matcher IP-adressen 
        import-csv -Path $using:CSVSti | `
            Select-Object -ExpandProperty GUID | `
                where {$_.computername -eq $using:IPAdresse}    
    }
    
    return $GUID     
}

Function Set-GUID {
    param(
        [parameter(mandatory)]
        [ipaddress]$IPAdresse,
        [parameter(mandatory)]
        [string]$CSVSti,
        [parameter(mandatory)]
        $Sesjon,
        [parameter(mandatory)]
        [string]$GUID)

    Invoke-Command -Session $Sesjon -ScriptBlock {
        # Lager GUID i liste
        Add-Content -Value "$using:IPAdresse,$GUID" -Path $using:CSVSti
    }
}

Function Set-DSCWindowsFeature 
{
    # Liste over IP-adresser med tilhørende GUID
    $CSVSti = "C:\DSC\ClientGUIDs.csv"

    # Velg IP-adresse 
    [ipaddress]$IPAdresse = New-IPAdresse

    # Skriv ut valgt IP-adresse 
    Write-Host "Maskin med navn $IPAdresse er valgt"
    
    # Hent ut IP-adressens tildelte GUID 
    <#$GUID = Invoke-Command -Session $sesjonPullServer -ScriptBlock {
        # Hent ut GUID som matcher IP-adressen 
        import-csv -Path $using:CSVSti | `
            Select-Object -ExpandProperty GUID | `
                where {$_.computername -eq $using:IPAdresse}    
    }#>
    
    # Hvis GUID ikke eksisterer 
    if($GUID -eq $null)
    {
        # Lag GUID 
        $GUID = New-Guid
        
        Set-GUID -IPAdresse $IPAdresse -CSVSti $CSVSti -Sesjon $sesjonPullServer

        #Invoke-Command -Session $sesjonPullServer -ScriptBlock {
            # Lager GUID i liste
        #    Add-Content -Value "$using:IPAdresse,$using:GUID" -Path $using:CSVSti
        #}
    }

    # Hent windowsfeatures 
    $WinFeatures = Invoke-Command -Session $sesjonPullServer -ScriptBlock {
        Get-WindowsFeature
    }   

    # Sett linjenummer på windowsfeatures
    $WinFeatures = Set-LinjeNummer -Objekt $WinFeatures 

    # For å skrive ut alle win features først 
    $SøkeResultat = $WinFeatures

    Write-Host "Søk etter Windows Rolle. Velg ved å skrive tallet" 

    while($valg -eq $null)
    {
        
        # Skriv ut Windows Features 
        Write-Host ($SøkeResultat | format-table -AutoSize -Property nummer, DisplayName, name | out-string)
        
        # Les inn søkeord 
        $SøkeOrd = Read-Host 'Søk etter Windows Rolle'

        # Forsøker å hente ut et valg 
        $Valg = $WinFeatures | where {$_.nummer -eq $SøkeOrd}

        # Henter ut resultat fra søk 
        $SøkeResultat = $WinFeatures | where {$_.displayname -match $SøkeOrd}
    }

    Write-Host "Du har valgt $($valg.displayname)"

    # Velg tilstand for windows rolle 
    $Tilstand = Get-Valg -alternativer 'Present', 'Absent' -PromptTekst 'Velg tilstand for rollen'

    # Last inn mal for konfigurasjon  
    $DSCKonfigurasjon = Get-Content "\dsc\dscWindowsFeature.ps1"


    Invoke-Command -Session $sesjonPullServer -ScriptBlock {
        
    }
}

Function Set-PullMode 
{
    # Navn på konfigurasjon 
    $KonfigurasjonsNavn = 'SetPullMode'

    # Fil der alle GUID og ipadresser lagres
    $CSVSti = "C:\DSC\ClientGUIDs.csv"

    # Sti til dsc konfigurasjon på ekstern maskin 
    $DscSti = "C:\DSC"
    
    # Filen som skal inneholde konfigurasjon 
    $KonfigurasjonsFil = #

    # Skriv inn IP på klient     
    [ipaddress]$IPAdresse = New-IPAdresse -Prompt 'Skriv inn IP adresse på klienten du ønsker å konfigurere'

    # Sjekk IP har tilknyttet GUID
    $GUID = Get-GUID -CSVSti $CSVSti -IPAdresse $IPAdresse -Sesjon $sesjonPullServer 

    # Opprett GUID hvis det mangler 
    if($GUID -eq $null) {
        $GUID = New-GUID
        # Lagre i csv fil
        Set-GUID -IPAdresse $IPAdresse -CSVSti $CSVSti -Sesjon $sesjonPullServer -GUID $guid
    }

   # Hent inn Pull Server adresse 
   $PullServerUrl = Invoke-Command -Session $sesjonPullServer -ScriptBlock {
        Get-DscConfiguration | `
            where {$_.endpointname -eq 'PSDSCPullServer'} | `
                Select-Object -ExpandProperty DSCServerUrl
   }

   # Kopier konfigurasjon inn i variabel 
   $DscPullKonf = Get-Content "\dsc\SetPullMode.ps1"

   # Legger til linjen som initerer funksjonen
   $DscPullKonf += "$KonfigurasjonsNavn -guid $guid -IPAdresse $IPAdresse -serverurl $PullServerUrl"  

   # Kjør konfigurasjon 
   Start-EksternDscKonfigurasjon -DscKode $DscPullKonf -Sesjon $sesjonPullServer `
    -DscSti $DscSti -DscKonfigurasjonsNavn $KonfigurasjonsNavn -IPAdresse $IPAdresse 


}