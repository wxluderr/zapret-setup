@echo off
if "%~1"=="max" goto :init
start /max "" "%~f0" max
exit /b

:init
setlocal EnableDelayedExpansion
chcp 65001 >nul
color 0a

echo ==========================================================================================
echo    ███████╗ █████╗ ██████╗ ██████╗ ███████╗████████╗
echo    ╚══███╔╝██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
echo      ███╔╝ ███████║██████╔╝██████╔╝█████╗     ██║   
echo     ███╔╝  ██╔══██║██╔═══╝ ██╔══██╗██╔══╝     ██║   
echo    ███████╗██║  ██║██║     ██║  ██║███████╗   ██║   
echo    ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   
echo               [ ПОЛНОСТЬЮ АВТОМАТИЧЕСКИЙ ОДНОКНОПОЧНЫЙ УСТАНОВЩИК ]
echo ==========================================================================================
echo.

echo [*] Проверка привилегий...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [+] Права Администратора получены.
) else (
    echo [-] Ошибка: Требуются права Администратора.
    echo [*] Запрашиваю повышение прав...
    powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList 'max' -Verb RunAs"
    exit /b
)
echo.

set "INSTALL_DIR=%ProgramFiles%\zapret"
echo =================================== [ УСТАНОВКА ЗАПРЕТА ] ===================================
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo [*] Подключение к GitHub для поиска самой свежей версии...
set "PS_DL_CMD=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $r = Invoke-RestMethod -Uri 'https://api.github.com/repos/Flowseal/zapret-discord-youtube/releases/latest'; foreach($a in $r.assets){ if($a.name -match '\.zip$'){ Write-Host '[+] Найдена версия:' $a.name; Invoke-WebRequest -Uri $a.browser_download_url -OutFile '%INSTALL_DIR%\latest.zip'; break; } }"

powershell -Command "%PS_DL_CMD%"

if not exist "%INSTALL_DIR%\latest.zip" (
    echo [-] Ошибка: Не удалось скачать архив. Проверьте интернет или доступ к GitHub.
    pause
    exit /b
)

echo [*] Распаковка загруженного архива...
powershell -command "Expand-Archive -Path '%INSTALL_DIR%\latest.zip' -DestinationPath '%INSTALL_DIR%\temp_extract' -Force"

if exist "%INSTALL_DIR%\temp_extract\bin\" (
    xcopy /E /Y "%INSTALL_DIR%\temp_extract\*" "%INSTALL_DIR%\" >nul
) else (
    for /d %%D in ("%INSTALL_DIR%\temp_extract\*") do (
        xcopy /E /Y "%%D\*" "%INSTALL_DIR%\" >nul
    )
)

rmdir /S /Q "%INSTALL_DIR%\temp_extract"
del /Q "%INSTALL_DIR%\latest.zip"

echo [+] Программа успешно установлена в папку: %INSTALL_DIR%
echo ==========================================================================================
echo.

cd /d "%INSTALL_DIR%"

echo [*] Применение конфигурации...
if not exist "utils" mkdir utils
echo all> "utils\game_filter.enabled"
echo [+] Game Filter: включен режим [all]
echo ENABLED> "utils\check_updates.enabled"
echo [+] Auto-Update Check: включен режим [ENABLED]
echo.

echo [*] Обновление системного файла hosts...
set "HOSTS_PATH=%windir%\System32\drivers\etc\hosts"
copy /Y "%HOSTS_PATH%" "%HOSTS_PATH%.bak" >nul

curl -sL -o "utils\temp_hosts.txt" "https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/main/.service/hosts"
if exist "utils\temp_hosts.txt" (
    copy /Y "utils\temp_hosts.txt" "%HOSTS_PATH%" >nul
    echo [+] Файл hosts успешно обновлен. Оригинальный бэкап сохранен.
    del "utils\temp_hosts.txt"
) else (
    echo [-] Ошибка обновления hosts. Проверьте подключение к сети.
)
echo.

echo ==========================================================================================
echo [+] ВСЕ ПОДГОТОВИТЕЛЬНЫЕ ЭТАПЫ УСПЕШНО ВЫПОЛНЕНЫ.
echo.
echo [*] ПОСЛЕ НАЖАТИЯ ЛЮБОЙ КЛАВИШИ:
echo     1. Этот установщик автоматически закроется.
echo     2. В новом окне запустится файл "service.bat" для окончательной настройки службы.
echo.
echo Нажмите любую клавишу для продолжения...
echo ==========================================================================================
pause >nul

if exist "service.bat" (
    :: Запускаем service.bat в новом процессе и НЕ ждем его завершения (чтобы закрыть текущее окно)
    start "" "service.bat"
) else (
    echo [-] ОШИБКА: Файл service.bat не найден в папке %INSTALL_DIR%
    pause
)

exit
