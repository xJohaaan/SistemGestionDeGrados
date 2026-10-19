@echo off
rem ==========================================================================
rem  Ejecuta las pruebas automatizadas del sistema (JUnit 5, sin Maven).
rem  Requisitos: JDK en el PATH, MySQL con la base gestion_grados y, para las
rem  pruebas de flujo HTTP, Tomcat iniciado (si no lo está, esas se omiten).
rem  Uso: doble clic o "test\ejecutar_pruebas.bat" desde la raíz del proyecto.
rem ==========================================================================
cd /d "%~dp0\.."
set JUNIT=test\lib\junit-platform-console-standalone-1.10.2.jar
set CP=WEB-INF\classes;WEB-INF\lib\mysql-connector-j-8.0.33.jar;C:\xampp\tomcat\lib\servlet-api.jar;%JUNIT%

if exist test\out rmdir /s /q test\out
javac -encoding UTF-8 -d test\out -cp "%CP%" test\src\co\edu\uts\grados\pruebas\*.java
if errorlevel 1 (
    echo Error al compilar las pruebas.
    exit /b 1
)
java -Dapp.raiz=. -Dfile.encoding=UTF-8 -jar %JUNIT% execute -cp "test\out;%CP%" --scan-classpath test\out --details=tree --disable-banner
