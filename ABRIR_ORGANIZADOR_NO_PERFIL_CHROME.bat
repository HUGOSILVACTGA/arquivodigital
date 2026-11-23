@echo off
setlocal

set "HTML=%~dp0ORGANIZADOR_DE_PDFS_V6_0_CENTRAL_INTELIGENTE_PENDENCIAS_V52.html"
set "PS=%~dp0INICIAR_ORGANIZADOR_PERFIL_CHROME.ps1"

if not exist "%PS%" (
  echo ERRO: arquivo INICIAR_ORGANIZADOR_PERFIL_CHROME.ps1 nao encontrado.
  pause
  exit /b 1
)

if not exist "%HTML%" (
  echo ERRO: arquivo principal do Arquivo Digital nao encontrado:
  echo "%HTML%"
  pause
  exit /b 1
)

if /I "%~1"=="/ESCOLHER" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS%" -HtmlPath "%HTML%" -AppName "Arquivo Digital" -ChooseProfile
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS%" -HtmlPath "%HTML%" -AppName "Arquivo Digital"
)

endlocal
