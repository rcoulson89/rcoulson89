# Ignore SSL Certificate Errors
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Script Details
Write-Output "This script will install your bot on the Cisco DevNet Mantl Sandbox"
Write-Output ""
Write-Output "The details on the Sandbox can be found at:"
Write-Output "    https://devnetsandbox.cisco.com/"
Write-Output "You can access the Sandbox at:"
Write-Output "    https://mantlsandbox.cisco.com"
Write-Output "    user/pass: admin/1vtG@lw@y"
Write-Output ""

# Mantl Info
$control_address = "mantlsandbox.cisco.com"
$mantl_user = "admin"
$mantl_password = ConvertTo-SecureString "1vtG@lw@y" -AsPlainText -Force
$mantl_domain = "app.mantldevnetsandbox.com"
$mantl_credential = New-Object System.Management.Automation.PSCredential ($mantl_user, $mantl_password)


# Retrieving User Information
$docker_username = Read-Host -Prompt "What is your Docker Username?"
Write-Output ""
$docker_repo = Read-Host -Prompt "What is the your Docker Repository for your Bot?"
Write-Output ""
$bot_name = Read-Host -Prompt "What is the name of your bot? (Letters and numbers only)"
Write-Output ""
$bot_email = Read-Host -Prompt "What is the email address of your bot?"
Write-Output ""
$bot_token = Read-Host -Prompt "What is the token for your bot?"
Write-Output ""
Write-Output "Docker Location:"
Write-Output "https://hub.docker.com/r/$docker_username/$bot_name/"

$ANSWER = Read-Host -Prompt "Is this correct?  yes/no"
if ($ANSWER -ne "yes"){
	Write-Output "Exiting without installing bot"
	exit
}

# Configure JSON File
Copy-Item -Path "sample_marathon_app_def.json" -Destination "$docker_username-$bot_name-sandbox.json"
(Get-Content -Path "$docker_username-$bot_name-sandbox.json") -replace "DOCKERUSER", "$docker_username" | Set-Content -Path "$docker_username-$bot_name-sandbox.json"
(Get-Content -Path "$docker_username-$bot_name-sandbox.json") -replace "DOCKERREPO", "$docker_repo" | Set-Content -Path "$docker_username-$bot_name-sandbox.json"
(Get-Content -Path "$docker_username-$bot_name-sandbox.json") -replace "USERNAME", "$docker_username" | Set-Content -Path "$docker_username-$bot_name-sandbox.json"
(Get-Content -Path "$docker_username-$bot_name-sandbox.json") -replace "BOTNAME", "$bot_name" | Set-Content -Path "$docker_username-$bot_name-sandbox.json"
(Get-Content -Path "$docker_username-$bot_name-sandbox.json") -replace "APPDOMAIN", "$mantl_domain" | Set-Content -Path "$docker_username-$bot_name-sandbox.json"

if ($TAG -ne $null){
	(Get-Content -Path "$docker_username-$bot_name-sandbox.json") -replace "latest", "$TAG" | Set-Content -Path "$docker_username-$bot_name-sandbox.json"
}

# Install BOT to Mantl
Write-Output ""
Write-Output "***************************************************"
Write-Output "Installing the Bot as  $docker_username/$bot_name"
Invoke-RestMethod -Method Post -Uri "https://$control_address`:8080/v2/apps" -ContentType "application/json" -InFile "$docker_username-$bot_name-sandbox.json" -Credential $mantl_credential

Write-Output "***************************************************"
Write-Output ""
Write-Output "Bot Installed"
Write-Output ""


# Validate BOT
$BOT_URL="http://$docker_username-$bot_name.$mantl_domain"

Do {
	Write-Output "Checking if Bot is up. This should take 2-3 minutes."
	Start-Sleep -Seconds 30
	$HEALTH_CHECK = (Invoke-WebRequest -Method Get -Uri "$BOT_URL/health").statuscode
} While ($HEALTH_CHECK -ne 200)
Write-Output ""

Write-Output "Bot is up.  Configuring Spark."
Write-Output "Bot Configuration: "
Invoke-RestMethod -Method Post -Uri "$BOT_URL/config" -Body "{`"SPARK_BOT_TOKEN`": `"$bot_token`", `"SPARK_BOT_EMAIL`": `"$bot_email`"}"
Write-Output ""
Write-Output ""

Write-Output "Your bot is deployed to:"
Write-Output "http://$docker_username-$bot_name.$mantl_domain/"
Write-Output ""
Write-Output "You should be able to send a message to yourself from the bot by using this call:"
Write-Output "Invoke-WebRequest http://$docker_username-$bot_name.$mantl_domain/hello/<YOUR EMAIL ADDRESS>"
Write-Output ""
Write-Output "You can also watch the progress from the GUI at:"
Write-Output "https://$control_address/marathon"
Write-Output ""