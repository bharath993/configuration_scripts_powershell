#Script to create new vm and assign no. of processor to it 
#By default this script assigns 1Gb of memory to each vm
#all the vm are created with generation type 1
param
(
[int]$max_no_of_vm,
[int]$no_of_processor_count_for_each_vm,
[string]$VHD_path
)

if (($max_no_of_vm -eq 0) -or ($no_of_processor_count_for_each_vm -eq 0) -or ($VHD_path -eq [string]$null))
{
write-host "Please specify all fo these  params -max_no_of_vm,-no_of_processor_count_for_each_vm,-VHD_path" -f Yellow
pause
exit
}

for ($i =1 ; $i -le $max_no_of_vm ; $i++)
{
$app = $VHD_path + "\vm$i.vhdx"
foreach ($apps in $app){
if((Test-VHD -Path $apps) -ne 1)
{
write-host "The vhd path is not correct!!!! for $apps" -f Red
pause 
exit
}
write-host "Creating vm of name vm$i and assigning $no_of_processor_count_for_each_vm processor count to it" -f Yellow
New-VM -Name "vm$i" -MemoryStartupBytes 1GB -VHDPath $apps -Generation 1 
sleep 2
set-Vm -Name "vm$i" -ProcessorCount $no_of_processor_count_for_each_vm
sleep 2
}
}
