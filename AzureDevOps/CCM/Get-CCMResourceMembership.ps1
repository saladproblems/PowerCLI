Function Get-CCMResourceMembership {
    [Alias('Get-SMS_FullCollectionMembership')]
    [cmdletbinding()]

    param(

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = 'Identity')]
        [Alias('ClientName', 'ResourceName','ResourceID','Name')]
        [string[]]$Identity,
        
        [Parameter()]
        [alias('HasServiceWinow')]
        [switch]$HasMaintenanceWindow,

        [Parameter()]
        [string[]]$Property,

        # Parameter help description
        [Parameter()]
        [switch]$ShowResourceName
    )

    Begin {     
        $cimHash = $Global:CCMConnection.PSObject.Copy()

        $cimHash['ClassName'] = 'SMS_FullCollectionMembership'

        if ($Property) { $cimHash['Property'] = $Property }

        @{ }
    }

    Process {

        Foreach ($obj in $Identity) {
            #CollectionID for a resource is an integer, unlike collections, so we can't do an OR statement like 'ResourceID = "test" OR 'Name = "test"'
            $filter = try {
                "ResourceID = '$([int]$obj)'"
            }catch{
                switch -regex ($obj){
                    '^SMS_R_System' {
                        $obj -replace '.+\(|\).+'
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

            Get-CimInstance @cimHash -filter $filter -KeyOnly | Group-Object Name | ForEach-Object {                
                if ($ShowResourceName.IsPresent){
                    #Starting in Windows PowerShell 5.0, Write-Host is a wrapper for Write-Information
                    Write-Host "Collection memberships for: '$($PSItem.Name)'" -ForegroundColor Green
                }

                Get-CCMCollection -Identity $PSItem.Group.CollectionID -HasMaintenanceWindow:($HasMaintenanceWindow.IsPresent) | 
                    Sort-Object -Property Name
            }
        }
           
    }
}