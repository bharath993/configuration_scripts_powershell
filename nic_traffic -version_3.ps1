#NIC traffic

#Pre-requist is chelsio ports must be named as port0 and port1 on both local and remote machine respectively


param(
[Parameter(Mandatory = $true)][string]$remote_computer_ip,
[Parameter(Mandatory = $true)][string]$time_to_run_test_in_seconds
)

#$remote_computer_ip = 10.193.204.30
Set-Item WSMan:\localhost\Client\TrustedHosts * -Force

#function to check the LSO counter of the respective port
function port_tx_error_LSO($stats_tx_0)
{
$stats_tx_0_LSO = $stats_tx_0 | findstr "LSO"
write-host "#################################################################################################################" -f Cyan
echo $stats_tx_0_LSO
write-host "#################################################################################################################" -f Cyan
sleep 5
$i = 3
while($i -le 100)
{
if($stats_tx_0_LSO[$i] -eq "0")
{
$c++
$j =  $i
if($stats_tx_0_LSO[--$j] -eq $stats_tx_0_LSO[3])
{
write-host "LSO increment had failed for the tx queue $c,hence exiting" -f Red
exit
}
}
$i++
}
write-host "LSO had successfully incremented for all the queues" -f Green
}

#function to check the TxChecksum counter of the respective port
function port_tx_error_Txchecksum($stats_tx_0){
$stats_tx_0_TxC = $stats_tx_0 | findstr "TxCsumOfld"
write-host "#################################################################################################################" -f Cyan
echo $stats_tx_0_TxC
write-host "#################################################################################################################" -f Cyan
sleep 5
$i = 10
while($i -le 100)
{
if($stats_tx_0_TxC[$i] -eq "0")
{
$c++
$j =  $i
if($stats_tx_0_TxC[--$j] -eq $stats_tx_0_TxC[10])
{
write-host "TxChecksum increment had failed for the tx queue" -f Red
exit
}
}
$i++
}
write-host "TxChecksum had successfully incremented for all the queues" -f Green
}



function port_tx_error_PktDrop($stats_tx_0)
{
$stats_tx_0_PktsDrop = $stats_tx_0 | findstr "PktsDrop"
write-host "#################################################################################################################" -f Cyan
echo $stats_tx_0_PktsDrop
write-host "#################################################################################################################" -f Cyan
sleep 5
$i = 8
while($i -le 100)
{
if($stats_tx_0_PktsDrop[$i] -eq "0")
{
$c++
$j = $i
if($stats_tx_0_PktsDrop[--$j] -eq $stats_tx_0_PktsDrop[8])
{
write-host "There are no pktdrop seen for the queue $c" -f Green
}
else
{
write-host "PktDrop had been seen for queue $c" -f Red
exit
}
}
$i++
}
}



#Master function to check tx_error
function port_tx_error_check($stats_tx_0){

port_tx_error_LSO $stats_tx_0
port_tx_error_Txchecksum $stats_tx_0
port_tx_error_PktDrop $stats_tx_0

}


#function to check the port id of the ports using dumpctx
function dump_ctx_check($input_choice){
if($input_choice -eq 1)
{
$ctx = cxgbtool nic0 debug dumpctx | findstr "Port"
if($ctx[16] -eq "0")
{
$stats_tx_0 = cxgbtool nic0 debug qstats txe
port_tx_error_check $stats_tx_0
}
else
{
$stats_tx_0 = cxgbtool nic1 debug qstats txe
port_tx_error_check $stats_tx_0
}
}
if ($input_choice -eq 2){
$ctx = cxgbtool nic0 debug dumpctx | findstr "Port"
if($ctx[16] -eq "1")
{
$stats_tx_0 = cxgbtool nic0 debug qstats txe
port_tx_error_check $stats_tx_0
}
else
{
$stats_tx_0 = cxgbtool nic1 debug qstats txe
port_tx_error_check $stats_tx_0
}
}
}

#function to check if ntttcp tool exist in local machine
function exist_local{

if(test-path C:\Windows\System32\ntttcp.exe)
{
write-host "Ntttcp is present in system32 of local machine" -f green
return 1
}
else
{
write-host "Ntttcp is not present in system32 of local machine" -f red
return 0
}
}

#function to check if ntttcp tool exist in remote machine
function exist_remote{
if(test-path C:\Windows\System32\ntttcp.exe)
{
write-host "Ntttcp is present in system32 of remote machine" -f green
return 1
}
else
{
write-host "Ntttcp is not present in system32 of remote machine" -f red
return 0
}
}


