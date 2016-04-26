$meny = 
[pscustomobject]@{
    Nummer=1
    Alternativ='Virtuell Router'
    Handling='..'
},
[pscustomobject]@{
    Nummer=2
    Alternativ='Pull'
    Handling=
    [pscustomobject]@{
        Nummer=1
        Alternativ='Sett opp Pull Server'
        Handling=[scriptblock]::Create('New-PullServer')
    },
    [pscustomobject]@{
        Nummer=2
        Alternativ='Sett opp Pull Mode på klient'
        Handling=[scriptblock]::Create('Set-PullMode')
    },
    [pscustomobject]@{
        Nummer=3
        Alternativ='Legg til DSC konfigurasjon for en server'
        Handling=[scriptblock]::Create('')
    }
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
        Handling=
        [pscustomobject]@{
            Nummer=1
            Alternativ='List ut arbeidsstasjoner'
            Handling=[scriptblock]::Create('Write-AdArbeidsstasjon -pause')
        },
        [pscustomobject]@{
            Nummer=2
            Alternativ='Aktiver arbeidsstasjon'
            Handling=[scriptblock]::Create('Set-ArbeidsStasjon -Aktiver')         
        },
        [pscustomobject]@{
            Nummer=3
            Alternativ='Deaktiver arbeidsstasjon'
            Handling=[scriptblock]::Create('Set-ArbeidsStasjon -Deaktiver')         
        },
        [pscustomobject]@{
            Nummer=4
            Alternativ='Ny arbeidsstasjon'
            Handling=[scriptblock]::Create('New-ArbeidsStasjon')         
        },
        [pscustomobject]@{
            Nummer=5
            Alternativ='Slett arbeidsstasjon'
            Handling=[scriptblock]::Create('Remove-ArbeidsStasjon')         
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
        },
        [pscustomobject]@{
            Nummer=6
            Alternativ='Legg brukere til i gruppe'
            Handling=[scriptblock]::Create('Add-BrukerTilGruppe')
        },
        [pscustomobject]@{
            Nummer=7
            Alternativ='Legg gruppe til i gruppe'
            Handling=[scriptblock]::Create('Add-GruppeTilGruppe')
        },
        [pscustomobject]@{
            Nummer=8
            Alternativ='List ut medlemmer av gruppe'
            Handling=[scriptblock]::Create('Get-ADGruppe')
        }
    },
    [pscustomobject]@{
        Nummer=4
        Alternativ='Konfigurer GPO'
        Handling=
        [pscustomobject]@{
            Nummer=1
            Alternativ='Opprett GPO'
            Handling=[scriptblock]::Create('New-cGPO')
        },
        [pscustomobject]@{
            Nummer=2
            Alternativ='Legg gruppe til GPO'
            Handling=[scriptblock]::Create('Add-GRuppeTilGPO')
        },
        [pscustomobject]@{
            Nummer=3
            Alternativ='Fjern gruppe fra GPO'
            Handling=[scriptblock]::Create('Remove-GruppeFraGPO')
        },
        [pscustomobject]@{
            Nummer=4
            Alternativ='Sett brannmur GPO'
            Handling=[scriptblock]::Create('Set-GPO -brannmur')
        },
        [pscustomobject]@{
            Nummer=5
            Alternativ='Slett GPO'
            Handling=[scriptblock]::Create('Remove-cGPO')
        },
        [pscustomobject]@{
            Nummer=6
            Alternativ='List ut alle GPO'
            Handling=[scriptblock]::Create('Write-GPO')
        },
        [pscustomobject]@{
            Nummer=7
            Alternativ='Sett GPO status'
            Handling=[scriptblock]::Create('Set-GPO -status')
        }
    }
},
[pscustomobject]@{
    Nummer=4
    Alternativ='Hyper-V'
    Handling=
    [pscustomobject]@{
        Nummer=1
        Alternativ='Opprett ny virtuell maskin uten virtuell harddisk'
        Handling=[scriptblock]::Create('New-VirtuellMaskin -NoVhd')
    },
    [pscustomobject]@{
        Nummer=2
        Alternativ='Opprett ny virtuell maskin med virtuell harddisk'
        Handling=[scriptblock]::Create('New-VirtuellMaskin -NyVhd')
    },
    [pscustomobject]@{
        Nummer=3
        Alternativ='Opprett ny virtuell maskin fra template'
        Handling=[scriptblock]::Create('New-VirtuellMaskin -Template')
    },
    [pscustomobject]@{
        Nummer=4
        Alternativ='Endre virtuelt minne'
        Handling=[scriptblock]::Create('Set-VirtueltMinne')
    },
    [pscustomobject]@{
        Nummer=5
        Alternativ='Opprett checkpoints'
        Handling=[scriptblock]::Create('New-VmCheckPoint')
    },
    [pscustomobject]@{
        Nummer=6
        Alternativ='Slett checkpoints'
        Handling=[scriptblock]::Create('Remove-VmCheckPoint')
    }, # Slett snapshots eldre enn X dager? https://technet.microsoft.com/en-us/library/hh848601.aspx
    [pscustomobject]@{
        Nummer=7
        Alternativ='Start virtuelle maskiner'
        Handling=[scriptblock]::Create('Start-VirtuellMaskin')
    },
    [pscustomobject]@{
        Nummer=8
        Alternativ='Skru av virtuelle maskiner'
        Handling=[scriptblock]::Create('Stopp-VirtuellMaskin')
    },
    [pscustomobject]@{
        Nummer=9
        Alternativ='Slett virtuell maskin'
        Handling=[scriptblock]::Create('Remove-VirtuellMaskin')
    }
}


