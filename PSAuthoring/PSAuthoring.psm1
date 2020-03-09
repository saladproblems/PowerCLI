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
            Where-Object { $PSItem.Name -notmatch 'tests\.ps1' -and $PSItem.Extension -EQ '.ps1' -and $PSItem.DirectoryName -notmatch '\\tests$' } |
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
                $version = [Version]::new( [math]::Max(0, $version.Major), [math]::Max(0, $version.Minor), [math]::Max(0, $version.Build), [math]::Max(0, $version.Revision + 1) )
            }
            $version | Write-Verbose
        }
        Update-ModuleManifest ($modulePath -replace 'psm1$', 'psd1' ) -FunctionsToExport (Get-Childitem -Path "$($Module.DirectoryName)\public" *.ps1).BaseName -ModuleVersion $version
    }

}
