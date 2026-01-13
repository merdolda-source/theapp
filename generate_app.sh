#!/bin/bash
set -e

echo "=============================================="
echo " ERDİNXTREAM - FULL REPO ROOT GENERATOR (v1)"
echo " Unity Inter ACTIVE (opening) + AdMob Banner"
echo " Xtream: Live + Movies + Series + Episodes"
echo " Package: com.erdin.xtream"
echo "=============================================="

# ----------------------------------------------------
# 0) SABİT AYARLAR (REPO ROOT'TA app/ MODÜLÜ)
# ----------------------------------------------------
APP_NAME="ERDİNXTREAM"
PACKAGE_NAME="com.erdin.xtream"

VERSION_CODE=1
VERSION_NAME="1.0"

# Reklam stratejisi:
# - Unity: Interstitial aktif (açılış + tıklama arası istersen)
# - AdMob: sadece Banner aktif (test banner)
AD_MODE="unity_open_admob_banner"

PROJECT_ROOT="."
MODULE_DIR="$PROJECT_ROOT/app"
RES_DIR="$MODULE_DIR/src/main/res"
JAVA_DIR="$MODULE_DIR/src/main/java"
PKG_PATH="${PACKAGE_NAME//./\/}"

# Unity IDs (senin verdiğin)
UNITY_GAME_ID="5497808"
UNITY_INTER_ID="Interstitial_Android"
UNITY_REWARD_ID="Rewarded_Android"

# AdMob Test IDs (banner aktif)
ADMOB_APP_ID="ca-app-pub-3940256099942544~3347511713"
ADMOB_BANNER_ID="ca-app-pub-3940256099942544/6300978111"
ADMOB_INTER_ID="ca-app-pub-3940256099942544/1033173712"
ADMOB_REWARD_ID="ca-app-pub-3940256099942544/5224354917"

echo "APP_NAME      = $APP_NAME"
echo "PACKAGE_NAME  = $PACKAGE_NAME"
echo "VERSION       = $VERSION_NAME ($VERSION_CODE)"
echo "MODULE_DIR    = $MODULE_DIR"
echo "PKG_PATH      = $PKG_PATH"
echo "UNITY_GAME_ID = $UNITY_GAME_ID"

# ----------------------------------------------------
# 1) KLASÖRLER
# ----------------------------------------------------
mkdir -p "$JAVA_DIR/$PKG_PATH/model"
mkdir -p "$JAVA_DIR/$PKG_PATH/adapter"
mkdir -p "$JAVA_DIR/$PKG_PATH/api"
mkdir -p "$JAVA_DIR/$PKG_PATH/utils"
mkdir -p "$JAVA_DIR/$PKG_PATH/ui"

mkdir -p "$RES_DIR"/{layout,values,drawable,mipmap-xxxhdpi}

# ----------------------------------------------------
# 2) KEYSTORE (varsa dokunma)
# ----------------------------------------------------
if [ ! -f "$MODULE_DIR/release.keystore" ]; then
  echo "🔐 Keystore üretiliyor..."
  keytool -genkey -v \
    -keystore "$MODULE_DIR/release.keystore" \
    -alias erdinxtream \
    -keyalg RSA -keysize 2048 \
    -validity 10000 \
    -storepass 123456 \
    -keypass 123456 \
    -dname "CN=Erdin, O=ErdinXTREAM, C=TR" \
    2>/dev/null || true
else
  echo "🔐 Keystore var, geçiliyor."
fi

# ----------------------------------------------------
# 3) ICON (fallback garantili)
# ----------------------------------------------------
echo "🎨 Launcher icon hazırlanıyor..."
ICON_TARGET="$RES_DIR/mipmap-xxxhdpi/ic_launcher.png"
TEMP_ICON="icon_temp.png"
ICON_URL="https://i.hizliresim.com/aunp77o.png"

create_fallback_icon() {
  echo "🧩 Yedek ikon üretiliyor (1x1 PNG)..."
  cat > /tmp/icon_base64.txt <<'B64EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/6XWuk0AAAAASUVORK5CYII=
B64EOF
  base64 -d /tmp/icon_base64.txt > "$ICON_TARGET" 2>/dev/null || \
  base64 --decode /tmp/icon_base64.txt > "$ICON_TARGET" 2>/dev/null || true
  rm -f /tmp/icon_base64.txt
}

curl -s -L -k -A "Mozilla/5.0" -o "$TEMP_ICON" "$ICON_URL" || true
if [ -s "$TEMP_ICON" ]; then
  if command -v convert >/dev/null 2>&1; then
    convert "$TEMP_ICON" -resize 512x512! -background none -flatten "$ICON_TARGET" || create_fallback_icon
  else
    cp "$TEMP_ICON" "$ICON_TARGET" || create_fallback_icon
  fi
else
  create_fallback_icon
fi
rm -f "$TEMP_ICON"

# ----------------------------------------------------
# 4) ROOT GRADLE (yoksa oluştur / varsa overwrite edebilirsin)
# ----------------------------------------------------
cat > "$PROJECT_ROOT/settings.gradle" <<'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
rootProject.name = "ERDINXTREAM"
include(":app")
EOF

cat > "$PROJECT_ROOT/build.gradle" <<'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.1.1"
    }
}
EOF

cat > "$PROJECT_ROOT/gradle.properties" <<'EOF'
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx4096m
EOF

# ----------------------------------------------------
# 5) APP build.gradle (Unity + AdMob Banner)
# ----------------------------------------------------
cat > "$MODULE_DIR/build.gradle" <<EOF
plugins {
    id 'com.android.application'
}

