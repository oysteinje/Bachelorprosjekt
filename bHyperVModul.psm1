# HYPER-V FUNKSJONER 

Function Write-VmSvitsj 
{
    param($VmSwitsj)

    Write-Host ($VmSwitsj | `
        Format-Table -AutoSize -Property Nummer, Name, SwitchType, NetAdapterInterfaceDescription | out-string)
}

Function Get-VmSvitsj
{
    param($sesjon)

    $Svitsjer = Invoke-Command -Session $sesjon -ScriptBlock {
        Get-VMSwitch 
    } 

    $Svitsjer = Set-LinjeNummer $Svitsjer

    return $Svitsjer
}

Function Select-VmSvitsj
{
    param($VmSvitsj) 

    do
    {
        Write-VmSvitsj -VmSwitsj $VmSvitsj    
        $valg = Read-Tall -Prompt 'Velg Virtuell Svitsj [f.eks. 1]' -NotNull
        $ValgtSvitsj = $VmSvitsj | where{$_.nummer -eq $valg} | Select-Object -ExpandProperty Name 
    }
    while($ValgtSvitsj -eq $null)
    
    return $ValgtSvitsj
}

Function New-VirtuellMaskin
{
    param(
    	[switch]$NyVHD,
        [switch]$NoVhd,
        [switch]$Template)

    while ($VmNavn.Length -eq 0) {
        [string[]]$VmNavn = (Read-Host -Prompt 'Skriv inn navn på virtuelle maskiner. Skill med komma').Split(',') | `
            foreach {$_.trim()}
    }

    $OppstartsMinne = Read-Tall -Prompt 'Skriv inn oppstartsminne [1GB]' -DefaultVerdi 1GB
    
    # Velg generasjon 
    $alternativer = [pscustomobject]@{'Name'='Generasjon 1';'Value'=1},[pscustomobject]@{'Name'='Generasjon 2';'Value'=2}
    $Generasjon = Select-Alternativ -alternativer $alternativer -Prompt 'Velg generasjon [2]' -Default 2

    # Velg svitsj 
    $VmSvitsj = Select-VmSvitsj -VmSvitsj (Get-VmSvitsj -sesjon $SesjonHyperV)

    # Skriv ut ledig plass på stasjonene 


    # Velg sti 
    do{
        $Sti = Read-Host -Prompt 'Skriv sti der virtuell maskin skal lagres f.eks [C:\VM]'
        
        Invoke-Command -Session $SesjonHyperV -ScriptBlock {
            if((Test-Path $using:sti) -eq $false) { mkdir $using:Sti }
        } 
         
    }while($? -eq $false)


    if($NyVHD) {
        do {
            $VhdSti = Read-Host 'Sti der virtuell harddisk skal lagres'
            Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                if((Test-Path $using:vhdsti) -eq $false) { mkdir $using:vhdsti }
            }
        }while($? -eq $false)
        
        
        if($VhdSti.Substring($VhdSti.Length - 1) -ne '\') { $VhdSti += '\'}
         
        $VhdStørrelse = Read-Tall -Prompt 'Størrelse på virtuell harddisk [40GB]' -DefaultVerdi 40GB

        foreach ($vm in $VmNavn) {
            Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                New-VM -name $using:vm -MemoryStartupBytes $using:OppstartsMinne -Generation $using:Generasjon `
                    -Path $using:sti -NewVHDPath "$using:VhdSti$using:vm.VHDX" -NewVHDSizeBytes $using:VhdStørrelse 
            } 
            if($?) {Write-Host "VM med navnet $vm er opprettet"}
            else{Write-Host "Noe gikk galt, $vm er ikke opprettet"}
        }
    }elseif($NoVhd){
        foreach ($vm in $VmNavn) {
            Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                new-vm -name $using:vm -MemoryStartupBytes $using:OppstartsMinne `
                -SwitchName $using:VmSvitsj -Path $using:sti -Generation $using:Generasjon -NoVHD 
            }
            if($?) {Write-Host "VM med navnet $vm er opprettet"}
            else{Write-Host "Noe gikk galt, $vm er ikke opprettet"}
        }
    }
    elseif($Template) {
        
        do{
            $VhdParentPath = Read-String -Prompt 'Sti til template harddisk [f.eks. C:\MinTemplate.vhdx]' 

            $TestSti = Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                Get-VHD -Path $using:VhdParentPath -ErrorAction SilentlyContinue
            }


            if($TestSti -eq $null) {       
                Write-Host 'Finner ikke template. Prøv på nytt'
                $TestSti = $false
            }
            
        }while($TestSti -eq $false)

        do {
            $VhdSti = Read-String -Prompt  'Sti der virtuell harddisk skal lagres [f.eks. C:\]'
            
            Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                if((Test-Path $using:vhdsti) -eq $false) { mkdir $using:vhdsti }
            }
        }while($? -eq $false)
        
        
        if($VhdSti.Substring($VhdSti.Length - 1) -ne '\') { $VhdSti += '\'}
         
        #$VhdStørrelse = Read-Tall -Prompt 'Størrelse på virtuell harddisk [40GB]' -DefaultVerdi 40GB        

        foreach ($vm in $VmNavn) {
            Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                New-VHD -ParentPath $using:VhdParentPath -Path "$using:VhdSti$using:vm.VHDX" 
                New-VM -Name $using:vm -VHDPath "$using:VhdSti$using:vm.VHDX" -SwitchName $using:VmSvitsj `
                -Path $using:sti -MemoryStartupBytes $using:OppstartsMinne -Generation $using:Generasjon

            }
            if($?) {Write-Host "VM med navnet $vm er opprettet"}
            else{Write-Host "Noe gikk galt, $vm er ikke opprettet"}
        }
    }
}

Function Format-Size {
    param(
        [parameter(mandatory=$true)]
    $Størrelse)
    
    # Mindre enn 1MB 
    if($Størrelse -lt 1048576) {
        return "$([math]::truncate(($Størrelse / 1MB),2))`KB"
    }
    # Mindre enn 1GB
    elseif($Størrelse -lt 1073741824) {
        return "$([math]::round(($Størrelse / 1MB),2))`MB"
    # Større enn 1GB
    }else {
        return "$([math]::truncate(($Størrelse / 1GB)))`GB"
    }
}

