Function Get-CCMApplication {
    [Alias('Get-SMS_Application')]
    [cmdletbinding()]

    param(
        #Specifies an SCCM Application object by providing the CI_ID, CI_UniqueID, or 'LocalizedDisplayName'.
        [Parameter(ValueFromPipeline, Position = 0, ParameterSetName = 'Identity')]
        [Alias('CI_ID', 'CI_UniqueID', 'Name', 'LocalizedDisplayName')]
        [string[]]$Identity,

        # Parameter help description
        [Parameter()]
        [CimInstance]$CimInstance,

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

        $cimHash['ClassName'] = 'SMS_Application'

        $identityEqualFilter = 'LocalizedDisplayName = "{0}" OR CI_UniqueID = "{0}" OR CI_ID = "{0}"'

        $identityLikeFilter = 'LocalizedDisplayName LIKE "{0}" OR CI_UniqueID LIKE "{0}" OR CI_ID LIKE "{0}"'
    }

    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                Foreach ($obj in $Identity) {
                    if ($obj -match '\*') {
                        Get-CimInstance @cimHash -filter ($identityLikeFilter -f $obj -replace '\*', '%') |
                            Get-CimInstance #retrieving lazy properties
                    }
                    else {
                        Get-CimInstance @cimHash -filter ($identityEqualFilter -f $obj) |
                            Get-CimInstance #retrieving lazy properties
                    }
                }
            }
            'Filter' {
                Foreach ($obj in $Filter) {
                    Get-CimInstance @cimHash -filter $Filter |
                        Get-CimInstance #retrieving lazy properties
                }
            }
        }

    }
}