# Skriv ut informasjon om programmet 
$info = @"
Server Hyper-V 
Programmet lar deg konfigurere det meste som har med Hyper-V å gjøre.
"@

# Importerer moduler
.\Kjor-Meg.ps1

do {

    # Holder løkka gående så lenge exit er lik false
    $exit = $false 

    # Legg alternativer i tabell
    $alternativer = $("Søk", "Virtuelle Maskiner", "Migrasjon", "Clusters", "Nettverk", "Avslutt")

    # Gjør et valg 
    $valg = Velg-Alternativ $alternativer 

    # Utfører valg 
    switch($alternativer) {
        # 
        0 {}
        # 
        1 
        {
            $alternativer = "Ta snapshot", "Ny blank VM", "Ny VM fra template", "Ny virtuell harddisk", "Slett VM"
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

}while ($exit -eq $false)

