@echo off
chcp 65001 > nul

echo ====================================================
echo НАСТРОЙКА КОНФИГУРАЦИИ СЕРВЕРА И ДЕПЛОЯ
echo ====================================================

rem --- БЛОК НАСТРОЕК (ПЕРЕМЕННЫЕ) ---
set SSH_ALIAS=nemtsev
set SSH_PORT=8022
set BASE_HREF=/filmnya/

rem Пути на Linux-сервере
set SERVER_WWW_DIR=/var/www/html/filmnya
set SERVER_HOME_DIR=/home/nemtsev
set SERVER_BACKUP_ROOT=/home/nemtsev/backup/filmnya
rem ----------------------------------

rem 1. Получаем текущую дату и время для штампа версии и бэкапа
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'"`) do set BACKUP_DIR=%%i

set SERVER_BACKUP_PATH=%SERVER_BACKUP_ROOT%/%BACKUP_DIR%

echo.
echo [1/7] Автоматическое обновление номера версии в коде Flutter...
rem Генерируем красивую строку версии на основе штампа времени
set NEW_VERSION="v1.2.0 (Build: %BACKUP_DIR%)"
powershell -NoProfile -Command "(Get-Content lib\screens\configuration_screen.dart) -replace 'const String appVersion = .*;', 'const String appVersion = ''%NEW_VERSION%'';' | Set-Content lib\screens\configuration_screen.dart"

echo.
echo [2/7] Запуск сборки приложения для подпапки %BASE_HREF%...
call flutter build web --release --base-href "%BASE_HREF%"
if %errorlevel% neq 0 (
    echo ОШИБКА: Сборка Flutter завершилась неудачно.
    pause
    exit /b %errorlevel%
)

echo.
echo [3/7] Внедрение штампа времени в загрузчик index.html и упаковка в web.zip...
powershell -NoProfile -Command "(Get-Content build\web\index.html) -replace 'flutter_bootstrap.js', 'flutter_bootstrap.js?v=%BACKUP_DIR%' | Set-Content build\web\index.html"

if exist web.zip del /q web.zip
powershell -NoProfile -Command "Compress-Archive -Path 'build\web\*' -DestinationPath 'web.zip' -Force"
if %errorlevel% neq 0 (
    echo ОШИБКА: Не удалось создать ZIP-архив.
    pause
    exit /b %errorlevel%
)

echo.
echo [4/7] Создание резервной копии старой версии на сервере...
echo Папка бэкапа: %SERVER_BACKUP_PATH%/
ssh -p %SSH_PORT% %SSH_ALIAS% "mkdir -p %SERVER_BACKUP_PATH% && if [ -d %SERVER_WWW_DIR% ] && [ \"\$(ls -A %SERVER_WWW_DIR%)\" ]; then cp -r %SERVER_WWW_DIR%/. %SERVER_BACKUP_PATH%/; fi"

echo.
echo [5/7] Копирование архива web.zip на сервер через SCP...
scp -P %SSH_PORT% web.zip %SSH_ALIAS%:%SERVER_HOME_DIR%/

echo.
echo [6/7] Распаковка архива на сервере...
ssh -p %SSH_PORT% %SSH_ALIAS% "unzip -o -q %SERVER_HOME_DIR%/web.zip -d %SERVER_WWW_DIR%/"

echo.
echo [7/7] Удаление временных файлов...
ssh -p %SSH_PORT% %SSH_ALIAS% "rm -f %SERVER_HOME_DIR%/web.zip"
del /q web.zip

if %errorlevel% equ 0 (
    echo.
    echo ====================================================
    echo УСПЕШНО! Рецепт сборки %NEW_VERSION% развернут!
    echo Откройте: https://nemtsev.ru%BASE_HREF%
    echo ====================================================
) else (
    echo.
    echo ОШИБКА во время деплоя.
    pause
)