# Navn for servere
$global:NavnHyperV = 'Hyper-V Server'
$global:NavnVRouter = 'Virtuell Router'
$global:NavnADServer = 'Active Directory Server'
$global:NavnPullServer = 'Pull Server'

# IP for servere 
$global:IPHyperV = '158.38.56.146'
$global:IPVRouter = '158.38.56.149'
$global:IPADServer = '158.38.56.149'
$global:IPPullServer = '158.38.56.147'

# IP og port for servere 
$global:HyperV = @{NAVN=$NavnHyperV;IP=$IPHyperV;PORT='13389';PREFIX='hv'}
$global:vRouter = @{NAVN=$NavnVRouter;IP=$IPVRouter;PORT='13389';PREFIX='vr'}
$global:ADServer = @{NAVN=$NavnADServer;IP=$IPADServer;PORT='33895';PREFIX='vr'}
$global:PullServer = @{NAVN=$global:NavnPullServer;IP=$global:IPPullServer;PORT='13389';PREFIX='ps'}

# Prefix for servere
$global:PrefixHyperV = 'hv'
$global:PrefixVRouter = 'vr'
$global:PrefixADServer = 'ad'
$global:PrefixPullServer = 'ps'

# Initialiserer nødvendige moduler 
Import-Module .\bActiveDirectoryModul.psm1 -force -WarningAction SilentlyContinue
Import-Module .\bSesjonModul.psm1 -force -WarningAction SilentlyContinue
Import-Module .\bObjektModul.psm1 -force -WarningAction SilentlyContinue
Import-Module .\bDesiredStateConfiguration.psm1 -Force -WarningAction SilentlyContinue
Import-Module .\bHyperVModul.psm1 -Force -WarningAction SilentlyContinue

# Kobler til sesjonene 
Connect-Sesjoner -Servere $HyperV, $vRouter, $ADServer, $PullServer -Credentials $cred

# Henter sesjoner inn i variabel
$global:SesjonHyperV = Get-PSSession -name $NavnHyperV
$global:SesjonVRouter = Get-PSSession -name $NavnVRouter
$global:SesjonADServer = Get-PSSession -name $NavnADServer
$global:sesjonPullServer = Get-PSSession -name $NavnPullServer

$tidligereValg = $null 

function Add-StandardObjekt
{
    param
    (
        [parameter(mandatory)][pscustomobject[]]$Objekt,
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
    # Løkken går så lenge avslutt er lik false 
    $avslutt = $false 

    # Legger til 'tilbake' og 'avslutt' i meny
    $meny = Add-StandardObjekt $meny $tidligereValg

    # Skriver ut meny 
    $meny | ft -AutoSize

    # Legger menyen i variabel slik at den huskes til neste runde i løkken
    $tidligereValg = $meny

    do
    {
        # Går så lenge valget ikke er gyldig
        $err = $false 

        # Lar brukeren velge 
        $r = Read-Host '>'
        
        # Hent valg 
        $valg = $meny | where {$_.nummer -eq $r} 
        
        # Kjør løkke på nytt hvis valget ikke har gitt noen resultat 
        if($valg -eq $null)
        {
            $err = $true 
            write-host 'Feil i inndata. Prøv på nytt.' -ForegroundColor red
        }
    }while($err -eq $true)
    
    # Forsøker å utføre kode 
    try
    {
        Invoke-Command -ScriptBlock $valg.handling | out-host
    }
    # Hvis det ikke er kode, skal det være et menyobjekt 
    catch
    {
        write 'catch'
        $meny = $valg | Select-Object -ExpandProperty Handling    
    }
}while($avslutt -eq $false)

