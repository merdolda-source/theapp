#!/bin/bash

# Renkler
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 XTRE PLAYER - OTOMATİK KURULUM BAŞLIYOR...${NC}"

# 1. Klasör Yapısı
PROJECT_NAME="ErdinXtream"
PACKAGE_DIR="app/src/main/java/com/erdin/xplayer"
RES_DIR="app/src/main/res"
SERVER_DIR="SERVER_PANEL"

mkdir -p $PROJECT_NAME/$PACKAGE_DIR
mkdir -p $PROJECT_NAME/$RES_DIR/layout
mkdir -p $PROJECT_NAME/$RES_DIR/values
mkdir -p $PROJECT_NAME/$RES_DIR/drawable
mkdir -p $PROJECT_NAME/app/src/main/assets
mkdir -p $PROJECT_NAME/.github/workflows
mkdir -p $PROJECT_NAME/gradle/wrapper
mkdir -p $SERVER_DIR

cd $PROJECT_NAME

# ==========================================
# BÖLÜM 1: ANDROID BUILD SİSTEMİ (GRADLE & YML)
# ==========================================

echo -e "📦 Gradle ve YML dosyaları oluşturuluyor..."

# 1.1 build.gradle (Proje)
cat << 'EOF' > build.gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.0.0"
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://maven.google.com' }
    }
}
task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

# 1.2 settings.gradle
echo "include ':app'" > settings.gradle

# 1.3 app/build.gradle (AdMob + Unity Ads)
cat << 'EOF' > app/build.gradle
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.erdin.xplayer'
    compileSdk 33

    defaultConfig {
        applicationId "com.erdin.xplayer"
        minSdk 24
        targetSdk 33
        versionCode 1
        versionName "1.0"
    }
    buildFeatures {
        viewBinding true
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'com.squareup.okhttp3:okhttp:4.9.3'
    
    // REKLAM AĞLARI
    implementation 'com.google.android.gms:play-services-ads:22.1.0' // AdMob
    implementation 'com.unity3d.ads:unity-ads:4.7.1' // Unity Ads
}
EOF

# 1.4 GitHub Action YML (Otomatik Build)
cat << 'EOF' > .github/workflows/android.yml
name: Android Build APK

on:
  push:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
        cache: gradle

    - name: Grant execute permission for gradlew
      run: chmod +x gradlew

    - name: Build with Gradle
      run: ./gradlew assembleDebug

    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-debug
        path: app/build/outputs/apk/debug/app-debug.apk
EOF

# ==========================================
# BÖLÜM 2: JAVA KODLARI (REKLAM MANTIĞI)
# ==========================================

echo -e "☕ Java ve Reklam mantığı kodlanıyor..."

# 2.1 AndroidManifest.xml
cat << 'EOF' > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:label="ERDİNXTREAM"
        android:theme="@style/Theme.AppCompat.NoActionBar"
        android:usesCleartextTraffic="true">
        
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713"/>

        <activity android:name=".MainActivity"
            android:exported="true"
            android:configChanges="orientation|screenSize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# 2.2 MainActivity.java (HYBRID AD MANAGER)
cat << 'EOF' > app/src/main/java/com/erdin/xplayer/MainActivity.java
package com.erdin.xplayer;

import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.appcompat.app.AppCompatActivity;

// AdMob
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;

// Unity Ads
import com.unity3d.ads.IUnityAdsInitializationListener;
import com.unity3d.ads.UnityAds;
import com.unity3d.ads.IUnityAdsLoadListener;
import com.unity3d.ads.IUnityAdsShowListener;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import org.json.JSONObject;

public class MainActivity extends AppCompatActivity {

    private WebView webView;
    private InterstitialAd mAdMobInterstitial;
    
    // --- BURAYI KENDİ HOSTING ADRESİNLE DEĞİŞTİR ---
    private String API_URL = "http://seninsiten.com/api.php";
    
    // Config Variables
    private boolean adsEnabled = false;
    private String activeNetwork = "admob"; // admob, unity, hybrid
    private String admobInterId = "";
    private String unityGameId = "";
    private String unityPlacementId = "";
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        webView = findViewById(R.id.webview);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        webView.setWebViewClient(new WebViewClient());
        
        // Load Local Interface
        webView.loadUrl("file:///android_asset/index.html");

