@echo off
REM Automated test runner for YouTube scraper with FFmpeg integration
REM Usage: run-tests.bat [unit|integration|all|cleanup]

setlocal

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running
    exit /b 1
)

REM Default to "all" if no argument provided
set COMMAND=%1
if "%COMMAND%"=="" set COMMAND=all

echo.
echo ============================================
echo YouTube Scraper Test Runner
echo ============================================
echo.

if "%COMMAND%"=="unit" goto unit
if "%COMMAND%"=="integration" goto integration
if "%COMMAND%"=="all" goto all
if "%COMMAND%"=="coverage" goto coverage
if "%COMMAND%"=="cleanup" goto cleanup
if "%COMMAND%"=="logs" goto logs
if "%COMMAND%"=="help" goto help
goto unknown

:unit
echo [INFO] Running Unit Tests...
docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit youtube-test-unit
echo [SUCCESS] Unit tests completed
goto end

:integration
echo [INFO] Running Integration Tests...
echo [INFO] Starting services (FFmpeg + MinIO)...
docker-compose -f docker-compose.test.yml up -d minio-test ffmpeg-service-test

echo [INFO] Waiting for services to be healthy...
timeout /t 10 /nobreak >nul

echo [INFO] Running integration tests...
docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit youtube-test-integration
echo [SUCCESS] Integration tests completed
goto end

:all
echo [INFO] Running All Tests (Unit + Integration)...
docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit youtube-test-all
echo [SUCCESS] All tests completed
goto end

:coverage
echo [INFO] Opening coverage report...
if exist youtube\htmlcov\index.html (
    start youtube\htmlcov\index.html
) else (
    echo [ERROR] No coverage report found. Run tests with coverage first.
)
goto end

:cleanup
echo [INFO] Cleaning up...
docker-compose -f docker-compose.test.yml down -v --remove-orphans
echo [SUCCESS] Cleanup completed
goto end

:logs
if "%2"=="" (
    echo [ERROR] Please specify a service name
    echo Usage: run-tests.bat logs [service-name]
    exit /b 1
)
echo [INFO] Showing logs for %2...
docker-compose -f docker-compose.test.yml logs --tail=50 %2
goto end

:help
echo Usage: run-tests.bat [command]
echo.
echo Commands:
echo   unit          Run only unit tests
echo   integration   Run only integration tests
echo   all           Run all tests (default)
echo   coverage      Open coverage report
echo   cleanup       Stop services and remove volumes
echo   logs [service] Show logs for a service
echo   help          Show this help message
echo.
echo Examples:
echo   run-tests.bat unit
echo   run-tests.bat integration
echo   run-tests.bat logs ffmpeg-service-test
echo   run-tests.bat cleanup
goto end

:unknown
echo [ERROR] Unknown command: %COMMAND%
echo Use 'run-tests.bat help' for usage information
exit /b 1

:end
echo.
echo Done! 🎉
endlocal
