@echo off
rem Musubi Tuner GUI - update the workspace and the cloned repositories, then start the GUI.
rem
rem Usage: update.bat [--skip-trainer] [--no-start]
rem   --skip-trainer   do not update musubi-tuner or its environment
rem   --no-start       do not run start.bat when the update finishes
rem
rem Fast-forwards this workspace repository, musubi-tuner-gui-backend,
rem musubi-tuner-gui-frontend and musubi-tuner (git fetch, then merge --ff-only; local
rem changes are never discarded - it stops instead), updates the trainer's packages, then
rem runs install.bat --rebuild-frontend. Close the GUI first. Requires git and Node 20.19+.
rem The trainer is only updated when musubi-tuner\.venv exists; install.bat sets it up.
chcp 65001 >nul
setlocal EnableExtensions

for %%I in ("%~dp0.") do set "ROOT=%%~fI"
for %%I in ("%ROOT%\musubi-tuner-gui-backend") do set "B=%%~fI"
set "SELF=%~f0"
set "TRAINER_PY=%ROOT%\musubi-tuner\.venv\Scripts\python.exe"

set "SKIP_TRAINER="
set "TRAINER_MISSING="
set "NO_START="

:parse
if "%~1"=="" goto :parsed
if /i "%~1"=="--skip-trainer" set "SKIP_TRAINER=1" & shift & goto :parse
if /i "%~1"=="--no-start" set "NO_START=1" & shift & goto :parse
echo ERROR: unknown option "%~1". See the usage at the top of this file.
exit /b 1

:parsed
echo Workspace root: %ROOT%
echo Close the GUI first: a running server or training job locks files the update replaces.

rem --- preflight: nothing is changed until these pass --------------------
where git >nul 2>nul
if errorlevel 1 goto :fail_git
where node >nul 2>nul
if errorlevel 1 goto :fail_node
node -e "const [a,b]=process.versions.node.split('.').map(Number);process.exit(a>20||(a===20&&b>=19)?0:1)"
if errorlevel 1 goto :fail_node
if not exist "%B%\.venv\Scripts\python.exe" goto :fail_not_installed
if defined SKIP_TRAINER goto :trainer_decided
if not exist "%TRAINER_PY%" set "SKIP_TRAINER=1" & set "TRAINER_MISSING=1"
:trainer_decided

rem --- 1. workspace repository -------------------------------------------
if defined MUSUBI_UPDATE_RERUN goto :root_done
echo.
echo [1/4] Updating the workspace repository...
if not exist "%ROOT%\.git" goto :root_not_git
git -C "%ROOT%" rev-parse --abbrev-ref --symbolic-full-name "@{u}" >nul 2>nul
if errorlevel 1 goto :root_no_upstream
git -C "%ROOT%" fetch
if errorlevel 1 goto :fail_fetch_root
git -C "%ROOT%" merge-base --is-ancestor "@{u}" HEAD
if not errorlevel 1 goto :root_up_to_date
rem Merging can replace this file while it runs, and cmd reads a batch file as it runs
rem it, so merge and re-run the new update.bat inside one block, which cmd reads in full
rem before running it. Keep the block free of labels and comments. Inside it, exit /b
rem must be the last command that runs (cmd reports exit code 0 for the whole run when
rem more commands follow it in the block), so failures leave by goto.
rem The re-run skips this step through MUSUBI_UPDATE_RERUN; keep that name.
rem SELF is set before the option loop because shift also drops the script name.
(
  git -C "%ROOT%" merge --ff-only "@{u}"
  if errorlevel 1 goto :root_merge_failed
  set "MUSUBI_UPDATE_RERUN=1"
  call "%SELF%" %*
  if errorlevel 1 (exit /b 1) else if errorlevel 0 (exit /b 0) else exit /b 1
)
:root_merge_failed
echo ERROR: the workspace repository could not be fast-forwarded. Commit, stash or discard the local changes or commits in the way, then run update.bat again.
exit /b 1
:root_not_git
echo Not a git checkout; skipped.
goto :root_done
:root_no_upstream
echo WARNING: the workspace repository does not track a remote branch; it was not updated.
goto :root_done
:root_up_to_date
echo Already up to date.
:root_done