function exist{
$exist_local_var = exist_local
$exist_remote_var = Invoke-Command -ComputerName $remote_computer_ip  -ScriptBlock ${function:exist_remote}

if (($exist_local_var -eq 1) -and  ($exist_remote_var -eq 0) )
{
write-host "Copying ntttcp tool from local machine to remote machine" -f Yellow
cp C:\Windows\System32\NTttcp.exe \\$remote_computer_ip\C$\Windows\System32\
}
elseif(($exist_local_var -eq 0) -and ($exist_remote_var -eq 1))
{
write-host "Copying ntttcp tool from remote machine to local machine" -f Yellow
cp \\$remote_computer_ip\C$\Windows\System32\NTttcp.exe C:\Windows\System32\
}
elseif(($exist_local_var -eq 0) -and ($exist_remote_var -eq 0))
{
Write-Host "Ntttcp tool is not present in both the machines" -f Red
exit
}
}

#function to retrieve the ipaddress of port0 and port1 from this machine
function ipaddress{
$net_ip = Get-NetIPAddress -InterfaceAlias port0,port1 -AddressFamily ipv4
$net_ip = $net_ip | sort
return $net_ip
}


function transmit($net_ip_peer,$input_choice){

write-host "Starting the peer machine as rx" -f Yellow
$dummy = "ntttcp -r -m 32,*," + $net_ip_peer + " -rb 512k -l 64k -t $time_to_run_test_in_seconds"
echo "remote computer ip is" $remote_computer_ip
Invoke-Command -ComputerName $remote_computer_ip -ScriptBlock {invoke-expression "$args[0]"} -ArgumentList $dummy  -AsJob
sleep 3
Write-Host "Starting this machine as tx" -f Yellow
ntttcp -s -m 32,*,$net_ip_peer -sb 512k -l 64k -t $time_to_run_test_in_seconds
sleep 3
dump_ctx_check $input_choice

}


function receive($net_ip){

$dummy = "ntttcp -r -m 32,*," + $net_ip + " -rb 512k -l 64k -t $time_to_run_test_in_seconds"
$dummy1 = "ntttcp -s -m 32,*," + $net_ip + " -sb 512k -l 64k -t $time_to_run_test_in_seconds"

Write-Host "Starting this machine as rx" -f Yellow
Invoke-Command -ComputerName . -ScriptBlock {invoke-expression "$args[0]"} -ArgumentList $dummy  -AsJob
sleep 3
write-host "Starting the peer machine as tx" -f Yellow
Invoke-Command -ComputerName $remote_computer_ip -ScriptBlock {invoke-expression "$args[0]"} -ArgumentList $dummy1  -AsJob


}

#function to get the choice from user to run the tcp traffic on preferred interface
function choice($net_ip,$net_ip_peer){
$input_choice= read-host "Enter 1 to run on port0, 2 to run on port1, 3 to run on both"

if($input_choice -eq 1)
{
$direction = read-host "Enter tx to transmit packet or rx to receive packet to this machine from port0"
if(($direction -eq "tx") -or ($direction -eq "TX"))
{
transmit $net_ip_peer.ipaddress[0] $input_choice
}
elseif (($direction -eq "rx") -or ($direction -eq "RX"))
{
receive $net_ip.ipaddress[0]
}
else{
write-host "please enter the choice correctly" -f Red
exit
}
}
elseif($input_choice -eq 2)
{
$direction = read-host "Enter tx to transmit packet or rx to receive packet to this machine from port1"
if(($direction -eq "tx") -or ($direction -eq "TX"))
{
transmit $net_ip_peer.ipaddress[1] $input_choice
}
elseif (($direction -eq "rx") -or ($direction -eq "RX"))
{
receive $net_ip.ipaddress[1]
}
else{
write-host "please enter the choice correctly" -f Red
exit
}
}
elseif($input_choice -eq 3)
{
receive $net_ip.ipaddress[0]
transmit $net_ip_peer.ipaddress[1]

}
}



#main function
#test if ntttcp tool exist
exist
Write-Host "clearing the tx queue of both the ports" -f Yellow
$garb = cxgbtool nic0 debug qstats txe clr
$garb1 = cxgbtool nic1 debug qstats txe clr
#Retrive the ip address of the chelsio cards on this machine"
$net_ip = ipaddress
#Retrive the ip address of the chelsio cards on peer machine"
$net_ip_peer = Invoke-Command -ComputerName $remote_computer_ip  -ScriptBlock ${function:ipaddress} 
write-host "Remote machine chelsio ip address are"  $net_ip_peer.ipaddress 
write-host "Ip assigned to chelsio interfaces are" $net_ip.ipaddress
#choice to run the nic traffic on port0 or port1 or both
choice $net_ip $net_ip_peer