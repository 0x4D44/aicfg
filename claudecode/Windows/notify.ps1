param($HookData)

try {
    # Parse the hook data
    $data = $hookData | ConvertFrom-Json
    $transcriptPath = $data.transcript_path
    $sessionDir = Split-Path -Leaf $data.cwd
    
    $message = "Task completed in $sessionDir"
    
    # Extract last Claude message from transcript
    if ($transcriptPath -and (Test-Path $transcriptPath)) {
        try {
            # Read last 20 lines of transcript
            $lastLines = Get-Content $transcriptPath -Tail 20
            
            # Find the most recent assistant message
            $lastAssistantMessage = $null
            $assistantLines = $lastLines | Where-Object { $_ -match '"role":"assistant"' }
            
            foreach ($line in $assistantLines) {
                try {
                    $entry = $line | ConvertFrom-Json
                    
                    if ($entry.message.role -eq "assistant" -and $entry.message.content) {
                        # Handle different content structures
                        $content = $entry.message.content
                        if ($content -is [array] -and $content[0].text) {
                            $lastAssistantMessage = $content[0].text
                        } elseif ($content -is [string]) {
                            $lastAssistantMessage = $content
                        } elseif ($content.text) {
                            $lastAssistantMessage = $content.text
                        }
                    }
                } catch {
                    # Skip lines that fail to parse
                    continue
                }
            }
            
            if ($lastAssistantMessage) {
                # Truncate and clean the message
                $cleanMessage = $lastAssistantMessage -replace '\n', ' ' -replace '\r', '' -replace '\t', ' '
                if ($cleanMessage.Length -gt 80) {
                    $cleanMessage = $cleanMessage.Substring(0, 80) + "..."
                }
                $message = $cleanMessage
            }
        } catch {
            # Fall back to default message if transcript parsing fails
        }
    }
} catch {
    $message = "Claude Code task completed"
}

# Create toast notification
try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    
    # Escape XML special characters
    $escapedMessage = [System.Security.SecurityElement]::Escape($message)
    
    $xml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>Claude Code Complete</text>
            <text>$escapedMessage</text>
        </binding>
    </visual>
</toast>
"@
    
    $XmlDocument = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
    $XmlDocument.LoadXml($xml)
    
    $AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($XmlDocument)
} catch {
    # Silently fail if toast notification doesn't work
}

# Play custom sound
(New-Object Media.SoundPlayer 'C:\apps\claude.wav').PlaySync()