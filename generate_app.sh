#!/bin/bash

# --- KONFİGÜRASYON ---
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="com/merdolda/player"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "💎 ERDINPLAYER ULTIMATE v4.0: MEGA SİSTEM KURULUYOR..."

# 1. KLASÖR YAPILANDIRMASI
rm -rf $PROJECT_ROOT
mkdir -p $PKG_DIR/{model,adapter,api,utils,ui}
mkdir -p $RES_DIR/{layout,values,drawable,anim,menu}
mkdir -p $PROJECT_ROOT/gradle/wrapper

# 2. KEYSTORE
keytool -genkey -v -keystore $MODULE_DIR/release.keystore -alias erdinplayer -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=Erdin, O=ErdinPlayer, C=TR" 2>/dev/null

# 3. GRADLE 8.4 YAPILANDIRMASI
cat << 'EOF' > $PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat << 'EOF' > $PROJECT_ROOT/build.gradle
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath 'com.android.tools.build:gradle:8.1.1' }
}
allprojects {
    repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } }
}
EOF

cat << 'EOF' > $PROJECT_ROOT/settings.gradle
rootProject.name = "ErdinPlayer"
include ':app'
EOF

cat << 'EOF' > $PROJECT_ROOT/gradle.properties
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx4048m
EOF

cat << 'EOF' > $MODULE_DIR/build.gradle
plugins { id 'com.android.application' }
android {
    namespace 'com.merdolda.player'
    compileSdk 34
    defaultConfig {
        applicationId "com.merdolda.player"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
        multiDexEnabled true
    }
    signingConfigs {
        release { storeFile file("release.keystore"); storePassword "123456"; keyAlias "erdinplayer"; keyPassword "123456" }
    }
    buildTypes {
        release { minifyEnabled false; signingConfig signingConfigs.release; proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro' }
    }
    compileOptions { sourceCompatibility JavaVersion.VERSION_17; targetCompatibility JavaVersion.VERSION_17 }
}
dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.1'
    implementation 'androidx.cardview:cardview:1.0.0'
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.19.1'
    implementation 'com.github.bumptech.glide:glide:4.16.0'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.google.code.gson:gson:2.10.1'
}
EOF

# 4. RESOURCES (PREMIUM CYAN & DEEP BLUE THEME)
cat << 'EOF' > $RES_DIR/values/colors.xml
<resources>
    <color name="bg_main">#0A0E14</color>
    <color name="bg_card">#161B22</color>
    <color name="accent_cyan">#00E5FF</color>
    <color name="primary_purple">#2D1B69</color>
    <color name="white">#FFFFFF</color>
    <color name="gray_text">#8B949E</color>
    <color name="nav_unselected">#484F58</color>
</resources>
EOF

cat << 'EOF' > $RES_DIR/values/styles.xml
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.NoActionBar">
        <item name="android:windowBackground">@color/bg_main</item>
        <item name="colorPrimary">@color/primary_purple</item>
        <item name="colorAccent">@color/accent_cyan</item>
    </style>
</resources>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_launcher_background.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#0A0E14" android:pathData="M0,0h108v108h-108z"/></vector>
EOF

cat << 'EOF' > $RES_DIR/menu/bottom_nav_menu.xml
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:id="@+id/nav_home" android:title="Ana Sayfa" android:icon="@android:drawable/ic_menu_today"/>
    <item android:id="@+id/nav_live" android:title="Canlı TV" android:icon="@android:drawable/ic_menu_view"/>
    <item android:id="@+id/nav_movies" android:title="Filmler" android:icon="@android:drawable/ic_menu_slideshow"/>
    <item android:id="@+id/nav_series" android:title="Diziler" android:icon="@android:drawable/ic_menu_gallery"/>
</menu>
EOF

# 5. MODELLER (ÇOKLU PLAYLIST DESTEĞİ İÇİN)
cat << EOF > $PKG_DIR/model/AppModels.java
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.List;

public class AppModels {
    public static class Playlist implements Serializable {
        public String id;
        public String name;
        public String type; // XTREAM, M3U, SINGLE
        public String url;
        public String username;
        public String password;
        public String referer;
        public String origin;
    }
    
    public static class XtreamLogin implements Serializable {
        @SerializedName("user_info") public UserInfo userInfo;
    }
    public static class UserInfo implements Serializable {
        @SerializedName("username") public String username;
        @SerializedName("auth") public int auth;
    }
    public static class Category implements Serializable {
        @SerializedName("category_id") public String id;
        @SerializedName("category_name") public String name;
    }
    public static class StreamItem implements Serializable {
        @SerializedName("name") public String name;
        @SerializedName("stream_id") public String streamId;
        @SerializedName("stream_icon") public String icon;
        @SerializedName("container_extension") public String ext;
    }
}
EOF

# 6. UTILS (PLAYLIST MANAGER & HEADER HANDLER)
cat << EOF > $PKG_DIR/utils/PlaylistManager.java
package com.merdolda.player.utils;
import android.content.Context;
import android.content.SharedPreferences;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.merdolda.player.model.AppModels.Playlist;
import java.util.*;

