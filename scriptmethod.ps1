$what = get-vm 

$koko = {
    foreach ($t in $this.name) {
     $c = [char[]] $t
     [array]::Reverse($c)
     [string]::Join('',$c)      
    }
}

add-member -InputObject $what -MemberType ScriptMethod -Name ekstra -Value $koko
$what.ekstra()