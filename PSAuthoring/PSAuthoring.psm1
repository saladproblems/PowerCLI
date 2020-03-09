    Write-Verbose "Importing $($MyInvocation.MyCommand.Name )"

Function Convert-LFToCRLF
{
	[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
	Param
	(
    [Parameter(Mandatory=$true,Position=1,ParameterSetName='PathString')]
    [string]$RootPath,
		[Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='InputFile')]
		[System.IO.FileInfo]$InputFile
	)
	Begin
	{
		# code
	}
	Process
	{
		if ( $InputFile)
		{
			$content = Get-Content $InputFile.FullName -Raw
			if ( $content -notmatch "`r`n" -and $content -match "`n" -and $PSCmdlet.ShouldProcess($InputFile.FullName, 'Convert LF to CRLF') )
			{
				$content -replace "`n","`r`n" | Set-Content $InputFile.FullName -Force
			}
		}
	}
	End
	{
		$carryParams = $PSBoundParameters
		$null = $carryParams.Remove('RootPath')
		if ( $RootPath )
		{
			Get-ChildItem $RootPath -Recurse | where { -not $_.PsIsContainer } | Convert-LFToCRLF @carryParams
		}
	}
<#
.SYNOPSIS
	Short description

.DESCRIPTION
	Long description

.OUTPUTS
	The value returned by this cmdlet

.EXAMPLE
	Example of how to use this cmdlet

.LINK
	To other relevant cmdlets or help
#>
}
Function Copy-ModulesToDFS{
	[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
  param(
    [Parameter(Mandatory=$true,Position=1)]
    [string]$DevRootPath
  )
	function ModuleFileCopy {
		param
		(
			$DevPath,
			$DFSPath,
			$ShouldProcessString
		)
		if ( $PSCmdlet.ShouldProcess($ShouldProcessString, ( 'Copy new/updated files from development to DFS?' ) ) )
		{
            robocopy $DevPath $DFSPath /MIR /S
		}
	}
	if ( ( Test-Path $DevRootPath ) ) {
		#Test section
		$devTestPath = "$DevRootPath\branches\test"
		$dfsTestPath = "\\phillips66.net\apps\CoreServerTools\wss\scripts\test\Modules\WindowsServerOperations"
		ModuleFileCopy -DevPath $devTestPath -DFSPath $dfsTestPath -ShouldProcessString 'WindowsServerOperations_Test'
		$devProdPath = "$DevRootPath\trunk\WindowsServerOperations"
		$dfsProdPath = "\\phillips66.net\apps\CoreServerTools\wss\scripts\Modules\WindowsServerOperations"
		ModuleFileCopy -DevPath $devProdPath -DFSPath $dfsProdPath -ShouldProcessString 'WindowsServerOperations_Prod'
	}

<#
.SYNOPSIS
	Short description

.DESCRIPTION
	Long description

.INPUTS
	Values or types to submit to the function

.OUTPUTS
	Values or types returned by the function

.EXAMPLE
	Example of how to use this cmdlet

.NOTES
	Comments, credits, etc.

.LINK
	To other relevant cmdlets or help
#>
}
#Requires -version 2.0
#Generates External MAML Powershell help file for any loaded cmdlet or function
#Note: Requires Joel Bennet's New-XML script from http: //www.poshcode.com/1244
#place New-XML in same directory as New-MAML
#Once the XML/MAML file is generated, you'll need to fill in the TODO items and the parameters options
#that are defaulted to false. The position parameter option will need to be changed in the generated MAML also.
#Example Usage to generate a test-ispath.ps1-help.xml file:
#PS C:\Users\u00\bin> $xml = ./new-maml test-ispath
#PS C:\Users\u00\bin> $xml.Declaration.ToString() | out-file ./test-ispath.ps1-help.xml -encoding "UTF8"
#PS C:\Users\u00\bin> $xml.ToString() | out-file ./test-ispath.ps1-help.xml -encoding "UTF8" -append
#For compiled cmdlets place the MAML file in the same directory as the binary module or snapin dll
#For script modules/functions include a reference to the External MAML file for each function
#Note: You can use the same MAML file for multiple functions, example:
#
## .ExternalHelp C:\Users\u00\bin\test-ispath.ps1-help.xml
## function test-ipath

function New-MAML {
  param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$CommandName,
    [Parameter(Position=1)]
    [string]$FilePath,
    [switch]$Append, [switch]$Force, [switch]$NoClobber
    )

  [XNamespace]$helpItems="http://msh"
  [XNamespace]$maml="http://schemas.microsoft.com/maml/2004/10"
  [XNamespace]$command="http://schemas.microsoft.com/maml/dev/command/2004/10"
  [XNamespace]$dev="http://schemas.microsoft.com/maml/dev/2004/10"
  $parameters =  get-command $commandName | %{ $commandName= $_.Name ; $_.parameters} | %{$_.Values} | where { @('ErrorVariable','WarningVariable','OutBuffer','OutVariable','PipelineVariable','Debug','Verbose','ErrorAction','WarningAction') -notContains $_.Name }

  $xml = New-Xml helpItems -schema "maml" {
      xe ($command + "command") -maml $maml -command $command -dev $dev {
              xe ($command + "details") {
                  xe ($command + "name") {"$commandName"}
                  xe ($maml + "description") {
                      xe ($maml + "para") {"TODO Add Short description"}
                  }
                  xe ($maml + "copyright") {
                      xe ($maml + "para") {}
                  }
                  xe ($command + "verb") {"$(($CommandName -split '-')[0])"}
                  xe ($command + "noun") {"$(($commandName -split '-')[1])"}
                  xe ($dev + "version") {}
              }
              xe ($maml + "description") {
                  xe ($maml + "para") {"TODO Add Long description"}
              }
              xe ($command + "syntax") {
                  xe ($command + "syntaxItem") {
                  $parameters | foreach {
                      xe ($command + "name") {"$commandName"}

                          xe ($command + "parameter") -globbing "false" -variableLength "" -position "named" -required "true" -pipelineInput "true (ByValue, ByPropertyName)" {
#                          xe ($command + "parameter") -require "false" -variableLength "false" -globbing "false" -pipelineInput "false" -postion "0" {
                              xe ($maml + "name") {"$($_.Name)"}
#                              xe ($maml + "description") {
#                                  xe ($maml + "para") {"TODO Add $($_.Name) Description"}
#                              }
                              xe ($command + "parameterValue") -required "false" -variableLength "false" {"$($_.ParameterType.Name)"}
                          }
                      }
                  }
              }
              xe ($command + "parameters") {
                  $parameters | foreach {
                  xe ($command + "parameter") -globbing "false" -variableLength "" -position "named" -required "true" -pipelineInput "true (ByValue, ByPropertyName)" {
#                  xe ($command + "parameter") -required "false" -variableLength "false" -globbing "false" -pipelineInput "false (ByValue)" -position "0" {
                      xe ($maml + "name") {"$($_.Name)"}
  		    xe ($maml + "description") {
  			xe ($maml + "para") {"TODO Add $($_.Name) Description"}
                      }
  		    xe ($command + "parameterValue") -required "true" -variableLength "false" {"$($_.ParameterType.Name)"}
                      xe ($dev + "type") {
                          xe ($maml + "name") {"$($_.ParameterType.Name)"}
                      }
  		    xe ($dev + "defaultValue") {}
                  }
                  }
              }
  	    xe ($command + "inputTypes") {
                  xe ($command + "inputType") {
                      xe ($dev + "type") {
                          xe ($maml + "name") {"TODO Add $commandName inputType"}
                          xe ($maml + "description") {
                              xe ($maml + "para") {}
                          }
                      }
  			xe ($maml + "description") {}
                  }
              }
  	    xe ($command + "returnValues") {
  		xe ($command + "returnValue") {
  		    xe ($dev + "type") {
  		        xe ($maml + "name") {"TODO Add $commandName returnType"}
                          xe ($maml + "description") {
                              xe ($maml + "para") {}
                          }
                      }
  		    xe ($maml + "description") {}
  		}
  	    }
              xe ($command + "terminatingErrors") {}
  	    xe ($command + "nonTerminatingErrors") {}
  	    xe ($maml + "alertSet") {
  		xe ($maml + "alert") {
  		    xe ($maml + "para") {"AUTHOR: "}
                  }
              }
              xe ($command + "examples") {
  		xe ($command + "example") {
                      xe ($maml + "title") {"--------------  EXAMPLE 1 --------------"}
                      xe ($dev + "code") {"TODO Add $commandName Example code"}
                      xe ($dev + "remarks") {
                          xe ($maml + "para") {"TODO Add $commandName Example Comment"}
                          xe ($maml + "para") {}
                      }
                  }
              }
              xe ($maml + "relatedLinks") {
                  xe ($maml + "navigationLink") {
  		    xe ($maml + "linkText") {"$commandName"}
                  }
              }
          }
      }
  if ( $FilePath ) {
    $null = $PSBoundParameters.Remove('CommandName')
    $xml.ToString() | Out-File @PSBoundParameters -Encoding 'UTF8'
  }
  else { return $xml }
}
Function New-SimpleModule
{
	[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
	Param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$Name,

		[string]$ParentPath = $pwd,
		[string]$Description,
		[switch]$PassThru
	)
	if (!( Test-Path $ParentPath\$Name ))
	{
		md $ParentPath\$Name
	}
	$psd = @()
	try {
		$oHash = [ordered]@{
			Guid = [System.Guid]::NewGuid().ToString()
			RootModule = ''
			Description = $Description
			ModuleVersion = '1.0'
			NestedModules = ( '@(''{0}.psm1'')' -f $Name )
			PowerShellVersion = ''
			PowerShellHostName = ''
			PowerShellHostVersion = ''
			RequiredModules = '@()'
			FormatsToProcess = '@(''_Formats.ps1xml'')'
			ScriptsToProcess = '@()'
			RequiredAssemblies = '@()'
			FunctionsToExport = '*-*'
			AliasesToExport = '*'
			VariablesToExport = '*'
			CmdletsToExport = '*'
		}
		$psd += '@{'
		foreach ( $key in $oHash.Keys )
		{
			if ( $oHash.$key -match '@' )
			{
			 	$psd += ('{0} = {1}' -f $key, $oHash.$key )
			}
			else
			{
				$psd += ('{0} = ''{1}''' -f $key, $oHash.$key )
			}
		}
		$psd += '}'
		if ( ! ( Test-Path $ParentPath\$Name\$Name.psd1 ) -or $PSCmdlet.ShouldProcess("$Name.psd1",'Overwrite file?') ) {
			$psd | Set-Content $ParentPath\$Name\$Name.psd1
		}
		if ( ! ( Test-Path $ParentPath\$Name\$Name.psm1 ) -or $PSCmdlet.ShouldProcess("$Name.psm1",'Overwrite file?') ) {
			'foreach ( $functionFile in ( Get-ChildItem $PSScriptRoot\*.ps1 ) )',
			'{',
			' 	. $functionFile.FullName',
			'}',
			'Export-ModuleMember -Alias * -Function * -Cmdlet *' | Set-Content $ParentPath\$Name\$Name.psm1
		}
		if ( ! ( Test-Path $ParentPath\$Name\_Formats.ps1xml ) -or $PSCmdlet.ShouldProcess("\$Name\_Formats.ps1xml",'Overwrite file?') )
		{
			'<?xml version="1.0" encoding="utf-8" ?>',
			'<Configuration>',
			'    <ViewDefinitions>',
			'    </ViewDefinitions>',
			'</Configuration>' |
			Set-Content $ParentPath\$Name\_Formats.ps1xml
		}

	}
	catch{

	}

}
Function New-WSOModuleDataFiles
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
            CompanyName = 'Phillips66'

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
#requires -version 2.0
#### NOTE: you can revert this to work in PowerShell 1.0 by just removing the [Parameter(...)] lines
####       BUT YOU WILL HAVE TO pass the $Version $Encoding $Standalone parameters EACH TIME
####       UNLESS you remove them, and switch back to a hardcoded XDeclaration ... or something.
####################################################################################################
#### I still have to add documentation comments to these, but in the meantime ...
### please see the samples at the bottom to understand how to use them :)
####
$xlr8r = [psobject].Assembly.gettype("System.Management.Automation.TypeAccelerators")
$xlinq = [Reflection.Assembly]::Load("System.Xml.Linq, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
$xlinq.GetTypes() | ? { $_.IsPublic -and !$_.IsSerializable -and $_.Name -ne "Extensions" -and !$xlr8r::Get[$_.Name] } | % {
  $xlr8r::Add( $_.Name, $_.FullName )
}

function New-Xml {
Param(
   [Parameter(Mandatory = $true, Position = 0)]
   [System.Xml.Linq.XName]$root
,
   [Parameter(Mandatory = $false)]
   [string]$Version = "1.0"
,
   [Parameter(Mandatory = $false)]
   [string]$Encoding = "UTF-8"
,
   [Parameter(Mandatory = $false)]
   [string]$Standalone = "yes"
,
   [Parameter(Position=99, Mandatory = $false, ValueFromRemainingArguments=$true)]
   [PSObject[]]$args
)
BEGIN {
   if(![string]::IsNullOrEmpty( $root.NamespaceName )) {
      Function New-XmlDefaultElement {
         Param([System.Xml.Linq.XName]$tag)
         if([string]::IsNullOrEmpty( $tag.NamespaceName )) {
            $tag = $($root.Namespace) + $tag
         }
         New-XmlElement $tag @args
      }
      Set-Alias xe New-XmlDefaultElement
   }
}
PROCESS {
   #New-Object XDocument (New-Object XDeclaration "1.0", "UTF-8", "yes"),(
   New-Object XDocument (New-Object XDeclaration $Version, $Encoding, $standalone),(
      New-Object XElement $(
         $root
         #  foreach($ns in $namespace){
            #  $name,$url = $ns -split ":",2
            #  New-Object XAttribute ([XNamespace]::Xmlns + $name),$url
         #  }
         while($args) {
            $attrib, $value, $args = $args
            if($attrib -is [ScriptBlock]) {
               &$attrib
            } elseif ( $value -is [ScriptBlock] -and "-Content".StartsWith($attrib)) {
               &$value
            } elseif ( $value -is [XNamespace]) {
               New-XmlAttribute ([XNamespace]::Xmlns + $attrib.TrimStart("-")) $value
            } else {
               New-XmlAttribute $attrib.TrimStart("-") $value
            }
         }
      ))
}
END {
   Set-Alias xe New-XmlElement
}
}
function New-XmlAttribute {
Param($name,$value)
   New-Object XAttribute $name,$value
}
Set-Alias xa New-XmlAttribute


function New-XmlElement {
  Param([System.Xml.Linq.XName]$tag)
  Write-Verbose $($args | %{ $_ | Out-String } | Out-String)
  New-Object XElement $(
     $tag
     while($args) {
        $attrib, $value, $args = $args
        if($attrib -is [ScriptBlock]) {
           &$attrib
        } elseif ( $value -is [ScriptBlock] -and "-Content".StartsWith($attrib)) {
           &$value
        } elseif ( $value -is [XNamespace]) {
            New-Object XAttribute ([XNamespace]::Xmlns + $attrib.TrimStart("-")),$value
        } else {
           New-Object XAttribute $attrib.TrimStart("-"), $value
        }
     }
   )
}
Set-Alias xe New-XmlElement




####################################################################################################
###### EXAMPLE SCRIPT: NOTE the `: in the http`: is only there for PoshCode, you can just use http:
# [XNamespace]$dc = "http`://purl.org/dc/elements/1.1"
#
# $xml = New-Xml rss -dc $dc -version "2.0" {
#    xe channel {
#       xe title {"Test RSS Feed"}
#       xe link {"http`://HuddledMasses.org"}
#       xe description {"An RSS Feed generated simply to demonstrate my XML DSL"}
#       xe ($dc + "language") {"en"}
#       xe ($dc + "creator") {"Jaykul@HuddledMasses.org"}
#       xe ($dc + "rights") {"Copyright 2009, CC-BY"}
#       xe ($dc + "date") {(Get-Date -f u) -replace " ","T"}
#       xe item {
#          xe title {"The First Item"}
#          xe link {"http`://huddledmasses.org/new-site-new-layout-lost-posts/"}
#          xe guid -isPermaLink true {"http`://huddledmasses.org/new-site-new-layout-lost-posts/"}
#          xe description {"Ema Lazarus' Poem"}
#          xe pubDate  {(Get-Date 10/31/2003 -f u) -replace " ","T"}
#       }
#    }
# }
#
# $xml.Declaration.ToString()  ## I can't find a way to have this included in the $xml.ToString()
# $xml.ToString()
#
####### OUTPUT: (NOTE: I added the space in the http: to paste it on PoshCode -- those aren't in the output)
# <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
# <rss xmlns:dc="http ://purl.org/dc/elements/1.1" version="2.0">
#   <channel>
#     <title>Test RSS Feed</title>
#     <link>http ://HuddledMasses.org</link>
#     <description>An RSS Feed generated simply to demonstrate my XML DSL</description>
#     <dc:language>en</dc:language>
#     <dc:creator>Jaykul@HuddledMasses.org</dc:creator>
#     <dc:rights>Copyright 2009, CC-BY</dc:rights>
#     <dc:date>2009-07-26T00:50:08Z</dc:date>
#     <item>
#       <title>The First Item</title>
#       <link>http ://huddledmasses.org/new-site-new-layout-lost-posts/</link>
#       <guid isPermaLink="true">http ://huddledmasses.org/new-site-new-layout-lost-posts/</guid>
#       <description>Ema Lazarus' Poem</description>
#       <pubDate>2003-10-31T00:00:00Z</pubDate>
#     </item>
#   </channel>
# </rss>


####################################################################################################
###### ANOTHER EXAMPLE SCRIPT, this time with a default namespace
## IMPORTANT! ## NOTE that I use the "xe" shortcut which is redefined when you specify a namespace
##            ## for the root element, so that all child elements (by default) inherit that.
##            ## You can still control the prefixes by passing the namespace as a parameter
##            ## e.g.: -atom $atom
###### The `: in the http`: is still only there for PoshCode, you can just use http: ...
####################################################################################################
#
#   [XNamespace]$atom="http`://www.w3.org/2005/Atom"
#   [XNamespace]$dc = "http`://purl.org/dc/elements/1.1"
#
#   New-Xml ($atom + "feed") -Encoding "UTF-16" -$([XNamespace]::Xml +'lang') "en-US" -dc $dc {
#      xe title {"Test First Entry"}
#      xe link {"http`://HuddledMasses.org"}
#      xe updated {(Get-Date -f u) -replace " ","T"}
#      xe author {
#         xe name {"Joel Bennett"}
#         xe uri {"http`://HuddledMasses.org"}
#      }
#      xe id {"http`://huddledmasses.org/" }
#
#      xe entry {
#         xe title {"Test First Entry"}
#         xe link {"http`://HuddledMasses.org/new-site-new-layout-lost-posts/" }
#         xe id {"http`://huddledmasses.org/new-site-new-layout-lost-posts/" }
#         xe updated {(Get-Date 10/31/2003 -f u) -replace " ","T"}
#         xe summary {"Ema Lazarus' Poem"}
#         xe link -rel license -href "http://creativecommons.org/licenses/by/3.0/" -title "CC By-Attribution"
#         xe ($dc + "rights") {"Copyright 2009, Some rights reserved (licensed under the Creative Commons Attribution 3.0 Unported license)"}
#         xe category -scheme "http://huddledmasses.org/tag/" -term "huddled-masses"
#      }
#   } | % { $_.Declaration.ToString(); $_.ToString() }
#
####### OUTPUT: (NOTE: I added the spaces again to the http: to paste it on PoshCode)
# <?xml version="1.0" encoding="UTF-16" standalone="yes"?>
# <feed xml:lang="en-US" xmlns="http ://www.w3.org/2005/Atom">
#   <title>Test First Entry</title>
#   <link>http ://HuddledMasses.org</link>
#   <updated>2009-07-29T17:25:49Z</updated>
#   <author>
#      <name>Joel Bennett</name>
#      <uri>http ://HuddledMasses.org</uri>
#   </author>
#   <id>http ://huddledmasses.org/</id>
#   <entry>
#     <title>Test First Entry</title>
#     <link>http ://HuddledMasses.org/new-site-new-layout-lost-posts/</link>
#     <id>http ://huddledmasses.org/new-site-new-layout-lost-posts/</id>
#     <updated>2003-10-31T00:00:00Z</updated>
#     <summary>Ema Lazarus' Poem</summary>
#     <link rel="license" href="http ://creativecommons.org/licenses/by/3.0/" title="CC By-Attribution" />
#     <dc:rights>Copyright 2009, Some rights reserved (licensed under the Creative Commons Attribution 3.0 Unported license)</dc:rights>
#     <category scheme="http ://huddledmasses.org/tag/" term="huddled-masses" />
#   </entry>
# </feed>
#
#
function Reset-DevModules {
  param(
    [Parameter(Mandatory=$true,Position=1)]
    [string]$DevRootPath
  )
  function New-ModuleFileList {
   	param(
  		[string]$Path = $pwd
  	)
  	$array = Get-ChildItem $Path\*.ps1 | select -ExpandProperty Name
  	$returnArray = New-Object System.Collections.ArrayList
  	foreach ( $file in $array )
  	{
  	  $null = $returnArray.Add( ('. $PSScriptRoot\{0}' -f $file) )
  	}
  	$returnArray
  }
  $module = Get-Item "$DevRootPath\PSAuthoring"
  $temp = New-ModuleFileList $module.FullName
  if ( ( Get-Content ( "{0}\{1}.psm1" -f $module.FullName, $module.Name ) ) -ne $temp ) {
  	$temp | Set-Content ( "{0}\{1}.psm1" -f $module.FullName, $module.Name ) -Force
  }

  $root = "$DevRootPath\WindowsServerOperations"
  foreach ( $module in ( Get-ChildItem $root\shared | ? { $_.PsIsContainer }  ) ) {
  	$temp = New-ModuleFileList $module.FullName
    $temp += 'Export-ModuleMember -Alias * -Function * -Cmdlet *'
  	if ( ( Get-Content ( '{0}\{1}.psm1' -f $module.FullName, $module.Name ) ) -ne $temp ) {
  		$temp | Set-Content ( '{0}\{1}.psm1' -f $module.FullName, $module.Name ) -Force
  	}
  }

  foreach ( $module in ( Get-ChildItem $root\private | ? { $_.PsIsContainer }  ) ) {
  	$temp = New-ModuleFileList $module.FullName
    $temp += 'Export-ModuleMember -Alias * -Function * -Cmdlet *'
    $fileName = "{0}\{1}.psm1" -f $module.FullName, $module.Name
  	if ( ! ( Test-Path $fileName -ErrorAction SilentlyContinue ) -or ( ( Get-Content $fileName ) -ne $temp ) ) {
  		$temp | Set-Content ( "{0}\{1}.psm1" -f $module.FullName, $module.Name ) -Force
  	}
  }
  
  foreach ( $module in ( Get-ChildItem $root\Sandbox | ? { $_.PsIsContainer }  ) ) {
  	$temp = New-ModuleFileList $module.FullName
    $temp += 'Export-ModuleMember -Alias * -Function * -Cmdlet *'
    $fileName = "{0}\{1}.psm1" -f $module.FullName, $module.Name
  	if ( ! ( Test-Path $fileName -ErrorAction SilentlyContinue ) -or ( ( Get-Content $fileName ) -ne $temp ) ) {
  		$temp | Set-Content ( "{0}\{1}.psm1" -f $module.FullName, $module.Name ) -Force
  	}
  }
}
function Set-DevProfile {
	(Get-Content $PROFILE ) -replace 'ModulesToLoad.P','ModulesToLoad.D' | Set-Content $PROFILE
}
function Set-ProductionProfile {
	(Get-Content $PROFILE ) -replace 'ModulesToLoad.D','ModulesToLoad.P' | Set-Content $PROFILE
}
function Set-TestProfile {
	(Get-Content $PROFILE ) -replace 'ModulesToLoad.P','ModulesToLoad.D' | Set-Content $PROFILE
}
