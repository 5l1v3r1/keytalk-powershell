<#
.SYNOPSIS
Configures the altSecurityIdentities for Keytalk
.DESCRIPTION
.PARAMETER Path
The path of the objects to add
.PARAMETER Filter
The filter to use
.PARAMETER Test
Default in test mode, no writes
.EXAMPLE
.\keytalk.ps1 -add -Path "cn=test,cn=users,dc=remco,dc=keytalk" -Filter "ObjectClass=user" 
.\keytalk.ps1 -delete -Path "cn=test,cn=users,dc=remco,dc=keytalk" -Filter "ObjectClass=user"
.LINK
www.keytalk.com
#>

param (
    [Parameter(Mandatory=$true)][string]$path,
	[Parameter(Mandatory=$false)][string]$filter = "(&(objectClass=user)(!(objectClass=computer)))",
	[Parameter(Mandatory=$false, ParameterSetName='add')][string]$template = "X509:<I>C=NL,S=Utrecht,L=Utrecht,O=KeyTalk BV,OU=Operations,CN=KeyTalk Signing CA,E=info@keytalk.com<S>E=info@keytalk.com,C=NL,S=Utrecht,L=Utrecht,O=KeyTalk BV,OU=KeyTalk-Test,CN={name}",
	[Parameter()][switch]$force=$false,
	[Parameter(ParameterSetName='add')][switch]$add=$false,
	[Parameter(ParameterSetName='delete')][switch]$delete=$false
)

Import-Module ActiveDirectory

$items = Get-ChildItem -Recurse -Path "ad:\$path" -Filter $filter
switch ($PsCmdlet.ParameterSetName) 
{ 
	"add" {
		Foreach ($item in $items) {
			$currentIdentities = (Get-ItemProperty -Name "altSecurityIdentities" -Path $item.pspath).altSecurityIdentities
			
			[System.Collections.ArrayList]$identities=@()

			if ($currentIdentities -is [String]) {
				[void]$identities.Add($currentIdentities)
			} elseif ($currentIdentities -is [String[]]) {
				[System.Collections.ArrayList]$identities = $currentIdentities
			}

			$value = $template
			
			$vars = @{
				"name" = $item.Name;
				"displayName" = (Get-ItemProperty -Name "displayName" -Path $item.pspath).displayName;
				"company" = (Get-ItemProperty -Name "company" -Path $item.pspath).company;
			}
			
			Foreach ($p in $vars.GetEnumerator()) {
				$value = $value.Replace("{" + $p.Key + "}", $p.Value)
			}

			if ($value -in $identities) {
				Write-Host "Skipping altSecurityIdentities to $($item.ObjectClass) $($item), alt identity already exists."
				continue
			}

			[void]$identities.Add($value)

			if (!$force) {
				Write-Host "Skipping add due to test mode for $($item.ObjectClass) $($item)."
				continue
			}

			Write-Host "Updating altSecurityIdentities to $($item.ObjectClass) $($item)"
			Set-ItemProperty -Name "altSecurityIdentities" -Value $identities.ToArray() -Path $item.pspath
		}
		break
	} 
	"delete" {
		Foreach ($item in $items) {
			$currentIdentities = (Get-ItemProperty -Name "altSecurityIdentities" -Path $item.pspath).altSecurityIdentities

			if (!$force) {
				Write-Host "Skipping delete due to test mode for $($item.ObjectClass) $($item) with value ""$($currentIdentities)""."
				continue
			}

			Write-Host "Deleting altSecurityIdentities to $($item.ObjectClass) $($item)"
			Clear-ItemProperty -Name "altSecurityIdentities" -Path $item.pspath
		}
		break
	}
}