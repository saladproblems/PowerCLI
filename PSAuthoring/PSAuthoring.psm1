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
function Split-Module {
    [cmdletbinding()]
    
    param(
        [parameter(mandatory,ValueFromPipeline)]
        [alias('fullname')]
        [string]$Path
    )

    process {
        $file = Get-Item -Path $Path
        
        $module = Import-Module -Name $file.FullName -Force -PassThru

        foreach ($command in (Get-Command -Module $module)) {
            $scriptDefinition = [System.Text.StringBuilder]::new($command.Definition)
            $null = $scriptDefinition.Insert(0,"function $($command.Name) {`r`n")
            $null = $scriptDefinition.Append('}')
    
            New-Item -Force -Value $scriptDefinition.ToString() -Path ('{0}\Public\{1}.ps1' -f $file.Directory.FullName,$command.Name)
        }
        
    }
}
Function Update-ModuleContent {
    [cmdletbinding()]
    param(
        [parameter(valuefrompipeline)]
        [System.IO.FileInfo]$Module,
        [switch]$DoNotIncrementVersion
    )

    Process {
        Write-Verbose $Module.FullName
        if ($Module.Extension -notmatch 'ps(d|m)1$') { return }

        $modulePath = $Module.FullName -replace 'psd1$', 'psm1'

        Write-Verbose "Setting content of: '$modulePath'"

        $beforeHash = Get-FileHash -Path $modulePath

        $ps1Files = Get-ChildItem $Module.Directory -filter *.ps1 -Recurse |
        Where-Object { $PSItem.Extension -EQ '.ps1' -and $PSItem.DirectoryName -notmatch '\\tests$' } |
        Sort-Object Name |
        ForEach-Object {
            Add-Member -InputObject $PSItem -PassThru -NotePropertyName Content -NotePropertyValue ($_ | Get-Content)
        }

        $ps1Files | ForEach-Object -Begin { $Errors = $null } {
            $null = [System.Management.Automation.PSParser]::Tokenize( $PSItem.Content, [ref]$Errors)
            if ($Errors.Count -gt 0) {
                Write-Warning "Found $([int]$Errors.Count) error(s) in $($PSItem.Name), skipping"
            }
            else {
                $PSItem.Content
            }
        } | Set-Content -Path $modulePath

        [version]$version = (Get-Module ($modulePath -replace 'psm1$', 'psd1' ) -ListAvailable).Version

        if ($beforeHash.Hash -ne (Get-FileHash -Path $modulePath).Hash) {
            Write-Host "Module content updated: $modulePath" -ForegroundColor Green
            if (-not $DoNotIncrementVersion.IsPresent) {
                $version = [Version]::new( [math]::(0,$version.Major), [math]::(0,$version.Minor), [math]::Max(0,$version.Build), [math]::Max(0,$version.Revision + 1) )
            }
            $version | Write-Verbose
        }
        Update-ModuleManifest ($modulePath -replace 'psm1$', 'psd1' ) -FunctionsToExport (Get-Childitem -Path "$($Module.DirectoryName)\public" *.ps1).BaseName -ModuleVersion $version
    }

}
