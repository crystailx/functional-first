: << 'CMDBLOCK'
@echo off
REM Cross-platform polyglot wrapper for the SessionStart hook script.
REM Pattern adapted from the superpowers plugin's hooks/run-hook.cmd (MIT licence).
REM On Windows: cmd.exe runs the batch portion, which finds and calls bash.
REM On Unix: the shell interprets this as a script (: is a no-op in bash).
REM
REM The hook script is extensionless ("session-start", not "session-start.sh")
REM so Claude Code's Windows auto-detection -- which prepends "bash" to any
REM command containing .sh -- does not interfere.
REM
REM Usage: run-hook.cmd session-start

if "%~1"=="" (
    echo run-hook.cmd: missing script name >&2
    exit /b 1
)

set "HOOK_DIR=%~dp0"

REM Try Git for Windows bash in standard locations
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%HOOK_DIR%%~1"
    exit /b %ERRORLEVEL%
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" "%HOOK_DIR%%~1"
    exit /b %ERRORLEVEL%
)

REM Try bash on PATH (e.g. user-installed Git Bash, MSYS2, Cygwin)
where bash >nul 2>nul
if %ERRORLEVEL% equ 0 (
    bash "%HOOK_DIR%%~1"
    exit /b %ERRORLEVEL%
)

REM No bash found. Tell the user on stderr instead of failing silently: the
REM principles block will not reach context, and that should be visible.
echo functional-first: bash not found; the SessionStart principles block was not loaded. Install Git for Windows to enable it. >&2
exit /b 0
CMDBLOCK

# Unix: run the named script directly
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "${SCRIPT_DIR}/$1"
