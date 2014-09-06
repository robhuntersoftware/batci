@ECHO OFF

ECHO Welcome to the simple continuous integration system
ECHO ---------------------------------------------------
ECHO.

SETLOCAL

SET errorlevel=

SET PATH=%PATH%;C:\Program Files\Perforce

SET /A polltime = 10

REM CD TO Root
pushd ..

REM TOP OF LOOP
:START

ECHO.
ECHO Checking source control...
ECHO.

REM Check if Perforce is reachable
FOR %%X IN (p4.exe) DO (SET FOUND=%%~$PATH:X)
IF NOT DEFINED FOUND (
  IF NOT EXIST p4.exe (
		ECHO Error: Cannot locate p4.exe, please add to PATH. Terminating CI.
		EXIT /b 1
	) 
)

REM check if changes are available by capturing stderr
FOR /F "delims=" %%i IN ('p4 sync -n 2^>^&1 1^>NUL') DO @SET stderr=%%i
IF  "%stderr%" NEQ "" (
	ECHO "%stderr%"
	GOTO WAIT
)

REM sync CI server with repository
p4 sync
IF errorlevel 1 (
   ECHO Error: p4.exe exited with error code: %errorlevel%. Terminating CI.
   EXIT /b %errorlevel%
)

:BUILD
ECHO.
ECHO Building...

pushd BuildProducts
p4 edit ...
popd

pushd Source
CALL ..\Compiler\Compile.bat
SET COMPILERETURN=%ERRORLEVEL%
popd

IF %COMPILERETURN% NEQ 0 ( 
	ECHO Warning: COMPILE FAILED: error code was %COMPILERETURN% - see build log for details.
	REM TODO: PUT IN EXTERNAL NOTIFIER
)

pushd BuildProducts
FOR /r %%f IN (*) DO p4 add %%f
p4 submit -f revertunchanged -d CI_Checkin ...
popd

GOTO WAIT

:WAIT
REM use ping to work as SLEEP
ECHO.
ECHO Will poll source control again in %polltime% seconds.  Use Ctrl-C to exit.
PING 127.0.0.1 -n %polltime% > nul || PING ::1 -n %polltime% > nul

REM LOOP
GOTO START

:END
popd
