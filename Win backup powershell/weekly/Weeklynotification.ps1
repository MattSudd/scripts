﻿#Grab last 1337 event
$events = get-winevent  -FilterHashTable @{logname = "Application"; ID = 1338; StartTime=[datetime]::today}
$body = $events | Format-List | Out-String
#Set email details and craft payload
$hostname = hostname
$EmailFrom = "IT@blackmilkclothing.com"
$EmailTo = "IT@blackmilkclothing.com" 
$Subject = "Weekly snapshot notification from " + $hostname
$Body = "The snapshot scheduled task has run, the contents of the logged event is:" + $nl + $body
$SMTPServer = "smtp.gmail.com" 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
$SMTPClient.EnableSsl = $true 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("it@blackmilkclothing.com", "xxxxx"); 
# Send email
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)



