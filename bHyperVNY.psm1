#####################
### Hyper-V Modul ###
#####################

# Spesifiser Hyper-V Sesjon her 
Function Get-HyperVSesjon
{
    return $SesjonHyperV 
}

# Returnerer alle vm eller vm basert på ID 
Function Get-VirtuellMaskin 
{
    param($id) 


    # Hent ut alle VM hvis id er tom 
    if($id -eq $null) 
    {
        Invoke-Command -Session (Get-HyperVSesjon) `
        -ScriptBlock {
            get-vm 
        }
    }
    # Hent ut vm basert på id 
    else {
        Invoke-Command -Session (Get-HyperVSesjon) `
        -ScriptBlock {
            get-vm $using:id 
        }
    }    
}

# Konverterer string til byte 
Function Convert-StørrelseTilByte
{
    param(
        [parameter(mandatory=$true)]
        [string]$Tall
    )

    try {
        $StørrelseType = $tall.substring($tall.length -2) 
    }catch{}

    if($StørrelseType -eq 'GB') {
        try {
            [int64]$tall = $tall.remove($tall.length -2, 2) 
            $tall = $tall * 1024 * 1024 * 1024
        }catch { }
    }elseif($StørrelseType -eq 'MB') {
        try {
            [int64]$tall = $tall.remove($tall.length -2, 2) 
            $tall = $tall * 1024 * 1024
        }catch {}
    }elseif($StørrelseType -eq 'KB') {
        try {
            [int64]$tall = $tall.remove($tall.length -2, 2) 
            $tall = $tall * 1024
        }catch {}
    }

    return $tall 
}

# Returnerer virtuelle svitsjer 
Function Get-VmSvitsj
{
    $Svitsjer = Invoke-Command -Session (Get-HyperVSesjon) -ScriptBlock {
        Get-VMSwitch 
    } 

    return $Svitsjer
}

