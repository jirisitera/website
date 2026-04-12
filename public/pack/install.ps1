$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$scriptFilePath = $PSCommandPath
if ([string]::IsNullOrWhiteSpace($scriptFilePath)) {
	$scriptFilePath = $MyInvocation.PSCommandPath
}
$scriptDirectory = $null
if (-not [string]::IsNullOrWhiteSpace($scriptFilePath)) {
	$scriptDirectory = Split-Path -Path $scriptFilePath -Parent
}
function Show-Menu {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Title,
		[Parameter(Mandatory = $true)]
		[string[]]$Options,
		[string[]]$Description = @(),
		[int]$DefaultIndex = 0
	)
	$index = [Math]::Max(0, [Math]::Min($DefaultIndex, $Options.Count - 1))
	while ($true) {
		Clear-Host
		Write-Host $Title -ForegroundColor Cyan
		if ($Description.Count -gt 0) {
			foreach ($line in $Description) {
				Write-Host $line -ForegroundColor Gray
			}
		}
		Write-Host "Use Up/Down arrows and press Enter to confirm." -ForegroundColor DarkGray
		Write-Host ""
		for ($i = 0; $i -lt $Options.Count; $i++) {
			if ($i -eq $index) {
				Write-Host ("> " + $Options[$i]) -ForegroundColor Yellow
			}
			else {
				Write-Host ("  " + $Options[$i])
			}
		}
		$key = [Console]::ReadKey($true)
		switch ($key.Key) {
			"UpArrow" {
				$index = if ($index -le 0) { $Options.Count - 1 } else { $index - 1 }
			} "DownArrow" {
				$index = if ($index -ge ($Options.Count - 1)) { 0 } else { $index + 1 }
			} "Enter" {
				return $index
			} default {
				if ($key.KeyChar -match "^[1-9]$") {
					$numeric = [int]::Parse($key.KeyChar.ToString()) - 1
					if ($numeric -ge 0 -and $numeric -lt $Options.Count) {
						return $numeric
					}
				}
			}
		}
	}
}
function Show-Notice {
	param(
		[Parameter(Mandatory = $true)]
		[string[]]$Lines,
		[string]$Color = "DarkYellow"
	)
	foreach ($line in $Lines) {
		Write-Host $line -ForegroundColor $Color
	}
	Write-Host "Press Enter to continue..." -ForegroundColor DarkGray
	while ($true) {
		$key = [Console]::ReadKey($true)
		if ($key.Key -eq "Enter") {
			break
		}
	}
}
function Resolve-ModrinthProfileResourcepackPath {
	$defaultProfilesRoot = Join-Path $env:APPDATA "ModrinthApp\profiles"
	$backLabel = "Back to main menu..."
	if (-not (Test-Path -Path $defaultProfilesRoot)) {
		Show-Notice -Lines @(
			"No default Modrinth profiles directory found at '$defaultProfilesRoot'.",
			"Returning to main menu."
		)
		return $null
	}
	$profiles = Get-ChildItem -Path $defaultProfilesRoot -Directory | Sort-Object Name
	if ($profiles.Count -eq 0) {
		Show-Notice -Lines @(
			"No profiles were found in '$defaultProfilesRoot'.",
			"Returning to main menu."
		)
		return $null
	}
	$options = @()
	foreach ($profile in $profiles) {
		$options += "Use profile: '$($profile.Name)'..."
	}
	$options += $backLabel
	$selection = Show-Menu -Title "Choose a Modrinth profile:" -Options $options
	if ($selection -eq ($options.Count - 1)) {
		return $null
	}
	$selectedProfilePath = $profiles[$selection].FullName
	return (Join-Path $selectedProfilePath "resourcepacks")
}
function Get-RemoteTemplatePackPath {
	param(
		[Parameter(Mandatory = $true)]
		[string]$TemplateZipUrl
	)
	$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("japicraft-pack-" + [Guid]::NewGuid().ToString("N"))
	$zipPath = Join-Path $tempRoot "template.zip"
	$extractPath = Join-Path $tempRoot "template-extract"
	New-Item -Path $extractPath -ItemType Directory -Force | Out-Null
	Invoke-WebRequest -Uri $TemplateZipUrl -OutFile $zipPath -UseBasicParsing
	Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
	$directTemplate = Join-Path $extractPath "template"
	if (Test-Path -Path $directTemplate) {
		return $directTemplate
	}
	if (Test-Path -Path (Join-Path $extractPath "pack.mcmeta")) {
		return $extractPath
	}
	$candidate = Get-ChildItem -Path $extractPath -Directory | Where-Object {
		Test-Path -Path (Join-Path $_.FullName "pack.mcmeta")
	} | Select-Object -First 1
	if ($candidate) {
		return $candidate.FullName
	}
	throw "Downloaded template archive did not contain a valid resource pack folder."
}
function Resolve-TemplatePackPath {
	param(
		[Parameter(Mandatory = $true)]
		[string]$TemplateZipUrl,
		[string]$ScriptDirectory
	)
	if (-not [string]::IsNullOrWhiteSpace($ScriptDirectory)) {
		$localTemplatePath = Join-Path $ScriptDirectory "template"
		if (Test-Path -Path (Join-Path $localTemplatePath "pack.mcmeta")) {
			Write-Host "Using local template pack from: $localTemplatePath" -ForegroundColor DarkGray
			return $localTemplatePath
		}
	}
	Write-Host "Local template pack not found. Downloading from: $TemplateZipUrl" -ForegroundColor DarkGray
	return (Get-RemoteTemplatePackPath -TemplateZipUrl $TemplateZipUrl)
}
$templateZipUrl = "https://japicraft.com/pack/template.zip"
$sourcePackPath = Resolve-TemplatePackPath -TemplateZipUrl $templateZipUrl -ScriptDirectory $scriptDirectory
$mainOptions = @(
	"Install to a Modrinth App profile...",
	"Install to default .minecraft folder...",
	"Install to a custom folder...",
	"Exit (Cancel)"
)
$mainDescription = @(
	"Installs a simple template resource pack into a selected Minecraft resourcepacks folder."
)
$destinationRoot = $null
$cancelled = $false
$confirmed = $false
while ($true) {
	$mainSelection = Show-Menu -Title "Template Resource Pack Installer" -Options $mainOptions -Description $mainDescription
	switch ($mainSelection) {
		0 {
			$destinationRoot = Resolve-ModrinthProfileResourcepackPath
			if ($destinationRoot) {
				break
			}
			continue
		} 1 {
			$destinationRoot = Join-Path $env:APPDATA ".minecraft\resourcepacks"
			break
		} 2 {
			$customPath = Read-Host "Enter the full destination folder path (pack will be copied here)"
			if ([string]::IsNullOrWhiteSpace($customPath)) {
				$destinationRoot = (Get-Location).Path
				Show-Notice -Lines @("No path entered. Using current folder: $destinationRoot")
				break
			}
			$destinationRoot = $customPath.Trim()
			break
		} 3 {
			$cancelled = $true
			break
		}
		default {
			throw "Invalid installer selection '$mainSelection'."
		}
	}
	if ($cancelled -or $destinationRoot) {
		if ($cancelled) {
			break
		}
		$confirmSelection = Show-Menu -Title "Confirm install destination" -Description @("Selected path: $destinationRoot") -Options @(
			"Yes, install here!",
			"No, choose a different path...",
			"Cancel installation."
		)
		switch ($confirmSelection) {
			0 {
				$confirmed = $true
				break
			} 1 {
				$destinationRoot = $null
				continue
			} 2 {
				$cancelled = $true
				break
			} default {
				throw "Invalid confirmation selection '$confirmSelection'."
			}
		}
		if ($cancelled -or $confirmed) {
			break
		}
	}
}
if ($cancelled) {
	Write-Host "Installation cancelled successfully." -ForegroundColor DarkYellow
	return
}
if (-not (Test-Path -Path $destinationRoot)) {
	New-Item -Path $destinationRoot -ItemType Directory -Force | Out-Null
}
$destinationPackPath = Join-Path $destinationRoot (Split-Path $sourcePackPath -Leaf)
if (Test-Path -Path $destinationPackPath) {
	Remove-Item -Path $destinationPackPath -Recurse -Force
}
Copy-Item -Path $sourcePackPath -Destination $destinationRoot -Recurse -Force
Write-Host "Template resource pack successfully installed to: $destinationPackPath" -ForegroundColor Green
