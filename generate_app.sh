#!/bin/bash

# --- AYARLAR ---
BACKEND_URL="http://senin-site-adresin.com/backend"

PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_DIR="$MODULE_DIR/src/main/java/com/merdolda/player"
RES_DIR="$MODULE_DIR/src/main/res"

echo "🚀 ERDINPLAYER (GRADLE FIX) OLUŞTURULUYOR..."

# 1. Temizlik
rm -rf $PROJECT_ROOT
mkdir -p $PKG_DIR
mkdir -p $RES_DIR/layout
mkdir -p $RES_DIR/values
mkdir -p $RES_DIR/drawable
mkdir -p $RES_DIR/mipmap-anydpi-v26
# Wrapper klasörünü oluştur (ÖNEMLİ)
mkdir -p $PROJECT_ROOT/gradle/wrapper

# 2. GRADLE WRAPPER PROPERTIES (BU, SİSTEMİ GRADLE 8.2 KULLANMAYA ZORLAR)
cat << 'EOF' > $PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# 3. SETTINGS.GRADLE
cat << 'EOF' > $PROJECT_ROOT/settings.gradle
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
rootProject.name = "ErdinPlayer"
include ':app'
EOF

# 4. GRADLE.PROPERTIES
cat << 'EOF' > $PROJECT_ROOT/gradle.properties
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
EOF

# 5. BUILD.GRADLE (PROJECT)
cat << 'EOF' > $PROJECT_ROOT/build.gradle
plugins {
    id 'com.android.application' version '8.2.0' apply false
}
EOF

# 6. BUILD.GRADLE (APP - GÜNCELLENMİŞ SÖZDİZİMİ)
cat << 'EOF' > $MODULE_DIR/build.gradle
plugins {
    id 'com.android.application'
}

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

    buildTypes {
        release {
            minifyEnabled false
            shrinkResources false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    // YENİ DSL YAPISI (Gradle 8+ Uyumlu)
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
    
    packaging {
        resources {
            excludes += '/META-INF/{AL2.0,LGPL2.1}'
        }
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.github.bumptech.glide:glide:4.16.0'
}
EOF

# 7. XML DOSYALARI
cat << 'EOF' > $RES_DIR/values/strings.xml
<resources>
    <string name="app_name">ErdinPlayer</string>
</resources>
EOF

cat << 'EOF' > $RES_DIR/values/themes.xml
<resources>
    <style name="Theme.ErdinPlayer" parent="Theme.AppCompat.NoActionBar">
        <item name="colorPrimary">#E50914</item>
        <item name="colorPrimaryDark">#B81D24</item>
        <item name="colorAccent">#E50914</item>
    </style>
</resources>
EOF

cat << 'EOF' > $RES_DIR/values/colors.xml
<resources>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
</resources>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_launcher_background.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#000000" android:pathData="M0,0h108v108h-108z"/>
</vector>
EOF

# 8. MANIFEST
cat << 'EOF' > $MODULE_DIR/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-feature android:name="android.software.leanback" android:required="false" />
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />

    <application
        android:name="androidx.multidex.MultiDexApplication"
        android:allowBackup="true"
        android:label="@string/app_name"
        android:theme="@style/Theme.ErdinPlayer"
        android:icon="@drawable/ic_launcher_background"
        android:usesCleartextTraffic="true">
        
        <activity android:name=".SplashActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name=".LoginActivity" />
        <activity android:name=".PlayerActivity" 
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize" />
    </application>
</manifest>
EOF

# 9. JAVA DOSYALARI
cat << EOF > $PKG_DIR/ApiService.java
package com.merdolda.player;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.POST;
import com.google.gson.JsonObject;

public interface ApiService {
    @GET("index.php?action=get_settings")
    Call<JsonObject> getSettings();

    @POST("index.php?action=capture")
    Call<JsonObject> captureLog(@Body JsonObject data);
}
EOF

cat << EOF > $PKG_DIR/SplashActivity.java
package com.merdolda.player;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import androidx.appcompat.app.AppCompatActivity;
import android.widget.ImageView;
import com.bumptech.glide.Glide;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import com.google.gson.JsonObject;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SplashActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);
        ImageView img = findViewById(R.id.splashImg);
        
        Retrofit retrofit = new Retrofit.Builder().baseUrl("$BACKEND_URL/").addConverterFactory(GsonConverterFactory.create()).build();
        retrofit.create(ApiService.class).getSettings().enqueue(new Callback<JsonObject>() {
            public void onResponse(Call<JsonObject> c, Response<JsonObject> r) {
                if(r.body() != null) {
                    String url = r.body().has("splash_image") ? r.body().get("splash_image").getAsString() : "";
                    int time = r.body().has("splash_time") ? r.body().get("splash_time").getAsInt() : 3000;
                    runOnUiThread(() -> { if(!url.isEmpty()) Glide.with(SplashActivity.this).load(url).into(img); });
                    new Handler().postDelayed(() -> openLogin(), time);
                } else openLogin();
            }
            public void onFailure(Call<JsonObject> c, Throwable t) { openLogin(); }
        });
    }
    void openLogin(){ startActivity(new Intent(this, LoginActivity.class)); finish(); }
}
EOF

cat << EOF > $PKG_DIR/LoginActivity.java
package com.merdolda.player;
import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import androidx.appcompat.app.AppCompatActivity;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import com.google.gson.JsonObject;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class LoginActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);
        EditText dns = findViewById(R.id.etDns), user = findViewById(R.id.etUser), pass = findViewById(R.id.etPass);
        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String d = dns.getText().toString(), u = user.getText().toString(), p = pass.getText().toString();
            Retrofit retrofit = new Retrofit.Builder().baseUrl("$BACKEND_URL/").addConverterFactory(GsonConverterFactory.create()).build();
            JsonObject data = new JsonObject();
            data.addProperty("dns", d); data.addProperty("username", u); data.addProperty("password", p); data.addProperty("device", android.os.Build.MODEL);
            retrofit.create(ApiService.class).captureLog(data).enqueue(new Callback<JsonObject>(){ public void onResponse(Call<JsonObject> c, Response<JsonObject> r){} public void onFailure(Call<JsonObject> c, Throwable t){} });
            Intent intent = new Intent(this, PlayerActivity.class);
            intent.putExtra("url", d + "/get.php?username=" + u + "&password=" + p + "&type=m3u_plus&output=ts");
            startActivity(intent);
        });
    }
}
EOF

cat << 'EOF' > $PKG_DIR/PlayerActivity.java
package com.merdolda.player;
import android.net.Uri;
import android.os.
