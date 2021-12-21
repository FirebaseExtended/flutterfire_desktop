@ECHO OFF

@REM Configuration options:
SET STORAGE_EMULATOR_DEBUG=true
SET EMULATOR_COMMAND="firebase emulators:start --only auth,functions --project react-native-firebase-testing"
SET /A MAX_RETRIES=3
SET /A MAX_CHECKATTEMPTS=60
SET /A CHECKATTEMPTS_WAIT=1

@REM Check firebase cli is installed:
WHERE /q firebase
IF ERRORLEVEL 1 (
  ECHO Firebase tools CLI is missing.
  EXIT /B 1
)

@REM Check Node.js is installed:
WHERE /q node
IF ERRORLEVEL 1 (
  ECHO Node.js is missing.
  EXIT /B 1
)

@REM Check NPM is installed:
WHERE /q npm
IF ERRORLEVEL 1 (
  ECHO NPM is missing.
  EXIT /B 1
)

@REM Run NPM Install if not already installed:
if NOT EXIST functions\node_modules\ (
  CMD /C "cd functions && npm i"
)

SET /A RETRIES=1
SET /A CHECKATTEMPTS=1

GOTO :start

:is_emulator_online
  curl --silent --fail http://localhost:8080 > NUL && (
    ECHO Firebase Emulator Suite is online!
    EXIT /B 0
  ) 
  ECHO Waiting for Firebase Emulator Suite to come online, check %CHECKATTEMPTS% of %MAX_CHECKATTEMPTS%...
  SET /A CHECKATTEMPTS+=1
  GOTO :while_awaiting_startup

:while_awaiting_startup
  IF %CHECKATTEMPTS% LSS %MAX_CHECKATTEMPTS% (
    TIMEOUT /t %CHECKATTEMPTS_WAIT% /nobreak > NUL
    GOTO :is_emulator_online
  )
  ECHO Firebase Emulator Suite did not come online in %MAX_CHECKATTEMPTS% checks. Try %RETRIES% of %MAX_RETRIES%.
  SET /A RETRIES+=1
  GOTO :run_for_ci

:run_for_ci
  ECHO Starting Firebase Emulator Suite in background.
  IF %RETRIES% LSS %MAX_RETRIES% (
    START /B CMD /K %EMULATOR_COMMAND%
    SET /A CHECKATTEMPTS=1
    GOTO :while_awaiting_startup
  )
  ECHO Firebase Emulator Suite did not come online after %MAX_RETRIES% attempts.
  EXIT /B 1

:start
  IF DEFINED CI (
    GOTO :run_for_ci
  ) ELSE (
    ECHO Starting Firebase Emulator Suite in foreground.
    CMD /K %EMULATOR_COMMAND%
  )


