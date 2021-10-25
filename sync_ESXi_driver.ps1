 Param(
 [Parameter(mandatory=$true)][string]$Driver_name,
 [Parameter(mandatory=$true)][string]$Remote_host_ip
 )
 cd "C:\Program Files (x86)\WinSCP"
 $Full_path = "C:\ESX_driver\" + "v" +$Driver_name + '\Out\BIN'
 echo $Full_path
 ./winscp.com root:cdrom@888@$Remote_host_ip /command "synchronize remote $Full_path /var/log/vmware"
 #./winscp.exe  /command "open root:cdrom@888@$Remote_host_ip" "put ""\\star\Projects\QA\ESXi 6.7\3.0.0.6\Out\BIN\*"""