# Lister ut detaljert (relevant) informasjon for virtuelle maskiner 
Function Write-VmDetaljert {
    param(
        [parameter(mandatory=$true)]
        $VMs
    )

    # Skriv ut virtuelle maskiner 
    $VMs | Format-Table -AutoSize `
        -Property vmname, Status, `
        @{Label='Memory';Expression={Format-Size($_.memoryassigned)}}, `
        Version, Path, CheckpointFileLocation, Uptime
}


Function Set-VirtueltMinne 
{
    # Hent alle VM 
    $VMs = Invoke-Command -Session $SesjonHyperV -ScriptBlock {
        get-vm | Get-VMMemory 
    } 

    # Legger på linjenummer 
    $Vms = Set-LinjeNummer $VMs

    # Skriv ut alle VM 
    Write-host ($vms | ft -autosize -prop nummer, vmname, DynamicMemoryEnabled, `
        @{Label='Minimum';Expression={Format-size($_.minimum)}}, 
        @{Label='Startup';Expression={Format-size($_.Startup)}},
        @{Label='Maximum';Expression={Format-size($_.Maximum)}} | 
        out-string)

    # Bruker velger VM 
    $ValgtVM = Select-EgenDefinertObjekt -Objekt $vms -Parameter 'nummer' `
        -Prompt 'Velg vm ved å skrive inn nummer. Skill med komma for å velge flere'
    
    # Returner hvis avslutt 
    if($ValgtVM -eq "x!") {return $null} 

    # Hent ut vm objekt for alle maskiner 
    $ValgtVmState = Invoke-Command -Session $SesjonHyperV -ScriptBlock {        
        ($using:valgtvm).vmname | get-vm
    }

    # Hent ut alle maskiner som ikke er slått av 
    $ValgtVmState = $ValgtVmState | where {$_.state -ne 'off'} 

    # Gir mulighet til å skru av valgte vms som er påslått. Hvis ikke brukeren vil, avbrytes sekvensen.
    if($ValgtVmState -ne $null) {
         $SkruAv = Read-JaNei `
           -prompt "Virtuell maskin $($valgtVmState.vmname) må slås av for å endre minne. Ønsker du å dette? [j/n]"
         if($SkruAv) {
          Invoke-Command -Session $SesjonHyperV -ScriptBlock {
            Stop-VM -Name $using:ValgtVmState.vmname
          }  
        }else{
            return $null
        }                 
    }

    # Aktiver/Deaktiver dynamisk minne 
    if($ValgtVM.DynamicMemoryEnabled -eq $false) {
        $DynamicMemoryEnabled = Read-JaNei -prompt "Dynamisk minne er ikke aktivert. Ønsker du å aktivere? [j/n]"
    }else {
        $DynamicMemoryEnabled = Read-JaNei -prompt "Dynamisk minne er aktivert. Hvil du at dette fortsatt skal være aktivert? [j/n]"
    }

    $StartupBytes = Read-Tall -Prompt "Velg oppstarts minne f.eks. 1GB [$(Format-Size($ValgtVM.Startup))]" -DefaultVerdi $ValgtVM.Startup
    
    if($DynamicMemoryEnabled -eq $true) {     
        do {
            $MaximumBytes = Read-Tall -Prompt "Velg maximum minne f.eks. 2GB [$(Format-Size($ValgtVM.Maximum))]" `
                -DefaultVerdi $ValgtVM.Maximum
            
            $MinimumBytes = Read-Tall -Prompt "Velg minimum minne f.eks. 1GB [$(Format-Size($ValgtVM.Minimum))]" `
                -DefaultVerdi $ValgtVM.Minimum
        }while(($MinimumBytes -gt $MaximumBytes) -or ($StartupBytes -gt $MaximumBytes))

        foreach ($vm in $ValgtVM) {
            Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                Set-VMMemory -VMName $using:vm.vmname -DynamicMemoryEnabled $true -MinimumBytes $using:MinimumBytes `
                    -MaximumBytes $using:MaximumBytes -StartupBytes $using:StartupBytes 
            }
            if($?) {"Instillinger endret for $vm"}
            else {"Noe gikk galt med endringen av $vm"}
        }
    }else{
        foreach ($vm in $ValgtVM) {
            Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                Set-VMMemory -VMName $using:vm.vmname -DynamicMemoryEnabled $false `
                    -StartupBytes $using:StartupBytes 
            }
            if($?) {"Instillinger endret for $vm"}
            else {"Noe gikk galt med endringen av $vm"}
        }       
    } 
}

