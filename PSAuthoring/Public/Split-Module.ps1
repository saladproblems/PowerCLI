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