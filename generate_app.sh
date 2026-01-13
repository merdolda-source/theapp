#!/bin/bash

# --- 1. Değişkenler (Panelden Gelenler) ---
APP_NAME="${1:-XtrewmmmmPlayer}"
PKG_NAME="${2:-com.xtrewmmmm.tv}"
ICON_URL="${3:-https://site.com/icon.png}"
AD_APP_ID="${4:-ca-app-pub-3940256099942544~3347511713}"
BANNER_ID="${5:-ca-app-pub-3940256099942544/6300978111}"
INTER_ID="${6:-ca-app-pub-3940256099942544/1033173712}"
INT_COUNT="${7:-3}"

# Renkler
BG="#1A1A1A"
GREEN="#2E7D32"
MAROON="#800000"

echo "--- Xtrewmmmm: Proje İnşa Ediliyor: $PKG_NAME ---"

# --- 2. Klasör Yapısını Oluştur ---
PKG_PATH=${PKG_NAME//./\/}
mkdir -p app/src/main/java/$PKG_PATH
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/mipmap-xxxhdpi
mkdir -p gradle/wrapper

# --- 3. Root build.gradle Oluştur ---
cat <<EOF > build.gradle
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath 'com.android.tools.build:gradle:8.1.1' }
}
allprojects {
    repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } }
}
EOF

# --- 4. App build.gradle Oluştur (Kütüphaneler Dahil) ---
cat <<EOF > app/build.gradle
apply plugin: 'com.android.application'
android {
    namespace '$PKG_NAME'
    compileSdk 34
    defaultConfig {
        applicationId '$PKG_NAME'
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.gms:play-services-ads:22.3.0'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.github.bumptech.glide:glide:4.15.1'
}
EOF

# --- 5. Android Manifest (Notch/Reklam/İzinler) ---
cat <<EOF > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="$APP_NAME"
        android:theme="@style/Theme.Xtrew"
        android:usesCleartextTraffic="true">
        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="$AD_APP_ID"/>
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <activity android:name=".PlayerActivity" android:configChanges="orientation|screenSize|layoutDirection" />
    </application>
</manifest>
EOF

# --- 6. Kaynak Dosyaları (Colors & Strings) ---
cat <<EOF > app/src/main/res/values/colors.xml
<resources>
    <color name="colorPrimary">$MAROON</color>
    <color name="colorAccent">$GREEN</color>
    <color name="bg_dark">$BG</color>
    <color name="white">#FFFFFF</color>
</resources>
EOF

cat <<EOF > app/src/main/res/values/themes.xml
<resources>
    <style name="Theme.Xtrew" parent="Theme.MaterialComponents.DayNight.NoActionBar">
        <item name="colorPrimary">$MAROON</item>
        <item name="android:windowBackground">@color/bg_dark</item>
        <item name="android:windowLayoutInDisplayCutoutMode" tools:ignore="NewApi">shortEdges</item>
    </style>
</resources>
EOF

# --- 7. Java Kodları: Player & Header Logic ---
# PlayerActivity (Referer, Origin ve Zoom modlarını içerir)
cat <<EOF > app/src/main/java/$PKG_PATH/PlayerActivity.java
package $PKG_NAME;
import android.os.Bundle;
import android.view.WindowManager;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;

public class PlayerActivity extends AppCompatActivity {
    StyledPlayerView playerView;
    ExoPlayer player;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_player);
        
        // Full screen notch bypass
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS, WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
        
        playerView = findViewById(R.id.player_view);
        
        // Header (Referer/Origin) Ayarı
        DefaultHttpDataSource.Factory httpDataSourceFactory = new DefaultHttpDataSource.Factory()
            .setUserAgent("XtrewPlayer")
            .setDefaultRequestProperties(java.util.Collections.singletonMap("Referer", getIntent().getStringExtra("referer")));

        player = new ExoPlayer.Builder(this).setMediaSourceFactory(new com.google.android.exoplayer2.source.DefaultMediaSourceFactory(httpDataSourceFactory)).build();
        playerView.setPlayer(player);
        
        // ZOOM MODU (Kamera/Notch aşan mod)
        playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM); 

        String streamUrl = getIntent().getStringExtra("url");
        player.setMediaItem(MediaItem.fromUri(streamUrl));
        player.prepare();
        player.play();
    }
}
EOF

# --- 8. İkon İndir ---
curl -L "$ICON_URL" -o app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

# --- 9. Gradle Wrapper (Build için şart) ---
# Eğer repoda gradlew yoksa otomatik oluşturur
if [ ! -f "gradlew" ]; then
    gradle wrapper --gradle-version 8.2
fi

chmod +x gradlew
echo "--- Proje Oluşturuldu. Gradle Build Başlatılıyor... ---"
./gradlew assembleRelease
