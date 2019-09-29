param (
    [string]$VMLinuxPrivateIP
)

# Creating InstallDir
$Downloaddir = "C:\InstallDir"
if ((Test-Path -Path $Downloaddir) -ne $true) {
    mkdir $Downloaddir
}
cd $Downloaddir

Start-Transcript ($Downloaddir+".\InstallPSScript.log")

function Log($Message){
    Write-Output (([System.DateTime]::Now).ToString() + " " + $Message)
}

function Add-SystemPaths([array] $PathsToAdd) {
    $VerifiedPathsToAdd = ""
    foreach ($Path in $PathsToAdd) {
        if ($Env:Path -like "*$Path*") {
            Log("  Path to $Path already added")
        }
        else {
            $VerifiedPathsToAdd += ";$Path";Log("  Path to $Path needs to be added")
        }
    }
    if ($VerifiedPathsToAdd -ne "") {
        Log("Adding paths: $VerifiedPathsToAdd")
        [System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + "$VerifiedPathsToAdd","Machine")
        Log("Note: Reloading Path env to the current script")
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Log("##########################")
Log("# Adding Host Entry")
Log("##########################")
Add-Content C:\Windows\system32\drivers\etc\hosts ""
Add-Content C:\Windows\system32\drivers\etc\hosts "$VMLinuxPrivateIP       contoso.com"
Add-Content C:\Windows\system32\drivers\etc\hosts "$VMLinuxPrivateIP       www.contoso.com"
Get-Content C:\Windows\system32\drivers\etc\hosts

Log("##########################")
Log("# Downloading Source Code Apps")
Log("##########################")
Invoke-WebRequest -Uri https://github.com/Welasco/labtest/raw/master/oss-labs.zip -OutFile ($Downloaddir+"\oss-labs.zip")
Log("Extracting source Code Files")
Expand-Archive -Path ($Downloaddir+"\oss-labs.zip") -DestinationPath $Downloaddir
Log("Cleaning...")
Remove-Item ($Downloaddir+"\oss-labs\VMTemplate") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\StaticDesign") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\.gitignore") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\README.md") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\.vscode") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\.git") -Recurse -Confirm:$False
Move-Item ($Downloaddir+"\oss-labs") ($Downloaddir+"\apps")

Log("##########################")
Log("# Installing VSCode")
Log("##########################")
#$url = "https://aka.ms/win32-x64-user-stable"
#$url = "https://vscode-update.azurewebsites.net/latest/win32-x64-user/stable"
#$url = "https://go.microsoft.com/fwlink/?Linkid=852157"
$url = "https://vscode-update.azurewebsites.net/latest/win32-x64/stable"

Log("Downloading VSCode from $url to VSCodeSetup.exe")
Invoke-WebRequest -Uri $url -OutFile ($Downloaddir+"\VSCodeSetup.exe")
Unblock-File ($Downloaddir+"\VSCodeSetup.exe")
Log("Installing VSCode Using the command: $Downloaddir\VSCodeSetup.exe /verysilent /suppressmsgboxes /mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath")
$VSCodeInstallResult = (Start-Process ($Downloaddir+"\VSCodeSetup.exe") '/verysilent /suppressmsgboxes /mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath' -Wait -Passthru).ExitCode
if ($VSCodeInstallResult -eq 0) {
    Log("Install VSCode Success")
}
Log("Installing VSCode Extensions")
$VSCodeInstallPath = "C:\Program Files\Microsoft VS Code\bin"
cd $VSCodeInstallPath
.\code --install-extension ms-vscode.powershell -force
.\code --install-extension ms-azuretools.vscode-docker -force
.\code --install-extension ms-vscode.csharp -force
.\code --install-extension ms-python.python -force
.\code --install-extension vscode-icons-team.vscode-icons -force
.\code --install-extension visualstudioexptteam.vscodeintellicode -force
.\code --install-extension vscjava.vscode-maven -force
.\code --install-extension vscjava.vscode-spring-boot-dashboard -force
.\code --install-extension pivotal.vscode-spring-boot -force
.\code --install-extension vscjava.vscode-spring-initializr -force
.\code --install-extension vscjava.vscode-java-debug -force
cd $Downloaddir

