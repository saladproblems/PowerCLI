<#
Function New-ModuleFiles
{

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium")]

    Param(

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="File")]
        [IO.FileSystemInfo]$File,
        [switch]$NewGUID
    )

    Begin{

            $CommonCode = @'
    Write-Verbose "Importing $($MyInvocation.MyCommand.Name )"

'@
    
    $versionHash = @{ TypeName = 'System.Version' }

    #$hasher = new-object System.Security.Cryptography.SHA256Managed

    Filter StringToHash
    {
        [System.Text.Encoding]::UTF8.GetBytes($PSItem)
    }
    
    }    

    Process{

        #$file

        Write-Verbose -Message $File.FullName

        $NestedModules = $File.Directory | Get-ChildItem -Depth 1 -Include "*.psm1" -Filter *

        if ( $File.Extension -ne ".psd1" ) { return }
    
        $psm1Path = $File.fullname -replace 'psd1','psm1'

        $psm1Hash = Get-FileHash $psm1Path | Select-Object -ExpandProperty Hash

        $psm1Hash | Write-Verbose

        $importParms = Invoke-Expression ( $file | Get-Content | Out-String )
    
        $combineParms = $importParms.Clone()

        $setParms = @{
            path = $file.fullname
            NestedModules = $NestedModules.BaseName
            ModuleList = $NestedModules.BaseName
            FunctionsToExport = "*-*"
            #RootModule = $file.BaseName
        }

        if ( Test-Path "$($file.directory)\_Formats.ps1xml" )
        {
            $setParms['FormatsToProcess'] = '_Formats.ps1xml'
        }
        ELSE
        {
            Write-Verbose "Format file not found"
            $null = $importParms.Remove('FormatsToProcess')
        }

        if ( Test-Path "$($file.directory)\_Types.ps1xml" )
        {
            $setParms['TypesToProcess'] = '_Types.ps1xml'
        }
        ELSE
        {
            Write-Verbose "Type file not found"
            $null = $importParms.Remove('FormatsToProcess')
        }

        $NestedModules = $file.Directory | Get-ChildItem -Depth 1 -Include "*.psm1" -Filter *
    
        Write-Verbose  "Reading Manifest File: $($file.FullName)"

        $setParms.GetEnumerator() | Out-String | Write-Verbose       

        $combineParms.Remove('RootModule')

        if (-not $combineParms['PrivateData'].Values)
        {
            $combineParms.Remove('PrivateData')
        }

        if ($NewGUID) { $combineParms.Remove('GUID') }
    
        $PS1 = Get-ChildItem  "$($File.Directory.FullName)\*" -Include '*.ps1' | Sort-Object Name

        if ($PSCmdlet.ShouldProcess)
        {
            Write-Verbose "Generating script file: $($File.fullname -replace "psd1","psm1" )"

            $CommonCode,( $PS1 | Get-Content ) | Set-Content -Path $psm1Path

            Switch ((Get-FileHash $psm1Path).Hash)
            { 
                { -not $psm1Hash }{ break }

                { $PSItem -ne $psm1Hash }
                {
                
                    $versionHash = @{ ArgumentList = (Get-Module $File.fullname -ListAvailable).Version.Major,( (Get-Module $File.fullname -ListAvailable).Version.Minor + 1 )}
                    $combineParms['ModuleVersion'] = New-Object -TypeName System.Version @versionHash

                    $combineParms.ModuleVersion | Out-String | Write-Verbose
                }

            }
        
            $hashDiff = $importParms.GetEnumerator() | ForEach-Object {
                '{0}:{1}' -f $PSItem.Name, ($importParms[$PSItem.name] -eq $combineParms[$PSItem.name])
            }

            $compareHash = ($importParms.GetEnumerator()).foreach({ $combineParms[$PSItem.name] -eq $importParms[$PSItem.name] })
        
            #$hashDiff | Out-String | Write-Verbose

            $combineParms | Out-String | Write-Verbose
        
            if($compareHash -contains $false)
            {
                #$setParms['PrivateData'] = [PSCustomObject]($combineParms['PrivateData'])
                $setParms.Keys | ForEach-Object {
                    $combineParms.Remove($PSItem)
                }

                #private data appears to be bugged with New-ModuleManifest, review later
                $combineParms.Remove('PrivateData')

                Write-Verbose "Generating Manifest file $($combineParms['path'])"
                New-ModuleManifest @combineParms @setParms -ErrorAction Stop
                #break
            }

        }

    }

    End{}

}
#>