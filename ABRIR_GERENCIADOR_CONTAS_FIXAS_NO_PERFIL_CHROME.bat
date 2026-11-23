@echo off
setlocal

set "HTML=%~dp0gerenciador-contas-fixas.html"
set "PS=%~dp0INICIAR_ORGANIZADOR_PERFIL_CHROME.ps1"

if not exist "%PS%" (
  echo ERRO: arquivo INICIAR_ORGANIZADOR_PERFIL_CHROME.ps1 nao encontrado.
  pause
  exit /b 1
)

if not exist "%HTML%" (
  echo ERRO: arquivo gerenciador-contas-fixas.html nao encontrado:
  echo "%HTML%"
  pause
  exit /b 1
)

if /I "%~1"=="/ESCOLHER" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS%" -HtmlPath "%HTML%" -AppName "Gerenciador de Contas Fixas" -ChooseProfile
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS%" -HtmlPath "%HTML%" -AppName "Gerenciador de Contas Fixas"
)

endlocal
