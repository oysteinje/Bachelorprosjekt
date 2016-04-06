
$cred = Get-Credential $cred

# Legg eventuell eksisterende sesjon i variabel og koble til 
$SesjonHyperV = Get-PSSession | where {$_.ComputerName -match '158.38.56.146'} | Connect-PSSession

# Oppretter sesjon hvis den ikke eksiterer 
if ($SesjonHyperV -eq $null) 
{
    $SesjonHyperV = New-PSSession -ComputerName 158.38.56.146 -port 13389 -Name "Hyper-V Server" -Credential $cred 
}

# Importerer Hyper-V modulen fra ekstern maskin hvis den ikke allerede eksisterer 
if ((Get-Command Get-VM -ErrorAction SilentlyContinue) -eq $null) 
{
    Write-Host "Laster inn moduler fra Hyper-V server. Vennligst vent. . ." -ForegroundColor Cyan
    Invoke-Command -Session $SesjonHyperV -ScriptBlock {Import-Module Hyper-V} -Verbose
    Import-PSSession -Session $SesjonHyperV -Module hyper-v -Verbose
}

# Initialiserer nødvendige moduler 
.\Kjor-Meg.ps1

# Opprett alternativer som objekt 
#$alternativer = Get-Meny

# Skriv ut alternativer 
#$alternativer | ft -AutoSize

$reaksjon = Get-Meny

do
{
    $reaksjon | ft -AutoSize
    $valg = get-objekt $reaksjon 
    $reaksjon = ($valg | Select-Object -ExpandProperty reaksjon)

}while ($reaksjon -notmatch 'avslutt')

Write-Output $reaksjon






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


