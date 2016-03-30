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

    # Holder l�kka g�ende s� lenge exit er lik false
    $exit = $false 

    <#
    # Legg alternativer i tabell
    #$alternativer = "S�k", "Administrer Virtuelle Maskiner", "Opprett Virtuell Maskin", "Migrasjon", "Clusters", "Nettverk", "Avslutt"
    
    # Gj�r et valg 
    #$valg = Velg-Alternativ $alternativer 
     
    # Utf�rer valg 
    switch($valg) {
        # 
        0 {}
        # 
        1 
        {
            # Velg hva som skal gj�res 
            $alternativer = "Snapshots", "Endre Hardware", "Slett VM", "Tilbake"

            # Utf�r valg 
            $valg = Velg-Alternativ $alternativer

            # Velg virtuelle maskiner som skal endres 
            $VMs = Velg-Objekt (get-vm) name, Status, @{Label='Memory(MB)';Expression={$_.memoryassigned/1MB}}, Version, Path, CheckpointFileLocation, Uptime

            # Utf�r valg 
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

    
    if ($exit -eq $false) { Read-Host "Trykk enter for � fortsette"  }
    #>
}while ($exit -eq $false)

