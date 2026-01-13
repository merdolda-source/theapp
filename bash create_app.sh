#!/bin/bash

# --- AYARLAR ---
APP_NAME="ErdinPlayer"
PACKAGE_NAME="com.erdin.player"
PATH_NAME="com/erdin/player"
KEYSTORE_PASS="erdin123" # İmza şifresi (Otomatik girilecek)
KEY_ALIAS="key0"

echo "🚀 Proje ve İmza Dosyaları Hazırlanıyor: $APP_NAME..."

mkdir -p $APP_NAME/app/src/main/java/$PATH_NAME
mkdir -p $APP_NAME/app/src/main/res/layout
mkdir -p $APP_NAME/app/src/main/res/values
mkdir -p $APP_NAME/.github/workflows # GitHub Action klasörü

cd $APP_NAME

# 1. SAHTE İMZA OLUŞTURMA (KEYSTORE)
echo "🔐 Keystore (İmza) oluşturuluyor..."
keytool -genkey -v -keystore app/keystore.jks \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -alias $KEY_ALIAS -storepass $KEYSTORE_PASS -keypass $KEYSTORE_PASS \
        -dname "CN=Erdin, OU=TV, O=ErdinMedia, L=Istanbul, S=Istanbul, C=TR"

# 2. Build Gradle (Project Level)
cat <<EOF > build.gradle
buildscript {
    ext.kotlin_version = '1.8.0'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.0.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:\$kotlin_version"
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

# 3. Build Gradle (Module: App) - İMZA AYARLARI EKLENDİ
cat <<EOF > app/build.gradle
plugins {
    id 'com.android.application'
    id 'kotlin-android'
}

android {
    namespace '$PACKAGE_NAME'
    compileSdk 33

    defaultConfig {
        applicationId "$PACKAGE_NAME"
        minSdk 24
        targetSdk 33
        versionCode 1
        versionName "1.0"
    }

    signingConfigs {
        release {
            storeFile file("keystore.jks")
            storePassword "$KEYSTORE_PASS"
            keyAlias "$KEY_ALIAS"
            keyPassword "$KEYSTORE_PASS"
        }
    }

    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
    }
    
    buildFeatures {
        viewBinding true
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.7.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'androidx.media3:media3-exoplayer:1.1.0'
    implementation 'androidx.media3:media3-ui:1.1.0'
    implementation 'com.google.android.gms:play-services-ads:22.1.0'
}
EOF

# 4. Android Manifest
cat <<EOF > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar"
        android:usesCleartextTraffic="true">

        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713"/>

        <activity android:name=".LoginActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        
        <activity android:name=".PlayerActivity" />
    </application>
</manifest>
EOF

# 5. Strings
cat <<EOF > app/src/main/res/values/strings.xml
<resources>
    <string name="app_name">$APP_NAME</string>
    <string name="login">Giriş Yap</string>
    <string name="url_hint">http://url:port</string>
    <string name="user_hint">Kullanıcı Adı</string>
    <string name="pass_hint">Şifre</string>
</resources>
EOF

# 6. Login Activity
cat <<EOF > app/src/main/java/$PATH_NAME/LoginActivity.kt
package $PACKAGE_NAME

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.MobileAds

class LoginActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)

        MobileAds.initialize(this) {}
        val mAdView = findViewById<AdView>(R.id.adView)
        val adRequest = AdRequest.Builder().build()
        mAdView.loadAd(adRequest)

        val btnLogin = findViewById<Button>(R.id.btnLogin)
        val etUrl = findViewById<EditText>(R.id.etUrl)
        val etUser = findViewById<EditText>(R.id.etUser)
        val etPass = findViewById<EditText>(R.id.etPass)

        btnLogin.setOnClickListener {
            val url = etUrl.text.toString()
            if(url.isNotEmpty()){
                val intent = Intent(this, PlayerActivity::class.java)
                intent.putExtra("stream_url", "\$url") 
                startActivity(intent)
            } else {
                Toast.makeText(this, "Bilgileri giriniz", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
EOF

# 7. Login Layout
cat <<EOF > app/src/main/res/layout/activity_login.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:ads="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="20dp"
    android:gravity="center">

    <EditText android:id="@+id/etUrl" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="@string/url_hint"/>
    <EditText android:id="@+id/etUser" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="@string/user_hint"/>
    <EditText android:id="@+id/etPass" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="@string/pass_hint" android:inputType="textPassword"/>
    <Button android:id="@+id/btnLogin" android:layout_width="match_parent" android:layout_height="wrap_content" android:text="@string/login" android:layout_marginTop="20dp"/>
    
    <com.google.android.gms.ads.AdView
        android:id="@+id/adView"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="50dp"
        ads:adSize="BANNER"
        ads:adUnitId="ca-app-pub-3940256099942544/6300978111"/> 
</LinearLayout>
EOF

# 8. Player Activity
cat <<EOF > app/src/main/java/$PATH_NAME/PlayerActivity.kt
package $PACKAGE_NAME

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView

class PlayerActivity : AppCompatActivity() {
    private var player: ExoPlayer? = null
    private lateinit var playerView: PlayerView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_player)
        playerView = findViewById(R.id.player_view)
        val streamUrl = intent.getStringExtra("stream_url") ?: ""
        initializePlayer(streamUrl)
    }

    private fun initializePlayer(url: String) {
        player = ExoPlayer.Builder(this).build()
        playerView.player = player
        val mediaItem = MediaItem.fromUri(url)
        player!!.setMediaItem(mediaItem)
        player!!.prepare()
        player!!.play()
    }
    
    override fun onStop() {
        super.onStop()
        player?.release()
        player = null
    }
}
EOF

# 9. Player Layout
cat <<EOF > app/src/main/res/layout/activity_player.xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#000000">
    <androidx.media3.ui.PlayerView
        android:id="@+id/player_view"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</FrameLayout>
EOF

echo "✅ Proje Hazır! Keystore oluşturuldu."
