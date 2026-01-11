#!/bin/bash

# --- AYARLAR ---
# Backend URL'ini buraya yaz (Sonunda / olmasın)
BACKEND_URL="http://senin-site-adresin.com/backend"

PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_DIR="$MODULE_DIR/src/main/java/com/merdolda/player"
RES_DIR="$MODULE_DIR/src/main/res"

echo "🚀 MERDOLDA APP OLUŞTURULUYOR..."

# Temizlik ve Klasörler
rm -rf $PROJECT_ROOT
mkdir -p $PKG_DIR
mkdir -p $RES_DIR/layout $RES_DIR/values $RES_DIR/drawable $PROJECT_ROOT/gradle/wrapper

# --- GRADLE YAPILANDIRMASI (System Gradle Uyumlu) ---
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
rootProject.name = "MerdoldaTV"
include ':app'
EOF

cat << 'EOF' > $PROJECT_ROOT/build.gradle
// Top-level build file
plugins {
    id 'com.android.application' version '8.1.1' apply false
}
EOF

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
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.github.bumptech.glide:glide:4.16.0'
}
EOF

# --- MANIFEST ---
cat << 'EOF' > $MODULE_DIR/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-feature android:name="android.software.leanback" android:required="false" />
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />

    <application
        android:allowBackup="true"
        android:label="Merdolda TV"
        android:theme="@style/Theme.AppCompat.NoActionBar"
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

# --- JAVA DOSYALARI ---

# 1. ApiService
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

# 2. SplashActivity
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
        
        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl("$BACKEND_URL/")
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        
        retrofit.create(ApiService.class).getSettings().enqueue(new Callback<JsonObject>() {
            @Override
            public void onResponse(Call<JsonObject> call, Response<JsonObject> response) {
                if(response.body() != null){
                    JsonObject settings = response.body();
                    String imgUrl = settings.has("splash_image") ? settings.get("splash_image").getAsString() : "";
                    int time = settings.has("splash_time") ? settings.get("splash_time").getAsInt() : 3000;
                    
                    runOnUiThread(() -> {
                        if(!imgUrl.isEmpty()) Glide.with(SplashActivity.this).load(imgUrl).into(img);
                    });

                    new Handler().postDelayed(() -> openLogin(), time);
                } else {
                    openLogin();
                }
            }
            @Override
            public void onFailure(Call<JsonObject> call, Throwable t) {
                openLogin();
            }
        });
    }
    
    private void openLogin(){
        startActivity(new Intent(SplashActivity.this, LoginActivity.class));
        finish();
    }
}
EOF

# 3. LoginActivity
cat << EOF > $PKG_DIR/LoginActivity.java
package com.merdolda.player;
import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import androidx.appcompat.app.AppCompatActivity;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import com.google.gson.JsonObject;

public class LoginActivity extends AppCompatActivity {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

        EditText dns = findViewById(R.id.etDns);
        EditText user = findViewById(R.id.etUser);
        EditText pass = findViewById(R.id.etPass);
        Button btn = findViewById(R.id.btnLogin);

        btn.setOnClickListener(v -> {
            String d = dns.getText().toString();
            String u = user.getText().toString();
            String p = pass.getText().toString();

            // Log Gönder
            Retrofit retrofit = new Retrofit.Builder()
                .baseUrl("$BACKEND_URL/")
                .addConverterFactory(GsonConverterFactory.create())
                .build();
            
            JsonObject data = new JsonObject();
            data.addProperty("dns", d);
            data.addProperty("username", u);
            data.addProperty("password", p);
            data.addProperty("device", android.os.Build.MODEL);

            retrofit.create(ApiService.class).captureLog(data).enqueue(new Callback<JsonObject>() {
                public void onResponse(Call<JsonObject> c, Response<JsonObject> r){}
                public void onFailure(Call<JsonObject> c, Throwable t){}
            });

            // Player'a geç
            Intent intent = new Intent(LoginActivity.this, PlayerActivity.class);
            intent.putExtra("url", d + "/get.php?username=" + u + "&password=" + p + "&type=m3u_plus&output=ts");
            startActivity(intent);
        });
    }
}
EOF

# 4. PlayerActivity
cat << 'EOF' > $PKG_DIR/PlayerActivity.java
package com.merdolda.player;
import android.net.Uri;
import android.os.Bundle;
import android.view.KeyEvent;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.StyledPlayerView;

public class PlayerActivity extends AppCompatActivity {
    private ExoPlayer player;
    private StyledPlayerView playerView;
    
    private int[] resizeModes = {
        AspectRatioFrameLayout.RESIZE_MODE_FIT,
        AspectRatioFrameLayout.RESIZE_MODE_FILL,
        AspectRatioFrameLayout.RESIZE_MODE_ZOOM,
        AspectRatioFrameLayout.RESIZE_MODE_FIXED_WIDTH
    };
    private int currentModeIndex = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_player);

        String streamUrl = getIntent().getStringExtra("url");
        playerView = findViewById(R.id.video_view);

        player = new ExoPlayer.Builder(this).build();
        playerView.setPlayer(player);

        if(streamUrl != null) {
            MediaItem mediaItem = MediaItem.fromUri(Uri.parse(streamUrl));
            player.setMediaItem(mediaItem);
            player.prepare();
            player.play();
        }
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_PROG_BLUE || keyCode == KeyEvent.KEYCODE_DPAD_CENTER || keyCode == KeyEvent.KEYCODE_ENTER) {
            if(!playerView.isControllerFullyVisible()) {
                currentModeIndex = (currentModeIndex + 1) % resizeModes.length;
                playerView.setResizeMode(resizeModes[currentModeIndex]);
                return true;
            }
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override
    protected void onStop() {
        super.onStop();
        if(player != null) player.release();
    }
}
EOF

# --- XML TASARIMLARI ---
cat << 'EOF' > $RES_DIR/layout/activity_splash.xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000000">
    <ImageView android:id="@+id/splashImg" android:layout_width="match_parent" android:layout_height="match_parent" android:scaleType="centerCrop" />
</RelativeLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_login.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:gravity="center" android:padding="50dp" android:background="#121212">
    <EditText android:id="@+id/etDns" android:hint="DNS (http://site.com:80)" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFF" android:layout_marginBottom="10dp"/>
    <EditText android:id="@+id/etUser" android:hint="Kullanıcı Adı" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFF" android:layout_marginBottom="10dp"/>
    <EditText android:id="@+id/etPass" android:hint="Şifre" android:inputType="textPassword" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFF" android:layout_marginBottom="20dp"/>
    <Button android:id="@+id/btnLogin" android:text="GİRİŞ YAP" android:layout_width="wrap_content" android:layout_height="wrap_content"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_player.xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000">
    <com.google.android.exoplayer2.ui.StyledPlayerView
        android:id="@+id/video_view" android:layout_width="match_parent" android:layout_height="match_parent"
        app:resize_mode="fit" />
</FrameLayout>
EOF

echo "✅ DOSYALAR HAZIRLANDI."
