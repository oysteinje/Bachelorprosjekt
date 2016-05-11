# Konverterer GB/MB/KB til bytes 
Function Convert-SizeToBytes
{
    param(
        [parameter(mandatory=$true)]
        $Tall
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

Function Read-JaNei
{
 <#
 .SYNOPSIS
 Returnerer $true hvis bruker svarer 'j'
 Returnerer $false hvis bruker svarer 'n'
 #>
    [cmdletbinding()]
    param([string]$prompt = '>')

    do {
        $svar = read-host -Prompt $prompt
    }while($svar -ne 'j' -and $svar -ne 'n')

    if($svar -eq 'j') {$svar = $true}
    else {$svar = $false}

    return $svar 
}

# Henter / oppretter sesjon 
Function Get-HypervSesjon
{
    # IP for hyper server
    $ComputerName = '158.38.56.146'
    $Name = 'Hyper-V Server'

    # Henter ut sesjon 
    $Sesjon = Get-PSSession | where {$_.name -eq $Name}

    # Oppretter sesjon 
    if($sesjon -eq $null) {
        $sesjon = New-PSSession `
                    -ComputerName $ComputerName `
                    -Credential Get-Credential
    }

    # Returnerer sesjon
    return $sesjon 
}

# Returnerer alle vm
Function Get-VirtuellMaskin
{

    # Skriv ut beskjed 
    Write-Verbose "Henter VM" 

    # Henter vm fra sesjons
    $vms = Invoke-Command `
    -Session (Get-HypervSesjon) `
    -scriptblock {
        get-vm *
    }

    return $vms 
}

# Velger ut vm basert på navn 
Function Select-VirtuellMaskin
{
    param(
    [parameter(Mandatory=$true)]
    $VMs)

    # Skriv ut beskjed 
    Write-Host "Velg VM ved å skrive inn navn"
    Write-Host "Skill med komma for å velge flere"
    Write-Host "Skriv x! for å avslutte" 
    
    do {
        # Les inn valg 
        $valg = Read-Host -Prompt ">"

        # Returner hvis ønsket 
        if($valg -eq 'x!') {
            return $valg 
        }

        # Splitt valg i tabell 
        $valg = $valg.Split(',')

        # Trim start og slutt 
        $valg = $valg.Trim() 

        # Hent ut virtuelle maskiner 
        foreach($navn in $valg) {
            [object[]]$ValgtVM += 
                $vms | where {$_.vmname -eq $navn} 
        }

    # Går så lenge ikke no er valgt 
    }while($ValgtVM -eq $null)
    
    # returner valgte vms
    return $ValgtVM
}

# Setter minimum minne for VM 
Function Set-VmMinMinne
{
    param(
    [parameter(Mandatory=$true)]
    $VMs)

    # Minmum minne kan ikke være lavere enn:
    $min = 256MB

    # Les inn min. minne 
    do {
        # skriv ut beskjed 
        write-host "Skriv inn minumum minne du vil sette i MB/GB"
        write-Host "for eksempel 512MB"

        # Les inn minne 
        $minMinne = 
        read-host ">"

        # Evt. avslutt 
        if($minMinne -eq 'x!') {
            return $null 
        }

        # Konverter MB/GB til bytes 
        $minMinne = Convert-SizeToBytes $minMinne 

    }until($minMinne -ge $min `
            -and $minMinne.gettype().name  -eq 'int64')

    # Gjennomfør endring 
    Invoke-Command -Session (Get-HyperVSesjon) -script {
        Set-VMMemory -vmname $using:vms.vmname `
        -DynamicMemoryEnabled $true `
        -MinimumBytes $using:minMinne 
    }

    # skriv melding 
    if($?) {write-host "Minimum minne satt for $($vms.vmname)"}
    else {write-host "Noe gikk galt"}

    # Returner innsendte vm 
    return $vms 
}

# Setter max minne for VM
Function Set-VmMaxMinne
{
    param(
    [parameter(Mandatory=$true)]
    $VMs)

    # Max minne kan ikke være lavere enn:
    $min = 512MB

    # Les inn oppstartsminne 
    do {
        # skriv ut beskjed 
        write-host "Skriv inn max minne du vil sette i MB/GB"
        write-Host "for eksempel 1GB"

        # Les inn minne 
        $maxMinne = 
        read-host ">"

        # Evt. avslutt 
        if($maxMinne -eq 'x!') {
            return $null 
        }

        # Konverter MB/GB til bytes 
        $maxMinne = Convert-SizeToBytes $maxMinne 

    }until($maxMinne -ge $min `
            -and $maxMinne.gettype().name  -eq 'int64')

    # Gjennomfør endring 
    Invoke-Command -Session (Get-HyperVSesjon) -script {
        Set-VMMemory -vmname $using:vms.vmname `
        -DynamicMemoryEnabled $true `
        -MaximumBytes $using:maxMinne 
    }

    # skriv melding 
    if($?) {write-host "Minimum minne satt for $($vms.vmname)"}
    else {write-host "Noe gikk galt"}

    # Returner innsendte vm 
    return $vms 
}

# Setter oppstartsminne for VM 
Function Set-VmOppstartsMinne
{
    param(
    [parameter(Mandatory=$true)]
    $VMs)

    # Oppstartsminne kan ikke være lavere enn:
    $min = 256MB

    # Les inn oppstartsminne 
    do {
        # skriv ut beskjed 
        write-host "Skriv inn oppstartsminne"
        write-Host "for eksempel 1GB"

        # Les inn minne 
        $oppstartsminne = 
        read-host ">"

        # Evt. avslutt 
        if($oppstartsminne -eq 'x!') {
            return $null 
        }

        # Konverter MB/GB til bytes 
        $oppstartsminne = Convert-SizeToBytes $oppstartsminne 

    }until($oppstartsminne -ge $min `
            -and $oppstartsminne.gettype().name  -eq 'int64')

    # Gjennomfør endring 
    Invoke-Command -Session (Get-HyperVSesjon) -script {
        Set-VMMemory -vmname $using:vms.vmname `
        -StartupBytes $using:oppstartsminne 
    }

    # skriv melding 
    if($?) {write-host "Oppstartsminne satt for $($vms.vmname)"}
    else {write-host "Noe gikk galt"}

    # Returner innsendte vm 
    return $vms 
}

# Stopper kjørende vm 
Function Stop-VirtuellMaskin
{
    param(
    [parameter(Mandatory=$true)]
    $VMs)

    # Spør om å avslutt alle påslåtte vm 
    $vms = Invoke-Command -Session (Get-HyperVSesjon) `
    -scriptblock {
        # Hent ut valgte vm 
        $vms = $using:vms.vmname | get-vm 
        
        # Forsøk å stopp valgte vm 
        $n = stop-vm $vms.vmname 
        
        # Returner de som ble avslått 
        get-vm $vms.vmname | where {$_.state -eq 'off'}
    }

    # Returner kun de som ble avslått 
    return $vms
}

# Setter virtuelt minne 
Function Set-VmMinne
{
    # Hent alle vm 
    $vms = Invoke-Command -Session (Get-HyperVSesjon) -ScriptBlock {
        Get-VMMemory *
    } 

    # Skriv ut vm 
    Write-host ($vms | ft -autosize -prop nummer, vmname, DynamicMemoryEnabled, `
        @{Label='Minimum';Expression={Format-size($_.minimum)}}, 
        @{Label='Startup';Expression={Format-size($_.Startup)}},
        @{Label='Maximum';Expression={Format-size($_.Maximum)}}| 
        out-string)

    # Velg vm 
    $ValgtVM = Select-VirtuellMaskin -VMs $vms 
    
    # Avslutt hvis ønsket 
    if($ValgtVM -eq 'x!') { return $null} 

    # Stopp alle virtuelle som er påslått 
    $ValgtVM = Stop-VirtuellMaskin $ValgtVM

    # Avslutt hvis denne ble tom 
    if($ValgtVM -eq $null) {
        return $null 
    }

    # Spør om å sette oppstartsminne 
    [switch]$oppstartsminne = 
    Read-JaNei -prompt "Ønsker du å sette oppstartsminne? [j/n]"

    # Sett oppstartsminne 
    if($oppstartsminne) {
        $ValgtVM = Set-VmOppstartsMinne -VMs $ValgtVM 
    }

    # Spør om å sette minimum minne 
    [switch]$minMinne = 
    Read-JaNei -prompt "Ønsker du å sette minimum minne? [j/n]"

    # Sett minumum minne 
    if($minMinne) {
        $ValgtVM = Set-VmMinMinne -vms $ValgtVM
    }

    # Spør om å sette max minne
    [switch]$maxMinne = 
    Read-JaNei -prompt "Ønsker du å sette max minne? [j/n]"

    # Sett max minne 
    if($maxMinne) {
        $ValgtVM = Set-VmMaxMinne -vms $ValgtVM 
    }

    Write-Host "Endringer gjennomført"
}

Function Set-VmProsessor
{
    # Hent vm
    $vms = Invoke-Command -Session (Get-HyperVSesjon) `
    -script {
        get-vmprocessor *
    }

    # List ut vm 
    write-host ($vms | ft -prop vmname, count | out-string) 

    # Velg vm 
    $valgtVm = Select-VirtuellMaskin $vms 

    # Evt. avslutt 
    if($valgtVm -eq 'x!') {
        return $null
    }

    # Skru av kjørende vm 
    $valgtVm = Stop-VirtuellMaskin $valgtVm 

    # Sjekk at ikke var er tom
    if($valgtVm -eq $null) {
        return $null 
    }

    # Velg antall prosessor 
    do{
        # skriv ut melding 
        Write-Host "Velg antall prosessorer"
        Write-Host "Mellom 1 og 4"
        
        # Velg antall 
        $antall = Read-Host '>'
    }while($antall -notin 1,2,3,4)

    # gjennomfør endring 
    Invoke-Command -Session (Get-HyperVSesjon) `
    -ScriptBlock {
        set-vmprocessor -vmname $using:valgtvm.vmname `
        -count $using:antall 
    }

    # Skriv ut melding 
    if($?) {
        write-host "Antall prosessorer endret for $($valgtVm.vmname)"
    }else{
        write-host "Noe gikk galt"
    }
}

Function New-VirtuellMaskin
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
    $vms = Get-VirtuelleMaskiner 

    # Les inn ønskede navn 
    do {
        # skriv ut melding 
        Write-host "Skriv inn ønsket navn for VM"
        Write-Host "Skill med komma for å opprette flere"

        # Les inndata 
        $vmnavn = read-host '>'
        
        # Evt. avslutt 
        if($vmnavn -eq 'x!') {
            return $null 
        }

        # Splitt til tabell 
        $vmnavn = $vmnavn.Split(',')

        # Trim start og slutt 
        $vmnavn = $vmnavn.Trim() 
        
    }while($vmnavn -eq $null -or $vmnavn -eq "")

    # Sjekk at navn er ledige 
    for($i=0; $i -le $vmnavn.length; $i++) {
        # Endre navn som ikke er ledige  
        while($vmnavn[$i] -in $vms.vmname) {
            Write-Host "$($vmnavn[$i]) er ikke ledig"
            write-host "Skriv et annet navn"
            $vmnavn[$i] = read-host ">"
        }
    }

    # Fjern evt. duplikater 
    $vmnavn = $vmnavn | select -Unique

    # Hent vm svitsj 
    $vmsvitsjer = Invoke-Command -Session (Get-HyperVSesjon) `
    -scriptblock{
        Get-VMSwitch -ErrorAction SilentlyContinue
    }
    
    # Hvis det finnes vm svitsj 
    if($vmsvitsjer -ne $null) {
        # Velg vm svitsj 
        do{
            # skriv ut svitsj 
            write-host ($vmsvitsjer | ft -prop name, SwitchType | out-string)

            # skriv ut melding 
            write-host "Velg svitsj ved å skrive navn"
            write-host "La stå tomt hvis du ikke vil velge nå"

            # les inndata
            $svitsj = read-host '>'

        }until($svitsj -in $vmsvitsjer.name -or `
                $svitsj -eq "")
    }

    # Les inn generasjon 
    do{
        $gen = 
        read-host -Prompt `
        "Skriv inn ønsket generasjon [1,2]"
    }while($gen -notin 1,2)


    # Sti der vm skal lagres 
    do{
        # Skriv ut melding 
        write-host 'Skriv sti der virtuell maskin skal lagres f.eks'
        write-host 'For eksempel [C:\VM]'
        write-host 'La stå tomt for å bruker standardplassering'
        
        # Les inn sti 
        $VmSti = Read-Host '>'
         
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

    

    # Opprett vm uten VHD
    if($NoVhd) {
        New-VmNoVhd `
            -VmNavn $vmnavn `
            -VmSvitsj $svitsj `
            -VmPath $VmSti `
            -generasjon $gen 
    }

    # Opprett vm med VHD
    if($NewVHD) {

        # Sett VHD mappe
        do {
            $VhdSti = Read-Host 'Sti der virtuell harddisk skal lagres'
            Invoke-Command -Session (Get-HyperVSesjon) -ScriptBlock {
                if((Test-Path $using:vhdsti) -eq $false) { mkdir $using:vhdsti }
            }
        }while($? -eq $false)
        
        # Evt. legg til '\' på slutten av path
        if($VhdSti.Substring($VhdSti.Length - 1) -ne '\') 
        { 
            $VhdSti += '\'
        }
        
        # Min. størrelse for vhd 
        $vhdMin = 5GB 

        # Sett VHD størrelse 
        do{
            # Skriv ut beskjed 
            write-host "Skriv størrelse på harddisk"
            write-host "F.eks. 20GB" 
            write-host "Standardverdi er 40GB"

            # Les inndata 
            $VhdStørrelse = read-host '>'

            # Konverter til bytes 
            $VhdStørrelse = Convert-SizeToBytes $VhdStørrelse 

            # Evt. sett standardverdi 
            if($VhdStørrelse -eq "") {
                $VhdStørrelse = 20GB
            }

        }until($VhdStørrelse -ge $vhdMin -and $VhdStørrelse.GetType().name -eq 'int64') 
        
        # Funksjon som oppretter vm 
        New-VmVhd `
            -VmNavn $vmnavn `
            -VmSvitsj $svitsj `
            -VmPath $VmSti `
            -generasjon $gen `
            -VhdPath $VhdSti `
            -VhdSize $VhdStørrelse 
    }

    # Opprett vm fra template 
    if($Template) {
        
        # Sti til template 
        do{
            # Les inn sti
            write-host "Sti til template vhdx"
            write-host "For eksempel C:\mintemplate.vhdx"          
            $templateSti = read-host '>'
            
            # Test om template eksisterer 
            $TestSti = Invoke-Command -Session (Get-HyperVSesjon) `
            -ScriptBlock {
                Get-VHD -Path $using:templateSti -ErrorAction SilentlyContinue
            }

            # Skriv ut 
            if($TestSti -eq $null) {       
                Write-Host 'Finner ikke template. Prøv på nytt'
                $TestSti = $false
            }
            
        }while($TestSti -eq $false)
        
        # Sett VHD mappe
        do {
            $VhdSti = Read-Host 'Sti der virtuell harddisk skal lagres'
            Invoke-Command -Session (Get-HyperVSesjon) -ScriptBlock {
                if((Test-Path $using:vhdsti) -eq $false) { mkdir $using:vhdsti }
            }
        }while($? -eq $false)
        
        # Evt. legg til '\' på slutten av path
        if($VhdSti.Substring($VhdSti.Length - 1) -ne '\') 
        { 
            $VhdSti += '\'
        }
        
        # Min. størrelse for vhd 
        $vhdMin = 5GB 

        # Sett VHD størrelse 
        do{
            # Skriv ut beskjed 
            write-host "Skriv størrelse på harddisk"
            write-host "F.eks. 20GB" 
            write-host "Standardverdi er 40GB"

            # Les inndata 
            $VhdStørrelse = read-host '>'

            # Konverter til bytes 
            $VhdStørrelse = Convert-SizeToBytes $VhdStørrelse 

            # Evt. sett standardverdi 
            if($VhdStørrelse -eq "") {
                $VhdStørrelse = 20GB
            }

        }until($VhdStørrelse -ge $vhdMin -and $VhdStørrelse.GetType().name -eq 'int64') 
        
        # Funksjon som oppretter vm 
        New-VmTemplate `
            -VmNavn $vmnavn `
            -VmSvitsj $svitsj `
            -VmPath $VmSti `
            -generasjon $gen `
            -VhdPath $VhdSti `
            -VhdSize $VhdStørrelse `
            -ParentPath $templateSti
    }
}

Function New-VmNoVhd
{
    param(
        [string[]]$VmNavn,
        [string]$VmSvitsj,
        [string]$VmPath,
        [int]$generasjon
    )


    # Uten svitsj og uten path 
    if($VmSvitsj -eq "" -and $VmPath -eq "") {
        foreach($navn in $VmNavn) {
            [string[]]$kommando += "new-vm -name $navn ``
                -Generation $generasjon ``
                -novhd"
        }  
    }
    # Uten svitsj, med path 
    elseif($VmSvitsj -eq "") {
        foreach($navn in $VmNavn) {
            [string[]]$kommando += "new-vm -name $navn ``
                -Generation $generasjon ``
                -novhd ``
                -path $VmPath"
        }  
    }
    # Uten path, med svitsj 
    elseif($VmPath -eq "") {
        foreach($navn in $VmNavn) {
            [string[]]$kommando += "new-vm -name $navn ``
                -Generation $generasjon ``
                -novhd ``
                -SwitchName $VmSvitsj"
        }  
    }
    # Alle paremtre har verdi 
    else {
        foreach($navn in $VmNavn) {
            [string[]]$kommando += "new-vm -name $navn ``
                -Generation $generasjon ``
                -novhd ``
                -SwitchName $VmSvitsj ``
                -path $VmPath"
        }  
    }

    # Oppretter vm på ekstern server 
    foreach($cmd in $kommando) {
        [object[]]$vms += 
        Invoke-Command `
        -Session (Get-HyperVSesjon) `
        -script {
            Invoke-Expression -Command $using:cmd 
        }
    }

    # Returner vm 
    return $vms
}


Function New-VmVhd
{
    param(
        [string[]]$VmNavn,
        [string]$VmSvitsj,
        [string]$VmPath,
        [int]$generasjon,
        [string]$VhdPath,
        [int64]$VhdSize
    )


    # Uten svitsj og uten path 
    if($VmSvitsj -eq "" -and $VmPath -eq "") {
        foreach($navn in $VmNavn) {
            [string[]]$kommando += "new-vm -name $navn ``
                -Generation $generasjon ``
                -NewVHDPath $VhdPath$navn.vhdx ``
                -NewVHDSizeBytes $VhdSize"
        }  
    }
    # Uten svitsj, med path 
    elseif($VmSvitsj -eq "") {
        foreach($navn in $VmNavn) {
            [string[]]$kommando += "new-vm -name $navn ``
                -Generation $generasjon ``
                -NewVHDPath $VhdPath$navn.vhdx ``
                -NewVHDSizeBytes $VhdSize ``
                -path $VmPath"
        }  
    }
    # Uten path, med svitsj 
    elseif($VmPath -eq "") {
        foreach($navn in $VmNavn) {
            [string[]]$kommando += "new-vm -name $navn ``
                -Generation $generasjon ``
                -NewVHDPath $VhdPath$navn.vhdx ``
                -NewVHDSizeBytes $VhdSize ``
                -SwitchName $VmSvitsj"
        }  
    }
    # Alle paremtre har verdi 
    else {
        foreach($navn in $VmNavn) {
            [string[]]$kommando += "new-vm -name $navn ``
                -Generation $generasjon ``
                -NewVHDPath $VhdPath$navn.vhdx ``
                -NewVHDSizeBytes $VhdSize ``
                -SwitchName $VmSvitsj ``
                -path $VmPath"
        }  
    }

    # Oppretter vm på ekstern server 
    foreach($cmd in $kommando) {
        [object[]]$vms += 
        Invoke-Command `
        -Session (Get-HyperVSesjon) `
        -script {
            Invoke-Expression -Command $using:cmd 
        }
    }

    # Returner vm 
    return $vms
}

Function New-VmTemplate
{
    param(
        [string[]]$VmNavn,
        [string]$VmSvitsj,
        [string]$VmPath,
        [int]$generasjon,
        [string]$VhdPath,
        [int64]$VhdSize,
        [string]$ParentPath
    )

    # Sett vhd filtype
    $vhdExt = 'vhd'

    # Hent vhd filtype 
    if($ParentPath.Substring($ParentPath.length -4) -eq 'vhdx') {
        $vhdExt = 'vhdx'
    }

    # Sett gen
    if($vhdExt -eq 'vhd') {
        $generasjon = 1
    }


    # Uten svitsj og uten path 
    if($VmSvitsj -eq "" -and $VmPath -eq "") {
        foreach($navn in $VmNavn) {
            # Kommando for ny vhd 
            [string[]]$kommandoVhd += "New-VHD ``
                -ParentPath $ParentPath ``
                -Path $VhdPath$navn.$vhdExt"

            # Kommando for vm 
            [string[]]$kommandoVm += "new-vm -name $navn ``
                -Generation $generasjon ``
                -VHDPath $VhdPath$navn.$vhdExt"
        }  
    }
    # Uten svitsj, med path 
    elseif($VmSvitsj -eq "") {
        foreach($navn in $VmNavn) {
            # Kommando for å opprette vhd
            [string[]]$kommandoVhd += "New-VHD ``
                -ParentPath $ParentPath ``
                -Path $VhdPath$navn.$vhdExt"

            # Kommando for vm
            [string[]]$kommandoVm += "new-vm -name $navn ``
                -Generation $generasjon ``
                -VHDPath $VhdPath$navn.$vhdExt ``
                -path $VmPath"
        }  
    }
    # Uten path, med svitsj 
    elseif($VmPath -eq "") {
        foreach($navn in $VmNavn) {
            # Kommando for ny vhd 
            [string[]]$kommandoVhd += "New-VHD ``
                -ParentPath $ParentPath ``
                -Path $VhdPath$navn.$vhdExt"            
            
            # kommando for ny vm 
            [string[]]$kommandoVm += "new-vm -name $navn ``
                -Generation $generasjon ``
                -VHDPath $VhdPath$navn.$vhdExt ``
                -SwitchName $VmSvitsj"
        }  
    }
    # Alle paremtre har verdi 
    else {
        foreach($navn in $VmNavn) {
            # kmmando for ny vhd 
            [string[]]$kommandoVhd += "New-VHD ``
                -ParentPath $ParentPath ``
                -Path $VhdPath$navn.$vhdExt"

            # kommando for ny vm 
            [string[]]$kommandoVm += "new-vm -name $navn ``
                -Generation $generasjon ``
                -VHDPath $VhdPath$navn.$vhdExt ``
                -SwitchName $VmSvitsj ``
                -path $VmPath"
        }  
    }


    # oppretter vhd på ekstern sever 
    foreach($cmd in $kommandoVhd) {
        write-host $cmd 
        pause 
        [object[]]$vhds += 
        Invoke-Command `
        -Session (Get-HyperVSesjon) `
        -script {
            Invoke-Expression -Command $using:cmd 
        }
    }


    # Oppretter vm på ekstern server 
    foreach($cmd in $kommandoVm) {
        [object[]]$vms += 
        Invoke-Command `
        -Session (Get-HyperVSesjon) `
        -script {
            Invoke-Expression -Command $using:cmd 
        }
    }
    
    # Returner vm 
    return $vms
}