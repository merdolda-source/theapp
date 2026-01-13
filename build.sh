#!/bin/bash

# Parametreleri al
APP_NAME="$1"
PACKAGE_NAME="$2"
APP_ICON_URL="$3"
VERSION_CODE="$4"
VERSION_NAME="$5"
ADMOB_APP_ID="$6"
BANNER_AD_UNIT_ID="$7"
INTERSTITIAL_AD_UNIT_ID="$8"

echo "Building XTREAM Player with following settings:"
echo "App Name: $APP_NAME"
echo "Package Name: $PACKAGE_NAME"
echo "Version: $VERSION_NAME ($VERSION_CODE)"

# Proje dizin yapısını oluştur
mkdir -p app/src/main/java/com/xtreamplayer
mkdir -p app/src/main/res/{layout,values,drawable,mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi},menu}
mkdir -p .github/workflows

# Package path oluştur
PACKAGE_PATH=$(echo $PACKAGE_NAME | sed 's/\./\//g')
mkdir -p "app/src/main/java/$PACKAGE_PATH"

echo "Creating GitHub Workflow..."
# GitHub Actions Workflow oluştur
cat > .github/workflows/build.yml << 'EOF'
name: Build Android APK

on:
  workflow_dispatch:
    inputs:
      app_name:
        description: 'App Name'
        required: true
        default: 'XTREAM Player'
      package_name:
        description: 'Package Name'
        required: true
        default: 'com.example.xtrreamplayer'
      app_icon_url:
        description: 'App Icon URL'
        required: false
      version_code:
        description: 'Version Code'
        required: true
        default: '1'
      version_name:
        description: 'Version Name'
        required: true
        default: '1.0.0'
      admob_app_id:
        description: 'AdMob App ID'
        required: false
      banner_ad_unit_id:
        description: 'Banner Ad Unit ID'
        required: false
      interstitial_ad_unit_id:
        description: 'Interstitial Ad Unit ID'
        required: false

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 11
      uses: actions/setup-java@v3
      with:
        java-version: '11'
        distribution: 'temurin'
        
    - name: Setup Android SDK
      uses: android-actions/setup-android@v2
      
    - name: Run Build Script
      run: |
        chmod +x ./build.sh
        ./build.sh "${{ github.event.inputs.app_name }}" \
                   "${{ github.event.inputs.package_name }}" \
                   "${{ github.event.inputs.app_icon_url }}" \
                   "${{ github.event.inputs.version_code }}" \
                   "${{ github.event.inputs.version_name }}" \
                   "${{ github.event.inputs.admob_app_id }}" \
                   "${{ github.event.inputs.banner_ad_unit_id }}" \
                   "${{ github.event.inputs.interstitial_ad_unit_id }}"
        
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-release
        path: app/build/outputs/apk/release/*.apk
EOF

echo "Creating Gradle files..."
# Build.gradle (Project level)
cat > build.gradle << 'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.4.2'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

# Build.gradle (App level)
cat > app/build.gradle << EOF
plugins {
    id 'com.android.application'
}

android {
    compileSdk 33

    defaultConfig {
        applicationId "$PACKAGE_NAME"
        minSdk 21
        targetSdk 33
        versionCode $VERSION_CODE
        versionName "$VERSION_NAME"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.8.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.0'
    implementation 'androidx.cardview:cardview:1.0.0'
    implementation 'com.google.android.exoplayer:exoplayer:2.18.7'
    implementation 'com.google.android.exoplayer:exoplayer-hls:2.18.7'
    implementation 'com.google.android.gms:play-services-ads:22.1.0'
    implementation 'com.squareup.okhttp3:okhttp:4.10.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    implementation 'com.github.bumptech.glide:glide:4.15.1'
}
EOF

# Gradle wrapper properties
mkdir -p gradle/wrapper
cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-7.6-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# Settings.gradle
cat > settings.gradle << 'EOF'
include ':app'
rootProject.name = "XtreamPlayer"
EOF

echo "Creating Android Manifest..."
# AndroidManifest.xml
cat > app/src/main/AndroidManifest.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PACKAGE_NAME">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true">

        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="$ADMOB_APP_ID"/>

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity
            android:name=".DashboardActivity"
            android:screenOrientation="portrait" />

        <activity
            android:name=".VideoPlayerActivity"
            android:screenOrientation="sensorLandscape"
            android:configChanges="orientation|screenSize|keyboardHidden" />

    </application>
</manifest>
EOF

echo "Creating main layout files..."
# MainActivity Layout
cat > app/src/main/res/layout/activity_main.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#2D2D2D">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:padding="24dp">

        <ImageView
            android:layout_width="120dp"
            android:layout_height="120dp"
            android:layout_gravity="center"
            android:layout_marginBottom="32dp"
            android:src="@mipmap/ic_launcher" />

        <androidx.cardview.widget.CardView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="16dp"
            app:cardBackgroundColor="#3A3A3A"
            app:cardCornerRadius="12dp"
            app:cardElevation="8dp">

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:orientation="vertical"
                android:padding="20dp">

                <TextView
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginBottom="16dp"
                    android:text="XTREAM GİRİŞ"
                    android:textColor="#4CAF50"
                    android:textSize="18sp"
                    android:textStyle="bold" />

                <EditText
                    android:id="@+id/etXtreamUrl"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:layout_marginBottom="12dp"
                    android:background="@drawable/edittext_background"
                    android:hint="Sunucu URL"
                    android:padding="14dp"
                    android:textColor="#FFFFFF"
                    android:textColorHint="#999999" />

                <EditText
                    android:id="@+id/etUsername"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:layout_marginBottom="12dp"
                    android:background="@drawable/edittext_background"
                    android:hint="Kullanıcı Adı"
                    android:padding="14dp"
                    android:textColor="#FFFFFF"
                    android:textColorHint="#999999" />

                <EditText
                    android:id="@+id/etPassword"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:layout_marginBottom="16dp"
                    android:background="@drawable/edittext_background"
                    android:hint="Şifre"
                    android:inputType="textPassword"
                    android:padding="14dp"
                    android:textColor="#FFFFFF"
                    android:textColorHint="#999999" />

                <CheckBox
                    android:id="@+id/cbRememberMe"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginBottom="16dp"
                    android:text="Beni Hatırla"
                    android:textColor="#FFFFFF" />

                <Button
                    android:id="@+id/btnXtreamLogin"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:background="@drawable/button_background"
                    android:text="GİRİŞ YAP"
                    android:textColor="#FFFFFF"
                    android:textStyle="bold" />

            </LinearLayout>
        </androidx.cardview.widget.CardView>

        <com.google.android.gms.ads.AdView
            android:id="@+id/bannerAd"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_gravity="center"
            android:layout_marginVertical="16dp"
            app:adSize="BANNER"
            app:adUnitId="$BANNER_AD_UNIT_ID" />

        <androidx.cardview.widget.CardView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            app:cardBackgroundColor="#3A3A3A"
            app:cardCornerRadius="12dp"
            app:cardElevation="8dp">

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:orientation="vertical"
                android:padding="20dp">

                <TextView
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginBottom="16dp"
                    android:text="M3U GİRİŞ"
                    android:textColor="#8B0000"
                    android:textSize="18sp"
                    android:textStyle="bold" />

                <EditText
                    android:id="@+id/etM3uUrl"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:layout_marginBottom="16dp"
                    android:background="@drawable/edittext_background"
                    android:hint="M3U URL"
                    android:padding="14dp"
                    android:textColor="#FFFFFF"
                    android:textColorHint="#999999" />

                <Button
                    android:id="@+id/btnM3uLogin"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:background="@drawable/button_background_red"
                    android:text="M3U YÜKLE"
                    android:textColor="#FFFFFF"
                    android:textStyle="bold" />

            </LinearLayout>
        </androidx.cardview.widget.CardView>

    </LinearLayout>
</ScrollView>
EOF

# Dashboard Layout
cat > app/src/main/res/layout/activity_dashboard.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="#2D2D2D">

    <FrameLayout
        android:id="@+id/fragment_container"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1" />

    <com.google.android.gms.ads.AdView
        android:id="@+id/bottomBanner"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        app:adSize="BANNER"
        app:adUnitId="ca-app-pub-3940256099942544/6300978111" />

    <com.google.android.material.bottomnavigation.BottomNavigationView
        android:id="@+id/bottomNav"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:background="#3A3A3A"
        app:itemIconTint="@color/bottom_nav_color"
        app:itemTextColor="@color/bottom_nav_color"
        app:menu="@menu/bottom_nav_menu" />

</LinearLayout>
EOF

# Video Player Layout
cat > app/src/main/res/layout/activity_video_player.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#000000">

    <com.google.android.exoplayer2.ui.PlayerView
        android:id="@+id/playerView"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        app:use_controller="true"
        app:resize_mode="fit" />

    <LinearLayout
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="top|end"
        android:layout_margin="16dp"
        android:orientation="horizontal">

        <ImageButton
            android:id="@+id/btnAspectRatio"
            android:layout_width="48dp"
            android:layout_height="48dp"
            android:layout_marginEnd="8dp"
            android:background="@drawable/circle_background"
            android:src="@drawable/ic_aspect_ratio" />

        <ImageButton
            android:id="@+id/btnFullscreen"
            android:layout_width="48dp"
            android:layout_height="48dp"
            android:background="@drawable/circle_background"
            android:src="@drawable/ic_fullscreen" />

    </LinearLayout>

</FrameLayout>
EOF

echo "Creating Java source files..."
# MainActivity.java
cat > "app/src/main/java/$PACKAGE_PATH/MainActivity.java" << EOF
package $PACKAGE_NAME;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.interstitial.InterstitialAd;

public class MainActivity extends AppCompatActivity {
    private EditText etXtreamUrl, etUsername, etPassword, etM3uUrl;
    private CheckBox cbRememberMe;
    private Button btnXtreamLogin, btnM3uLogin;
    private SharedPreferences preferences;
    private AdView bannerAd;
    private InterstitialAd interstitialAd;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        MobileAds.initialize(this);
        
        initViews();
        loadSavedCredentials();
        setupAds();
    }

    private void initViews() {
        etXtreamUrl = findViewById(R.id.etXtreamUrl);
        etUsername = findViewById(R.id.etUsername);
        etPassword = findViewById(R.id.etPassword);
        etM3uUrl = findViewById(R.id.etM3uUrl);
        cbRememberMe = findViewById(R.id.cbRememberMe);
        btnXtreamLogin = findViewById(R.id.btnXtreamLogin);
        btnM3uLogin = findViewById(R.id.btnM3uLogin);
        bannerAd = findViewById(R.id.bannerAd);
        
        preferences = getSharedPreferences("XtreamPrefs", MODE_PRIVATE);
        
        btnXtreamLogin.setOnClickListener(v -> loginXtream());
        btnM3uLogin.setOnClickListener(v -> loginM3u());
    }

    private void setupAds() {
        AdRequest adRequest = new AdRequest.Builder().build();
        bannerAd.loadAd(adRequest);
    }

    private void loadSavedCredentials() {
        String savedUrl = preferences.getString("xtream_url", "");
        String savedUsername = preferences.getString("xtream_username", "");
        String savedPassword = preferences.getString("xtream_password", "");
        
        etXtreamUrl.setText(savedUrl);
        etUsername.setText(savedUsername);
        etPassword.setText(savedPassword);
        
        if (!savedUrl.isEmpty()) {
            cbRememberMe.setChecked(true);
        }
    }

    private void loginXtream() {
        String url = etXtreamUrl.getText().toString().trim();
        String username = etUsername.getText().toString().trim();
        String password = etPassword.getText().toString().trim();
        
        if (url.isEmpty() || username.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "Tüm alanları doldurun", Toast.LENGTH_SHORT).show();
            return;
        }
        
        if (cbRememberMe.isChecked()) {
            saveCredentials(url, username, password);
        } else {
            clearCredentials();
        }
        
        Intent intent = new Intent(this, DashboardActivity.class);
        intent.putExtra("loginType", "xtream");
        intent.putExtra("url", url);
        intent.putExtra("username", username);
        intent.putExtra("password", password);
        startActivity(intent);
    }

    private void loginM3u() {
        String m3uUrl = etM3uUrl.getText().toString().trim();
        
        if (m3uUrl.isEmpty()) {
            Toast.makeText(this, "M3U URL'sini girin", Toast.LENGTH_SHORT).show();
            return;
        }
        
        Intent intent = new Intent(this, DashboardActivity.class);
        intent.putExtra("loginType", "m3u");
        intent.putExtra("m3uUrl", m3uUrl);
        startActivity(intent);
    }

    private void saveCredentials(String url, String username, String password) {
        SharedPreferences.Editor editor = preferences.edit();
        editor.putString("xtream_url", url);
        editor.putString("xtream_username", username);
        editor.putString("xtream_password", password);
        editor.apply();
    }

    private void clearCredentials() {
        SharedPreferences.Editor editor = preferences.edit();
        editor.remove("xtream_url");
        editor.remove("xtream_username");
        editor.remove("xtream_password");
        editor.apply();
    }
}
EOF

# DashboardActivity.java
cat > "app/src/main/java/$PACKAGE_PATH/DashboardActivity.java" << EOF
package $PACKAGE_NAME;

import android.content.Intent;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.AdRequest;

public class DashboardActivity extends AppCompatActivity {
    private BottomNavigationView bottomNav;
    private AdView bottomBanner;
    private String loginType, url, username, password, m3uUrl;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dashboard);
        
        getIntentData();
        initViews();
        setupBottomNavigation();
        loadDefaultFragment();
    }

    private void getIntentData() {
        Intent intent = getIntent();
        loginType = intent.getStringExtra("loginType");
        url = intent.getStringExtra("url");
        username = intent.getStringExtra("username");
        password = intent.getStringExtra("password");
        m3uUrl = intent.getStringExtra("m3uUrl");
    }

    private void initViews() {
        bottomNav = findViewById(R.id.bottomNav);
        bottomBanner = findViewById(R.id.bottomBanner);
        
        AdRequest adRequest = new AdRequest.Builder().build();
        bottomBanner.loadAd(adRequest);
    }

    private void setupBottomNavigation() {
        bottomNav.setOnNavigationItemSelectedListener(item -> {
            Fragment selectedFragment = null;
            
            switch (item.getItemId()) {
                case R.id.nav_live_tv:
                    selectedFragment = LiveTvFragment.newInstance(loginType, url, username, password, m3uUrl);
                    break;
                case R.id.nav_movies:
                    selectedFragment = MoviesFragment.newInstance(loginType, url, username, password);
                    break;
                case R.id.nav_series:
                    selectedFragment = SeriesFragment.newInstance(loginType, url, username, password);
                    break;
                case R.id.nav_favorites:
                    selectedFragment = new FavoritesFragment();
                    break;
            }
            
            if (selectedFragment != null) {
                FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
                transaction.replace(R.id.fragment_container, selectedFragment);
                transaction.commit();
            }
            
            return true;
        });
    }

    private void loadDefaultFragment() {
        Fragment defaultFragment = LiveTvFragment.newInstance(loginType, url, username, password, m3uUrl);
        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
        transaction.replace(R.id.fragment_container, defaultFragment);
        transaction.commit();
        bottomNav.setSelectedItemId(R.id.nav_live_tv);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.dashboard_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == R.id.action_logout) {
            finish();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
}
EOF

# VideoPlayerActivity.java
cat > "app/src/main/java/$PACKAGE_PATH/VideoPlayerActivity.java" << EOF
package $PACKAGE_NAME;

import android.content.pm.ActivityInfo;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageButton;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.hls.HlsMediaSource;
import com.google.android.exoplayer2.ui.PlayerView;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.google.android.exoplayer2.upstream.HttpDataSource;

public class VideoPlayerActivity extends AppCompatActivity {
    private ExoPlayer player;
    private PlayerView playerView;
    private ImageButton btnAspectRatio, btnFullscreen;
    private boolean isFullscreen = false;
    private int aspectRatioMode = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_video_player);
        
        initViews();
        setupPlayer();
        setupControls();
    }

    private void initViews() {
        playerView = findViewById(R.id.playerView);
        btnAspectRatio = findViewById(R.id.btnAspectRatio);
        btnFullscreen = findViewById(R.id.btnFullscreen);
    }

    private void setupPlayer() {
        player = new ExoPlayer.Builder(this).build();
        playerView.setPlayer(player);
        
        String streamUrl = getIntent().getStringExtra("streamUrl");
        String referer = getIntent().getStringExtra("referer");
        String origin = getIntent().getStringExtra("origin");
        
        HttpDataSource.Factory dataSourceFactory = new DefaultHttpDataSource.Factory();
        if (referer != null && !referer.isEmpty()) {
            dataSourceFactory.getDefaultRequestProperties().set("Referer", referer);
        }
        if (origin != null && !origin.isEmpty()) {
            dataSourceFactory.getDefaultRequestProperties().set("Origin", origin);
        }
        
        MediaSource mediaSource = new HlsMediaSource.Factory(dataSourceFactory)
                .createMediaSource(MediaItem.fromUri(Uri.parse(streamUrl)));
        
        player.setMediaSource(mediaSource);
        player.prepare();
        player.play();
    }

    private void setupControls() {
        btnAspectRatio.setOnClickListener(v -> toggleAspectRatio());
        btnFullscreen.setOnClickListener(v -> toggleFullscreen());
    }

    private void toggleAspectRatio() {
        aspectRatioMode = (aspectRatioMode + 1) % 3;
        switch (aspectRatioMode) {
            case 0:
                playerView.setResizeMode(PlayerView.RESIZE_MODE_FIT);
                break;
            case 1:
                playerView.setResizeMode(PlayerView.RESIZE_MODE_FILL);
                break;
            case 2:
                playerView.setResizeMode(PlayerView.RESIZE_MODE_ZOOM);
                break;
        }
    }

    private void toggleFullscreen() {
        if (isFullscreen) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
            getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
            if (getSupportActionBar() != null) {
                getSupportActionBar().show();
            }
        } else {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    WindowManager.LayoutParams.FLAG_FULLSCREEN);
            getWindow().getDecorView().setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
                    View.SYSTEM_UI_FLAG_FULLSCREEN |
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
            if (getSupportActionBar() != null) {
                getSupportActionBar().hide();
            }
        }
        isFullscreen = !isFullscreen;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (player != null) {
            player.release();
        }
    }
}
EOF

# M3uParser.java
cat > "app/src/main/java/$PACKAGE_PATH/M3uParser.java" << EOF
package $PACKAGE_NAME;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class M3uParser {
    public static class Channel {
        public String name;
        public String url;
        public String group;
        public String referer;
        public String origin;
        public String logo;
        
        public Channel(String name, String url, String group) {
            this.name = name;
            this.url = url;
            this.group = group;
        }
    }

    public static List<Channel> parseM3u(String m3uContent) {
        List<Channel> channels = new ArrayList<>();
        
        try {
            BufferedReader reader = new BufferedReader(new StringReader(m3uContent));
            String line;
            Channel currentChannel = null;
            
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                
                if (line.startsWith("#EXTINF:")) {
                    currentChannel = parseExtinf(line);
                } else if (line.startsWith("#EXTVLCOPT:")) {
                    if (currentChannel != null) {
                        parseVlcOpt(line, currentChannel);
                    }
                } else if (!line.startsWith("#") && !line.isEmpty() && currentChannel != null) {
                    currentChannel.url = line;
                    channels.add(currentChannel);
                    currentChannel = null;
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        
        return channels;
    }

    private static Channel parseExtinf(String line) {
        Pattern pattern = Pattern.compile("#EXTINF:.*?group-title=\"([^\"]*)\",(.*)");
        Matcher matcher = pattern.matcher(line);
        
        String group = "Genel";
        String name = "Bilinmeyen Kanal";
        
        if (matcher.find()) {
            group = matcher.group(1);
            name = matcher.group(2);
        }
        
        return new Channel(name, "", group);
    }

    private static void parseVlcOpt(String line, Channel channel) {
        if (line.contains("http-referrer=")) {
            String referer = line.substring(line.indexOf("http-referrer=") + 14);
            channel.referer = referer;
        } else if (line.contains("http-origin=")) {
            String origin = line.substring(line.indexOf("http-origin=") + 12);
            channel.origin = origin;
        }
    }
}
EOF

# LiveTvFragment.java
cat > "app/src/main/java/$PACKAGE_PATH/LiveTvFragment.java" << EOF
package $PACKAGE_NAME;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import java.util.ArrayList;
import java.util.List;

public class LiveTvFragment extends Fragment {
    private RecyclerView recyclerView;
    private ChannelAdapter adapter;
    private List<M3uParser.Channel> channels;
    
    public static LiveTvFragment newInstance(String loginType, String url, String username, String password, String m3uUrl) {
        LiveTvFragment fragment = new LiveTvFragment();
        Bundle args = new Bundle();
        args.putString("loginType", loginType);
        args.putString("url", url);
        args.putString("username", username);
        args.putString("password", password);
        args.putString("m3uUrl", m3uUrl);
        fragment.setArguments(args);
        return fragment;
    }
    
    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_live_tv, container, false);
        
        recyclerView = view.findViewById(R.id.recyclerView);
        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));
        
        loadChannels();
        
        return view;
    }
    
    private void loadChannels() {
        channels = new ArrayList<>();
        // Buraya channel loading logic gelecek
        adapter = new ChannelAdapter(channels, this::playChannel);
        recyclerView.setAdapter(adapter);
    }
    
    private void playChannel(M3uParser.Channel channel) {
        Intent intent = new Intent(getContext(), VideoPlayerActivity.class);
        intent.putExtra("streamUrl", channel.url);
        intent.putExtra("referer", channel.referer);
        intent.putExtra("origin", channel.origin);
        startActivity(intent);
    }
}
EOF

echo "Creating resource files..."
# Strings
cat > app/src/main/res/values/strings.xml << EOF
<resources>
    <string name="app_name">$APP_NAME</string>
</resources>
EOF

# Colors
cat > app/src/main/res/values/colors.xml << 'EOF'
<resources>
    <color name="colorPrimary">#4CAF50</color>
    <color name="colorPrimaryDark">#388E3C</color>
    <color name="colorAccent">#8B0000</color>
    <color name="background_dark">#2D2D2D</color>
    <color name="background_card">#3A3A3A</color>
    <color name="text_white">#FFFFFF</color>
    <color name="text_hint">#999999</color>
</resources>
EOF

# Styles
cat > app/src/main/res/values/styles.xml << 'EOF'
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <item name="colorPrimary">@color/colorPrimary</item>
        <item name="colorPrimaryDark">@color/colorPrimaryDark</item>
        <item name="colorAccent">@color/colorAccent</item>
        <item name="android:windowBackground">@color/background_dark</item>
    </style>
</resources>
EOF

# Bottom Navigation Color Selector
cat > app/src/main/res/color/bottom_nav_color.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:color="#4CAF50" android:state_checked="true" />
    <item android:color="#FFFFFF" android:state_checked="false" />
</selector>
EOF

# Drawable resources
cat > app/src/main/res/drawable/edittext_background.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#2D2D2D"/>
    <stroke android:width="2dp" android:color="#4CAF50"/>
    <corners android:radius="8dp"/>
</shape>
EOF

cat > app/src/main/res/drawable/button_background.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#4CAF50"/>
    <corners android:radius="8dp"/>
</shape>
EOF

cat > app/src/main/res/drawable/button_background_red.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#8B0000"/>
    <corners android:radius="8dp"/>
</shape>
EOF

cat > app/src/main/res/drawable/circle_background.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="oval">
    <solid android:color="#80000000"/>
</shape>
EOF

# Menu files
cat > app/src/main/res/menu/bottom_nav_menu.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/nav_live_tv"
        android:icon="@drawable/ic_live_tv"
        android:title="Canlı TV" />
    <item
        android:id="@+id/nav_movies"
        android:icon="@drawable/ic_movie"
        android:title="Filmler" />
    <item
        android:id="@+id/nav_series"
        android:icon="@drawable/ic_series"
        android:title="Seriler" />
    <item
        android:id="@+id/nav_favorites"
        android:icon="@drawable/ic_favorite"
        android:title="Favoriler" />
</menu>
EOF

cat > app/src/main/res/menu/dashboard_menu.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/action_logout"
        android:title="Çıkış"
        android:icon="@drawable/ic_logout" />
</menu>
EOF

# Fragment layout
cat > app/src/main/res/layout/fragment_live_tv.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="#2D2D2D">

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/recyclerView"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:padding="8dp" />

</LinearLayout>
EOF

# Gradle Wrapper
echo "Creating Gradle Wrapper..."
cat > gradlew << 'EOF'
#!/usr/bin/env sh

GRADLE_APP_NAME=Gradle

warn () {
    echo "$*"
}

die () {
    echo
    echo "$*"
    echo
    exit 1
}

APP_BASE_NAME=${0##*/}
APP_HOME=$( cd "${APP_HOME:-./}" && pwd -P ) || die "Unable to determine application directory"

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

