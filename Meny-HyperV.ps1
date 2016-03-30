# Skriv ut informasjon om programmet 
write $info = @"
-----------------
Server Hyper-V 
-----------------

Kommando    Beskrivelse
---------   -----------
?           Hjelp
"@ 

# Importerer moduler
.\Kjor-Meg.ps1


do {

    # Holder løkka gående så lenge exit er lik false
    $exit = $false 

    <#
    # Legg alternativer i tabell
    #$alternativer = "Søk", "Administrer Virtuelle Maskiner", "Opprett Virtuell Maskin", "Migrasjon", "Clusters", "Nettverk", "Avslutt"
    
    # Gjør et valg 
    #$valg = Velg-Alternativ $alternativer 
     
    # Utfører valg 
    switch($valg) {
        # 
        0 {}
        # 
        1 
        {
            # Velg hva som skal gjøres 
            $alternativer = "Snapshots", "Endre Hardware", "Slett VM", "Tilbake"

            # Utfør valg 
            $valg = Velg-Alternativ $alternativer

            # Velg virtuelle maskiner som skal endres 
            $VMs = Velg-Objekt (get-vm) name, Status, @{Label='Memory(MB)';Expression={$_.memoryassigned/1MB}}, Version, Path, CheckpointFileLocation, Uptime

            # Utfør valg 
            switch ($valg) {
                0 
                {
                    
                }
                1 {}
                2 {}
                3 {}
                4 {}
            }
        }
        #
        2 {}
        #
        3 {}
        #
        4 {}
        #
        5 {$exit = $true}
    }

    
    if ($exit -eq $false) { Read-Host "Trykk enter for å fortsette"  }
    #>
}while ($exit -eq $false)