rem --- 2. backend and web UI source --------------------------------------
echo.
echo [2/4] Updating the backend and the web UI source...
call :update_repo "%B%" "musubi-tuner-gui-backend"
if errorlevel 1 goto :fail
call :update_repo "%ROOT%\musubi-tuner-gui-frontend" "musubi-tuner-gui-frontend"
if errorlevel 1 goto :fail

rem --- 3. trainer --------------------------------------------------------
echo.
echo [3/4] Trainer (musubi-tuner)...
if defined TRAINER_MISSING goto :trainer_missing
if defined SKIP_TRAINER goto :trainer_skipped
call :update_repo "%ROOT%\musubi-tuner" "musubi-tuner"
if errorlevel 1 goto :fail
where uv >nul 2>nul
if errorlevel 1 set "PATH=%USERPROFILE%\.local\bin;%PATH%"
where uv >nul 2>nul
if errorlevel 1 goto :fail_uv
call uv pip install --python "%TRAINER_PY%" -e "%ROOT%\musubi-tuner"
if errorlevel 1 goto :fail
goto :after_trainer
:trainer_missing
echo Not installed, so not updated; run install.bat to set it up.
goto :after_trainer
:trainer_skipped
echo Skipped (--skip-trainer).
:after_trainer

rem --- 4. sync the environment and rebuild the web UI --------------------
echo.
echo [4/4] Syncing the backend and rebuilding the web UI with install.bat...
set "INSTALL_ARGS=--rebuild-frontend"
if defined SKIP_TRAINER set "INSTALL_ARGS=%INSTALL_ARGS% --skip-trainer"
if defined NO_START set "INSTALL_ARGS=%INSTALL_ARGS% --no-start"
call "%ROOT%\install.bat" %INSTALL_ARGS%
exit /b %ERRORLEVEL%

:update_repo
rem Arguments: the repository folder, then the name shown in messages
echo Updating %~2...
if not exist "%~1" goto :repo_missing
if not exist "%~1\.git" goto :repo_not_git
git -C "%~1" rev-parse --abbrev-ref --symbolic-full-name "@{u}" >nul 2>nul
if errorlevel 1 goto :repo_no_upstream
git -C "%~1" fetch
if errorlevel 1 goto :repo_fetch_failed
git -C "%~1" merge --ff-only "@{u}"
if errorlevel 1 goto :repo_merge_failed
exit /b 0

:repo_missing
echo %~2 was not found; install.bat clones it.
exit /b 0

:repo_not_git
echo WARNING: %~2 is not a git checkout; it was not updated.
exit /b 0

:repo_no_upstream
echo WARNING: %~2 does not track a remote branch, for example a detached HEAD; it was not updated.
exit /b 0

:repo_fetch_failed
echo ERROR: could not fetch %~2; check the network connection.
exit /b 1

:repo_merge_failed
echo ERROR: %~2 could not be fast-forwarded. Commit, stash or discard the local changes or commits in the way, then run update.bat again.
exit /b 1

:fail_git
echo ERROR: git is required. Install it from https://git-scm.com/download/win and run update.bat again.
goto :fail

:fail_node
echo ERROR: Node.js 20.19 or newer is required to rebuild the web UI. Install it from https://nodejs.org/ and run update.bat again.
goto :fail

:fail_not_installed
echo ERROR: the GUI is not installed yet; run install.bat first.
exit /b 1

:fail_uv
echo ERROR: uv was not found; run install.bat once, then update.bat.
goto :fail

:fail_fetch_root
echo ERROR: could not fetch the workspace repository; check the network connection.
goto :fail

:fail
echo.
echo ERROR: the update failed; see the messages above. Repositories already updated stay updated; fix the problem and run update.bat again.
exit /b 1