Function New-VmCheckPoint
{
    param(
        [switch]$Ny
    )


    # Hent virtuelle maskiner 
    $VMs = Invoke-Command -Session $SesjonHyperV -ScriptBlock {
        get-vm 
    } 

    # Legg til linjenummer 
    $Vms = Set-LinjeNummer $vms 

    # Skriv ut VMs 
    Write-Host ($vms | ft `
        -Property Nummer, Name, State, Uptime, Status, Version | out-string)
    
    # Velg vms 
    $ValgtVM = Select-EgenDefinertObjekt -Objekt $vms -Parameter nummer `
        -Prompt "Velg virtuell maskin. Skill med komma for å velge flere"

    # Hent checkpoints for VM 
    $CheckPoints = Invoke-Command -Session $SesjonHyperV -ScriptBlock {
        $using:ValgtVM.name | Get-VMCheckpoint
    }

    # Skriv ut checkpoints 
    if($CheckPoints -eq $null) { Write-Host "Det eksisterer ingen checkpoints for valgte maskiner"}
    else {
    
        Write-host ($CheckPoints | ft `
            -Property VMName, Name, SnapshotType, CreationTime, ParentSnapshotName | `
            out-string)
    }


    $Godta = Read-JaNei -prompt "Ønsker du å opprette checkpoint for $($ValgtVM.vmname)? [j/n]"
    
    if($Godta) {
        $SnapshotName = @()
        # Les inn snapshotnavn
        Foreach($vm in $ValgtVM) {
            $SnapshotName += Read-String -Prompt "SnapshotNavn for $($vm.vmname) [$($vm.vmname) - ($(Get-Date))]" `
                -Default "$($vm.vmname) - ($(Get-Date))"
        }
        
        # Opprett checkpoints
        $i = 0 
        foreach($vm in $ValgtVM) {
      
            $ThisSnapshotName = $SnapshotName[$i]
      
            Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                Checkpoint-VM -name $using:vm.name -SnapshotName $using:ThisSnapshotName
            }
      
            if($?){Write-Host "Checkpoint for $($vm.name) er opprettet"}
            else{Write-Host "Noe gikk galt ved opprettelse av checkpoint for $($vm.name)"}
      
            $i++
        }
    }else{
        return $null 
    }

}

Function Remove-VmCheckPoint
{
    $CheckPoints = Invoke-Command -Session $SesjonHyperV -ScriptBlock {
        Get-Vm | Get-VMCheckpoint
    }

    $CheckPoints = Set-LinjeNummer $CheckPoints

    Write-host ($CheckPoints | Format-Table `
        -Property Nummer, VMName, Name, SnapshotType, CreationTime, ParentSnapshotName | `
        Out-String)


    $ValgtCheckPoint = Select-EgenDefinertObjekt -Objekt $CheckPoints -Parameter nummer `
        -Prompt 'Skriv inn nummer for å velge CheckPoint. Skill med komma for å velge flere'

    Write-Host "Du har valgt $($ValgtCheckPoint.name)"

    $Godta = Read-JaNei -prompt "Ønsker du å slette disse? [j/n]"

    if($Godta) {
        foreach($checkpoint in $ValgtCheckPoint) {
            Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                get-vmsnapshot -id $using:checkpoint.id | Remove-VMSnapshot           
            }
            if($?){Write-Host "Checkpoint $($checkpoint.name) er slettet"}
            else{Write-Host "Noe gikk galt ved slettingen av $($checkpoint.name)"}
        }
    }else{
        return $null
    }
}

Function Start-VirtuellMaskin
{
    $VMs = Invoke-Command -Session $SesjonHyperV -ScriptBlock {
        get-vm | where {$_.state -eq 'Off'}
    }

    $VMs = Set-LinjeNummer $VMs 

    Write-Host ($VMs | format-table `
        -Property Nummer, Name, State, CPUUsage, Uptime, Status, Version | `
        out-string)

    $ValgtVM = Select-EgenDefinertObjekt -Objekt $VMs -Parameter nummer `
        -Prompt "Velg virtuelle maskiner du ønsker å starte ved å skrive nummer. Skill med komma for å velge flere"

    Write-Host "Du har valgt $($ValgtVM.name)"
    
    $Godta = Read-JaNei -prompt "Ønker du å starte disse? [j/n]"
    
    if($Godta) {
        Write-Host "Starter virtuelle maskiner" -ForegroundColor Cyan
        Invoke-Command -Session $SesjonHyperV -ScriptBlock {
            start-vm $using:ValgtVM.name
        }
    }
}

Function Stopp-VirtuellMaskin
{
    $VMs = Invoke-Command -Session $SesjonHyperV -ScriptBlock {
        get-vm | where {$_.state -eq 'Running'}
    }

    $VMs = Set-LinjeNummer $VMs 

    Write-Host ($VMs | format-table `
        -Property Nummer, Name, State, CPUUsage, Uptime, Status, Version | `
        out-string)

    $ValgtVM = Select-EgenDefinertObjekt -Objekt $VMs -Parameter nummer `
        -Prompt "Velg virtuelle maskiner du ønsker å stoppe ved å skrive nummer. Skill med komma for å velge flere"

    Write-Host "Du har valgt $($ValgtVM.name)"
    
    $Godta = Read-JaNei -prompt "Ønker du å stoppe disse? [j/n]"
    
    if($Godta) {
        Invoke-Command -Session $SesjonHyperV -ScriptBlock {
            stop-vm $using:ValgtVM.name
        }
    }
}

Function Remove-VirtuellMaskin
{
    $VMs = Invoke-Command -Session $SesjonHyperV -ScriptBlock {
        get-vm 
    }

    $VMs = Set-LinjeNummer $VMs 

    Write-Host ($VMs | format-table `
        -Property Nummer, Name, State, CPUUsage, Uptime, Status, Version | `
        out-string)

    $ValgtVM = Select-EgenDefinertObjekt -Objekt $VMs -Parameter nummer `
        -Prompt "Velg virtuelle maskiner du ønsker å slette ved å skrive nummer. Skill med komma for å velge flere"

    Write-Host "Du har valgt $($ValgtVM.name)"
    
    $Godta = Read-JaNei -prompt "Ønker du å slette disse? [j/n]"
    
    if($Godta) {
        Invoke-Command -Session $SesjonHyperV -ScriptBlock {
            remove-vm -name $using:valgtvm.name
        }
    }    
}

Function Write-AdArbeidsstasjon 
{
    param(
        $ArbeidsStasjoner,
        [switch]$pause
    )

    if($ArbeidsStasjoner -eq $null) {
        $ArbeidsStasjoner = Get-AdArbeidsstasjon 
    }
    
    Write-output $ArbeidsStasjoner | format-table `
         -Property name, enabled, dnshostname, ObjectGUID, SamAccountName, DistinguishedName

    if($pause){pause}           
}


Function Get-AdArbeidsstasjon
{
    $ArbeidsStasjoner = invoke-command -Session $SesjonADServer -ScriptBlock {
        Get-Adcomputer -filter *
    }

    return $ArbeidsStasjoner 
}

Function Set-ArbeidsStasjon
{
    param(
        [switch]$Aktiver,
        [switch]$Deaktiver
    )

    # Hent ut arbeidsstasjoner 
    

    if($Aktiver) {
        $ArbeidsStasjoner = (Get-AdArbeidsstasjon | where {$_.enabled -eq $false})
        Write-AdArbeidsstasjon -ArbeidsStasjoner $ArbeidsStasjoner
        if($ArbeidsStasjoner -ne $null) {
            $ArbeidsStasjoner = Set-LinjeNummer $ArbeidsStasjoner
            $ValgtAS = Select-EgenDefinertObjekt -Objekt $ArbeidsStasjoner `
                -Parameter nummer `
                -Prompt "Velg arbeidsstasjoner du ønsker å aktivere ved å skrive inn nummer. Skill med komma for å velge flere"
            $Godkjent = Read-JaNei -prompt "Ønsker du å aktivere $($ValgtASs.name)? [j/n]" 
            if($Godkjent) {
                foreach($as in $ValgtAS) {
                    Invoke-Command -Session $SesjonADServer -ScriptBlock {
                        Set-ADComputer -Identity $as.ObjectGUID -Enabled $true 
                    }
                }
            }                   
        }else{
            Write-Host 'Det finnes ingen deaktiverte arbeidsstasjoner'
        }
    }
    if($Deaktiver) {
         $ArbeidsStasjoner = (Get-AdArbeidsstasjon | where {$_.enabled -eq $true})
         Write-AdArbeidsstasjon -ArbeidsStasjoner $ArbeidsStasjoner

         if($ArbeidsStasjoner -ne $null) {
            $ArbeidsStasjoner = Set-LinjeNummer $ArbeidsStasjoner
            $valgtAS = Select-EgenDefinertObjekt -Objekt $ArbeidsStasjoner `
                -Parameter nummer `
                -Prompt 'Velg arbeidsstasjoner du ønsker å deaktivere ved å skrive nummer. Skill med komma for å velge flere'
           $Godkjent = Read-JaNei -prompt "Ønsker du å deaktivere $($valgtAS.name)? [j/n]"
           if($Godkjent) {
                foreach($as in $ArbeidsStasjoner){
                    Invoke-Command -Session $SesjonADServer -ScriptBlock {
                        Set-ADComputer -Identity $as.objectguid -enabled $false
                    }
                }
           }
         }else{
            Write-Host 'Det finnes ingen aktiverte arbeidsstasjoner'
         }
    }
}

Function New-ArbeidsStasjon
{
    # Les inn passord 
    $pw = read-host "Skriv inn ønsket passord. Kan stå tomt" 

    # Konverter passord 
    if($pw -ne "") {
        $pw = ConvertTo-SecureString -String $pw -AsPlainText -Force
    }else{
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


    <#
    do {
        
        $err = $false

        $AdComputerNavn = Read-String -Prompt 'Skriv inn navn på AD arbeidsstasjon. Skill med komma for å opprette flere'

        $TestNavn = Invoke-Command -Session $SesjonADServer -ScriptBlock {
            $adcomp = $using:AdComputerNavn
            get-adcomputer -filter {name -eq $adcomp}
        }

        if($TestNavn -ne $null) {
            Write-Host "Det finnes allerede en arbeidsstasjon med navnet $AdComputerNavn"
            $err = $true 
        }
    }while($err -eq $true)
    
    # Opprett adstasjon 
    Invoke-Command -Session $SesjonADServer -ScriptBlock {
        new-adcomputer -name $using:AdComputerNavn
    }
    
    if($?) {"Arbeidsstasjonen $AdComputerNavn er opprettet"}
    else {"Noe gikk galt med opprettelsen av $AdComputerNavn"}
    #>
}

Function Remove-ArbeidsStasjon
{
    $ArbeidsStasjoner = Get-AdArbeidsstasjon 
    $ArbeidsStasjoner = Set-LinjeNummer $ArbeidsStasjoner 
   
    Write-Host ($ArbeidsStasjoner | format-table `
         -Property nummer, name, enabled, dnshostname, ObjectGUID, SamAccountName, DistinguishedName | 
         ` Out-String)
        
    $ValgtAdAs = Select-EgenDefinertObjekt -Objekt $ArbeidsStasjoner -Parameter nummer `
        -Prompt "Velg arbeidsstasjon ved å skrive nummer. Skill med komma for å velge flere"
    
    $Godta = Read-JaNei -prompt "Ønsker du å slette arbeidsstasjon $($ValgtAdAs.name)? [j/n]"
    if($Godta) {
        foreach($as in $ValgtAdAs) {
            Invoke-Command -Session $SesjonADServer -ScriptBlock {
                Remove-ADComputer -Identity $using:as.ObjectGUID
            }
        }
    }
}