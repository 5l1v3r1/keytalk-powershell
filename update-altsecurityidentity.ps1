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
.\keytalk.ps1 -Path "cn=test,cn=users,dc=remco,dc=keytalk" -Filter "ObjectClass=user"
.LINK
www.keytalk.com
#>

param (
	[Parameter(Mandatory=$false)][string]$filter = "(&(objectClass=user)(!(objectClass=computer)))",
	[Parameter(Mandatory=$true)][string]$path,
	[Parameter(Mandatory=$false)][bool]$test=$true
)

Import-Module ActiveDirectory

$items = Get-ChildItem -Recurse -Path "ad:\$path" -Filter $filter

Foreach ($item in $items) {
	$currentIdentities = (Get-ItemProperty -Name "altSecurityIdentities" -Path $item.pspath).altSecurityIdentities
	
	[System.Collections.ArrayList]$identities=@()

	if ($currentIdentities -is [String]) {
		[void]$identities.Add($currentIdentities)
	} elseif ($currentIdentities -is [String[]]) {
		[System.Collections.ArrayList]$identities = $currentIdentities
	}

	$value = "X509:<I>C=NL,S=Utrecht,L=Utrecht,O=KeyTalk BV,OU=Operations,CN=KeyTalk Signing CA,E=info@keytalk.com<S>E=info@keytalk.com,C=NL,S=Utrecht,L=Utrecht,O=KeyTalk BV,OU=KeyTalk-Test,CN=$($item.Name)"
	if ($value -in $identities) {
		Write-Host "Skipping altSecurityIdentities to $($item.ObjectClass) $($item), alt identity already exists."
		continue
	}

	[void]$identities.Add($value)

	if ($test) {
		Write-Host "Skipping set due to test mode for $($item.ObjectClass) $($item)."
		continue
	}

	Write-Host "Updating altSecurityIdentities to $($item.ObjectClass) $($item)"
	Set-ItemProperty -Name "altSecurityIdentities" -Value $identities.ToArray() -Path $item.pspath
}

