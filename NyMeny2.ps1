$meny = 
[pscustomobject]@{
    Nummer=1
    Alternativ='Virtuell Router'
    Handling='..'
},
[pscustomobject]@{
    Nummer=2
    Alternativ='Pull'
    Handling='..'
},
[pscustomobject]@{
    Nummer=3
    Alternativ='Active Directory'
    Handling=
    [pscustomobject]@{
        Nummer=1
        Alternativ='Brukerkontoer'
        Handling=
        [pscustomobject]@{
            Nummer=1
            Alternativ='Opprett brukere'
            Handling=
            [pscustomobject]@{
                Nummer=1
                Alternativ='Opprett bruker manuelt'
                Handling=[scriptblock]::Create('New-ADBruker')
            },
            [pscustomobject]@{
                Nummer=2
                Alternativ='Opprett brukere fra CSV'
                Handling=[scriptblock]::Create('New-ADBrukerCSV')
            }
        },
        [pscustomobject]@{
            Nummer=2
            Alternativ='Søk opp og modifiser brukere'
            Handling=
            [pscustomobject]@{
                Nummer=1
                Alternativ='Endre passord for bruker'
                Handling=[scriptblock]::Create('Set-ADBruker -passord')
            },
            [pscustomobject]@{
                Nummer=2
                Alternativ='Aktiver bruker'
                Handling=[scriptblock]::Create('Set-ADBruker -aktiver')
            },
            [pscustomobject]@{
                Nummer=3
                Alternativ='Deaktiver bruker'
                Handling=[scriptblock]::Create('Set-ADBruker -deaktiver')
            },
            [pscustomobject]@{
                Nummer=4
                Alternativ='Endre brukernavn'
                Handling=[scriptblock]::Create('Set-ADBruker -brukernavn')
            }
        },
        [pscustomobject]@{
            Nummer=3
            Alternativ='List ut alle deaktiverte brukere'
            Handling=[scriptblock]::Create('Write-ADDeaktivBruker')
        },
        [pscustomobject]@{
            Nummer=4
            Alternativ='List ut alle aktive brukere'
            Handling=[scriptblock]::Create('Write-ADAktivBruker')
        }
    },
    [pscustomobject]@{
        Nummer=2
        Alternativ='Arbeidsstasjoner'
        Handling=[pscustomobject]@{
           
        }
    },
    [pscustomobject]@{
        Nummer=3
        Alternativ='Grupper'
        Handling=
        [pscustomobject]@{
            Nummer=1
            Alternativ='Opprett grupper manuelt'
            Handling=[scriptblock]::Create('New-ADGruppe')
        },
        [pscustomobject]@{
            Nummer=2
            Alternativ='Opprett gruppe fra tekstfil'
            Handling=[scriptblock]::Create('New-ADGruppe -FraFil')
        },
        [pscustomobject]@{
            Nummer=3
            Alternativ='Søk opp og endre gruppenavn'
            Handling=[scriptblock]::Create('Set-ADGruppe -Navn')
        },
        [pscustomobject]@{
            Nummer=4
            Alternativ='Søk opp og endre gruppescope'
            Handling=[scriptblock]::Create('Set-ADGruppe -Scope')
        },
        [pscustomobject]@{
            Nummer=5
            Alternativ='Søk opp og slett gruppe'
            Handling=[scriptblock]::Create('Set-ADGruppe -Slett')
        }
    },
    [pscustomobject]@{
        Nummer=4
        Alternativ='Konfigurer GPO'
        Handling=[pscustomobject]@{
           
        }
    }
},
[pscustomobject]@{
    Nummer=4
    Alternativ='Hyper-V'
    Handling='..'
}


# Navn for servere
$global:NavnHyperV = 'Hyper-V Server'
$global:NavnVRouter = 'Virtuell Router'
$global:NavnADServer = 'Active Directory Server'

# IP for servere 
$global:IPHyperV = '158.38.56.146'
$global:IPVRouter = '158.38.56.149'
$global:IPADServer = '158.38.56.149'

# IP og port for servere 
$global:HyperV = @{NAVN=$NavnHyperV;IP=$IPHyperV;PORT='13389';PREFIX='hv'}
$global:vRouter = @{NAVN=$NavnVRouter;IP=$IPVRouter;PORT='13389';PREFIX='vr'}
$global:ADServer = @{NAVN=$NavnADServer;IP=$IPADServer;PORT='33895';PREFIX='vr'}

# Prefix for servere
$global:PrefixHyperV = 'hv'
$global:PrefixVRouter = 'vr'
$global:PrefixADServer = 'ad'

# Initialiserer nødvendige moduler 
Import-Module .\bActiveDirectoryModul.psm1 -force -WarningAction SilentlyContinue
Import-Module .\bSesjonModul.psm1 -force -WarningAction SilentlyContinue
Import-Module .\bObjektModul.psm1 -force -WarningAction SilentlyContinue

# Kobler til sesjonene 
Connect-Sesjoner -Servere $HyperV, $vRouter, $ADServer -Credentials $cred

# Henter sesjoner inn i variabel
$global:SesjonHyperV = Get-PSSession -name $NavnHyperV
$global:SesjonVRouter = Get-PSSession -name $NavnVRouter
$global:SesjonADServer = Get-PSSession -name $NavnADServer

$tidligereValg = $null 

function Add-StandardObjekt
{
    param
    (
        [parameter(mandatory)]$Objekt,
        $tidvalg
    )
    
    $Nummer = $Objekt.nummer.length + 1
    
    if('Tilbake' -notin $Objekt.alternativ -and 'Hyper-V' -notin $objekt.alternativ)
    {
        $objekt += [pscustomobject]@{
            Nummer=$Nummer
            Alternativ='Tilbake'
            Handling= $tidvalg #[scriptblock]::Create('Out-Null')
        }
    }

    # Legger på avslutt 
    if('Avslutt' -notin $Objekt.alternativ)
    {
        $Objekt += [PSCustomObject]@{
            Nummer=$Nummer+1
            Alternativ='Avslutt'
            Handling=[scriptblock]::Create('Write-Host "Avslutter. . ."; break')
        }
    }
    return $Objekt
}

do
{

    $avslutt = $false 
    $meny = Add-StandardObjekt $meny $tidligereValg
    $meny | ft -AutoSize
    $tidligereValg = $meny

    do
    {
        $err = $false 
        $r = Read-Host '>'
        $valg = $meny | where {$_.nummer -eq $r} 
        if($valg -eq $null)
        {
            $err = $true 
            write-host 'Feil i inndata. Prøv på nytt.' -ForegroundColor red
        }
    }while($err -eq $true)
    
    try
    {
        Invoke-Command -ScriptBlock $valg.handling | out-host
    }
    catch
    {
        write 'catch'
        $meny = $valg | Select-Object -ExpandProperty Handling    
    }
}while($avslutt -eq $false)

