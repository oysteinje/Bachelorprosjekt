# Navn for servere
$global:NavnHyperV = 'Hyper-V Server'
$global:NavnVRouter = 'Virtuell Router'

# IP for servere 
$global:IPHyperV = '158.38.56.146'
$global:IPVRouter = '158.38.56.149'

# IP og port for servere 
$global:HyperV = @{NAVN=$NavnHyperV;IP=$IPHyperV;PORT='13389';PREFIX='hv'}
$global:vRouter = @{NAVN=$NavnVRouter;IP=$IPVRouter;PORT='13389';PREFIX='vr'}

# Prefix for servere
$global:PrefixHyperV = 'hv'
$global:PrefixVRouter = 'vr'

# Initialiserer nødvendige moduler 
.\Kjor-Meg.ps1

# Henter sesjoner inn i variabel
#$global:SesjonHyperV = Get-PSSession -name $NavnHyperV
#$global:SesjonVRouter = Get-PSSession -name $NavnVRouter

# Kobler til sesjonene 
Connect-Sesjoner -Servere $HyperV, $vRouter -Credentials $cred

# Henter sesjoner inn i variabel
$global:SesjonHyperV = Get-PSSession -name $NavnHyperV
$global:SesjonVRouter = Get-PSSession -name $NavnVRouter

# Importerer Hyper-V modulen fra ekstern maskin hvis den ikke allerede eksisterer 
if ((Get-Command "Get-VM" -ErrorAction SilentlyContinue) -eq $null) 
{
    Write-Host "Laster inn moduler fra Hyper-V server. Vennligst vent. . ." -ForegroundColor Cyan
    Invoke-Command -Session $SesjonHyperV -ScriptBlock {Import-Module Hyper-V} -Verbose
    Import-PSSession -Session $SesjonHyperV -Module hyper-v -Verbose #-Prefix $PrefixHyperV
}

# Opprett alternativer som objekt 
$reaksjon = Get-Meny

do
{
    #$reaksjon | gm
    $reaksjon | ft -AutoSize
    $ValgtObjekt = get-objekt $reaksjon 
   
    #if($ValgtObjekt.length -gt 1) 
    #{
        
    #}else 
    #{
    $reaksjon = ($ValgtObjekt.Reaksjon()) #($ValgtObjekt | Select-Object -ExpandProperty reaksjon)
    #}

    Clear-Host


}while ($reaksjon -notmatch 'avslutt()')


# Meny oppsett 
$meny = 
@{
    'Nivå 1 (Router)' = 
        @{
        'Nivå 2 (Konfigurer DHCP)' = ''
        }

    'Nivå 1 (DSC)' = 
        @{
        'Nivå 2 (Sjekk: Pull Server)' = 
            @{
            'Nivå 3 (Konfigurer Pull Server)' = 
                @{
                'Sett Konfigurasjonsmappe' = ''
                'Sett modulmappe' = ''
                'Endre port' = ''
                }
            'Nivå 3 (Behandle Noder)' = 
                @{
                '' = ''
                }
            }
        }
    
    'Nivå 1 (Filtjener)' = ''

    'Nivå 1 (Active Directory)' = 
        @{
        'Nivå 2 (Datamaskiner)' = 
            @{
            'Nivå 3 (Opprett datamaskiner)' = ''
            'Nivå 3 ()' = ''
            }
        'Nivå 2 (Brukere)' = 
            @{
            'Nivå 3 (Opprett brukere)' = '' 
            'Nivå 3 (Slett brukere)' = ''
            'Nivå 3 (Legg brukere til gruppe)' = ''
            'Nivå 3 (Endre bruker)' = 
                @{
                'Nivå 4 (Endre brukernavn)' = ''
                'Nivå 4 (Endre passord)' = ''
                }
            }
        }
        
        'Nivå 2 (Grupper)' = ''
    
    'Nivå 1 (Hyper-V)'=
    @{
        'Nivå 2 (Opprett VM)' = ''
        'Nivå 2 (Administrer vm minne)' =
            @{
            'Nivå 3 (Velg type minne)' =
                @{
                'Nivå 4 (Velg vms)' = 
                    @{
                    'Nivå 5 (Skriv inn antall minne'=''
                    }
                }
            }
        }
}



        


<#

# Kommende løkke kjører så lenge valgtobjekt er lik null 
$valgtObjekt = $null 
do 
{
    # Velg alternativ 
    $valg = Read-Host "Velg et alternativ fra listen"

    # Henter ut valgt objekt 
    $valgtObjekt = $alternativer | where {$_.nummer -eq $valg}

    # Skriver ut melding hvis brukeren har ugyldig inndata 
    if($valgtObjekt -eq $null) 
    {
        write-host "Ugyldig input" -ForegroundColor Red
    }

}while ($valgtObjekt -eq $null)



#>



# Hyper-V Server Sesjon 
#$SesjonPull = New-PSSession -ComputerName 158.38.56.147 -port 13389 -name "Pull Server" -Credential $cred
#$SesjonAD = New-PSSession -ComputerName 158.38.56.149 -port 33895 -name "AD Server" -Credential $cred
#$SesjonVRouter = New-PSSession -ComputerName 158.38.56.149 -port 13389 -name "Virtuell Router" -Credential $cred

# Laster nødvendige moduler inn i minnet på serverne 
#Invoke-Command -Session $SesjonHyperV -ScriptBlock {Import-Module Hyper-V}
#Invoke-Command -Session $SesjonAD -ScriptBlock {Import-Module activedirectory}

# Importerer modulene fra minnet på serverne til lokal maskin. Disse modulene kan nå brukes lokalt :)
#Import-PSSession -Session $SesjonHyperV -Module hyper-v 
#Import-PSSession -Session $SesjonAD -Module activedirectory



# Legger modulen i variabel
#[string[]]$modul = get-content .\BachelorProsjekt.psm1

# Lagre modul på hver server og importer den 
#Invoke-Command -Session $SesjonHyperV -ScriptBlock {Set-Content -Value $using:modul -Path BachelorProsjekt.psm1; Import-Module .\BachelorProsjekt.psm1; Get-Module}
#Invoke-Command -Session $SesjonPull -ScriptBlock {Set-Content -Value $using:modul -Path BachelorProsjekt.psm1; Import-Module .\BachelorProsjekt.psm1}
#Invoke-Command -Session $SesjonAD -ScriptBlock {Set-Content -Value $using:modul -Path BachelorProsjekt.psm1; Import-Module .\BachelorProsjekt.psm1}
#Invoke-Command -Session $SesjonVRouter -ScriptBlock {Set-Content -Value $using:modul -Path BachelorProsjekt.psm1; Import-Module .\BachelorProsjekt.psm1}


