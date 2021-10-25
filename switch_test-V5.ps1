<#

.SYNOPSIS
This is a simple Powershell script to install/uninstall the chelsio iscsi/iser driver



.EXAMPLE
./switch_test.ps1 -Enable_ISCSI 1 -Enable_ISER 1
         --- will install iscsi and iser driver for the specified adapter

./switch_test.ps1 -Enable_ISCSI 1 
         --- will  install only the iscsi driver

./switch_test.ps1 -Enable_ISER 1
         --- will install only the iser driver

./switch_test.ps1 -Enable_ISER 0
         --- will uninstall only the iser driver

./switch_test.ps1 -Enable_ISCSI 0
         --- will uninstall only the iscsi driver

./switch_test.ps1 -Enable_ISCSI 1 -Enable_ISER 0
         --- will install iscsi driver and uninstalls the iser driver

./switch_test.ps1 -Enable_ISCSI 0 -Enable_ISER 1
         --- will install only iser driver and uninstall the iscsi driver

./switch_test.ps1 -Enable_ISCSI 0 -Enable_ISER 0
         --- will uninstall iscsi and iser driver

.NOTES
Script assumes VBD and NDIS drivers are installed

For now Max of only 3 adapters are supported in a machine



#>



Param(
[Parameter(mandatory=$true)][string]$Driver_path,
[ValidateSet('0','1')][string]$Enable_ISCSI,
[ValidateSet('0','1')][string]$Enable_ISER 
)


function check_vbd($path)   #To check the VBD version of the specified adapter in registry and comparing it with the Driver path provided
{
$Driver_path1 = $Driver_path
$Driver_path1 = $Driver_path1 + "\cht4iscsi.inf"
$driver = Get-ItemProperty -Path "$path" -Name DriverVersion 
$c = Get-Content $Driver_path1 |findstr "DriverVer"
$c = $c -split ','
$c = $c[1]
if ($driver.DriverVersion -ne $c)
{
Write-host "Driver version of VBD and provided driver doesn't match" -ForegroundColor Red
exit
}
}


function toggle($adapter)
{
Write-Host "toggle"
$adapter | Disable-PnpDevice -Confirm:$false
$adapter | Enable-PnpDevice -Confirm:$false
}

function modify_enable($path,$adapter)                                        #need to find a way to update/uninst particular instance of a adapter 
{
if ($Enable_ISCSI -eq 1 )
{
  $Driver_path1 = $Driver_path
  Set-ItemProperty -Path $path -Name iScsiInstances -Value -1
  toggle $adapter
  sleep 2
  $Driver_path1 = $Driver_path1 + "\cht4iscsi.inf"
  cxgbtool debug update $Driver_path1
   }


if ($Enable_ISER -eq 1 )
{
  $Driver_path1 = $Driver_path
  Set-ItemProperty -Path $path -Name iSerInstances -Value -1
  toggle $adapter
  sleep 2
  $Driver_path1 = $Driver_path1 + "\chiserx64.inf"
  echo $Driver_path
  cxgbtool debug update $Driver_path1
}

}

function revert_instance ($path)
{
if($Enable_ISCSI -eq 0)
  {
 Set-ItemProperty -Path $path -Name iScsiInstances -Value 0
 toggle $adapter
  }
if($Enable_ISER -eq 0)
  {
  Set-ItemProperty -Path $path -Name iSerInstances -Value 0
  toggle $adapter
  } 

}

function modify_disable($path)                                        #need to find a way to update/uninst particular instance of a adapter 
{

  if($Enable_ISCSI -eq 0)
  {
  $Driver_path1 = $Driver_path
  $Driver_path1 = $Driver_path1 + "\cht4iscsi.inf"
  cxgbtool debug uninst $Driver_path1
  sleep 2
  revert_instance $path
   
  }


if($Enable_ISER -eq 0)
  {
  $Driver_path1 = $Driver_path
  $Driver_path1 = $Driver_path1 + "\chiserx64.inf"
  cxgbtool debug uninst $Driver_path1
  sleep 2
  revert_instance $path
  
  } 
}




#main
$j = 0
$i = 0
$k = 0
$Chelsio_device = Get-PnpDevice -FriendlyName "*chelsio*enumerator*"

 
#Condition to check given driver path is correct
if(!(Test-Path $Driver_path))
{
Write-Host "Please enter the valid driver path" -f Red
Write-Host "Example: C:\Users\Administrator\Desktop\<driver>\bin\Win10\fre\x64"
exit
}

#Condtion to check cxgbtool is present in system32, if not copy it from the given driver path
if(!(Test-Path $Env:windir\System32\cxgbtool.exe ))
{
Write-Host "cxgbtool is not present" -f Red
Write-Host "copying cxgbtool from the driverpath provided" -f Green
cp $Driver_path\cxgbtool.exe C:\Windows\System32 -Recurse
}

#Enter the below condition if multiple chelsio adapters are present
if($Chelsio_device.FriendlyName.Count -gt 1)
{
write-host "Following Chelsio adapter(s) are present" -f Yellow
$table = foreach ($device in $Chelsio_device){@{ $j++ = $device }}

$table1 = foreach($t in $table.Values.friendlyname){@{$k++ = $t}}

echo $table1
$get = Read-host "Select which device to modify with their respective value"  


while(1){
if ($get -eq $table.keys[$i])
{
$adapter = $table.Values[$i]
break
}
$i++
}
}

#Enter this condition if only one adapter is present
if ($Chelsio_device.FriendlyName.Count -eq 1)
{
$adapter = $Chelsio_device[0]
}

$to_modify = $adapter | Get-PnpDeviceProperty -KeyName "DEVPKEY_Device_Driver"
$path = "HKLM:\System\CurrentControlSet\Control\Class\" + $to_modify.Data

check_vbd $path

if(($Enable_ISCSI -eq 1) -or ($Enable_ISER -eq 1))
{
modify_enable $path $adapter
}

if(($Enable_ISCSI -eq 0) -or ($Enable_ISER -eq 0))
{
$c = 0
$adapter = $Chelsio_device
$to_modify = $adapter | Get-PnpDeviceProperty -KeyName "DEVPKEY_Device_Driver"
foreach ($path in $to_modify.Data)
{
$path = "HKLM:\System\CurrentControlSet\Control\Class\" + $path
if ($c -eq 0)
{
modify_disable $path     #Enter this function to uninstall and revert_instance only for the first adapter 
}
if($c -gt 0)
{
revert_instance $path    #Enter this function to revert the instance for remaining adapters
}
$c++
}
}