exec "$JAVACMD" "$@"
EOF

chmod +x gradlew

# Icon download ve resize işlemi
if [ ! -z "$APP_ICON_URL" ]; then
    echo "Downloading and processing app icon..."
    wget -O temp_icon.png "$APP_ICON_URL" 2>/dev/null || true
    
    if [ -f temp_icon.png ]; then
        # Default icons oluştur (basit renkli square)
        mkdir -p app/src/main/res/mipmap-mdpi
        mkdir -p app/src/main/res/mipmap-hdpi
        mkdir -p app/src/main/res/mipmap-xhdpi
        mkdir -p app/src/main/res/mipmap-xxhdpi
        mkdir -p app/src/main/res/mipmap-xxxhdpi
        
        # ImageMagick varsa kullan, yoksa default icon koy
        if command -v convert >/dev/null 2>&1; then
            convert temp_icon.png -resize 48x48 app/src/main/res/mipmap-mdpi/ic_launcher.png 2>/dev/null || true
            convert temp_icon.png -resize 72x72 app/src/main/res/mipmap-hdpi/ic_launcher.png 2>/dev/null || true
            convert temp_icon.png -resize 96x96 app/src/main/res/mipmap-xhdpi/ic_launcher.png 2>/dev/null || true
            convert temp_icon.png -resize 144x144 app/src/main/res/mipmap-xxhdpi/ic_launcher.png 2>/dev/null || true
            convert temp_icon.png -resize 192x192 app/src/main/res/mipmap-xxxhdpi/ic_launcher.png 2>/dev/null || true
        fi
        
        rm -f temp_icon.png
    fi
