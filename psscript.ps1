param (
    [string]$VMLinuxPrivateIP
)

# Creating InstallDir
$Downloaddir = "C:\InstallDir"
if ((Test-Path -Path $Downloaddir) -ne $true) {
    mkdir $Downloaddir
}

Start-Transcript ($Downloaddir+".\InstallPSScript.log")

function Log($Message){
    Write-Output (([System.DateTime]::Now).ToString() + " " + $Message)
}

Log("##########################")
Log("# Adding Host Entry")
Log("##########################")
Write-Output "$VMLinuxPrivateIP       contoso.com" >> C:\Windows\system32\drivers\etc\hosts
Write-Output "$VMLinuxPrivateIP       www.contoso.com" >> C:\Windows\system32\drivers\etc\hosts
Get-Content C:\Windows\system32\drivers\etc\hosts

Log("##########################")
Log("# Downloading Source Code Apps")
Log("##########################")
Invoke-WebRequest -Uri https://github.com/Welasco/labtest/raw/master/oss-labs.zip -OutFile ($Downloaddir+"\oss-labs.zip")
#Add-Type -AssemblyName System.IO.Compression.FileSystem
# function Unzip
# {
#     param([string]$zipfile, [string]$outpath)
#     [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
# }
# Unzip ($Downloaddir+"\oss-labs.zip") $Downloaddir
Log("Extracting source Code Files")
Expand-Archive -Path ($Downloaddir+"\oss-labs.zip") -DestinationPath $Downloaddir
Log("Cleaning...")
Remove-Item ($Downloaddir+"\oss-labs\VMTemplate") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\StaticDesign") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-lab\.gitignores")  -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\README.md") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\.vscode") -Recurse -Confirm:$False

Log("##########################")
Log("# Installing VSCode")
Log("##########################")
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#$url = "https://aka.ms/win32-x64-user-stable"
#$url = "https://vscode-update.azurewebsites.net/latest/win32-x64-user/stable"
#$url = "https://go.microsoft.com/fwlink/?Linkid=852157"
$url = "https://vscode-update.azurewebsites.net/latest/win32-x64/stable"

Log("Downloading VSCode from $url to VSCodeSetup.exe")
Invoke-WebRequest -Uri $url -OutFile ($Downloaddir+"\VSCodeSetup.exe")
Log("Installing VSCode Using the command: $Downloaddir\VSCodeSetup.exe /verysilent /suppressmsgboxes /mergetasks=!runcode")
(Start-Process ($Downloaddir+"\VSCodeSetup.exe") '/verysilent /suppressmsgboxes /mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath' -Wait -Passthru).ExitCode
Log("Installing VSCode Extensions")
code --install-extension ms-vscode.powershell -force
code --install-extension ms-azuretools.vscode-docker -force
code --install-extension ms-vscode.csharp -force
code --install-extension ms-python.python -force
code --install-extension vscode-icons-team.vscode-icons -force
code --install-extension visualstudioexptteam.vscodeintellicode -force
code --install-extension vscjava.vscode-maven -force
code --install-extension vscjava.vscode-spring-boot-dashboard -force
code --install-extension pivotal.vscode-spring-boot -force
code --install-extension vscjava.vscode-spring-initializr -force
code --install-extension vscjava.vscode-java-debug -force

Log("##########################")
Log("# Setting Windows Features")
Log("##########################")
Log("Disable IE ESC")
function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
}

Disable-InternetExplorerESC

Log("Windows Firewall Allow Ping")
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow