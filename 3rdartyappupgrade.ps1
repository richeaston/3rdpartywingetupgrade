#########################################
# Script name: update 3rd party apps
# Usage: either a PR or baseline intune/sccm
# author: Richard Easton
# Desription: parse Winget upgrade output to a powershell friendly array
#########################################


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
clear-host    
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$exclusions = get-content "$dir\exclusions.txt"
$Upgraderesult = (winget upgrade) -split ('[\r\n]')
$results = @()
$upgraderesult | foreach-object {
    if (!($_ -like '*   -\| *' -or $_ -like '   -\ *' -or $_ -like '   - *' -or $_ -like '*upgrades available' -OR $_ -like '-*' )) {
        if ($_.Startswith("Name")) {
            $id = $_.indexof("Id")
            $Ver = $_.indexof("Version")
            $Avail = $_.indexof("Available")
            $source = $_.indexof("Source")
        } else {
            $item = [PSCustomObject]@{
                Name = $_.Substring(0, $id).TrimEnd()
                ID = $_.Substring($id,($ver - $id)).TrimEnd()
                Version = $_.Substring($ver,($Avail - $ver)).TrimEnd()
                Available = $_.Substring($avail,($source - $avail)).TrimEnd()
                Source = $_.Substring($source,($_.length - $source)).TrimEnd()
            }
            $results += $Item
        }
    }
}

clear-host
$ToUpgrade = @()
                    
foreach ($app in $results) {
    if ($exclusions -contains $app.id) { 
        Write-warning "$($app.name) in exclusions list"
    } else {
        Write-host "$($app.name) New version $($app.Available) Available"
        $ToUpgrade += $app
        Winget upgrade $($app.id) --silent --accept-package-agreements --accept-source-agreements --force --verbose-logs --purge
    }
}

$ToUpgrade | sort-object Name | FT -AutoSize