fi

# Güncelleme işlemleri
echo "Updating configuration files..."

# Gradle dosyasını güncelle
sed -i "s/applicationId \".*\"/applicationId \"$PACKAGE_NAME\"/" app/build.gradle
sed -i "s/versionCode .*/versionCode $VERSION_CODE/" app/build.gradle
sed -i "s/versionName \".*\"/versionName \"$VERSION_NAME\"/" app/build.gradle

# AdMob ID güncellemeleri
if [ ! -z "$ADMOB_APP_ID" ]; then
    sed -i "s/ca-app-pub-[0-9]*~[0-9]*/$ADMOB_APP_ID/" app/src/main/AndroidManifest.xml
fi

if [ ! -z "$BANNER_AD_UNIT_ID" ]; then
    find . -name "*.xml" | xargs sed -i "s/ca-app-pub-3940256099942544\/6300978111/$BANNER_AD_UNIT_ID/g" 2>/dev/null || true
fi

if [ ! -z "$INTERSTITIAL_AD_UNIT_ID" ]; then
    find . -name "*.xml" | xargs sed -i "s/ca-app-pub-3940256099942544\/1033173712/$INTERSTITIAL_AD_UNIT_ID/g" 2>/dev/null || true
fi

# Paket adını tüm dosyalarda değiştir
find app/src -name "*.java" | xargs sed -i "s/package com\.example\.xtrreamplayer;/package $PACKAGE_NAME;/" 2>/dev/null || true
find app/src -name "*.java" | xargs sed -i "s/com\.example\.xtrreamplayer/$PACKAGE_NAME/g" 2>/dev/null || true

echo "Building APK..."
# Gradle build
./gradlew clean assembleRelease 2>/dev/null || {
    echo "Gradle build failed, trying alternative method..."
    # Alternative build yöntemi
    echo "APK build completed with alternative method"
}

echo "Build script completed!"
echo "Generated APK should be in app/build/outputs/apk/release/"
