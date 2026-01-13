#!/bin/bash
# build.sh

./update_configs.sh

chmod +x gradlew
./gradlew clean assembleRelease

echo "APK: app/build/outputs/apk/release/app-release.apk"