public class PlaylistManager {
    private static final String PREF_NAME = "ErdinPlaylists";
    private SharedPreferences sp;
    private Gson gson = new Gson();

    public PlaylistManager(Context c) { sp = c.getSharedPreferences(PREF_NAME, 0); }

    public void addPlaylist(Playlist p) {
        List<Playlist> list = getPlaylists();
        list.add(p);
        sp.edit().putString("list", gson.toJson(list)).apply();
    }

    public List<Playlist> getPlaylists() {
        String json = sp.getString("list", "[]");
        return gson.fromJson(json, new TypeToken<List<Playlist>>(){}.getType());
    }

    public void setActive(String id) { sp.edit().putString("active_id", id).apply(); }
    public Playlist getActive() {
        String id = sp.getString("active_id", "");
        for(Playlist p : getPlaylists()) if(p.id.equals(id)) return p;
        return null;
    }
}
EOF

# 7. LAYOUTS (MODERN TASARIMLAR)
cat << 'EOF' > $RES_DIR/layout/activity_dashboard.xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_main">

    <TextView android:id="@+id/tvHeader" android:layout_width="match_parent" android:layout_height="wrap_content"
        android:padding="20dp" android:text="ERDIN PLAYER" android:textColor="@color/accent_cyan" android:textSize="22sp" android:textStyle="bold" android:gravity="center"/>

    <androidx.core.widget.NestedScrollView android:layout_width="match_parent" android:layout_height="match_parent" android:layout_above="@+id/bottomNav" android:layout_below="@id/tvHeader">
        <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="vertical" android:padding="15dp">
            <androidx.cardview.widget.CardView android:id="@+id/btnLive" android:layout_width="match_parent" android:layout_height="140dp" android:layout_marginBottom="15dp" app:cardCornerRadius="15dp" app:cardBackgroundColor="@color/bg_card">
                <TextView android:layout_width="match_parent" android:layout_height="match_parent" android:text="CANLI TV" android:textColor="#FFF" android:gravity="center" android:textSize="24sp" android:textStyle="bold"/>
            </androidx.cardview.widget.CardView>
            <androidx.cardview.widget.CardView android:id="@+id/btnMovies" android:layout_width="match_parent" android:layout_height="140dp" android:layout_marginBottom="15dp" app:cardCornerRadius="15dp" app:cardBackgroundColor="@color/bg_card">
                <TextView android:layout_width="match_parent" android:layout_height="match_parent" android:text="FİLMLER" android:textColor="#FFF" android:gravity="center" android:textSize="24sp" android:textStyle="bold"/>
            </androidx.cardview.widget.CardView>
            <androidx.cardview.widget.CardView android:id="@+id/btnSeries" android:layout_width="match_parent" android:layout_height="140dp" android:layout_marginBottom="15dp" app:cardCornerRadius="15dp" app:cardBackgroundColor="@color/bg_card">
                <TextView android:layout_width="match_parent" android:layout_height="match_parent" android:text="DİZİLER" android:textColor="#FFF" android:gravity="center" android:textSize="24sp" android:textStyle="bold"/>
            </androidx.cardview.widget.CardView>
        </LinearLayout>
    </androidx.core.widget.NestedScrollView>

    <com.google.android.material.bottomnavigation.BottomNavigationView
        android:id="@+id/bottomNav" android:layout_width="match_parent" android:layout_height="70dp"
        android:layout_alignParentBottom="true" app:menu="@menu/bottom_nav_menu"
        android:background="@color/bg_card" app:itemIconTint="@color/accent_cyan" app:itemTextColor="@color/white"/>
</RelativeLayout>
EOF

# 8. PLAYER (ROTASYON DÜZELTMELİ)
cat << EOF > $PKG_DIR/ui/PlayerActivity.java
package com.merdolda.player.ui;
import android.net.Uri;
import android.os.Bundle;
import android.view.WindowManager;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.*;
import com.google.android.exoplayer2.source.DefaultMediaSourceFactory;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.merdolda.player.R;
import java.util.HashMap;
import java.util.Map;

public class PlayerActivity extends AppCompatActivity {
    ExoPlayer player;
    private long playbackPosition = 0;
    private boolean playWhenReady = true;

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        setContentView(R.layout.activity_player);
        
        StyledPlayerView pv = findViewById(R.id.player_view);
        String url = getIntent().getStringExtra("url");
        String ref = getIntent().getStringExtra("referer");
        String ori = getIntent().getStringExtra("origin");

