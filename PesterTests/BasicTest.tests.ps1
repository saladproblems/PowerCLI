param(
    [string[]]$ComputerName = $env:COMPUTERNAME
)

foreach ($a_ComputerName in $ComputerName)
{

    describe "Operating System: $ComputerName" {
        $svc = Get-Service -Name Eventlog

        context 'Service Availability' {
            it 'Eventlog is running' {
                
                $svc.Status | Should be running
            }
        }
    }

}

#Invoke-Pester -Script @{ Path = 'S:\OneDrive\GIT\PesterTests\BasicTest.tests.ps1'; ComputerName = 'localhost' }