        // Fetch Server Config
        fetchConfig();
    }

    private void fetchConfig() {
        new Thread(() -> {
            try {
                OkHttpClient client = new OkHttpClient();
                Request request = new Request.Builder().url(API_URL).build();
                Response response = client.newCall(request).execute();
                
                if (response.isSuccessful()) {
                    JSONObject json = new JSONObject(response.body().string());
                    
                    adsEnabled = json.getBoolean("ads_status");
                    activeNetwork = json.getString("active_network");
                    
                    // AdMob Data
                    admobInterId = json.getJSONObject("admob").getString("interstitial");
                    
                    // Unity Data
                    unityGameId = json.getJSONObject("unity").getString("game_id");
                    unityPlacementId = json.getJSONObject("unity").getString("placement_id");
                    
                    if(adsEnabled) {
                        runOnUiThread(this::initializeAds);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }).start();
    }

    private void initializeAds() {
        // Init AdMob
        MobileAds.initialize(this, status -> {});
        
        // Init Unity
        if(!unityGameId.isEmpty()) {
            UnityAds.initialize(getApplicationContext(), unityGameId, false, new IUnityAdsInitializationListener() {
                @Override
                public void onInitializationComplete() { Log.d("Unity", "Init Complete"); }
                @Override
                public void onInitializationFailed(UnityAds.UnityAdsInitializationError error, String message) {}
            });
        }
        
        // Load Initial Ad
        loadInterstitial();
        
        // Show Ad Loop (Her 2 dakikada bir reklam tetikler - Örnek)
        new Handler().postDelayed(this::showInterstitial, 120000); 
    }

    private void loadInterstitial() {
        if (activeNetwork.equals("admob") || activeNetwork.equals("hybrid")) {
            AdRequest adRequest = new AdRequest.Builder().build();
            InterstitialAd.load(this, admobInterId, adRequest, new InterstitialAdLoadCallback() {
                @Override
                public void onAdLoaded(InterstitialAd interstitialAd) {
                    mAdMobInterstitial = interstitialAd;
                }
                @Override
                public void onAdFailedToLoad(LoadAdError loadAdError) {
                    mAdMobInterstitial = null;
                }
            });
        }
        
        if (activeNetwork.equals("unity") || activeNetwork.equals("hybrid")) {
            UnityAds.load(unityPlacementId, new IUnityAdsLoadListener() {
                @Override
                public void onUnityAdsAdLoaded(String placementId) {}
                @Override
                public void onUnityAdsFailedToLoad(String placementId, UnityAds.UnityAdsLoadError error, String message) {}
            });
        }
    }

    private void showInterstitial() {
        if (!adsEnabled) return;

        // ADMOB GÖSTER
        if (activeNetwork.equals("admob") && mAdMobInterstitial != null) {
            mAdMobInterstitial.show(this);
            mAdMobInterstitial = null;
            loadInterstitial(); // Yenisini yükle
        }
        // UNITY GÖSTER
        else if (activeNetwork.equals("unity")) {
            UnityAds.show(this, unityPlacementId, new IUnityAdsShowListener() {
                @Override public void onUnityAdsShowFailure(String placementId, UnityAds.UnityAdsShowError error, String message) {}
                @Override public void onUnityAdsShowStart(String placementId) {}
                @Override public void onUnityAdsShowClick(String placementId) {}
                @Override public void onUnityAdsShowComplete(String placementId, UnityAds.UnityAdsShowCompletionState state) { loadInterstitial(); }
            });
        }
        // HYBRID (Rastgele)
        else if (activeNetwork.equals("hybrid")) {
             if (Math.random() > 0.5 && mAdMobInterstitial != null) {
                 mAdMobInterstitial.show(this);
                 loadInterstitial();
             } else {
                 UnityAds.show(this, unityPlacementId, null);
             }
        }
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }
}
EOF

# 2.3 Layout XML
cat << 'EOF' > app/src/main/res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#000">
    <WebView
        android:id="@+id/webview"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</RelativeLayout>
EOF

# 2.4 WEB ARAYÜZÜ (Xtream Login & Player)
cat << 'EOF' > app/src/main/assets/index.html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Xtream Shell</title>
<style>
  body { background-color: #0d0d0d; color: #fff; font-family: sans-serif; text-align: center; margin-top: 50px; }
  input { background: #333; border: 1px solid #555; padding: 10px; width: 80%; color: white; margin: 5px; border-radius: 5px; }
  button { background: #e50914; border: none; padding: 12px; width: 85%; color: white; font-weight: bold; border-radius: 5px; margin-top: 10px; }
  .hidden { display: none; }
</style>
</head>
<body>
  <div id="login">
      <h2>ERDİNXTREAM</h2>
      <input type="text" id="dns" placeholder="http://url:port">
      <input type="text" id="user" placeholder="Username">
      <input type="password" id="pass" placeholder="Password">
      <button onclick="login()">GİRİŞ</button>
  </div>
  <div id="main" class="hidden">
      <h3>HOŞGELDİNİZ</h3>
      <button onclick="alert('Canlı TV Yükleniyor...')">CANLI TV</button>
      <button onclick="alert('Filmler Yükleniyor...')">FİLMLER</button>
      <button onclick="alert('Diziler Yükleniyor...')">DİZİLER</button>
  </div>
  <script>
      function login() {
          // Basit JS Login Simülasyonu
          document.getElementById('login').classList.add('hidden');
          document.getElementById('main').classList.remove('hidden');
      }
  </script>
</body>
</html>
EOF

# ==========================================
# BÖLÜM 3: SERVER DOSYALARI (PANEL & API)
# ==========================================

cd ../$SERVER_DIR
echo -e "📡 Server Admin Paneli oluşturuluyor..."

# 3.1 config.json (Veritabanı)
cat << 'EOF' > config.json
{
    "ads_status": true,
    "active_network": "admob",
    "admob": {
        "interstitial": "ca-app-pub-3940256099942544/1033173712"
    },
    "unity": {
        "game_id": "1234567",
        "placement_id": "video"
    }
}
EOF

# 3.2 api.php (Android Burayı Okur)
cat << 'EOF' > api.php
<?php
header('Content-Type: application/json');
echo file_get_contents('config.json');
?>
EOF

# 3.3 admin.php (Yönetim Paneli)
cat << 'EOF' > admin.php
<?php
if(isset($_POST['save'])){
    $newConfig = [
        "ads_status" => isset($_POST['ads_status']),
        "active_network" => $_POST['active_network'],
        "admob" => ["interstitial" => $_POST['admob_id']],
        "unity" => ["game_id" => $_POST['unity_id'], "placement_id" => $_POST['unity_place']]
    ];
    file_put_contents('config.json', json_encode($newConfig, JSON_PRETTY_PRINT));
    echo "<div style='background:green;color:white;padding:10px'>AYARLAR KAYDEDİLDİ!</div>";
}
$data = json_decode(file_get_contents('config.json'), true);
?>
<html>
<body style="background:#222; color:white; font-family:sans-serif; padding:20px;">
    <h2>REKLAM YÖNETİM PANELİ</h2>
    <form method="POST">
        <label>REKLAMLAR AÇIK MI?</label>
        <input type="checkbox" name="ads_status" <?php echo $data['ads_status'] ? 'checked' : ''; ?>><br><br>
        
        <label>AKTİF AĞ:</label>
        <select name="active_network" style="padding:5px;">
            <option value="admob" <?php echo $data['active_network']=='admob'?'selected':''; ?>>Sadece AdMob</option>
            <option value="unity" <?php echo $data['active_network']=='unity'?'selected':''; ?>>Sadece Unity Ads</option>
            <option value="hybrid" <?php echo $data['active_network']=='hybrid'?'selected':''; ?>>HYBRID (Karışık)</option>
        </select><br><br>
        
        <fieldset style="border:1px solid #E50914; padding:10px;">
            <legend style="color:#E50914">AdMob Ayarları</legend>
            Inter ID: <input type="text" name="admob_id" value="<?php echo $data['admob']['interstitial']; ?>" style="width:300px;">
        </fieldset><br>
        
        <fieldset style="border:1px solid #0000FF; padding:10px;">
            <legend style="color:#0000FF">Unity Ads Ayarları</legend>
            Game ID: <input type="text" name="unity_id" value="<?php echo $data['unity']['game_id']; ?>"><br>
            Placement ID: <input type="text" name="unity_place" value="<?php echo $data['unity']['placement_id']; ?>">
        </fieldset><br>
        
        <button type="submit" name="save" style="background:green; color:white; padding:10px 20px; border:none; cursor:pointer;">KAYDET VE GÜNCELLE</button>
    </form>
</body>
</html>
EOF

echo -e "${GREEN}✅ KURULUM TAMAMLANDI!${NC}"
echo -e "📂 Proje Klasörü: ${RED}ErdinXtream${NC}"
echo -e "📂 Panel Klasörü: ${RED}SERVER_PANEL${NC} (Bu dosyaları hostuna at)"
echo -e "👉 Android Studio'yu aç ve 'ErdinXtream' klasörünü seç."
echo -e "👉 MainActivity.java içindeki 'API_URL' kısmını kendi site adresinle değiştirmeyi unutma!"
