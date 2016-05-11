# Spesifiser din AD sesjon her 
Function Get-AdSesjon
{
    return $sesjonadserver 
}

# Velg blant en eller flere arbeidsstasjoner 
Function Select-Arbeidsstasjon
{
    param(
        [parameter(
        mandatory=$true)]
        $as
    )

    # Velg as 
    $AdComputerNavn = Read-Host `
     -Prompt `
     'Skriv inn brukernavn på AD arbeidsstasjon. 
     Skill med komma for å velge flere. 
     Skriv x! for å avbryte.
     >'

    # tilbake 
    if($AdComputerNavn -eq 'x!' -or $AdComputerNavn -eq "") {
        return $null
    }

    # Splitt hvis komma 
    $adcomputernavn = $AdComputerNavn | % {$_.split(',')} 

    # Fjern whitespace ved start og slutt
    $adcomputernavn  = $adcomputernavn | % {$_.trim()}

    # Fjern evt. doble forekomster
    $AdComputerNavn = $AdComputerNavn | select -Unique

    # Henter ut valg 
    foreach($navn in $AdComputerNavn) {
        [object[]]$valg += $as | where {$_.samaccountname -eq $navn} 
    }

    return $valg 
}

# Opprett en eller flere arbeidsstasjoner
Function New-ArbeidsStasjon
{
    # Les inn passord 
    $pw = read-host "Skriv inn ønsket passord. Kan stå tomt" -AsSecureString

    # Sett passord til null hvis det er tomt 
    if($pw -eq "") {
        $pw = $null
    }
    
    # Eksisterende as 
    $as = Invoke-Command -Session $SesjonADServer -script {
        get-adcomputer -filter * 
    }


    $AdComputerNavn = Read-Host `
     -Prompt 'Skriv inn navn på AD arbeidsstasjon. 
     Skill med komma for å opprette flere. 
     Skriv x! for å avbryte.
     navn'

    # tilbake 
    if($AdComputerNavn -eq 'x!') {
        return $null
    }

    # Splitt hvis komma 
    $adcomputernavn = $AdComputerNavn | % {$_.split(',')} 

    # Fjern whitespace ved start og slutt
    $adcomputernavn  = $adcomputernavn | % {$_.trim()}

    # Sjekker om as navnet er ledig 
    for($i=0; $i -le $AdComputerNavn.length; $i++)
    {
        while ($as.name -contains $AdComputerNavn[$i])
        {
            $navn = Read-Host `
             -Prompt "Navnet $($AdComputerNavn[$i]) finnes alerede. 
             Velg et annet"

            $AdComputerNavn[$i] = $navn
        }  
    }

    # Fjern evt. doble forekomster
    $AdComputerNavn = $AdComputerNavn | select -Unique
    
    # Returnerer hvis det ikke er skrevet noen navn
    if($AdComputerNavn -eq "") {
        return $null
    }

    # Opprett adstasjon 
    foreach ($navn in $AdComputerNavn) {
        Invoke-Command -Session $SesjonADServer -ScriptBlock {
            new-adcomputer -name $using:navn `
                           -AccountPassword $using:pw `
                           -Enabled $true `
                           -SamAccountName $($using:navn).replace(" ", "") `
                           -UserPrincipalName $($using:navn).replace(" ", "")

        }
    }

    if($?) {"Arbeidsstasjonen $AdComputerNavn er opprettet"}
    else {"Noe gikk galt med opprettelsen av $AdComputerNavn"}
}

