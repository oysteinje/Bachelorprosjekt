# Skriv ut informasjon om programmet 
$info = @"
Server Hyper-V 
Programmet lar deg konfigurere det meste som har med Hyper-V � gj�re.
"@

# Importerer moduler
.\Kjor-Meg.ps1

do {

    # Holder l�kka g�ende s� lenge exit er lik false
    $exit = $false 

    # Legg alternativer i tabell
    $alternativer = "S�k", "Virtuelle Maskiner", "Migrasjon", "Clusters", "Nettverk", "Avslutt"
    
    # Gj�r et valg 
    $valg = Velg-Alternativ $alternativer 
     
    # Utf�rer valg 
    switch($valg) {
        # 
        0 {}
        # 
        1 
        {
            $alternativer = "Administrer snapshots", "Ny blank VM", "Ny VM fra template", "Ny virtuell harddisk", "Slett VM", "Tilbake"
            $valg = Velg-Alternativ $alternativer
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

}while ($exit -eq $false)

