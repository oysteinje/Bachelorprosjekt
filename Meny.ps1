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

# Initialiserer n�dvendige moduler 
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
    'Niv� 1 (Router)' = 
        @{
        'Niv� 2 (Konfigurer DHCP)' = ''
        }

    'Niv� 1 (DSC)' = 
        @{
        'Niv� 2 (Sjekk: Pull Server)' = 
            @{
            'Niv� 3 (Konfigurer Pull Server)' = 
                @{
                'Sett Konfigurasjonsmappe' = ''
                'Sett modulmappe' = ''
                'Endre port' = ''
                }
            'Niv� 3 (Behandle Noder)' = 
                @{
                '' = ''
                }
            }
        }
    
    'Niv� 1 (Filtjener)' = ''

    'Niv� 1 (Active Directory)' = 
        @{
        'Niv� 2 (Datamaskiner)' = 
            @{
            'Niv� 3 (Opprett datamaskiner)' = ''
            'Niv� 3 ()' = ''
            }
        'Niv� 2 (Brukere)' = 
            @{
            'Niv� 3 (Opprett brukere)' = '' 
            'Niv� 3 (Slett brukere)' = ''
            'Niv� 3 (Legg brukere til gruppe)' = ''
            'Niv� 3 (Endre bruker)' = 
                @{
                'Niv� 4 (Endre brukernavn)' = ''
                'Niv� 4 (Endre passord)' = ''
                }
            }
        }
        
        'Niv� 2 (Grupper)' = ''
    
    'Niv� 1 (Hyper-V)'=
    @{
        'Niv� 2 (Opprett VM)' = ''
        'Niv� 2 (Administrer vm minne)' =
            @{
            'Niv� 3 (Velg type minne)' =
                @{
                'Niv� 4 (Velg vms)' = 
                    @{
                    'Niv� 5 (Skriv inn antall minne'=''
                    }
                }
            }
        }
}



        


<#

# Kommende l�kke kj�rer s� lenge valgtobjekt er lik null 
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

# Laster n�dvendige moduler inn i minnet p� serverne 
#Invoke-Command -Session $SesjonHyperV -ScriptBlock {Import-Module Hyper-V}
#Invoke-Command -Session $SesjonAD -ScriptBlock {Import-Module activedirectory}

# Importerer modulene fra minnet p� serverne til lokal maskin. Disse modulene kan n� brukes lokalt :)
#Import-PSSession -Session $SesjonHyperV -Module hyper-v 
#Import-PSSession -Session $SesjonAD -Module activedirectory



# Legger modulen i variabel
#[string[]]$modul = get-content .\BachelorProsjekt.psm1

# Lagre modul p� hver server og importer den 
#Invoke-Command -Session $SesjonHyperV -ScriptBlock {Set-Content -Value $using:modul -Path BachelorProsjekt.psm1; Import-Module .\BachelorProsjekt.psm1; Get-Module}
#Invoke-Command -Session $SesjonPull -ScriptBlock {Set-Content -Value $using:modul -Path BachelorProsjekt.psm1; Import-Module .\BachelorProsjekt.psm1}
#Invoke-Command -Session $SesjonAD -ScriptBlock {Set-Content -Value $using:modul -Path BachelorProsjekt.psm1; Import-Module .\BachelorProsjekt.psm1}
#Invoke-Command -Session $SesjonVRouter -ScriptBlock {Set-Content -Value $using:modul -Path BachelorProsjekt.psm1; Import-Module .\BachelorProsjekt.psm1}


