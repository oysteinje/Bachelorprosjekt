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
    
    $VMs = Invoke-Command -Session $SesjonHyperV -ScriptBlock {
        get-vm | Get-VMMemory 
    } 

    $Vms = Set-LinjeNummer $VMs

    Write-host ($vms | ft -autosize -prop nummer, vmname, DynamicMemoryEnabled, `
        @{Label='Minimum';Expression={Format-size($_.minimum)}}, 
        @{Label='Startup';Expression={Format-size($_.Startup)}},
        @{Label='Maximum';Expression={Format-size($_.Maximum)}} | 
        out-string)


    $ValgtVM = Select-EgenDefinertObjekt -Objekt $vms -Parameter nummer -Prompt 'Velg vm ved å skrive inn nummer'
    
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