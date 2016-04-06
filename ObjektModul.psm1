# Funksjonen bestemmer hvilke egenskaper som skal vises ved utdata når ikke annet er spesifisert
function Set-StandardUtData
{
    param 
    (
        [string[]]$defaultDisplaySet
    )
    
    $defaultDisplayPropertySet  = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
    
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

    return $PSStandardMembers 


}

# Henrwe ut ett eller flere objekter fra objekt 
function Get-Objekt
{
    param(
        [parameter(mandatory)]
        $objekt
    )

    $ValgtObjekt = $null 
    
    # Sjekker om det er lov til å gjøre flere valg fra objektet 
    if($objekt.flervalg -eq $true) 
    {

    }else
    {

        do
        {
            # Velg alternativ 
            $valg = Read-Host "Velg et alternativ fra listen"

            # Henter ut valgt objekt 
            $valgtObjekt = ($objekt | where {$_.nummer -eq $valg})

            # Skriver ut melding hvis brukeren har ugyldig inndata 
            if($valgtObjekt -eq $null) 
            {
                write-host "Ugyldig input" -ForegroundColor Red
            }
        }while($ValgtObjekt -eq $null)
    }

    return $ValgtObjekt
}


function Get-AdministrerVirtuelleMaskiner
{
    [pscustomobject]@{'Nummer'=1; 'Alternativ'='Endre Virtuelt Minne'; 'Flervalg'=$false; 'Reaksjon'='tom'}
    [pscustomobject]@{'Nummer'=2; 'Alternativ'='Endre Virtuell Harddisk'; 'Flervalg'=$false; 'Reaksjon'='tom'}
}

Function Get-Meny
{
    $PSStandardMembers = Set-StandardUtData "Nummer", "Alternativ"

    [pscustomobject]@{'Nummer'=1; 'Alternativ'='Administrer Virtuelle Maskiner'; 'Flervalg'=$false; 'Reaksjon'=Get-AdministrerVirtuelleMaskiner} #| 
    #Add-Member -MemberType MemberSet -Name PSStandardMembers  -Value $PSStandardMembers  -PassThru

    [pscustomobject]@{'Nummer'=2; 'Alternativ'='Hjelp'; 'Flervalg'=$false; 'Reaksjon'='tom'} #| 
    #Add-Member -MemberType MemberSet -Name PSStandardMembers  -Value $PSStandardMembers  -PassThru

    [pscustomobject]@{'Nummer'=3; 'Alternativ'='Avslutt'; 'Flervalg'=$false; 'Reaksjon'= 'avslutt'} #| 
    #Add-Member -MemberType MemberSet -Name PSStandardMembers  -Value $PSStandardMembers  -PassThru
}