@echo off
cd /d "%~dp0"
git add -A
git commit -m "Initial commit: FreeFight Godot 4.6 demo"
if errorlevel 1 exit /b 1
git remote remove origin 2>nul
git remote add origin https://github.com/yolk-l/free-fight.git
git push -u origin main
exit /b %ERRORLEVEL%
