param($message)

# Create Windows toast notification
try {
    # Load required assemblies
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    
    # Escape XML special characters
    $escapedMessage = [System.Security.SecurityElement]::Escape($message)
    
    # Create toast XML
    $xml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>Codex Complete</text>
            <text>$escapedMessage</text>
        </binding>
    </visual>
</toast>
"@
    
    # Create XML document and show toast
    $XmlDocument = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
    $XmlDocument.LoadXml($xml)
    
    # Use PowerShell's App ID
    $AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($XmlDocument)
} catch {
    Write-Host "Toast notification failed: $($_.Exception.Message)"
}

# Play custom sound
(New-Object Media.SoundPlayer 'C:\apps\gpt5-2.wav').PlaySync()