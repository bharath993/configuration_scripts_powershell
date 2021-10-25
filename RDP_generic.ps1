
$username = "administrator"
$password = cat C:\securestring.txt | convertto-securestring
$cred = new-object -typename System.Management.Automation.PSCredential `
         -argumentlist $username, $password

#$cred = get-credential administrator


$Computer = read-host -prompt "computer name"
while(1)
{
write-host "testing connection" -f yellow
$result = Test-Connection $Computer -Quiet
if ( $result -eq $true )
{
write-host "ping is succeded,checking for machine boot up" -f yellow
sleep 2
$event = Get-WinEvent -computername $Computer -FilterHashtable @{logname=’system’; id=6005; StartTime=(get-date).AddMinutes(-5)} -Credential $cred
if ( $event.count -ge 1 )
{
 mstsc /v $Computer
exit
}
write-host "machine haven't been booted up yet(no event found)" -f yellow
sleep 2
}
write-host "checking ping again" -f yellow
sleep 2
}