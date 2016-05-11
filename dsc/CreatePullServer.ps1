configuration CreatePullServer
{
  param
  (
    [string[]]$ComputerName = 'localhost',
    [int]$Port = 8080
  )

  Import-DSCResource -ModuleName xPSDesiredStateConfiguration

  Node $ComputerName
  {
    WindowsFeature DSCServiceFeature
    {
      Ensure = "Present"
      Name  = "DSC-Service"
    }

    xDscWebService PSDSCPullServer
    {
      Ensure         = "Present"
      EndpointName      = "PSDSCPullServer"
      Port          = $Port
      PhysicalPath      = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
      CertificateThumbPrint  = "AllowUnencryptedTraffic"
      ModulePath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
      ConfigurationPath    = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
      State          = "Started"
      DependsOn        = "[WindowsFeature]DSCServiceFeature"
    }

    xDscWebService PSDSCComplianceServer
    {
      Ensure         = "Present"
      EndpointName      = "PSDSCComplianceServer"
      Port          = 9080
      PhysicalPath      = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
      CertificateThumbPrint  = "AllowUnencryptedTraffic"
      State          = "Started"
      DependsOn        = ("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer")
    }

  }

}