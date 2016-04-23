Configuration dscWindowsFeature {
    param
    (
        [ipaddress]$ComputerName,
        [String]$WindowsFeature

    )
    Node 158.38.56.146 
    {
	    WindowsFeature Backup 
        {
	        Ensure = 'Present'
	        Name  = 'Windows-Server-Backup'
        }
    }
}
dscWindowsFeature