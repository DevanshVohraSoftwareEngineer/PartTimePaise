@echo off
echo ========================================
echo  SHA256 Fingerprint Generator for Android
echo ========================================
echo.

echo Getting SHA256 fingerprint for DEBUG keystore:
echo ------------------------------------------------
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr "SHA256"

echo.
echo.
echo For RELEASE keystore, run:
echo keytool -list -v -keystore "path\to\your\keystore.jks" -alias your_alias
echo.
echo Then update android/app/src/main/res/raw/assetlinks.json
echo with the SHA256 fingerprint (without colons)
echo.
pause