android {
    namespace '$PACKAGE_NAME'
    compileSdk 34

    defaultConfig {
        applicationId '$PACKAGE_NAME'
        minSdk 21
        targetSdk 34
        versionCode $VERSION_CODE
        versionName '$VERSION_NAME'
        multiDexEnabled true
    }

    buildFeatures {
        buildConfig true
    }

    signingConfigs {
        release {
            storeFile file("release.keystore")
            storePassword "123456"
            keyAlias "erdinxtream"
            keyPassword "123456"
        }
    }

    buildTypes {
        release {
            minifyEnabled false
            signingConfig signingConfigs.release
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'

            buildConfigField "String", "AD_MODE", "\"$AD_MODE\""
            buildConfigField "String", "ADMOB_APP_ID", "\"$ADMOB_APP_ID\""
            buildConfigField "String", "ADMOB_BANNER_ID", "\"$ADMOB_BANNER_ID\""
            buildConfigField "String", "UNITY_GAME_ID", "\"$UNITY_GAME_ID\""
            buildConfigField "String", "UNITY_INTER_ID", "\"$UNITY_INTER_ID\""
            buildConfigField "String", "UNITY_REWARD_ID", "\"$UNITY_REWARD_ID\""
        }

        debug {
            minifyEnabled false
            signingConfig signingConfigs.release

            buildConfigField "String", "AD_MODE", "\"$AD_MODE\""
            buildConfigField "String", "ADMOB_APP_ID", "\"$ADMOB_APP_ID\""
            buildConfigField "String", "ADMOB_BANNER_ID", "\"$ADMOB_BANNER_ID\""
            buildConfigField "String", "UNITY_GAME_ID", "\"$UNITY_GAME_ID\""
            buildConfigField "String", "UNITY_INTER_ID", "\"$UNITY_INTER_ID\""
            buildConfigField "String", "UNITY_REWARD_ID", "\"$UNITY_REWARD_ID\""
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.1'

    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.19.1'

    implementation 'com.github.bumptech.glide:glide:4.16.0'

    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'

    // ✅ AdMob (SADECE BANNER KULLANACAĞIZ)
    implementation 'com.google.android.gms:play-services-ads:23.1.0'

    // ✅ Unity Ads (Interstitial + Rewarded)
    implementation 'com.unity3d.ads:unity-ads:4.16.2'
}
EOF

cat > "$MODULE_DIR/proguard-rules.pro" <<EOF
-keep class $PACKAGE_NAME.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn com.google.gson.**
-dontwarn okhttp3.**
EOF

# ----------------------------------------------------
# 6) RES: colors/styles/drawables
# ----------------------------------------------------
cat > "$RES_DIR/values/colors.xml" <<'EOF'
<resources>
    <color name="bg_dark">#050A08</color>
    <color name="accent">#00C853</color>
    <color name="glass_bg">#1AFFFFFF</color>
    <color name="glass_stroke">#33FFFFFF</color>
    <color name="text_primary">#FFFFFF</color>
    <color name="text_secondary">#B0B0B0</color>
    <color name="black_overlay">#CC000000</color>
</resources>
EOF

cat > "$RES_DIR/values/styles.xml" <<'EOF'
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.NoActionBar">
        <item name="android:windowBackground">@color/bg_dark</item>
        <item name="colorPrimary">@color/accent</item>
        <item name="colorPrimaryVariant">@color/accent</item>
        <item name="colorAccent">@color/accent</item>
        <item name="android:statusBarColor">@color/bg_dark</item>
        <item name="android:navigationBarColor">@color/bg_dark</item>
    </style>

    <style name="GlassCard">
        <item name="android:background">@drawable/bg_glass</item>
        <item name="android:padding">16dp</item>
    </style>

    <style name="NeonButton" parent="Widget.MaterialComponents.Button">
        <item name="backgroundTint">@null</item>
        <item name="android:background">@drawable/bg_neon_btn</item>
        <item name="android:textColor">#FFFFFF</item>
        <item name="android:textAllCaps">true</item>
        <item name="android:textStyle">bold</item>
    </style>

    <style name="GlassInput">
        <item name="android:background">@drawable/bg_glass_input</item>
        <item name="android:textColor">#FFFFFF</item>
        <item name="android:textColorHint">#888888</item>
        <item name="android:padding">16dp</item>
    </style>
</resources>
EOF

cat > "$RES_DIR/drawable/bg_glass.xml" <<'EOF'
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="@color/glass_bg" />
    <corners android:radius="16dp" />
    <stroke android:width="1dp" android:color="@color/glass_stroke" />
</shape>
EOF

cat > "$RES_DIR/drawable/bg_glass_input.xml" <<'EOF'
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#0DFFFFFF" />
    <corners android:radius="12dp" />
    <stroke android:width="1dp" android:color="#22FFFFFF" />
</shape>
EOF

cat > "$RES_DIR/drawable/bg_neon_btn.xml" <<'EOF'
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <gradient android:startColor="#00C853" android:endColor="#1B5E20" android:angle="45" />
    <corners android:radius="12dp" />
</shape>
EOF

cat > "$RES_DIR/drawable/ic_play.xml" <<'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF" android:pathData="M8,5v14l11,-7z"/>
</vector>
EOF

cat > "$RES_DIR/drawable/ic_delete.xml" <<'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FF3D00"
        android:pathData="M6,19c0,1.1 0.9,2 2,2h8c1.1,0 2,-0.9 2,-2V7H6v12zM19,4h-3.5l-1,-1h-5l-1,1H5v2h14V4z"/>
</vector>
EOF

cat > "$RES_DIR/drawable/ic_zoom.xml" <<'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF"
        android:pathData="M15,3l2.3,2.3 -2.89,2.87 1.42,1.42L18.7,6.7 21,9V3zM3,9l2.3,-2.3 2.87,2.89 1.42,-1.42L6.7,5.3 9,3H3zM9,21l-2.3,-2.3 2.89,-2.87 -1.42,-1.42L5.3,17.3 3,15v6zM21,15l-2.3,2.3 -2.87,-2.89 -1.42,1.42L17.3,18.7 15,21h6z"/>
</vector>
EOF

# ----------------------------------------------------
# 7) LAYOUTS (Banner alanı eklendi)
# ----------------------------------------------------
cat > "$RES_DIR/layout/activity_selection.xml" <<'EOF'
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="@color/bg_dark">

    <TextView
        android:id="@+id/header"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="ERDİNXTREAM"
        android:textColor="@color/text_primary"
        android:textSize="28sp"
        android:textStyle="bold"
        android:layout_centerHorizontal="true"
        android:layout_marginTop="40dp" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvPlaylists"
        android:layout_width="match_parent" android:layout_height="match_parent"
        android:layout_below="@id/header"
        android:layout_above="@+id/btnGroup"
        android:padding="20dp"
        android:clipToPadding="false"/>

    <LinearLayout
        android:id="@+id/btnGroup"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:layout_alignParentBottom="true"
        android:orientation="vertical"
        android:padding="20dp">

        <Button
            android:id="@+id/btnXtream"
            android:layout_width="match_parent" android:layout_height="60dp"
            android:text="ADD XTREAM API"
            style="@style/NeonButton"
            android:layout_marginBottom="12dp"/>

        <Button
            android:id="@+id/btnM3u"
            android:layout_width="match_parent" android:layout_height="60dp"
            android:text="ADD M3U LINK"
            style="@style/GlassInput"
            android:textColor="@color/text_primary"/>
    </LinearLayout>

</RelativeLayout>
EOF

cat > "$RES_DIR/layout/item_playlist.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    style="@style/GlassCard"
    android:layout_marginBottom="12dp"
    android:orientation="horizontal"
    android:gravity="center_vertical">

    <LinearLayout
        android:layout_width="0dp" android:layout_height="wrap_content"
        android:layout_weight="1"
        android:orientation="vertical">

        <TextView
            android:id="@+id/tvPlayName"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:textColor="@color/text_primary"
            android:textSize="18sp"
            android:textStyle="bold"/>

        <TextView
            android:id="@+id/tvPlayInfo"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:layout_marginTop="4dp"
            android:textColor="@color/text_secondary"
            android:textSize="14sp"/>
    </LinearLayout>

    <ImageView
        android:id="@+id/btnDel"
        android:layout_width="32dp" android:layout_height="32dp"
        android:src="@drawable/ic_delete"
        android:padding="4dp"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_dashboard.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:gravity="center"
    android:padding="24dp">

    <TextView
        android:id="@+id/tvUser"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:gravity="center"
        android:textSize="22sp"
        android:textStyle="bold"
        android:layout_marginBottom="22dp"/>

    <LinearLayout
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:weightSum="3"
        android:layout_marginBottom="16dp">

        <LinearLayout
            android:id="@+id/btnLive"
            android:layout_width="0dp" android:layout_height="120dp"
            android:layout_weight="1"
            android:layout_marginRight="8dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical">
            <TextView
                android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="LIVE"
                android:textColor="@color/text_primary"
                android:textSize="18sp"
                android:textStyle="bold"/>
        </LinearLayout>

        <LinearLayout
            android:id="@+id/btnMovies"
            android:layout_width="0dp" android:layout_height="120dp"
            android:layout_weight="1"
            android:layout_marginLeft="8dp"
            android:layout_marginRight="8dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical">
            <TextView
                android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="MOVIES"
                android:textColor="@color/text_primary"
                android:textSize="18sp"
                android:textStyle="bold"/>
        </LinearLayout>

        <LinearLayout
            android:id="@+id/btnSeries"
            android:layout_width="0dp" android:layout_height="120dp"
            android:layout_weight="1"
            android:layout_marginLeft="8dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical">
            <TextView
                android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="SERIES"
                android:textColor="@color/text_primary"
                android:textSize="18sp"
                android:textStyle="bold"/>
        </LinearLayout>

    </LinearLayout>

    <Button
        android:id="@+id/btnLogout"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="SWITCH PLAYLIST"
        style="@style/NeonButton"
        android:paddingLeft="40dp"
        android:paddingRight="40dp"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_login_xtream.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:padding="24dp"
    android:gravity="center">

    <TextView
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="XTREAM LOGIN"
        android:textColor="@color/text_primary"
        android:textSize="24sp"
        android:textStyle="bold"
        android:layout_marginBottom="18dp"/>

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etUser"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Username"
        style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etPass"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Password"
        android:inputType="textPassword"
        style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etDns"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="http://url:port"
        style="@style/GlassInput"
        android:layout_marginBottom="18dp"/>

    <Button
        android:id="@+id/btnLogin"
        android:layout_width="match_parent" android:layout_height="56dp"
        android:text="CONNECT"
        style="@style/NeonButton"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_login_m3u.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:padding="24dp"
    android:gravity="center">

    <TextView
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="M3U LINK"
        android:textColor="@color/text_primary"
        android:textSize="24sp"
        android:textStyle="bold"
        android:layout_marginBottom="18dp"/>

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etUrl"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="http://example.com/playlist.m3u"
        style="@style/GlassInput"
        android:layout_marginBottom="18dp"/>

    <Button
        android:id="@+id/btnSave"
        android:layout_width="match_parent" android:layout_height="56dp"
        android:text="DOWNLOAD &amp; SAVE"
        style="@style/NeonButton"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_list.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:ads="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@color/bg_dark">

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvCats"
        android:layout_width="match_parent"
        android:layout_height="60dp"
        android:padding="8dp"
        android:clipToPadding="false"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvStreams"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:padding="8dp"/>

    <!-- ✅ AdMob Banner (ACTIVE) -->
    <com.google.android.gms.ads.AdView
        android:id="@+id/adView"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        ads:adSize="BANNER"
        ads:adUnitId="@string/admob_banner_id"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/item_channel.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:padding="12dp"
    style="@style/GlassCard"
    android:layout_marginBottom="8dp"
    android:orientation="horizontal"
    android:gravity="center_vertical">

    <ImageView
        android:id="@+id/ivIcon"
        android:layout_width="40dp" android:layout_height="40dp"
        android:src="@drawable/ic_play"/>

    <TextView
        android:id="@+id/tvName"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textSize="16sp"
        android:layout_marginLeft="14dp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/item_category.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="wrap_content" android:layout_height="wrap_content"
    android:padding="10dp"
    android:layout_marginRight="8dp"
    android:gravity="center"
    android:background="@drawable/bg_glass_input">
    <TextView
        android:id="@+id/tvCatName"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textSize="14sp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_player.xml" <<'EOF'
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="#000000">

    <com.google.android.exoplayer2.ui.StyledPlayerView
        android:id="@+id/player_view"
        android:layout_width="match_parent"
        android:layout_height="match_parent"/>

    <ImageButton
        android:id="@+id/btnZoom"
        android:layout_width="50dp"
        android:layout_height="50dp"
        android:src="@drawable/ic_zoom"
        android:background="@drawable/bg_glass"
        android:layout_gravity="top|end"
        android:layout_margin="24dp"
        android:padding="10dp"/>
</FrameLayout>
EOF

cat > "$RES_DIR/layout/activity_series_episodes.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:ads="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@color/bg_dark">

    <TextView
        android:id="@+id/tvTitle"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textStyle="bold"
        android:textSize="18sp"
        android:padding="12dp"
        android:text="Episodes"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvSeasons"
        android:layout_width="match_parent"
        android:layout_height="60dp"
        android:padding="8dp"
        android:clipToPadding="false"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvEpisodes"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:padding="8dp"/>

    <com.google.android.gms.ads.AdView
        android:id="@+id/adView"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        ads:adSize="BANNER"
        ads:adUnitId="@string/admob_banner_id"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/item_episode.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:padding="12dp"
    style="@style/GlassCard"
    android:layout_marginBottom="8dp"
    android:orientation="vertical">

    <TextView
        android:id="@+id/tvEpTitle"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textStyle="bold"
        android:textSize="16sp"
        android:text="Episode"/>

    <TextView
        android:id="@+id/tvEpInfo"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="@color/text_secondary"
        android:textSize="13sp"
        android:layout_marginTop="4dp"
        android:text="Tap to play"/>
</LinearLayout>
EOF

# Strings (AdMob banner id)
cat > "$RES_DIR/values/strings.xml" <<EOF
<resources>
    <string name="app_name">$APP_NAME</string>
    <string name="admob_banner_id">$ADMOB_BANNER_ID</string>
</resources>
EOF

# ----------------------------------------------------
# 8) MODELS
# ----------------------------------------------------
cat > "$JAVA_DIR/$PKG_PATH/model/AppModels.java" <<EOF
package $PACKAGE_NAME.model;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.List;
import java.util.Map;

public class AppModels {

    public static class Playlist implements Serializable {
        public String id, name, type, url, user, pass;
        public String m3uContent;
    }

    public static class LoginResponse implements Serializable {
        @SerializedName("user_info") public UserInfo userInfo;
        @SerializedName("server_info") public ServerInfo serverInfo;
    }

    public static class UserInfo implements Serializable {
        @SerializedName("username") public String username;
        @SerializedName("auth") public int auth;
        @SerializedName("exp_date") public String expDate;
    }

    public static class ServerInfo implements Serializable {
        @SerializedName("url") public String url;
    }

    public static class Category implements Serializable {
        @SerializedName("category_id") public String id;
        @SerializedName("category_name") public String name;
        public Category() {}
        public Category(String id, String name) { this.id = id; this.name = name; }
    }

    public static class StreamItem implements Serializable {
        @SerializedName("name") public String name;
        @SerializedName("stream_id") public String streamId;
        @SerializedName("stream_icon") public String icon;
        @SerializedName("container_extension") public String ext;

        public String directUrl;
        public String group;
        public String ref;
        public String origin;
    }

    // -------- SERIES --------
    public static class SeriesItem implements Serializable {
        @SerializedName("name") public String name;
        @SerializedName("series_id") public String seriesId;
        @SerializedName("cover") public String cover;
        @SerializedName("plot") public String plot;
    }

    public static class SeriesInfoResponse implements Serializable {
        @SerializedName("info") public SeriesInfo info;
        // Xtream çoğu panelde episodes: { "1":[...], "2":[...] }
        @SerializedName("episodes") public Map<String, List<EpisodeItem>> episodes;
    }

    public static class SeriesInfo implements Serializable {
        @SerializedName("name") public String name;
        @SerializedName("cover") public String cover;
        @SerializedName("plot") public String plot;
    }

    public static class EpisodeItem implements Serializable {
        @SerializedName("id") public String id;
        @SerializedName("title") public String title;
        @SerializedName("episode_num") public String episodeNum;
        @SerializedName("container_extension") public String ext;
        @SerializedName("added") public String added;
    }
}
EOF

# ----------------------------------------------------
# 9) API (Xtream)
# ----------------------------------------------------
cat > "$JAVA_DIR/$PKG_PATH/api/XtreamApi.java" <<EOF
package $PACKAGE_NAME.api;

import java.util.List;

import $PACKAGE_NAME.model.AppModels.Category;
import $PACKAGE_NAME.model.AppModels.LoginResponse;
import $PACKAGE_NAME.model.AppModels.SeriesInfoResponse;
import $PACKAGE_NAME.model.AppModels.SeriesItem;
import $PACKAGE_NAME.model.AppModels.StreamItem;

import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Query;
import retrofit2.http.Url;

public interface XtreamApi {

    @GET
    Call<LoginResponse> login(
            @Url String url,
            @Query("username") String u,
            @Query("password") String p
    );

    @GET
    Call<List<Category>> getCategories(
            @Url String url,
            @Query("username") String u,
            @Query("password") String p,
            @Query("action") String a
    );

    @GET
    Call<List<StreamItem>> getStreams(
            @Url String url,
            @Query("username") String u,
            @Query("password") String p,
            @Query("action") String a,
            @Query("category_id") String c
    );

    // ✅ SERIES CATEGORIES
    @GET
    Call<List<Category>> getSeriesCategories(
            @Url String url,
            @Query("username") String u,
            @Query("password") String p,
            @Query("action") String a
    );

    // ✅ SERIES LIST
    @GET
    Call<List<SeriesItem>> getSeries(
            @Url String url,
            @Query("username") String u,
            @Query("password") String p,
            @Query("action") String a,
            @Query("category_id") String c
    );

    // ✅ SERIES INFO + EPISODES
    @GET
    Call<SeriesInfoResponse> getSeriesInfo(
            @Url String url,
            @Query("username") String u,
            @Query("password") String p,
            @Query("action") String a,
            @Query("series_id") String sid
    );
}
EOF

# ----------------------------------------------------
# 10) UTILS: M3UParser + PrefUtils
# ----------------------------------------------------
cat > "$JAVA_DIR/$PKG_PATH/utils/M3UParser.java" <<EOF
package $PACKAGE_NAME.utils;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import $PACKAGE_NAME.model.AppModels.StreamItem;

public class M3UParser {

    public static Map<String, List<StreamItem>> parse(String content) {
        Map<String, List<StreamItem>> map = new LinkedHashMap<>();
        if (content == null) return map;

        String[] lines = content.split("\\n");
        String currentGroup = "Uncategorized";
        StreamItem currentItem = null;

        Pattern pGroup = Pattern.compile("group-title=\\\"([^\\\"]*)\\\"");
        Pattern pLogo  = Pattern.compile("tvg-logo=\\\"([^\\\"]*)\\\"");

        for (String lineRaw : lines) {
            String line = lineRaw.trim();
            if (line.isEmpty()) continue;

            if (line.startsWith("#EXTINF")) {
                currentItem = new StreamItem();

                int comma = line.lastIndexOf(",");
                currentItem.name = (comma > 0 && comma < line.length()-1) ? line.substring(comma+1).trim() : "Unknown";

                Matcher mGroup = pGroup.matcher(line);
                if (mGroup.find()) currentGroup = mGroup.group(1);

                Matcher mLogo = pLogo.matcher(line);
                if (mLogo.find()) currentItem.icon = mLogo.group(1);

                currentItem.group = currentGroup;

            } else if (line.startsWith("#EXTVLCOPT:")) {
                if (currentItem != null) {
                    if (line.startsWith("#EXTVLCOPT:http-referrer=")) {
                        currentItem.ref = line.substring("#EXTVLCOPT:http-referrer=".length()).trim();
                    } else if (line.startsWith("#EXTVLCOPT:http-origin=")) {
                        currentItem.origin = line.substring("#EXTVLCOPT:http-origin=".length()).trim();
                    }
                }
            } else if (!line.startsWith("#")) {
                if (currentItem != null) {
                    currentItem.directUrl = line;
                    if (!map.containsKey(currentGroup)) map.put(currentGroup, new ArrayList<>());
                    map.get(currentGroup).add(currentItem);
                    currentItem = null;
                }
            }
        }
        return map;
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/utils/PrefUtils.java" <<EOF
package $PACKAGE_NAME.utils;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.util.ArrayList;
import java.util.List;

import $PACKAGE_NAME.model.AppModels.Playlist;

public class PrefUtils {

    private static SharedPreferences get(Context c) {
        return c.getSharedPreferences("ERDINXTREAM_V1", 0);
    }

    public static void savePlaylist(Context c, Playlist p) {
        List<Playlist> list = getPlaylists(c);
        List<Playlist> newList = new ArrayList<>();
        for (Playlist pl : list) {
            if (pl.id != null && p.id != null && pl.id.equals(p.id)) continue;
            newList.add(pl);
        }
        newList.add(p);
        get(c).edit()
                .putString("L", new Gson().toJson(newList))
                .putString("A", p.id)
                .apply();
    }

    public static List<Playlist> getPlaylists(Context c) {
        String j = get(c).getString("L", "[]");
        List<Playlist> list = new Gson().fromJson(j, new TypeToken<List<Playlist>>(){}.getType());
        if (list == null) list = new ArrayList<>();
        return list;
    }

    public static Playlist getActive(Context c) {
        String id = get(c).getString("A", "");
        for (Playlist p : getPlaylists(c)) {
            if (p.id != null && p.id.equals(id)) return p;
        }
        return null;
    }

    public static void deletePlaylist(Context c, String id) {
        List<Playlist> list = getPlaylists(c);
        List<Playlist> newList = new ArrayList<>();
        for (Playlist p : list) {
            if (p.id != null && p.id.equals(id)) continue;
            newList.add(p);
        }
        get(c).edit().putString("L", new Gson().toJson(newList)).apply();
    }

    public static void logout(Context c) {
        get(c).edit().remove("A").apply();
    }
}
EOF

# ----------------------------------------------------
# 11) ADS: UnityAdsManager + AdMobBannerManager (BuildConfig import fix)
# ----------------------------------------------------
cat > "$JAVA_DIR/$PKG_PATH/utils/UnityAdsManager.java" <<EOF
package $PACKAGE_NAME.utils;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.unity3d.ads.IUnityAdsInitializationListener;
import com.unity3d.ads.IUnityAdsLoadListener;
import com.unity3d.ads.IUnityAdsShowListener;
import com.unity3d.ads.UnityAds;
import com.unity3d.ads.UnityAdsShowOptions;

import $PACKAGE_NAME.BuildConfig;

public class UnityAdsManager {

    private static final String TAG = "UnityAdsManager";
    private static boolean inited = false;
    private static boolean interLoaded = false;
    private static boolean rewardLoaded = false;

    // Test mode: geliştirmede true. Yayında false yap.
    private static final boolean TEST_MODE = true;

    private static String gameId() { return BuildConfig.UNITY_GAME_ID; }
    private static String interId() { return BuildConfig.UNITY_INTER_ID; }
    private static String rewardId(){ return BuildConfig.UNITY_REWARD_ID; }

    public static void init(Activity a) {
        if (inited) return;

        UnityAds.initialize(a, gameId(), TEST_MODE, new IUnityAdsInitializationListener() {
            @Override public void onInitializationComplete() {
                inited = true;
                Log.d(TAG, "init OK");
                loadInterstitial();
                loadRewarded();
            }

            @Override public void onInitializationFailed(UnityAds.UnityAdsInitializationError error, String msg) {
                Log.e(TAG, "init FAIL: " + error + " / " + msg);
            }
        });
    }

    public static void loadInterstitial() {
        if (!inited) return;
        UnityAds.load(interId(), new IUnityAdsLoadListener() {
            @Override public void onUnityAdsAdLoaded(String placementId) {
                interLoaded = true;
                Log.d(TAG, "inter loaded: " + placementId);
            }

            @Override public void onUnityAdsFailedToLoad(String placementId, UnityAds.UnityAdsLoadError error, String msg) {
                interLoaded = false;
                Log.e(TAG, "inter load FAIL: " + error + " / " + msg);
            }
        });
    }

    public static void loadRewarded() {
        if (!inited) return;
        UnityAds.load(rewardId(), new IUnityAdsLoadListener() {
            @Override public void onUnityAdsAdLoaded(String placementId) {
                rewardLoaded = true;
                Log.d(TAG, "reward loaded: " + placementId);
            }

            @Override public void onUnityAdsFailedToLoad(String placementId, UnityAds.UnityAdsLoadError error, String msg) {
                rewardLoaded = false;
                Log.e(TAG, "reward load FAIL: " + error + " / " + msg);
            }
        });
    }

    // Açılış inter: 1.2sn sonra dene (load şansı artsın)
    public static void showOpenInterstitial(Activity a) {
        init(a);
        new Handler(Looper.getMainLooper()).postDelayed(() -> showInterstitial(a), 1200);
    }

    public static void showInterstitial(Activity a) {
        if (!inited) init(a);
        if (!interLoaded) { loadInterstitial(); return; }

        UnityAds.show(a, interId(), new UnityAdsShowOptions(), new IUnityAdsShowListener() {
            @Override public void onUnityAdsShowStart(String placementId) {}

            @Override public void onUnityAdsShowClick(String placementId) {}

            @Override public void onUnityAdsShowComplete(String placementId, UnityAds.UnityAdsShowCompletionState state) {
                interLoaded = false;
                loadInterstitial();
            }

            @Override public void onUnityAdsShowFailure(String placementId, UnityAds.UnityAdsShowError error, String msg) {
                interLoaded = false;
                loadInterstitial();
            }
        });
    }

    public static void showRewarded(Activity a, Runnable onReward) {
        if (!inited) init(a);
        if (!rewardLoaded) { loadRewarded(); return; }

        UnityAds.show(a, rewardId(), new UnityAdsShowOptions(), new IUnityAdsShowListener() {
            @Override public void onUnityAdsShowStart(String placementId) {}
            @Override public void onUnityAdsShowClick(String placementId) {}

            @Override public void onUnityAdsShowComplete(String placementId, UnityAds.UnityAdsShowCompletionState state) {
                if (state == UnityAds.UnityAdsShowCompletionState.COMPLETED && onReward != null) {
                    onReward.run();
                }
                rewardLoaded = false;
                loadRewarded();
            }

            @Override public void onUnityAdsShowFailure(String placementId, UnityAds.UnityAdsShowError error, String msg) {
                rewardLoaded = false;
                loadRewarded();
            }
        });
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/utils/AdMobBannerManager.java" <<EOF
package $PACKAGE_NAME.utils;

import android.app.Activity;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.MobileAds;

import $PACKAGE_NAME.BuildConfig;

public class AdMobBannerManager {

    private static boolean inited = false;

    public static void init(Activity a) {
        if (inited) return;
        MobileAds.initialize(a, status -> inited = true);
    }

    public static void loadBanner(Activity a, AdView adView) {
        if (adView == null) return;
        init(a);
        // Ad unit xml'den geliyor, sadece load ediyoruz
        AdRequest req = new AdRequest.Builder().build();
        adView.loadAd(req);
    }
}
EOF

# ----------------------------------------------------
# 12) ADAPTERS (Playlist / Category / Stream / Series / Episode)
# ----------------------------------------------------
cat > "$JAVA_DIR/$PKG_PATH/adapter/PlaylistAdapter.java" <<EOF
package $PACKAGE_NAME.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Playlist;

public class PlaylistAdapter extends RecyclerView.Adapter<PlaylistAdapter.VH> {

    public interface OnClick {
        void onClick(Playlist p);
        void onDelete(Playlist p);
    }

    private final List<Playlist> list;
    private final OnClick listener;

    public PlaylistAdapter(List<Playlist> list, OnClick listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_playlist, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        Playlist item = list.get(position);
        h.n.setText(item.name == null ? "Playlist" : item.name);
        h.t.setText(item.type == null ? "" : item.type);

        h.itemView.setOnClickListener(v -> listener.onClick(item));
        h.d.setOnClickListener(v -> listener.onDelete(item));
    }

    @Override public int getItemCount() { return list == null ? 0 : list.size(); }

    static class VH extends RecyclerView.ViewHolder {
        TextView n, t;
        ImageView d;
        VH(@NonNull View v) {
            super(v);
            n = v.findViewById(R.id.tvPlayName);
            t = v.findViewById(R.id.tvPlayInfo);
            d = v.findViewById(R.id.btnDel);
        }
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/adapter/CategoryAdapter.java" <<EOF
package $PACKAGE_NAME.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Category;

public class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.VH> {

    public interface OnClick { void onClick(Category item); }

    private final List<Category> list;
    private final OnClick listener;
    private int selected = 0;

    public CategoryAdapter(List<Category> list, OnClick listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_category, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        Category c = list.get(position);
        h.t.setText(c.name == null ? "" : c.name);
        h.itemView.setAlpha(selected == position ? 1.0f : 0.7f);

        h.itemView.setOnClickListener(v -> {
            int old = selected;
            selected = h.getAdapterPosition();
            notifyItemChanged(old);
            notifyItemChanged(selected);
            listener.onClick(c);
        });
    }

    @Override public int getItemCount() { return list == null ? 0 : list.size(); }

    static class VH extends RecyclerView.ViewHolder {
        TextView t;
        VH(@NonNull View v) {
            super(v);
            t = v.findViewById(R.id.tvCatName);
        }
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/adapter/StreamAdapter.java" <<EOF
package $PACKAGE_NAME.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;

import java.util.List;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.StreamItem;

public class StreamAdapter extends RecyclerView.Adapter<StreamAdapter.VH> {

    public interface OnItemClick { void onClick(StreamItem item); }

    private List<StreamItem> list;
    private final OnItemClick listener;

    public StreamAdapter(List<StreamItem> list, OnItemClick listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_channel, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        StreamItem item = list.get(position);
        h.t.setText(item.name == null ? "" : item.name);

        Glide.with(h.itemView.getContext())
                .load(item.icon)
                .placeholder(R.drawable.ic_play)
                .into(h.i);

        h.itemView.setOnClickListener(v -> listener.onClick(item));
    }

    @Override public int getItemCount() { return list == null ? 0 : list.size(); }

    public void update(List<StreamItem> newList) {
        this.list = newList;
        notifyDataSetChanged();
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView t; ImageView i;
        VH(@NonNull View v) {
            super(v);
            t = v.findViewById(R.id.tvName);
            i = v.findViewById(R.id.ivIcon);
        }
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/adapter/SeriesAdapter.java" <<EOF
package $PACKAGE_NAME.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;

import java.util.List;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.SeriesItem;

public class SeriesAdapter extends RecyclerView.Adapter<SeriesAdapter.VH> {

    public interface OnClick { void onClick(SeriesItem item); }

    private List<SeriesItem> list;
    private final OnClick listener;

    public SeriesAdapter(List<SeriesItem> list, OnClick listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_channel, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        SeriesItem item = list.get(position);
        h.t.setText(item.name == null ? "" : item.name);
        Glide.with(h.itemView.getContext())
                .load(item.cover)
                .placeholder(R.drawable.ic_play)
                .into(h.i);

        h.itemView.setOnClickListener(v -> listener.onClick(item));
    }

    @Override public int getItemCount() { return list == null ? 0 : list.size(); }

    public void update(List<SeriesItem> newList) {
        this.list = newList;
        notifyDataSetChanged();
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView t; ImageView i;
        VH(@NonNull View v) {
            super(v);
            t = v.findViewById(R.id.tvName);
            i = v.findViewById(R.id.ivIcon);
        }
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/adapter/EpisodeAdapter.java" <<EOF
package $PACKAGE_NAME.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.EpisodeItem;

public class EpisodeAdapter extends RecyclerView.Adapter<EpisodeAdapter.VH> {

    public interface OnClick { void onClick(EpisodeItem ep); }

    private List<EpisodeItem> list;
    private final OnClick listener;

    public EpisodeAdapter(List<EpisodeItem> list, OnClick listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_episode, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        EpisodeItem ep = list.get(position);
        String t = (ep.title != null && !ep.title.isEmpty()) ? ep.title : "Episode";
        if (ep.episodeNum != null && !ep.episodeNum.isEmpty()) t = "E" + ep.episodeNum + " - " + t;
        h.title.setText(t);

        String info = (ep.ext != null ? ep.ext : "mp4");
        if (ep.added != null) info += " • " + ep.added;
        h.info.setText(info);

        h.itemView.setOnClickListener(v -> listener.onClick(ep));
    }

    @Override public int getItemCount() { return list == null ? 0 : list.size(); }

    public void update(List<EpisodeItem> newList) {
        this.list = newList;
        notifyDataSetChanged();
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView title, info;
        VH(@NonNull View v) {
            super(v);
            title = v.findViewById(R.id.tvEpTitle);
            info  = v.findViewById(R.id.tvEpInfo);
        }
    }
}
EOF

# ----------------------------------------------------
# 13) UI ACTIVITIES (hatalar fix: rv field, Activity.this kullanımı, brace düzgün)
# ----------------------------------------------------
cat > "$JAVA_DIR/$PKG_PATH/ui/SelectionActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.adapter.PlaylistAdapter;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;
import $PACKAGE_NAME.utils.UnityAdsManager;

public class SelectionActivity extends AppCompatActivity {

    private RecyclerView rv;
    private PlaylistAdapter adapter;
    private List<Playlist> list;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_selection);

        // ✅ Açılış reklamı Unity Inter (ACTIVE)
        UnityAdsManager.showOpenInterstitial(this);

        rv = findViewById(R.id.rvPlaylists);
        rv.setLayoutManager(new LinearLayoutManager(this));
        load();

        findViewById(R.id.btnXtream).setOnClickListener(v ->
                startActivity(new Intent(this, LoginXtreamActivity.class)));

        findViewById(R.id.btnM3u).setOnClickListener(v ->
                startActivity(new Intent(this, LoginM3uActivity.class)));
    }

    @Override protected void onResume() {
        super.onResume();
        load();
    }

    private void load() {
        list = PrefUtils.getPlaylists(this);
        adapter = new PlaylistAdapter(list, new PlaylistAdapter.OnClick() {
            @Override public void onClick(Playlist p) {
                PrefUtils.savePlaylist(SelectionActivity.this, p);
                startActivity(new Intent(SelectionActivity.this, DashboardActivity.class));
            }

            @Override public void onDelete(Playlist p) {
                PrefUtils.deletePlaylist(SelectionActivity.this, p.id);
                list.remove(p);
                adapter.notifyDataSetChanged();
            }
        });
        rv.setAdapter(adapter);
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/ui/DashboardActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;

public class DashboardActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dashboard);

        Playlist p = PrefUtils.getActive(this);
        if (p != null) ((TextView)findViewById(R.id.tvUser)).setText(p.name);

        findViewById(R.id.btnLive).setOnClickListener(v -> {
            Intent i = new Intent(this, CommonListActivity.class);
            i.putExtra("type", "live");
            startActivity(i);
        });

        findViewById(R.id.btnMovies).setOnClickListener(v -> {
            Intent i = new Intent(this, CommonListActivity.class);
            i.putExtra("type", "vod");
            startActivity(i);
        });

        findViewById(R.id.btnSeries).setOnClickListener(v -> {
            startActivity(new Intent(this, SeriesListActivity.class));
        });

        findViewById(R.id.btnLogout).setOnClickListener(v -> {
            PrefUtils.logout(this);
            startActivity(new Intent(this, SelectionActivity.class));
            finish();
        });
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/ui/LoginXtreamActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import java.util.UUID;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.api.XtreamApi;
import $PACKAGE_NAME.model.AppModels.LoginResponse;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;

public class LoginXtreamActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login_xtream);

        EditText name = findViewById(R.id.etName);
        EditText u = findViewById(R.id.etUser);
        EditText p = findViewById(R.id.etPass);
        EditText d = findViewById(R.id.etDns);

        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String url = d.getText().toString().trim();
            if (!url.startsWith("http")) url = "http://" + url;
            final String baseUrl = url;

            Retrofit r = new Retrofit.Builder()
                    .baseUrl(baseUrl + "/")
                    .addConverterFactory(GsonConverterFactory.create())
                    .build();

            XtreamApi api = r.create(XtreamApi.class);

            api.login(baseUrl + "/player_api.php", u.getText().toString(), p.getText().toString())
                    .enqueue(new Callback<LoginResponse>() {
                        @Override
                        public void onResponse(Call<LoginResponse> call, Response<LoginResponse> response) {
                            if (response.body() != null && response.body().userInfo != null) {
                                Playlist pl = new Playlist();
                                pl.id = UUID.randomUUID().toString();
                                pl.type = "Xtream";
                                pl.url = baseUrl;
                                pl.user = u.getText().toString();
                                pl.pass = p.getText().toString();
                                pl.name = name.getText().toString();

                                PrefUtils.savePlaylist(LoginXtreamActivity.this, pl);
                                startActivity(new Intent(LoginXtreamActivity.this, DashboardActivity.class));
                                finish();
                            } else {
                                Toast.makeText(LoginXtreamActivity.this, "Login Failed", Toast.LENGTH_SHORT).show();
                            }
                        }

                        @Override
                        public void onFailure(Call<LoginResponse> call, Throwable t) {
                            Toast.makeText(LoginXtreamActivity.this, "Connection Error", Toast.LENGTH_SHORT).show();
                        }
                    });
        });
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/ui/LoginM3uActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import java.io.IOException;
import java.util.UUID;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;

public class LoginM3uActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login_m3u);

        EditText n = findViewById(R.id.etName);
        EditText u = findViewById(R.id.etUrl);

        findViewById(R.id.btnSave).setOnClickListener(v -> {
            String url = u.getText().toString().trim();
            if (url.isEmpty()) {
                Toast.makeText(this, "URL boş olamaz", Toast.LENGTH_SHORT).show();
                return;
            }

            OkHttpClient client = new OkHttpClient();
            Request request = new Request.Builder().url(url).build();

            client.newCall(request).enqueue(new Callback() {
                @Override public void onFailure(Call call, IOException e) {
                    runOnUiThread(() -> Toast.makeText(LoginM3uActivity.this, "Failed to download M3U", Toast.LENGTH_SHORT).show());
                }

                @Override public void onResponse(Call call, Response response) throws IOException {
                    if (!response.isSuccessful()) {
                        runOnUiThread(() -> Toast.makeText(LoginM3uActivity.this, "M3U HTTP Error", Toast.LENGTH_SHORT).show());
                        return;
                    }
                    String content = response.body().string();
                    runOnUiThread(() -> {
                        Playlist pl = new Playlist();
                        pl.id = UUID.randomUUID().toString();
                        pl.type = "M3U";
                        pl.name = n.getText().toString();
                        pl.url = url;
                        pl.m3uContent = content;

                        PrefUtils.savePlaylist(LoginM3uActivity.this, pl);
                        startActivity(new Intent(LoginM3uActivity.this, DashboardActivity.class));
                        finish();
                    });
                }
            });
        });
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/ui/CommonListActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.gms.ads.AdView;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.adapter.CategoryAdapter;
import $PACKAGE_NAME.adapter.StreamAdapter;
import $PACKAGE_NAME.api.XtreamApi;
import $PACKAGE_NAME.model.AppModels.Category;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.model.AppModels.StreamItem;
import $PACKAGE_NAME.utils.AdMobBannerManager;
import $PACKAGE_NAME.utils.M3UParser;
import $PACKAGE_NAME.utils.PrefUtils;

public class CommonListActivity extends AppCompatActivity {

    private XtreamApi api;
    private RecyclerView rvC, rvS;
    private StreamAdapter streamAdapter;
    private String type;
    private Playlist playlist;

    private Map<String, List<StreamItem>> m3uMap;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list);

        // ✅ AdMob Banner aktif
        AdMobBannerManager.loadBanner(this, (AdView) findViewById(R.id.adView));

        type = getIntent().getStringExtra("type");
        playlist = PrefUtils.getActive(this);

        rvC = findViewById(R.id.rvCats);
        rvS = findViewById(R.id.rvStreams);

        rvC.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));

        streamAdapter = new StreamAdapter(new ArrayList<>(), item -> {
            Intent in = new Intent(this, PlayerActivity.class);
            String url;

            if ("Xtream".equals(playlist.type)) {
                String path = type.equals("live") ? "live" : "movie";
                String ext = (item.ext != null && !item.ext.isEmpty()) ? item.ext : "ts";
                url = playlist.url + "/" + path + "/" + playlist.user + "/" + playlist.pass + "/" + item.streamId + "." + ext;
                in.putExtra("ref", (String) null);
                in.putExtra("origin", (String) null);
            } else {
                url = item.directUrl;
                in.putExtra("ref", item.ref);
                in.putExtra("origin", item.origin);
            }

            in.putExtra("url", url);
            startActivity(in);
        });

        rvS.setAdapter(streamAdapter);

        if (playlist == null) return;

        if ("Xtream".equals(playlist.type)) {
            loadXtream();
        } else {
            loadM3u();
        }
    }

    private void loadM3u() {
        m3uMap = M3UParser.parse(playlist.m3uContent);
        List<Category> cats = new ArrayList<>();
        for (String key : m3uMap.keySet()) cats.add(new Category(key, key));

        CategoryAdapter catAdapter = new CategoryAdapter(cats, cat -> streamAdapter.update(m3uMap.get(cat.id)));
        rvC.setAdapter(catAdapter);

        if (!cats.isEmpty()) streamAdapter.update(m3uMap.get(cats.get(0).id));
    }

    private void loadXtream() {
        Retrofit r = new Retrofit.Builder()
                .baseUrl(playlist.url + "/")
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        api = r.create(XtreamApi.class);

        String action = type.equals("live") ? "get_live_categories" : "get_vod_categories";
        api.getCategories(playlist.url + "/player_api.php", playlist.user, playlist.pass, action)
                .enqueue(new Callback<List<Category>>() {
                    @Override public void onResponse(Call<List<Category>> call, Response<List<Category>> response) {
                        List<Category> body = response.body();
                        if (body == null) return;

                        CategoryAdapter catAdapter = new CategoryAdapter(body, cat -> loadItems(cat.id));
                        rvC.setAdapter(catAdapter);

                        if (!body.isEmpty()) loadItems(body.get(0).id);
                    }
                    @Override public void onFailure(Call<List<Category>> call, Throwable t) {}
                });
    }

    private void loadItems(String id) {
        String action = type.equals("live") ? "get_live_streams" : "get_vod_streams";
        api.getStreams(playlist.url + "/player_api.php", playlist.user, playlist.pass, action, id)
                .enqueue(new Callback<List<StreamItem>>() {
                    @Override public void onResponse(Call<List<StreamItem>> call, Response<List<StreamItem>> response) {
                        List<StreamItem> body = response.body();
                        if (body != null) streamAdapter.update(body);
                    }
                    @Override public void onFailure(Call<List<StreamItem>> call, Throwable t) {}
                });
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/ui/SeriesListActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.gms.ads.AdView;

import java.util.ArrayList;
import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.adapter.CategoryAdapter;
import $PACKAGE_NAME.adapter.SeriesAdapter;
import $PACKAGE_NAME.api.XtreamApi;
import $PACKAGE_NAME.model.AppModels.Category;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.model.AppModels.SeriesItem;
import $PACKAGE_NAME.utils.AdMobBannerManager;
import $PACKAGE_NAME.utils.PrefUtils;

public class SeriesListActivity extends AppCompatActivity {

    private XtreamApi api;
    private Playlist playlist;
    private RecyclerView rvC, rvS;
    private SeriesAdapter seriesAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list);

        // ✅ AdMob Banner aktif
        AdMobBannerManager.loadBanner(this, (AdView) findViewById(R.id.adView));

        playlist = PrefUtils.getActive(this);
        if (playlist == null) return;

        rvC = findViewById(R.id.rvCats);
        rvS = findViewById(R.id.rvStreams);
        rvC.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));

        seriesAdapter = new SeriesAdapter(new ArrayList<>(), item -> {
            Intent i = new Intent(this, SeriesEpisodesActivity.class);
            i.putExtra("series_id", item.seriesId);
            i.putExtra("series_name", item.name);
            startActivity(i);
        });
        rvS.setAdapter(seriesAdapter);

        Retrofit r = new Retrofit.Builder()
                .baseUrl(playlist.url + "/")
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        api = r.create(XtreamApi.class);

        api.getSeriesCategories(playlist.url + "/player_api.php", playlist.user, playlist.pass, "get_series_categories")
                .enqueue(new Callback<List<Category>>() {
                    @Override public void onResponse(Call<List<Category>> call, Response<List<Category>> response) {
                        List<Category> cats = response.body();
                        if (cats == null) return;

                        CategoryAdapter catAdapter = new CategoryAdapter(cats, cat -> loadSeries(cat.id));
                        rvC.setAdapter(catAdapter);

                        if (!cats.isEmpty()) loadSeries(cats.get(0).id);
                    }
                    @Override public void onFailure(Call<List<Category>> call, Throwable t) {}
                });
    }

    private void loadSeries(String catId) {
        api.getSeries(playlist.url + "/player_api.php", playlist.user, playlist.pass, "get_series", catId)
                .enqueue(new Callback<List<SeriesItem>>() {
                    @Override public void onResponse(Call<List<SeriesItem>> call, Response<List<SeriesItem>> response) {
                        List<SeriesItem> list = response.body();
                        if (list != null) seriesAdapter.update(list);
                    }
                    @Override public void onFailure(Call<List<SeriesItem>> call, Throwable t) {}
                });
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/ui/SeriesEpisodesActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.gms.ads.AdView;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.adapter.CategoryAdapter;
import $PACKAGE_NAME.adapter.EpisodeAdapter;
import $PACKAGE_NAME.api.XtreamApi;
import $PACKAGE_NAME.model.AppModels.Category;
import $PACKAGE_NAME.model.AppModels.EpisodeItem;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.model.AppModels.SeriesInfoResponse;
import $PACKAGE_NAME.utils.AdMobBannerManager;
import $PACKAGE_NAME.utils.PrefUtils;

public class SeriesEpisodesActivity extends AppCompatActivity {

    private XtreamApi api;
    private Playlist playlist;

    private RecyclerView rvSeasons, rvEpisodes;
    private EpisodeAdapter epAdapter;

    private Map<String, List<EpisodeItem>> episodesMap;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_series_episodes);

        // ✅ AdMob Banner aktif
        AdMobBannerManager.loadBanner(this, (AdView) findViewById(R.id.adView));

        playlist = PrefUtils.getActive(this);
        if (playlist == null) return;

        String seriesId = getIntent().getStringExtra("series_id");
        String seriesName = getIntent().getStringExtra("series_name");
        if (seriesName != null) ((TextView)findViewById(R.id.tvTitle)).setText(seriesName);

        rvSeasons = findViewById(R.id.rvSeasons);
        rvEpisodes = findViewById(R.id.rvEpisodes);

        rvSeasons.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        rvEpisodes.setLayoutManager(new LinearLayoutManager(this));

        epAdapter = new EpisodeAdapter(new ArrayList<>(), ep -> {
            // Xtream episode URL formatı panelden panele değişebilir.
            // En yaygın: /series/user/pass/EPISODE_ID.ext
            String ext = (ep.ext != null && !ep.ext.isEmpty()) ? ep.ext : "mp4";
            String url = playlist.url + "/series/" + playlist.user + "/" + playlist.pass + "/" + ep.id + "." + ext;

            Intent in = new Intent(SeriesEpisodesActivity.this, PlayerActivity.class);
            in.putExtra("url", url);
            in.putExtra("ref", (String) null);
            in.putExtra("origin", (String) null);
            startActivity(in);
        });
        rvEpisodes.setAdapter(epAdapter);

        Retrofit r = new Retrofit.Builder()
                .baseUrl(playlist.url + "/")
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        api = r.create(XtreamApi.class);

        api.getSeriesInfo(playlist.url + "/player_api.php", playlist.user, playlist.pass, "get_series_info", seriesId)
                .enqueue(new Callback<SeriesInfoResponse>() {
                    @Override public void onResponse(Call<SeriesInfoResponse> call, Response<SeriesInfoResponse> response) {
                        SeriesInfoResponse body = response.body();
                        if (body == null) return;

                        episodesMap = body.episodes;
                        if (episodesMap == null || episodesMap.isEmpty()) return;

                        // season listesi üret
                        List<Category> seasons = new ArrayList<>();
                        for (String seasonKey : episodesMap.keySet()) {
                            seasons.add(new Category(seasonKey, "Season " + seasonKey));
                        }

                        CategoryAdapter seasonAdapter = new CategoryAdapter(seasons, cat -> {
                            List<EpisodeItem> eps = episodesMap.get(cat.id);
                            if (eps != null) epAdapter.update(eps);
                        });

                        rvSeasons.setAdapter(seasonAdapter);

                        // default: ilk season
                        String firstKey = seasons.get(0).id;
                        List<EpisodeItem> first = episodesMap.get(firstKey);
                        if (first != null) epAdapter.update(first);
                    }

                    @Override public void onFailure(Call<SeriesInfoResponse> call, Throwable t) {}
                });
    }
}
EOF

cat > "$JAVA_DIR/$PKG_PATH/ui/PlayerActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.WindowManager;
import android.widget.ImageButton;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.source.DefaultMediaSourceFactory;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;

import java.util.HashMap;
import java.util.Map;

import $PACKAGE_NAME.R;

public class PlayerActivity extends AppCompatActivity {

    private ExoPlayer player;
    private StyledPlayerView playerView;
    private int resizeMode = 0; // 0 FIT, 1 FILL, 2 ZOOM

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            getWindow().setFlags(
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            );
            getWindow().getAttributes().layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        setContentView(R.layout.activity_player);

        playerView = findViewById(R.id.player_view);
        playerView.setControllerShowTimeoutMs(3000);

        ImageButton btnZoom = findViewById(R.id.btnZoom);
        btnZoom.setOnClickListener(v -> toggleZoom());

        String url = getIntent().getStringExtra("url");
        String ref = getIntent().getStringExtra("ref");
        String origin = getIntent().getStringExtra("origin");

        DefaultHttpDataSource.Factory dsFactory = new DefaultHttpDataSource.Factory();
        Map<String, String> headers = new HashMap<>();
        if (ref != null && !ref.isEmpty()) headers.put("Referer", ref);
        if (origin != null && !origin.isEmpty()) headers.put("Origin", origin);
        if (!headers.isEmpty()) dsFactory.setDefaultRequestProperties(headers);

        DefaultMediaSourceFactory mediaSourceFactory = new DefaultMediaSourceFactory(dsFactory);

        player = new ExoPlayer.Builder(this)
                .setMediaSourceFactory(mediaSourceFactory)
                .build();

        playerView.setPlayer(player);

        if (url != null && !url.isEmpty()) {
            player.setMediaItem(MediaItem.fromUri(Uri.parse(url)));
            player.prepare();
            player.play();
        } else {
            Toast.makeText(this, "URL boş", Toast.LENGTH_SHORT).show();
        }
    }

    private void toggleZoom() {
        resizeMode++;
        if (resizeMode > 2) resizeMode = 0;

        if (resizeMode == 0) playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT);
        else if (resizeMode == 1) playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FILL);
        else playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);
    }

    @Override protected void onDestroy() {
        super.onDestroy();
        if (player != null) player.release();
    }
}
EOF

