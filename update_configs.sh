#!/bin/bash
# update_configs.sh

curl -o configs.json https://seninpanel.com/api/get_configs.php

if [ ! -f configs.json ]; then
  echo "Configs indirilemedi!"
  exit 1
fi

PACKAGE=$(jq -r '.package_name' configs.json)
APP_NAME=$(jq -r '.app_name' configs.json)
ICON_URL=$(jq -r '.icon_url' configs.json)
BANNER_ID=$(jq -r '.ad_banner_id' configs.json)
INTER_ID=$(jq -r '.ad_inter_id' configs.json)
AD_COUNT=$(jq -r '.ad_count' configs.json)

# Manifest güncelle
sed -i "s/package=\"[^\"]*\"/package=\"$PACKAGE\"/" app/src/main/AndroidManifest.xml
sed -i "s/android:label=\"[^\"]*\"/android:label=\"$APP_NAME\"/" app/src/main/AndroidManifest.xml

# Icon indir
wget -O app/src/main/res/drawable/ic_launcher.png "$ICON_URL" 2>/dev/null || echo "Icon indirilemedi"

# Config sınıfı oluştur (reklam vs. için)
cat << EOF > app/src/main/kotlin/com/santra/tv/player/AppConfig.kt
package com.santra.tv.player

object AppConfig {
    const val ADMOB_BANNER_ID = "$BANNER_ID"
    const val ADMOB_INTER_ID = "$INTER_ID"
    const val TRANSITION_AD_EVERY = $AD_COUNT  // her X geçişte reklam
}
EOF

echo "Configs uygulandı."
