@ECHO OFF

SETLOCAL

REM Enable echoing for build log analysis
MD ..\BuildProducts\Win64
@ECHO ON
copy ..\Source\Source1.txt+..\Source\Source2.txt ..\BuildProducts\Win64\Executable.Win64.txt
@SET COPYRETURN=%ERRORLEVEL%
@ECHO OFF
exit /b %COPYRETURN%