Function Get-CCMResource {
<#
.SYNOPSIS

Get an SCCM Resource

.DESCRIPTION

Get an SCCM Resource by Name or ResourceID

.OUTPUTS
Microsoft.Management.Infrastructure.CimInstance#root/sms/site_qtc/SMS_R_System

.EXAMPLE
C:\PS> Get-CCMResource *
Retrieves all Resources

.EXAMPLE
C:\PS> Get-CCMResource *SVR*
Returns all resources with SVR in the name

.LINK

https://github.com/saladproblems/CCM-Core

#>
    [Alias('Get-SMS_R_System')]
    [cmdletbinding()]

    param(

        [Parameter(ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Identity')]
        [Alias('ClientName', 'ResourceName', 'ResourceID')]
        [string[]]$Identity,

        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter
    )

    Begin {
        try {
            $cimHash = $Global:CCMConnection.PSObject.Copy()   
        }
        catch {
            Throw 'Not connected to CCM, reconnect using Connect-CCM'
        }
    } 

    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                Foreach ($obj in $Identity) {
                    $cimFilter = try {
                        "ResourceID = '$([int]$obj)'"
                    }catch{
                        switch -regex ($obj){
                            '^SMS_R_System' {
                                $obj -replace '.+\(|\).?'
                            }
                            '\*' {
                                "Name LIKE '$obj'" -replace '\*','%'
                                continue
                            }
                            default {
                                "Name = '$obj'"
                            }
                        }
                    }
                    Get-CimInstance @cimHash -ClassName SMS_R_System -filter $cimFilter
                }

            }
            'Filter' {
                Foreach ($obj in $Filter) {
                    Get-CimInstance @cimHash -ClassName SMS_R_System -filter $Filter
                }
            }
        }
           
    }
}