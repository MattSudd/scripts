#Grab last 1337 event
$events = get-winevent  -FilterHashTable @{logname = "Application"; ID = 1337; StartTime=[datetime]::today}
$body = $events | Format-List | Out-String
#Set email details and craft payload
$hostname = hostname
$EmailFrom = "IT@blackmilkclothing.com"
$EmailTo = "IT@blackmilkclothing.com" 
$Subject = "Daily snapshot notification from " + $hostname
$Body = "The snapshot scheduled task has run, the contents of the logged event is:" + $nl + $body
$SMTPServer = "smtp.gmail.com" 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
$SMTPClient.EnableSsl = $true 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("it@blackmilkclothing.com", "!BubblingThunder?"); 
# Send email
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)



