@echo off

SET commit_message="autoCommit %date:~-4%%date:~3,2%%date:~0,2%.%time:~0,2%%time:~3,2%%time:~6,2%"

:uniqueLoop
SET tempdir="%temp%\obsidian_%random%"
IF EXIST "%tempdir%" GOTO :uniqueLoop

:: check if there is an existing worktree indicating script exited prematurely
FOR /f %%i IN ('call git worktree list') DO SET wstatus=%%i
SET "wstatus=%wstatus:/=\%"
IF NOT "%wstatus%\"=="%~dp0" (
  git worktree remove --force %wstatus%
  GOTO :updatemdlinks
)

:: check if files have changed or a push is pending, if not do nothing
FOR /f %%i IN ('call git status --porcelain') DO SET gstatus=%%i
FOR /f %%i IN ('call git rev-list --count origin/master..master') DO SET pstatus=%%i
IF [%gstatus%] == [] (
  IF %pstatus% == 0 (
    EXIT /b
  )
)

git add .
:: commit changes from the master wikilink-ed branch
git commit -m %commit_message%

:: integrate any updates from the master branch
git pull origin master --rebase
git push origin master


:updatemdlinks
:: create a temporary copy of mdlinks in which to convert updated files' wikilinks to markdown
git worktree add %tempdir% mdlinks
CD %tempdir%
IF %errorlevel% NEQ 0 EXIT /b %errorlevel%

:: integrate any updates from the markdown-linked branch
git pull origin mdlinks --rebase

:: clean up files that were deleted (including renamed) on master
FOR /f "delims=" %%F IN ('call git diff --name-only --no-renames --diff-filter=D master~1 master') DO (
  DEL "%%~fD"
  git add "%%D"
)

:: copy new files from master branch
FOR /f "delims=" %%F IN ('call git diff --name-only --no-renames --diff-filter=A mdlinks master') DO (
  :: do not copy these files
  IF NOT "%%F" == "auto_convertcommit.bat" IF NOT "%%F" == "convert_to_gitlab.py" (
    git checkout master "%%F"
  )
)

:: convert links of updated markdown files in tempdir
FOR /f "delims=" %%F IN ('call git diff --name-only master~1 master') DO (
  python %~dp0\convert_to_gitlab.py "%%F"
  git add "%%F"
)

:: also convert links in files linking to renamed or new files
FOR /f "delims=" %%F IN ('call git diff --name-only --diff-filter=AR master~1 master') DO (
  FOR /f "delims=:, tokens=2" %%L IN ('call git grep -El "\[\[%%~nF((\||#).*)?\]\]" master') DO (
    python %~dp0\convert_to_gitlab.py "%%L"
    git add "%%L"
  )
)

:: commit changes and push converted files to mdlinks branch
git commit -m %commit_message%
git push origin mdlinks

:: remove temporary worktree
CD %~dp0
git worktree remove %tempdir%
