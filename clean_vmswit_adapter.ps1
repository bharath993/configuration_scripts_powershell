write-host "Disconnecting the vmnetworkadapters from all vm's" -f Yellow
Get-VMNetworkAdapter * | Disconnect-VMNetworkAdapter -Confirm:$false
$get = Get-VMNetworkAdapter *
foreach ($got in $get.connected)
{
if($got -eq "true")
{
write-host "vmnetworkadapter is not removed properly, pls check" -f Red
exit
}}
write-host "Removing the vmswitch" -f Yellow
Remove-VMSwitch * -Confirm:$false -Force
$switch = Get-VMSwitch 
if ($switch.count -ne 0)
{
write-host "vmswitch is not properly removed, pls check" -f Red
exit
}