Log("##########################")
Log("# Installing Google Chrome")
Log("##########################")
Invoke-WebRequest 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile ($Downloaddir+"\chrome_installer.exe")
Unblock-File ($Downloaddir+"\chrome_installer.exe")
$ChromeInstallResult = (Start-Process ($Downloaddir+"\chrome_installer.exe") '/silent /install' -Wait -Passthru).ExitCode
if ($ChromeInstallResult -eq 0) {
    Log("Install Chrome Success")
}

Log("##########################")
Log("# Installing NodeJS")
Log("##########################")
Invoke-WebRequest 'https://nodejs.org/dist/v10.16.3/node-v10.16.3-x64.msi' -OutFile ($Downloaddir+"\node-v10.16.3-x64.msi")
Unblock-File ($Downloaddir+"\node-v10.16.3-x64.msi")
$NodeJSInstallResult = (Start-Process "msiexec.exe" '/i node-v10.16.3-x64.msi /qn' -Wait -Passthru).ExitCode
if ($NodeJSInstallResult -eq 0) {
    Log("Install Python Success")
}
Add-SystemPaths "C:\Program Files\nodejs"

Log("##########################")
Log("# Installing Python")
Log("##########################")
Invoke-WebRequest 'https://www.python.org/ftp/python/3.7.4/python-3.7.4-amd64.exe' -OutFile ($Downloaddir+"\python-3.7.4-amd64.exe")
Unblock-File ($Downloaddir+"\python-3.7.4-amd64.exe")
$PythonInstallResult = (Start-Process ($Downloaddir+"\python-3.7.4-amd64.exe") '/quiet InstallAllUsers=1 PrependPath=1 Include_test=0' -Wait -Passthru).ExitCode
if ($PythonInstallResult -eq 0) {
    Log("Install Python Success")
}
Add-SystemPaths "C:\Program Files\Python37"
Add-SystemPaths "C:\Program Files\Python37\Scripts"

Log("##########################")
Log("# Installing Java JRE")
Log("##########################")
Invoke-WebRequest https://github.com/Welasco/labtest/raw/master/jre-8u221-windows-x64.exe -OutFile ($Downloaddir+"\jre-8u221-windows-x64.exe")
Unblock-File ($Downloaddir+"\jre-8u221-windows-x64.exe")
$JavaInstallResult = (Start-Process ($Downloaddir+"\jre-8u221-windows-x64.exe") '/s' -Wait -Passthru).ExitCode
if ($JavaInstallResult -eq 0) {
    Log("Install Java JRE Success")
}
Add-SystemPaths "C:\Program Files\Java\jre1.8.0_221\bin"


Log("##########################")
Log("# Preparing Code")
Log("##########################")
cd $Downloaddir
Log("Reloading System Path for current session")
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Log("Preparing NodeJS App (npm install)")
cd $Downloaddir\apps\NodeJSApp
npm install

Log("Preparing Python App (pip install)")
cd $Downloaddir\apps\PythonApp
pip install -r requirements.txt

Log("Preparing Java App")

Log("##########################")
Log("# Loading App Services")
Log("##########################")
Log("Download nssm and unblock the file")
cd $Downloaddir
Invoke-WebRequest -Uri https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip -OutFile ($Downloaddir+"\nssm-2.24-101-g897c7ad.zip")
Expand-Archive -Path ($Downloaddir+"\nssm-2.24-101-g897c7ad.zip") -DestinationPath $Downloaddir
Copy-Item ($Downloaddir+"\nssm-2.24-101-g897c7ad\win64\nssm.exe") $Downloaddir
Unblock-File ($Downloaddir+"\nssm.exe")

Log("Adding NodeJSApp Service")
.\nssm.exe install NodeJSApp 'C:\Program Files\nodejs\node.exe' C:\InstallDir\apps\NodeJSApp\bin\www
.\nssm.exe set NodeJSApp AppDirectory C:\InstallDir\apps\NodeJSApp
Start-Service NodeJSApp

Log("Adding PythonApp Service")
.\nssm.exe install PythonApp 'C:\Program Files\Python37\python.exe' C:\InstallDir\apps\PythonApp\app.py
.\nssm.exe set PythonApp AppDirectory C:\InstallDir\apps\PythonApp
Start-Service PythonApp

Log("Adding JavaApp Service")
.\nssm.exe install JavaApp 'C:\Program Files\Java\jre1.8.0_221\bin\java.exe' -jar C:\InstallDir\apps\JavaApp\javaapp.jar
.\nssm.exe set JavaApp AppDirectory C:\InstallDir\apps\JavaApp
Start-Service JavaApp

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