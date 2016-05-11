<#
# Modul for sesjoner
#>

$global:cred = Get-Credential $cred

Function Connect-Sesjoner
{
    param
    (
        [hashtable[]]$Servere,
        $Credentials
    )

    # Fjerner alle ødelagte sesjoner 
    (Get-PSSession | where {$_.state -match 'Broken'}) | Remove-PSSession

    foreach($server in $servere)
    {
        # Henter sesjonen 
        $sesjon = Get-PSSession | where {$_.Name -match $server.get_item('NAVN')}

        if($sesjon -eq $null)
        {   
            New-PSSession -ComputerName $server.get_item('IP') -port $server.get_item('PORT') -Name $server.get_item('NAVN') -Credential $Credentials -Verbose
        }else
        {            
             $sesjon | Connect-PSSession | Out-Null
        }
        
        $sesjon = $null   
    }
}