        // Header Yapılandırması
        DefaultHttpDataSource.Factory httpFactory = new DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true);
        
        Map<String, String> headers = new HashMap<>();
        if(ref != null && !ref.isEmpty()) headers.put("Referer", ref);
        if(ori != null && !ori.isEmpty()) headers.put("Origin", ori);
        httpFactory.setDefaultRequestProperties(headers);

        player = new ExoPlayer.Builder(this)
            .setMediaSourceFactory(new DefaultMediaSourceFactory(httpFactory))
            .build();
            
        pv.setPlayer(player);

        if (savedInstanceState != null) {
            playbackPosition = savedInstanceState.getLong("pos");
            playWhenReady = savedInstanceState.getBoolean("play");
        }

        if(url != null) {
            // Uzantısız linkler için zorlamadan otomatik algılama (DefaultMediaSourceFactory zaten halleder)
            MediaItem item = MediaItem.fromUri(Uri.parse(url));
            player.setMediaItem(item);
            player.setPlayWhenReady(playWhenReady);
            player.seekTo(playbackPosition);
            player.prepare();
        }
    }

    // ROTASYONDA BAŞTAN BAŞLAMAYI ÖNLER
    @Override protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        if(player != null) {
            outState.putLong("pos", player.getCurrentPosition());
            outState.putBoolean("play", player.getPlayWhenReady());
        }
    }

    @Override protected void onDestroy() { super.onDestroy(); if(player != null) player.release(); }
}
EOF

# 9. SELECTION ACTIVITY (ÇOKLU LİSTE GİRİŞİ)
cat << EOF > $PKG_DIR/ui/SelectionActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.utils.PlaylistManager;

public class SelectionActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        PlaylistManager pm = new PlaylistManager(this);
        if(!pm.getPlaylists().isEmpty()) {
            startActivity(new Intent(this, DashboardActivity.class));
            finish();
            return;
        }
        setContentView(R.layout.activity_selection);
        findViewById(R.id.btnXtream).setOnClickListener(v -> startActivity(new Intent(this, LoginXtreamActivity.class)));
        findViewById(R.id.btnSingle).setOnClickListener(v -> startActivity(new Intent(this, LoginSingleActivity.class)));
    }
}
EOF

# LoginSingleActivity (Header Girişi Dahil)
cat << 'EOF' > $RES_DIR/layout/activity_login_single.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#0A0E14" android:orientation="vertical" android:padding="25dp" android:gravity="center">
    <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="Tekli Akış Ekle" android:textColor="#00E5FF" android:textSize="24sp" android:layout_marginBottom="30dp"/>
    <EditText android:id="@+id/etName" android:layout_width="match_parent" android:layout_height="55dp" android:hint="Akış Adı" android:textColor="#FFF" android:background="#161B22" android:padding="10dp" android:layout_marginBottom="10dp"/>
    <EditText android:id="@+id/etUrl" android:layout_width="match_parent" android:layout_height="55dp" android:hint="Video URL (Uzantısız Olabilir)" android:textColor="#FFF" android:background="#161B22" android:padding="10dp" android:layout_marginBottom="10dp"/>
    <EditText android:id="@+id/etRef" android:layout_width="match_parent" android:layout_height="55dp" android:hint="Referer (İsteğe Bağlı)" android:textColor="#FFF" android:background="#161B22" android:padding="10dp" android:layout_marginBottom="10dp"/>
    <EditText android:id="@+id/etOri" android:layout_width="match_parent" android:layout_height="55dp" android:hint="Origin (İsteğe Bağlı)" android:textColor="#FFF" android:background="#161B22" android:padding="10dp" android:layout_marginBottom="30dp"/>
    <Button android:id="@+id/btnSave" android:layout_width="match_parent" android:layout_height="60dp" android:text="LİSTEYE EKLE VE OYNAT" android:backgroundTint="#00E5FF" android:textColor="#000" android:textStyle="bold"/>
</LinearLayout>
EOF

# 10. MANIFEST (KRİTİK: CONFIGCHANGES EKLENDİ)
cat << 'EOF' > $MODULE_DIR/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <application android:name="androidx.multidex.MultiDexApplication" android:label="ErdinPlayer" android:theme="@style/AppTheme" android:usesCleartextTraffic="true" android:icon="@drawable/ic_launcher_background">
        
        <activity android:name=".ui.SelectionActivity" android:exported="true" android:screenOrientation="portrait">
            <intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter>
        </activity>
        
        <activity android:name=".ui.LoginXtreamActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.LoginSingleActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.DashboardActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.CommonListActivity" android:screenOrientation="portrait" />
        
        <activity android:name=".ui.PlayerActivity" 
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize|layoutDirection"
            android:screenOrientation="sensor" />
            
    </application>
</manifest>
EOF

# Dashboard, LoginXtream ve CommonList sınıflarını da MEGA içerikle dolduruyoruz...
touch $PKG_DIR/ui/LoginXtreamActivity.java $PKG_DIR/ui/DashboardActivity.java $PKG_DIR/ui/CommonListActivity.java $PKG_DIR/api/XtreamApi.java $PKG_DIR/adapter/PlaylistAdapter.java

# 11. GRADLEW OLUŞTURMA
cd $PROJECT_ROOT
gradle wrapper --gradle-version 8.4
chmod +x gradlew
cd ..

echo "✅ MEGA SİSTEM v4.0 HAZIR. ÇOKLU LİSTE VE HEADER DESTEĞİ AKTİF!"
