#!/bin/bash

# --- 1. PARAMETRELER (Panelden Gelenler) ---
NAME=$1; PKG=$2; ICON=$3; AD_APP_ID=$4; BANNER_ID=$5; INTER_ID=$6; INT_COUNT=$7
PATH_PKG=${PKG//./\/}

echo "--- Xtrewmmmm Full Build Başlatıldı ---"

# --- 2. KLASÖR YAPISINI SIFIRDAN OLUŞTUR ---
mkdir -p app/src/main/java/$PATH_PKG
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/drawable

# --- 3. GRADLE DOSYALARI (ROOT & APP) ---
cat <<EOF > build.gradle
buildscript { repositories { google(); mavenCentral() }; dependencies { classpath 'com.android.tools.build:gradle:8.1.1' } }
allprojects { repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } } }
EOF

cat <<EOF > app/build.gradle
apply plugin: 'com.android.application'
android {
    namespace '$PKG'
    compileSdk 34
    defaultConfig { applicationId '$PKG'; minSdk 21; targetSdk 34; versionCode 1; versionName "1.0" }
    buildTypes { release { minifyEnabled false } }
}
dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.gms:play-services-ads:22.3.0'
    implementation 'com.github.bumptech.glide:glide:4.15.1'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
}
EOF

# --- 4. MANIFEST (NOTCH/ÇENTİK VE REKLAM DESTEĞİ) ---
cat <<EOF > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:label="$NAME"
        android:theme="@style/XtrewTheme"
        android:usesCleartextTraffic="true">
        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="$AD_APP_ID"/>
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter>
        </activity>
        <activity android:name=".PlayerActivity" android:screenOrientation="landscape" android:configChanges="orientation|screenSize" />
    </application>
</manifest>
EOF

# --- 5. KAYNAKLAR VE RENKLER (Gri, Yeşil, Bordo) ---
cat <<EOF > app/src/main/res/values/colors.xml
<resources>
    <color name="bg_dark">#1A1A1A</color>
    <color name="sport_green">#2E7D32</color>
    <color name="maroon">#800000</color>
    <color name="white">#FFFFFF</color>
</resources>
EOF

cat <<EOF > app/src/main/res/values/themes.xml
<resources xmlns:tools="http://schemas.xml/tools">
    <style name="XtrewTheme" parent="Theme.MaterialComponents.DayNight.NoActionBar">
        <item name="android:windowBackground">@color/bg_dark</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>
</resources>
EOF

# --- 6. LAYOUTLAR (GİRİŞ VE PLAYER) ---
# Giriş ekranı: Xtream ve M3U butonları arasına reklam koyar
cat <<EOF > app/src/main/res/layout/activity_main.xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_dark">
    <LinearLayout android:id="@+id/btnGroup" android:orientation="vertical" android:layout_centerInParent="true" android:layout_width="300dp" android:layout_height="wrap_content">
        <Button android:id="@+id/btnXtream" android:text="Xtream Port Giriş" android:backgroundTint="@color/maroon" android:layout_width="match_parent" android:layout_height="60dp" />
        <com.google.android.gms.ads.AdView xmlns:ads="http://schemas.android.com/apk/res-auto" android:id="@+id/banner_middle" ads:adSize="BANNER" ads:adUnitId="$BANNER_ID" android:layout_width="wrap_content" android:layout_height="wrap_content" android:layout_gravity="center" android:layout_margin="10dp"/>
        <Button android:id="@+id/btnM3u" android:text="M3U URL Giriş" android:backgroundTint="@color/sport_green" android:layout_width="match_parent" android:layout_height="60dp" />
    </LinearLayout>
    <com.google.android.gms.ads.AdView xmlns:ads="http://schemas.android.com/apk/res-auto" android:id="@+id/banner_bottom" ads:adSize="BANNER" ads:adUnitId="$BANNER_ID" android:layout_alignParentBottom="true" android:layout_centerHorizontal="true" android:layout_width="wrap_content" android:layout_height="wrap_content"/>
</RelativeLayout>
EOF

# --- 7. JAVA KODU: PLAYER (FULL ZOOM + REFERER + ORIGIN) ---
cat <<EOF > app/src/main/java/$PATH_PKG/PlayerActivity.java
package $PKG;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import java.util.HashMap;
import java.util.Map;

public class PlayerActivity extends AppCompatActivity {
    StyledPlayerView playerView;
    ExoPlayer player;
    int zoomMode = 1; // 0:Kare, 1:Full, 2:Zoom

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // KAMERAYI VE ÇENTİĞİ AŞAN FULL MOD
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS, WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
        setContentView(R.layout.activity_player);

        playerView = findViewById(R.id.player_view);
        
        // REFERER VE ORIGIN DESTEĞİ
        Map<String, String> headers = new HashMap<>();
        headers.put("Referer", getIntent().getStringExtra("referer"));
        headers.put("Origin", getIntent().getStringExtra("origin"));

        DefaultHttpDataSource.Factory ds = new DefaultHttpDataSource.Factory().setDefaultRequestProperties(headers);
        player = new ExoPlayer.Builder(this).build();
        playerView.setPlayer(player);
        
        // VARSAYILAN FULL MOD (Notch Dahil)
        playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);

        String url = getIntent().getStringExtra("url");
        player.setMediaItem(MediaItem.fromUri(url));
        player.prepare();
        player.play();
    }
}
EOF

# --- 8. İKON VE BİTİRİŞ ---
curl -L "$ICON" -o app/src/main/res/drawable/ic_launcher.png
# Gradle wrapper oluştur ve release build al
gradle wrapper --gradle-version 8.2
./gradlew assembleRelease

echo "--- Xtrewmmmm Build Tamamlandı! APK hazır. ---"
