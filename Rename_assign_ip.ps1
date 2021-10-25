#Script to rename the chelsio adapter and assign ip to it
function host ($name)
{
if($name -eq "bumblebee")
{
netsh interface ip add address  "port0" 102.1.7.2 255.255.255.0
netsh interface ip add address  "port1" 102.1.8.2 255.255.255.0
}
elseif ($name -eq "core96cn23")
{
netsh interface ip add address  "port0" 102.1.7.3 255.255.255.0
netsh interface ip add address  "port1" 102.1.8.3 255.255.255.0
}
elseif ($name -eq "core96cn4")
{
netsh interface ip add address  "port0" 102.1.5.2 255.255.255.0
netsh interface ip add address  "port1" 102.1.6.2 255.255.255.0
}
elseif ($name -eq "core96cn16")
{
netsh interface ip add address  "port0" 102.1.5.3 255.255.255.0
netsh interface ip add address  "port1" 102.1.6.3 255.255.255.0
}
elseif ($name -eq "core96cn22")
{
netsh interface ip add address  "port0" 102.1.7.22 255.255.255.0
netsh interface ip add address  "port1" 102.1.8.22 255.255.255.0
}
elseif ($name -eq "core96cn24")
{
netsh interface ip add address  "port0" 102.1.7.24 255.255.255.0
netsh interface ip add address  "port1" 102.1.8.24 255.255.255.0
}
elseif ($name -eq "rattletrap")
{
netsh interface ip add address  "port0" 102.1.7.62 255.255.255.0
netsh interface ip add address  "port1" 102.1.8.62 255.255.255.0
}
elseif ($name -eq "warrior")
{
netsh interface ip add address  "port0" 102.1.7.56 255.255.255.0
netsh interface ip add address  "port1" 102.1.8.56 255.255.255.0
}
else
{
Write-Host "The local host name doesn't match with any of the hostname, please provide the ip manually" -f Yellow
$ip1 = Read-Host "Enter ip for port0" 
netsh interface ip add address  "port0" $ip1 255.255.255.0
$ip2 = Read-Host "Enter ip for port1" 
netsh interface ip add address  "port1" $ip2 255.255.255.0
}
}

$a = Get-NetAdapter -InterfaceDescription "Chel*" 
$p = $a.macaddress -replace '[0-9,a-z]+-\w',""
if ( $p.Get(0) -eq 0 )
{
Rename-NetAdapter $a.name.Get(0) -NewName "port0" -ErrorAction Ignore
Rename-NetAdapter $a.name.Get(1) -NewName "port1" -ErrorAction Ignore
}
else
{
Rename-NetAdapter $a.name.Get(0) -NewName "port1" -ErrorAction Ignore
Rename-NetAdapter $a.name.Get(1) -NewName "port0" -ErrorAction Ignore
}
$hostname = hostname
host $hostname
sleep 8
ipconfig 
