###PowerCLI Script to check all VMs that are powered off, when they were powered off (If within auditing time) and report back either to screen or to csv
###Replace Server with remote VSphere connection
Connect-VIServer -Server *** -Credential (Get-Credential)
$Report = @()

$VMs = Get-VM | Where {$_.PowerState -eq "PoweredOff"}

$Datastores = Get-Datastore | Select Name, Id

$PowerOff = Get-VIEvent -Entity $VMs -MaxSamples ([int]::MaxValue) | where {$_ -is [VMware.Vim.VmPoweredOffEvent]} | Group-Object -Property {$_.Vm.Name}

$fields = @{}

$VMs.ExtensionData.AvailableField | %{

    $fields.Add($_.Key,$_.Name)

}
    
foreach ($VM in $VMs) {

    $lastPowerOff = ($PowerOff | Where { $_.Group[0].Vm.Vm -eq $VM.Id }).Group | Sort-Object -Property CreatedTime -Descending | Select -First 1

    $row = "" | select VMName,Powerstate,OS,Host,Cluster,Datastore,NumCPU,MemMb,DiskGb,PoweredOffTime

    $row.VMName = $vm.Name

    $row.Powerstate = $vm.Powerstate

    $row.OS = $vm.Guest.OSFullName

    $row.Host = $vm.VMHost.name

    $row.Cluster = $vm.VMHost.Parent.Name

    $row.Datastore = $Datastores | Where{$_.Id -eq ($vm.DatastoreIdList | select -First 1)} | Select -ExpandProperty Name

    $row.NumCPU = $vm.NumCPU

    $row.MemMb = $vm.MemoryMB

    $row.DiskGb = Get-HardDisk -VM $vm | Measure-Object -Property CapacityGB -Sum | select -ExpandProperty Sum

    $row.PoweredOffTime = $lastPowerOff.CreatedTime

    $report += $row

}

# Output to screen if required, uncomment

#$report | Sort Cluster, Host, VMName | Select VMName, Cluster, Host, NumCPU, MemMb, @{N='DiskGb';E={[math]::Round($_.DiskGb,2)}}, PoweredOffTime | ft -a

# Output to CSV - change file path for local save

$report | Sort Cluster, Host, VMName | Export-Csv -Path "" -NoTypeInformation
