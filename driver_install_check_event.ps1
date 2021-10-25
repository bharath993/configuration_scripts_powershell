#Script to install chelsio driver and check for default config file and checksum errr (basically to check for [fini])

function choice ($path,$newpath)
{
$choice = Read-Host  "Enter 1 to install free build , 2 to install check build"
if ($choice -eq "1")
{
cxgbtool debug update $newpath\chvbdx64.inf
cxgbtool debug update $newpath\chnetx64.inf
return 0
}
elseif($choice -eq "2"){
$chkpath = join-path $path "bin\Win10\chk\x64"
cxgbtool debug update $chkpath\chvbdx64.inf
cxgbtool debug update $chkpath\chnetx64.inf
cxgbtool debug rescan all
return 0
}
else{
return 1 
}
}




#main function
$path = read-host "Enter the driver folder location only"
$newpath = Join-Path $path "bin\Win10\fre\x64"
write-host "Copying the cxgbtool from the driver location" -f green
cp $newpath\cxgbtool.exe C:\Windows\System32
$return  = choice $path $newpath
if($return -eq 1){
write-host "Enter the correct choice" -f Red
choice $path $newpath
}
$date = get-date 
$1min_date = $date.AddMinutes(-1)
$first_event =  Get-EventLog -before $date -After $1min_date -Source chvbd -LogName system  | where { $_.Message -match ' Successfully configured using Firmware Configuration File "Firmware Default"'} 
echo $first_event
$checksum_error = Get-EventLog -Source chvbd -LogName system -After $first_event.timegenerated | where { $_.Message -match "Config File checksum mismatch*"} 
echo $checksum_error
if ($checksum_error -eq $1)
{
write-host "No checksum error found in eventvwr" -f Green
powershell.exe "C:\Users\Administrator\Desktop\.\Rename_assign_ip.ps1"
}

