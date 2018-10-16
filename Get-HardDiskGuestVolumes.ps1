function Get-HardDiskGuestVolumes
{
<#
.Synopsis
    Query the hard disks on a VM and return volume names
.DESCRIPTION
    Wrapper function for Get-HardDisk, uses Invoke-VMScript to query and guset volume names
.EXAMPLE
    Get-VM <VM> | Get-HardDiskGuestVolumes
.EXAMPLE
    Get-VM <VM> | Get-HardDiskGuestVolumes -GuestCredential <CredentialObject>
#>

    [cmdletbinding()]

    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,

        [pscredential]$GuestCredential
    )

    begin
    {        
        $diskSB = {
            Get-CimInstance win32_diskdrive -ComputerName $env:COMPUTERNAME | 
                Select-Object Index, PSComputerName,SerialNumber,
                    @{ n = 'Volumes'; e = { $PSItem | Get-CimAssociatedInstance -ResultClassName Win32_DiskPartition | Get-CimAssociatedInstance -ResultClassName Win32_LogicalDisk | Select-Object -ExpandProperty Name }} |
                        ConvertTo-Json
        }
    }

    process
    {
        $vmScriptParm = @{
            ScriptText = $diskSB
            VM = $VM          
        }

        if ($GuestCredential)
        {
            $vmScriptParm['GuestCredential'] = $GuestCredential
        }

        $guestDisks = (Invoke-VMScript @vmScriptParm).ScriptOutput | ConvertFrom-Json
        $guestDiskHash = $guestDisks | Group-Object -AsString -AsHashTable -Property { ([guid]$PSItem.serialnumber).toString() }

        $keyVolumeHash = $vm.ExtensionData.Config.Hardware.Device.Where({ $PSItem -is [VMware.Vim.VirtualDisk] }) |
            Select-Object Key, @{ n = 'GuestVolumes'; e = { $guestDiskHash[$PSItem.Backing.UUID].Volumes }} |
                Group-Object -AsHashTable -Property Key
    
        $vmDisk = Get-HardDisk -VM $VM

        foreach ($a_vmDisk in $vmDisk)
        {
            Add-Member -InputObject $a_vmDisk -PassThru -NotePropertyName GuestVolumes -NotePropertyValue ($keyVolumeHash[ [int]($a_vmDisk.ExtensionData.Key) ].GuestVolumes) |
                ForEach-Object { $PSItem.psobject.TypeNames.Insert(0, 'VMware.VimAutomation.Types.HardDisk.VolumeInfo'); $PSItem }
        }       
    }

}