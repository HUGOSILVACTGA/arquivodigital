@echo off
setlocal
set "HTML=%~dp0ORGANIZADOR_DE_PDFS_V6_0.html"
set "PS=%~dp0INICIAR_ORGANIZADOR_PERFIL_CHROME.ps1"

if not exist "%PS%" (
  echo ERRO: arquivo INICIAR_ORGANIZADOR_PERFIL_CHROME.ps1 nao encontrado.
  pause
  exit /b 1
)

if /I "%~1"=="/ESCOLHER" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS%" -HtmlPath "%HTML%" -ChooseProfile
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS%" -HtmlPath "%HTML%"
)
endlocal