# ----------------------------------------------------
# 14) MANIFEST (AdMob APP_ID + AD_ID izni + Activities)
# ----------------------------------------------------
cat > "$MODULE_DIR/src/main/AndroidManifest.xml" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PACKAGE_NAME">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" />

    <application
        android:name="androidx.multidex.MultiDexApplication"
        android:label="$APP_NAME"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true"
        android:icon="@mipmap/ic_launcher">

        <!-- ✅ AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="$ADMOB_APP_ID" />

        <activity
            android:name=".$(echo ${PKG_PATH} | sed 's/\//./g').ui.SelectionActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name=".$(echo ${PKG_PATH} | sed 's/\//./g').ui.LoginXtreamActivity" android:screenOrientation="portrait" />
        <activity android:name=".$(echo ${PKG_PATH} | sed 's/\//./g').ui.LoginM3uActivity" android:screenOrientation="portrait" />
        <activity android:name=".$(echo ${PKG_PATH} | sed 's/\//./g').ui.DashboardActivity" android:screenOrientation="portrait" />

        <activity android:name=".$(echo ${PKG_PATH} | sed 's/\//./g').ui.CommonListActivity" android:screenOrientation="portrait" />
        <activity android:name=".$(echo ${PKG_PATH} | sed 's/\//./g').ui.SeriesListActivity" android:screenOrientation="portrait" />
        <activity android:name=".$(echo ${PKG_PATH} | sed 's/\//./g').ui.SeriesEpisodesActivity" android:screenOrientation="portrait" />

        <activity
            android:name=".$(echo ${PKG_PATH} | sed 's/\//./g').ui.PlayerActivity"
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize"
            android:screenOrientation="sensor" />
    </application>
</manifest>
EOF

# ----------------------------------------------------
# 15) BİTİŞ
# ----------------------------------------------------
echo "✅ FULL UPDATE BİTTİ."
echo "👉 Repo root'ta build: ./gradlew :app:assembleRelease"
echo "👉 Unity Inter açılışta: SelectionActivity (1.2sn gecikmeli)"
echo "👉 AdMob sadece Banner: activity_list + series_episodes alt kısım"
echo "👉 Series + Episodes: Dashboard -> SERIES"
