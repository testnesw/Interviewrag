@echo off
REM ===============================================================
REM  Double-click this file to open the Interview Playbook.
REM  It starts a tiny local server (needed so the browser can
REM  load the topic files) and opens the reader in your browser.
REM ===============================================================

cd /d "%~dp0"

REM Open the reader in the default browser
start "" "http://localhost:8080/deep-dives/index.html"

REM Start the server rooted at THIS folder (so ../topics/ resolves).
REM Try the Windows 'py' launcher first, then fall back to 'python'.
py -m http.server 8080 2>nul || python -m http.server 8080
