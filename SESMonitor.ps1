# Define constants
$domain = "amazonses.com"
$savedIpsFile = "C:\path\to\ses_ips.txt"      # Path to store the IP ranges
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$fromEmail = "your-email@gmail.com"
$toEmail = "recipient-email@gmail.com"
$gmailUsername = "your-email@gmail.com"       # Your Gmail username
$gmailPassword = "your-app-password"          # Use an app-specific password from Gmail

# Get the current SES IP ranges using nslookup and extract the "v=spf1" record
$nslookupOutput = nslookup -type=TXT $domain | findstr "v=spf1"
$currentIps = ($nslookupOutput -match "v=spf1\s+(.*)")[1] -replace "v=spf1\s+", ""

# Load saved IP ranges from file (if it exists)
if (Test-Path $savedIpsFile) {
    $savedIps = Get-Content $savedIpsFile
} else {
    $savedIps = ""
}

# Compare current IP ranges with saved IP ranges
if ($currentIps -ne $savedIps) {
    # If there's a difference, send an email alert
    $body = "AWS SES IP ranges have changed. Old IPs: $savedIps New IPs: $currentIps"
    $subject = "AWS SES IP Address Change Alert"

    $smtpMessage = New-Object system.net.mail.mailmessage
    $smtpMessage.from = $fromEmail
    $smtpMessage.To.Add($toEmail)
    $smtpMessage.Subject = $subject
    $smtpMessage.Body = $body
    $smtpClient = New-Object system.net.mail.smtpclient($smtpServer, $smtpPort)
    $smtpClient.EnableSsl = $true
    $smtpClient.Credentials = New-Object System.Net.NetworkCredential($gmailUsername, $gmailPassword)

    try {
        $smtpClient.Send($smtpMessage)
        Write-Output "Alert email sent."
    } catch {
        Write-Error "Failed to send email: $_"
    }

    # Update the saved IP ranges file
    $currentIps | Out-File -FilePath $savedIpsFile -Force
} else {
    Write-Output "No changes in SES IP ranges."
}