# Oppretter VM 
Function New-VirtuellMaskin
{
    param(
    	[switch]$NewVHD,
        [switch]$NoVhd,
        [switch]$Template
    )

    # Hent inn eksisterende vm 
    $vm = Get-VirtuellMaskin 

    # Les inn navn for vm 
    while($vmNavn -eq "" -or $vmNavn -eq $null) {
        # Les inn vm navn 
        $vmNavn = Read-Host `
        "Skriv inn navn for VM. Skill med komma for å opprette flere"
        
        # Splitt 
        $vmnavn = $vmNavn.Split(',')

        # Trim 
        $vmNavn = $vmNavn.Trim()
    }
    
    # Fiks doble forekomster 
    for($i=0;$i -le $vmNavn.Length; $i++) 
    {
        while ($vmNavn[$i] -in $vm.name -or $vmNavn[$i] -eq "")
        {
            $vmnavn[$i] = 
            read-host -Prompt `
            "Navnet $($vmNavn[$i]) eksisterer allerede, velg et annet"
        }
    }

    # Les inn generasjon 
    do{
        $gen = 
        read-host -Prompt `
        "Skriv inn ønsket generasjon [1,2]"
    }while($gen -notin 1,2)
    
    # Les inn svitsj 
    $vmsvitsjer = get-vmsvitsj 
    
    # Skriv ut vmsvitsj 
    write-host ($vmsvitsjer | select -prop name | out-string)

    # Velg vmsvitsj 
    do{
        # Les inn svitsj 
        $vmsvitsj =
        read-host -Prompt `
        "Skriv inn navn på ønsket vmsvitsj
        La stå tom hvis du ikke ønsker å velge dette nå.
        "
    }while($vmsvitsj -notin $vmsvitsjer.name -or $vmsvitsj -eq "")

    # Sti der vm skal lagres 
    do{
        # Skriv inn sti 
        $VmSti = Read-Host -Prompt `
        '
        Skriv sti der virtuell maskin skal lagres f.eks [C:\VM]
        La stå tomt for å bruker standardplassering
        '
        
        # Test sti  
        if($VmSti -ne "") {
            Invoke-Command -Session (Get-HyperVSesjon) -ScriptBlock {
                # Sjekk om mappe ekisterer 
                if((Test-Path -literalpath $using:VmSti) -eq $false) 
                { 
                    # opprett mappe 
                    mkdir $using:VmSti
                }
            } 
        }
    }while($? -eq $false)

    # VM med ny VHD 
    if($NewVHD) 
    {
        do {
            # Opprett sti der vmdisk skal lagres 
            $VhdSti = Read-Host 'Sti der virtuell harddisk skal lagres'

            # Opprett mappe hvis den ikke eksisterer 
            Invoke-Command -Session (Get-HyperVSesjon) -ScriptBlock {
                if((Test-Path -literalpath $using:vhdsti) -eq $false) 
                { 
                    mkdir $using:vhdsti 
                }
            }
        }while($? -eq $false)
        
        # Legger til \ på slutten av mappen 
        if($VhdSti.Substring($VhdSti.Length - 1) -ne '\') 
        { 
            $VhdSti += '\'
        }
        
        # Leser inn størrelse  
        do{  
            # Les inn størrelse på harddisk 
            $VhdStørrelse = Read-Host `
            -Prompt 'Størrelse på virtuell harddisk i GB [40GB]'

            # Standardverdi 
            if($VhdStørrelse -eq "") {
                $VhdStørrelse = 40GB 
            }else{
                try{
                    # Konverter GB/MB/KB til byte 
                    $VhdStørrelse = Convert-StørrelseTilByte $VhdStørrelse
                }catch{
                    write-host "Feil i inndata"
                }
            }
        }while($VhdStørrelse -lt 1GB -or ($VhdStørrelse.gettype().name -notin 'int32', 'int64'))
        
        # Oppretter vm 
        foreach ($vm in $VmNavn) {
            Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                New-VM -name $using:vm `
                       -MemoryStartupBytes $using:OppstartsMinne `
                       -Generation $using:Generasjon `
                       -Path $using:sti `
                       -NewVHDPath "$using:VhdSti$using:vm.VHDX" `
                       -NewVHDSizeBytes $using:VhdStørrelse 
            } 
            if($?) {Write-Host "VM med navnet $vm er opprettet"}
            else{Write-Host "Noe gikk galt, $vm er ikke opprettet"}
        }


        #new-vm -name -MemoryStartupBytes -Generation 1 -SwitchName -NewVHDPath 
    }
    if($NoVhd)
    {
        #new-vm -name -MemoryStartupBytes -Generation 1 -SwitchName -NoVHD
    }
    if($Template)
    {
        #new-vm -name -MemoryStartupBytes -Generation 1 -SwitchName -VHDPath
    }  
}


# Oppretter VM 
Function New-VirtuellMaskin2
{
    [cmdletbinding(DefaultParameterSetName='NoVhd')]
    param(
        [Parameter(ParameterSetName='NewVHD', 
        Mandatory=$false)]
    	[switch]$NewVHD,
        
        [Parameter(ParameterSetName='NoVhd', 
        Mandatory=$false)]
        [switch]$NoVhd,

        [Parameter(ParameterSetName='Template', 
        Mandatory=$false)]
        [switch]$Template
    )

    # Hent inn eksisterende vm 
    $vm = Get-VirtuellMaskin 

    # Les inn navn for vm 
    while($vmNavn -eq "" -or $vmNavn -eq $null) {
        # Les inn vm navn 
        $vmNavn = Read-Host `
        "Skriv inn navn for VM. Skill med komma for å opprette flere"
        
        # Splitt 
        $vmnavn = $vmNavn.Split(',')

        # Trim 
        $vmNavn = $vmNavn.Trim()
    }
    
    # Fiks doble forekomster 
    for($i=0;$i -le $vmNavn.Length; $i++) 
    {
        while ($vmNavn[$i] -in $vm.name -or $vmNavn[$i] -eq "")
        {
            $vmnavn[$i] = 
            read-host -Prompt `
            "Navnet $($vmNavn[$i]) eksisterer allerede, velg et annet"
        }
    }

    # Les inn generasjon 
    do{
        $gen = 
        read-host -Prompt `
        "Skriv inn ønsket generasjon [1,2]"
    }while($gen -notin 1,2)
    
    # Les inn svitsj 
    $vmsvitsjer = get-vmsvitsj 
    
    # Skriv ut vmsvitsj 
    write-host ($vmsvitsjer | select -prop name | out-string)

    # Velg vmsvitsj 
    do{
        # Les inn svitsj 
        $vmsvitsj =
        read-host -Prompt `
        "Skriv inn navn på ønsket vmsvitsj
        La stå tom hvis du ikke ønsker å velge dette nå.
        "
        # Setter inndata evt. til null
        if($vmsvitsj -eq "") {
            $vmsvitsj = $null
        }
    }until($vmsvitsj -in $vmsvitsjer.name -or $vmsvitsj -eq $null)

    # Sti der vm skal lagres 
    do{
        # Skriv inn sti 
        $VmSti = Read-Host -Prompt `
        '
        Skriv sti der virtuell maskin skal lagres f.eks [C:\VM]
        La stå tomt for å bruker standardplassering
        '
        
        # Test sti  
        if($VmSti -ne "") {
            Invoke-Command -Session (Get-HyperVSesjon) -ScriptBlock {
                # Sjekk om mappe ekisterer 
                if((Test-Path -literalpath $using:VmSti) -eq $false) 
                { 
                    # opprett mappe 
                    mkdir $using:VmSti  
                }
            } 
        }
    }while($? -eq $false)

    # VM med ny VHD 
    if($NewVHD) 
    {
        do {
            # Opprett sti der vmdisk skal lagres 
            $VhdSti = Read-Host 'Sti der virtuell harddisk skal lagres'

            # Opprett mappe hvis den ikke eksisterer 
            Invoke-Command -Session (Get-HyperVSesjon) -ScriptBlock {
                if((Test-Path -literalpath $using:vhdsti) -eq $false) 
                { 
                    mkdir $using:vhdsti 
                }
            }
        }while($? -eq $false)
        
        # Legger til \ på slutten av mappen 
        if($VhdSti.Substring($VhdSti.Length - 1) -ne '\') 
        { 
            $VhdSti += '\'
        }
        
        # Leser inn størrelse  
        do{  
            # Les inn størrelse på harddisk 
            $VhdStørrelse = Read-Host `
            -Prompt 'Størrelse på virtuell harddisk i GB [40GB]'

            # Standardverdi 
            if($VhdStørrelse -eq "") {
                $VhdStørrelse = 40GB 
            }else{
                try{
                    # Konverter GB/MB/KB til byte 
                    $VhdStørrelse = Convert-StørrelseTilByte $VhdStørrelse
                }catch{
                    write-host "Feil i inndata"
                }
            }
        }while($VhdStørrelse -lt 1GB -or ($VhdStørrelse.gettype().name -notin 'int32', 'int64'))
        
        # Oppretter vm 
        foreach ($vm in $VmNavn) {
            Invoke-Command -Session $SesjonHyperV -ScriptBlock {
                New-VM -name $using:vm `
                       -Generation $using:gen `
                       -Path $using:VmSti `
                       -NewVHDPath "$using:VhdSti$using:vm.VHDX" `
                       -NewVHDSizeBytes $using:VhdStørrelse 
            } 
            if($?) {Write-Host "VM med navnet $vm er opprettet"}
            else{Write-Host "Noe gikk galt, $vm er ikke opprettet"}
        }


        #new-vm -name -MemoryStartupBytes -Generation 1 -SwitchName -NewVHDPath 
    }
    if($NoVhd)
    {
        #new-vm -name -MemoryStartupBytes -Generation 1 -SwitchName -NoVHD
    }
    if($Template)
    {
        #new-vm -name -MemoryStartupBytes -Generation 1 -SwitchName -VHDPath
    }  
}