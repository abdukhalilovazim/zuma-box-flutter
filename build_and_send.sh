#!/bin/bash
TOKEN="8170225103:AAGl4djpH7BATdqD1-Tjb4oFch5ysCtf-Pc"
CHAT_ID="950348637"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

echo "APK yig'ilmoqda (build)..."
flutter build apk --release

if [ -f "$APK_PATH" ]; then
    echo "APK muvaffaqiyatli yig'ildi. Telegram'ga yuborilmoqda..."
    curl -F chat_id="$CHAT_ID" -F caption="zuma-box-flutter" -F document=@"$APK_PATH" "https://api.telegram.org/bot$TOKEN/sendDocument"
    echo -e "\nJo'natildi!"
else
    echo "Xatolik: APK topilmadi ($APK_PATH)"
fi
