Configuration SetPullMode
{
    param(
        [string]$guid,
        [string]$IPAdresse,
        [string]$ServerUrl)
    Node $IPAdresse
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            ConfigurationID = $guid
            RefreshMode = 'Pull'
            DownloadManagerName = 'WebDownloadManager'
            DownloadManagerCustomData = @{
                ServerUrl = $ServerUrl;
                AllowUnsecureConnection = 'true' }
        }
    }
}