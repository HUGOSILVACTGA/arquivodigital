param(
    [string]$HtmlPath,
    [switch]$ChooseProfile,
    [string]$AppName = "Arquivo Digital"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"
$windowTitle = "$AppName - Inicializador"

$chrome = Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
    $chrome = Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe"
}
if (-not (Test-Path $chrome)) {
    $chrome = Join-Path $env:LOCALAPPDATA "Google\Chrome\Application\chrome.exe"
}
if (-not (Test-Path $chrome)) {
    [System.Windows.Forms.MessageBox]::Show("Google Chrome nao foi encontrado neste computador.", $windowTitle) | Out-Null
    exit 1
}

if ([string]::IsNullOrWhiteSpace($HtmlPath) -or -not (Test-Path -LiteralPath $HtmlPath)) {
    $message = "Nao encontrei o arquivo HTML:" + [Environment]::NewLine + $HtmlPath + [Environment]::NewLine + [Environment]::NewLine + "Confira se o arquivo HTML esta na mesma pasta do inicializador."
    [System.Windows.Forms.MessageBox]::Show($message, $windowTitle) | Out-Null
    exit 1
}

$userData = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data"
$localState = Join-Path $userData "Local State"
if (-not (Test-Path $localState)) {
    [System.Windows.Forms.MessageBox]::Show("Nao encontrei os perfis habituais do Chrome neste usuario do Windows.", $windowTitle) | Out-Null
    exit 1
}

try {
    $state = Get-Content -LiteralPath $localState -Raw | ConvertFrom-Json
    $cache = $state.profile.info_cache
    $profiles = @()
    foreach ($prop in $cache.PSObject.Properties) {
        $dir = $prop.Name
        $display = [string]$prop.Value.name
        if ([string]::IsNullOrWhiteSpace($display)) { $display = $dir }
        $profiles += [pscustomobject]@{ Directory = $dir; Name = $display }
    }
    if ($profiles.Count -eq 0) { throw "Nenhum perfil foi encontrado." }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Nao foi possivel ler os perfis do Chrome: $($_.Exception.Message)", $windowTitle) | Out-Null
    exit 1
}

# Mantem o arquivo de preferencia existente para preservar o perfil ja escolhido.
# Os dois inicializadores compartilham esta configuracao.
$configPath = Join-Path $PSScriptRoot "perfil_chrome_organizador.txt"
$selected = $null
if ((-not $ChooseProfile) -and (Test-Path $configPath)) {
    $saved = (Get-Content -LiteralPath $configPath -Raw).Trim()
    $selected = $profiles | Where-Object { $_.Directory -eq $saved } | Select-Object -First 1
}

if ($null -eq $selected) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Escolher perfil do Chrome - $AppName"
    $form.Size = New-Object System.Drawing.Size(480, 205)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Selecione o perfil do Chrome que sera utilizado pelo sistema:"
    $label.AutoSize = $false
    $label.Location = New-Object System.Drawing.Point(18, 18)
    $label.Size = New-Object System.Drawing.Size(430, 38)
    $form.Controls.Add($label)

    $combo = New-Object System.Windows.Forms.ComboBox
    $combo.DropDownStyle = "DropDownList"
    $combo.Location = New-Object System.Drawing.Point(18, 65)
    $combo.Size = New-Object System.Drawing.Size(430, 30)
    foreach ($p in $profiles) {
        [void]$combo.Items.Add(("{0}  ({1})" -f $p.Name, $p.Directory))
    }
    $form.Controls.Add($combo)

    $savedDir = ""
    if (Test-Path $configPath) { $savedDir = (Get-Content $configPath -Raw).Trim() }
    $savedIndex = -1
    for ($i = 0; $i -lt $profiles.Count; $i++) {
        if ($profiles[$i].Directory -eq $savedDir) { $savedIndex = $i; break }
    }
    if ($savedIndex -ge 0) { $combo.SelectedIndex = $savedIndex } else { $combo.SelectedIndex = 0 }

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "Usar este perfil"
    $ok.Location = New-Object System.Drawing.Point(265, 112)
    $ok.Size = New-Object System.Drawing.Size(183, 32)
    $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($ok)
    $form.AcceptButton = $ok

    if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
    $selected = $profiles[$combo.SelectedIndex]
    Set-Content -LiteralPath $configPath -Value $selected.Directory -Encoding ASCII
}

# Abre o HTML em uma nova janela e envia F11 ao Chrome.
# O envio da tecla reproduz o atalho real do navegador, sem depender de
# --start-fullscreen ou --start-maximized.
$uri = ([System.Uri]::new((Resolve-Path -LiteralPath $HtmlPath).Path)).AbsoluteUri
$profileArgument = '--profile-directory="{0}"' -f $selected.Directory
$uriArgument = '"{0}"' -f $uri

Start-Process -FilePath $chrome -ArgumentList @(
    $profileArgument,
    "--new-window",
    $uriArgument
)

# Aguarda a nova janela assumir o foco antes de enviar F11.
Start-Sleep -Seconds 3
try {
    $shell = New-Object -ComObject WScript.Shell
    [void]$shell.AppActivate("Google Chrome")
    Start-Sleep -Milliseconds 500
    $shell.SendKeys("{F11}")
} catch {
    [System.Windows.Forms.MessageBox]::Show(
        "O sistema foi aberto, mas nao foi possivel ativar a tela cheia automaticamente. Clique na janela do Chrome e pressione F11.",
        $windowTitle
    ) | Out-Null
}
