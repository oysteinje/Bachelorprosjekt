# HYPER-V FUNKSJONER 

# Funksjonen oppretter en eller flere virtuelle maskiner 
Function New-VMFromTemplate {
<#
.SYNOPSIS

.DESCRIPTION

.PARAMETER VMName

.PARAMETER VhdPath

.PARAMETER ParentPath

.PARAMETER MemoryStartupBytes

.EXAMPLE

.EXAMPLE

#>
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 1,
            Mandatory = $true,
            ValueFromPipeline=$True
        )][string[]]$VMName,
        
        [Parameter(Mandatory)]
        [string]$VHDDestination,
        
        [parameter(Mandatory)]
        [string]$TemplatePath,

        [string]$MemoryStartupBytes = 1GB
    )


    begin{
        
        # Tester at stiene eksisterer 
        do
        {
            
            $error = $false

            if (Test-Path $VHDDestination -eq $false) 
            {
                $VHDDestination = read-host "Stien for VHD stemmer ikke, skriv inn ny"
                $error = $true
            }
            if (Test-Path $TemplatePath -eq $false) 
            {
                $TemplatePath = read-host "Stien for template stemmer ikke, skriv inn ny"
                $error = $true
            }
        }
        while ($error -eq $true)
    }

    process
    {
        foreach ($vm in $VMName)
        {
            # Sjekk at destinasjonen slutter med skråstrek (/), hvis ikke så legg det til 
            if ( ([char[]]$VHDDestination | select -last 1) -notmatch "/" ) 
            {
                $VHDDestination += '/'
            }

            # Opprett virtuell harddisk 
            New-VHD -Path ("$VHDDestination" + "$vm.vhdx") -ParentPath $TemplatePath -Verbose
            
            # Opprett virtuell maskin 
            New-VM -Name $vm -MemoryStartupBytes $MemoryStartupBytes -VHDPath ("$VHDDestination" + "$vm.vhdx") -Verbose
        }
    }
    end{}







    <#
    Begin{
        # Hent inn eksisterende svitsjer
        
        $svitsjer = Get-VMSwitch | select -ExpandProperty name
         
        # Sjekker at valgt(e) svitsj(er) eksisterer
        do {
            $err = $false 
            $valgteSvitsjer = $null 

            # List ut tilgjengelige svitsjer
            Write-Host “Velg svitsjer. Separere med komma. (La det stå tomt hvis du ikke ønsker å legge til noen). Du kan velge blant”
            $svitsjer 

            # Velg svitsj(er)
            [string[]]$valgteSvitsjer = (Read-Host).split(“,”) | %{$_.trim()}
            
            # Sjekk at innskrevet svitsj faktisk eksisterer 
            foreach($valg in $valgteSvitsjer) {
                if ( ($svitsjer -notcontains $valg) -and ($valgteSvitsjer -ne "")) 
                {$err = $true}
            }
        }while ($err -eq $true)
     
    }
    
    Process{
        foreach ($vm in $VMName) {
            # Opprett virtuell disk 
            New-VHD -ParentPath $TemplatePath -Path $VhdPath 

            # Opprett virtuell maskin 
            New-VM -Name $vmName -VHDPath $vhdPath 

            # Legg til svitsjer 
            #foreach ($switch in $additionalSwitches) {
            #    Add-VMNetworkAdapter -VMName $vmName -SwitchName $switch
            #}
        }
    }
    End{}
    #>
}








# Lister ut detaljert (relevant) informasjon for virtuelle maskiner 
Function Get-VmDetaljert {
    param(
        [parameter(mandatory=$true)]
        [ValidateNotNullOrEmpty]
        $VMs
    )

    # Skriv ut virtuelle maskiner 
    $VMs | Format-Table -AutoSize -Property name, Status, @{Label='Memory(MB)';Expression={$_.memoryassigned/1MB}}, Version, Path, CheckpointFileLocation, Uptime
}