Function Rename-ArbeidsStasjon
{
    # Hent ut eksisterende AS 
    $EksisterendeAS = 
        Invoke-Command -Session $sesjonadserver -scriptblock {
            get-adcomputer -filter *
        }

    # Velger as 
    $AsObjekter = Select-Arbeidsstasjon -as $EksisterendeAS

    # Gjennomgå hver as 
    foreach($as in $AsObjekter)
    {

        # Skriv nytt brukernavn 
        do {
            $Brukernavn = Read-Host -Prompt `
            "
            Skriv nytt brukernavn for $($as.samaccountname)
            >"
        }while ($Brukernavn -eq "")

        # Fjern mellomrom
        $brukernavn = $Brukernavn.Replace(" ", "")

        # Sjekk at brukernavn ikke finnes 
        while($brukernavn -in $EksisterendeAS.samaccountname `
            -or $Brukernavn -in $EksisterendeAS.UserPrincipalName)
        {
            do {
                # Brukernavn ikke ledig 
                $Brukernavn = Read-Host -Prompt `
                    "
                    Brukernavnet $Brukernavn er ikke ledig
                    Skriv inn et nytt
                    >" 
            
                # Fjern mellomrom
                $brukernavn = $Brukernavn.Replace(" ", "")
            }while ($Brukernavn -eq "")
        }

    
        # Oppdater brukernavn
        Invoke-Command -Session $sesjonadserver -ScriptBlock {
            Set-ADComputer -Identity $using:as.objectguid `
                           -SAMAccountName $using:brukernavn `
                           -UserPrincipalName $using:brukernavn
        }

        if($?) {
            Write-Host -Object `
            "
            $($as.name) har endret brukernavn fra:
            $($as.samaccountname) til $brukernavn
            "
        }else{
            Write-Host "Noe gikk galt"
        }
    } 
}

# Henter ut alle aktiverte arbeidstasjoner 
Function Get-ArbeidsStasjonAktiv
{
    # Hent ut as 
    $as = Invoke-Command -Session $sesjonadserver `
    -scriptblock {
        get-adcomputer -filter {enabled -eq $true}
    }

    return $as 
}

# Henter ut alle deaktiverte arbeidsstasjoner 
Function Get-ArbeidsStasjonInAktiv
{
    # Hent ut as 
    $as = Invoke-Command -Session $sesjonadserver `
    -scriptblock {
        get-adcomputer -filter {enabled -eq $false}
    }

    return $as 
}

# Velg en eller flere as som skal aktiveres
Function Enable-ArbeidsStasjon
{
    # Hent ut inaktive as 
    $as = Get-ArbeidsStasjonInAktiv

    # returner hvis null 
    if($as -eq $null) {
        write "Det finnes ingen inaktive arbeidsstasjoner"
        return $null 
    }

    # List ut 
    write-host ($as | ft -prop Name, SamAccountName,enabled | out-string) 

    # Velg én eller flere 
    $ValgteAS = Select-Arbeidsstasjon -as $as 

    # Aktiver as 
    foreach($valg in $ValgteAS) {
        Invoke-Command -Session $sesjonadserver -ScriptBlock {
            Set-ADComputer -Identity $using:valg.objectguid -Enabled $true
        } 
        
        # Skriv ut melding om resultat 
        if($?) {"$($valgteAS.name) er nå aktivert"}
        else {"Noe gikk galt"}
    }
}

# Velg en eller flere as som skal deaktiveres
Function Disable-ArbeidsStasjon
{
    # Hent ut aktive as 
    $as = Get-ArbeidsStasjonAktiv

    # returner hvis null 
    if($as -eq $null) {
        write "Det finnes ingen aktive arbeidsstasjoner"
        return $null 
    }

    # List ut 
    write-host ($as | ft -prop Name, SamAccountName,enabled | out-string) 

    # Velg én eller flere 
    $ValgteAS = Select-Arbeidsstasjon -as $as 

    # Deaktiver as 
    foreach($valg in $ValgteAS) {
        Invoke-Command -Session $sesjonadserver -ScriptBlock {
            Set-ADComputer -Identity $using:valg.objectguid -Enabled $false
        } 

        # Skriv ut melding om resultat 
        if($?) {"$($valgteAS.name) er nå deaktivert"}
        else {"Noe gikk galt"}
    }
}

# Sletter en eller flere arbeidsstasjoner 
Function Remove-ArbeidsStasjon
{
    # Hent ut as 
    $as = Invoke-Command -Session $sesjonadserver -ScriptBlock {
        get-adcomputer -filter *
    }

    # List ut as 
    write-host ($as | ft -prop name, samaccountname, enabled | out-string)

    # Velg en eller flere as 
    $ValgtAS = Select-Arbeidsstasjon -as $as 

    # Fjern AS 
    foreach($as in $ValgtAS) {
        write "Sletter $($as.name)"
        Invoke-Command -Session $sesjonadserver -ScriptBlock {
            Remove-ADComputer -Identity $using:as.objectguid
        }

        if($? -eq $false) {"Noe gikk galt"}
    }
}

# Henter ut gruppe medlemskap for arbeidsstasjoner
Function Get-AsGruppeMedlemskap
{
    # Hent AS 
    $as = Invoke-Command -Session $sesjonadserver -ScriptBlock {
        get-adcomputer -filter *
    }

    # List ut AS 
    write-host ($as | ft -prop name, samaccountname, enabled | out-string)

    # Velg AS 
    $ValgtAs = Select-Arbeidsstasjon $as 

    # Hent ut gruppemedlemskap for hver as 
    foreach ($as in $ValgtAs) {
        $grupper = 
        Invoke-Command -Session $sesjonadserver -script {
            Get-ADPrincipalGroupMembership `
            -Identity $using:as.objectguid
        } 

        write-host "$($as.name) er medlem av gruppene:"
        write-host ($grupper | 
                    ft -prop GroupCategory, GroupScope, name, SamAccountName | 
                    out-string)
        
    }

    # Pause 
    pause
}

# Setter nytt passord for arbeidsstasjoner 
Function Set-AsPassord
{
    # Hent ut as 
    $as = Invoke-Command -Session $sesjonadserver -ScriptBlock {
        get-adcomputer -filter *
    }

    # List ut as 
    write-host ($as | ft -prop name, samaccountname, enabled | out-string) 

    # Velg as 
    $ValgtAs = Select-Arbeidsstasjon $as 

    # Sett passord for hvert valg 
    foreach($as in $ValgtAs) {
        Invoke-Command -Session $sesjonadserver -ScriptBlock {
            Set-ADAccountPassword -Identity $using:as.objectguid `
            -Reset
        }

        # Skriv ut melding 
        if($?) {"Passordet for $($as.name) er endret"}
        else {"Noe gikk galt. . ."}
    }
}

################################
### Active Directory Brukere ###
################################

Function Select-Bruker
{
    param(
        [parameter(
        mandatory=$true)]
        $brukere
    )


    # Velg as 
    $brukernavn = Read-Host `
     -Prompt `
     'Skriv inn brukernavn for AD bruker. 
     Skill med komma for å velge flere. 
     Skriv x! for å avbryte.
     >'

    # tilbake 
    if($brukernavn -eq 'x!' -or $brukernavn -eq "") {
        return $null
    }

    # Splitt hvis komma 
    $brukernavn = $brukernavn | % {$_.split(',')} 

    # Fjern whitespace ved start og slutt
    $brukernavn  = $brukernavn | % {$_.trim()}

    # Fjern evt. doble forekomster
    $brukernavn = $brukernavn | select -Unique

    # Henter ut valg 
    foreach($navn in $brukernavn) {
        [object[]]$valg += $brukere | where {$_.samaccountname -eq $navn} 
    }

    return $valg 
}


#################################
### Active Directory Gruupper ###
#################################

Function Get-AdGrupper
{
    # Hent ut sesjon 
    $sesjon = Get-AdSesjon

    # Hent ut og returner grupper 
    Invoke-Command `
        -Session $sesjon `
        -ScriptBlock {
            get-adgroup -filter *
        }
}

Function New-AdGruppe
{
    param(
        [parameter(
            Position=0,
            ValueFromPipeLine=$true
        )]
        [string[]]$GruppeNavn,
        [parameter(
            Position=1,
            Mandatory=$true
        )]
        [System.Management.Automation.Runspaces.PSSession]
        $Sesjon,
        [parameter(
            Position=2
        )]
        [ValidateSet('Distribution','Security')]
        $GroupCategory = 'Security',
        [parameter(
            Position=3
        )]
        [ValidateSet('DomainLocal','Global', 'Universal')]
        $GroupScope = 'DomainLocal'
    )

    begin {
        Write-Verbose "Henter inn eksisterende grupper"
        $grupper = Invoke-Command -Session $Sesjon -ScriptBlock {
            get-adgroup -filter *
        }
    }
    process {
        
        # Hent inn gruppenavn hvis det ikke finnes 
        while ($GruppeNavn -eq $null -or $GruppeNavn -eq "") {
            # Les inn gruppenavn
            $GruppeNavn = read-host `
            "
            Skriv inn et navn for gruppen.
            Skill med komma for å opprette flere
            "
            # Splitt navn 
            $GruppeNavn = $GruppeNavn.Split(',')

            # Trim whitespace ved start og slutt
            $GruppeNavn = $GruppeNavn.trim()
        }


        # Gjennomgå hvert gruppenavn 
        foreach($navn in $GruppeNavn) {
            # Fjerner whitespace i brukernavn
            $samName = $navn.replace(" ", "") 

            # Sjekker om navnet eksisterer
            while($navn -in $grupper.name `
                -or $samName -in $grupper.samaccountname `
                -or $navn -eq "")
            {
                $navn = Read-Host "Navnet $navn er ikke ledig, velg et annet"
                $samName = $navn.replace(" ", "") 
            }

            # Opprett gruppe 
            Invoke-Command -Session $Sesjon -ScriptBlock {
                New-ADGroup -name $using:navn `
                            -DisplayName $using:navn `
                            -SamAccountName $using:samname `
                            -GroupScope $using:groupscope `
                            -GroupCategory $using:groupcategory
            }

            # Skriv ut melding 
            if($?) {
                # Legger til nylig opprettet gruppe 
                # Dette er for å unngå duplikat 
                $grupper += @{'name'=$navn}
                "Gruppen $navn er opprettet"
            }
            else {"Noe gikk galt"}
        }
    }
}

# Velger en AD gruppe 
Function Select-AdGruppe
{
    param(
        [parameter(
            mandatory=$true
        )]
        $grupper
    )

    # Velg gruppe 
    $GruppeNavn = Read-Host `
     -Prompt `
     'Skriv inn brukernavn på AD gruppe. 
     Skriv x! for å avbryte.
     >'

    # tilbake 
    if($GruppeNavn -eq 'x!' -or $GruppeNavn -eq "") {
        return $null
    }

    # Fjern whitespace ved start og slutt
    $GruppeNavn  = $GruppeNavn.trim()

    # Henter ut valg 
    foreach($navn in $GruppeNavn) {
        [object[]]$valg += $grupper | where {$_.samaccountname -eq $navn} 
    }

    return $valg 
}

Function Add-AdGruppeMedlem
{

    param(
        [parameter(
            mandatory=$true)]
        [ValidateSet(
        'Bruker','ArbeidsStasjon','Gruppe')]
        $MembersType
    )

    # Hent grupper 
    $grupper = Invoke-Command -Session $sesjonadserver -ScriptBlock {
        get-adgroup -filter *
    }

    # Sorter innholdet i grupper 
    $grupper = $grupper | sort -prop samaccountname

    # List ut grupper 
    write-host ($grupper | ft -prop samaccountname, name, `
                GroupCategory, GroupScope | out-string)

    # Velg gruppe 
    $ValgtGruppe = Select-AdGruppe $grupper 

    # Legg til medlem
    switch($MembersType){
        'Bruker' {
            # Hent ut brukere 
            $brukere = 
            Invoke-Command -Session $sesjonadserver `
            -ScriptBlock {
                get-aduser -filter *
            }

            # Skriv ut brukere
            clear-host 
            write-host ($brukere | ft -prop samaccountname , ObjectClass | out-string)

            # Velg brukere 
            $Member = Select-Bruker $brukere
        }
        'ArbeidsStasjon' {
            # Hent ut AS 
            $as = 
            Invoke-Command -Session $sesjonadserver `
            -ScriptBlock {
                get-adcomputer -filter *
            }

            # Skriv ut AS 
            clear-host 
            write-host ($as | ft -prop samaccountname, objectclass | out-string) 

            # Velg AS 
            $Member = Select-Arbeidsstasjon $as
        }
        'Gruppe' {
            # Skriv ut grupper 
            clear-host 
            write-host ($grupper | ft -prop samaccountname, objectclass | out-string)

            # Velg gruppe
            $Member = Select-AdGruppe $grupper
        }
    }

    # Returner hvis null 
    if($member -eq $null -or $valgtgruppe -eq $null)
    {
        return $null 
    }

    foreach($m in $Member) {
        Invoke-Command -Session $sesjonadserver -ScriptBlock {
            Add-ADGroupMember `
                    -Identity $using:ValgtGruppe.objectguid `
                    -Members $using:m.objectguid 
        }

        if($?) {"$($m.name) er lagt til i gruppen $($ValgtGruppe.name)"}
        else {"Noe gikk galt"}
    }
}

# Lister ut medlemmer av en gruppe
Function Get-AdGruppeMedlemmer
{
    param($ValgtGruppe)

    # Hent medlemmer av gruppen 
    $members = Invoke-Command -Session $sesjonadserver -script {
        get-adgroupmember -Identity $using:valgtgruppe.objectguid 
    }

    # List ut medlemmer av gruppen 
    write $members 
}

# Sletter en gruppe 
Function Remove-AdGruppe
{
    # Hent ut grupper 
    $grupper = Invoke-Command -Session $sesjonadserver -ScriptBlock {
        get-adgroup -filter *
    }

    # List ut grupper 
    write-host ($grupper | 
        ft -prop SamAccountName, Name, GroupCategory, GroupScope | 
        out-string)

    # Velg en gruppe 
    $ValgtGruppe = Select-AdGruppe $grupper 

    # Returner hvis null 
    if($ValgtGruppe -eq $null) {
        Write-Host "Ingen gruppe valgt. . ."
        return $null 
    }

    # Fjern gruppe
    Invoke-Command -Session $sesjonadserver -ScriptBlock {
        remove-adgroup -identity $using:valgtgruppe.objectguid
    } 

    # Skriv ut melding 
    if($? -ne $true)  {"Noe gikk galt"}
}

Function Remove-AdGruppeMedlem
{
    # Hent ut grupper 
    $grupper = Invoke-Command `
    -Session $sesjonadserver -script {
        get-adgroup -filter *
    }

    # Skriv ut grupper 
    write-host ($grupper | 
        ft -prop samaccountname, name, GroupCategory, groupscope | 
        out-string)

    # Velg gruppe 
    $ValgtGruppe = Select-AdGruppe $grupper 

    # Hent medlemmer av gruppe 
    $medlemmer = Get-AdGruppeMedlemmer $ValgtGruppe 

    # Skriv ut medlemmer
    clear-host  
    write-host ($medlemmer | ft -prop samaccountname, name | out-string) 

    # Velg medlem 
    $ValgtMedlem = select-bruker $medlemmer 

    # Returner hvis inndata mangler 
    if($ValgtGruppe -eq $null -or $ValgtMedlem -eq $null)
    {
        return $null 
    }

    # Fjern medlem fra gruppe 
    foreach($medlem in $ValgtMedlem) {
        Invoke-Command -Session $sesjonadserver -ScriptBlock {
            Remove-ADGroupMember `
                -Identity $using:valgtgruppe.objectguid `
                -Members $using:medlem.objectguid 
        }
    }
}

# Henter tomme grupper
Function Get-GruppeTom
{
    # Hent tomme grupper 
    $TommeGrupper = invoke-command -Session $sesjonadserver `
    -scriptblock {
        get-adgroup -filter * -prop members | 
                    where {-not $_.members} 
    }

    # List ut tomme grupper 
    write $TommeGrupper 
}