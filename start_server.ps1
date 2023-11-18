# Wrapper PS script to automate firewall checks + world backups

$firewallRuleName = "Satisfactory default inbound ports"
$maybeRule = Get-NetFirewallRule -DisplayName $firewallRuleName 2> $null;
if ($maybeRule) {
	write-host "Firewall rule exists, skipping creation"
} else {
	write-host "Creating firewall rules for ports 15000, 15777, 7777"
	New-NetFirewallRule -DisplayName $firewallRuleName -Direction Inbound -Action Allow -EdgeTraversalPolicy Allow -Protocol UDP -LocalPort 15000,15777,7777
}

.\FactoryServer.exe -multihome=0.0.0.0 -log -unattended

try
{
    While($true)
    {
        Start-Sleep -Seconds (60 * 60 * 3)
        New-Item -ItemType Directory -Path "$PSScriptRoot\saves" -Force
        Copy-Item -Path "$env:LOCALAPPDATA\FactoryGame\Saved\SaveGames\server\*" -Destination "$PSScriptRoot\saves" -Recurse
        git add *
        git commit -m "Automatic backup $((Get-Date).ToString())"
        git push
    }
}

finally
{
    taskkill /im FactoryServer* /F
    taskkill /im UnrealServer-Win64-Shipping* /F
    git add *
    git commit -m "Stopping Save $((Get-Date).ToString())"
    git push
}
