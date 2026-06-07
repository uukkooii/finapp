#!/bin/bash
# 一键构建+部署 APK
set -e
cd /opt/finapp
echo "🔨 构建中..."
flutter build apk --debug
echo "📦 部署到 Docker nginx..."
docker cp build/app/outputs/flutter-apk/app-debug.apk nginx-proxy:/usr/share/nginx/html/app.apk
echo "✅ 完成 — http://118.24.77.3/app.apk"
MD5=$(md5sum build/app/outputs/flutter-apk/app-debug.apk | cut -d' ' -f1)
echo "MD5: $MD5"
