param(
    [string]$SMBDrive
)

# Stasjoner der den delte ressursen kan mappes (henter inn stasjoner fra E til Z)
$Stasjoner = @()
69..90 | foreach-object {$Stasjoner+=[char]$_}

# Bruker for å sjekke om den delte ressursen allerede er mappet 
$test = Get-PSDrive | where {$_.displayroot -eq $SMBDrive}

# Hvis den delte ressursen ikke er mappet 
if ($SMBDrive -eq $null) {
    foreach ($StasjonsNavn in $Stasjoner) {
        if (Test-Path $StasjonsNavn) {
            New-PSDrive -Name $StasjonsNavn -Root $SMBDrive -Persist -PSProvider FileSystem -Credential administrator -scope global
        }
    }
}
