#!/bin/bash

# --- AYARLAR ---
PACKAGE_NAME="com.merdolda.player"
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_DIR="$MODULE_DIR/src/main/java/com/merdolda/player"
RES_DIR="$MODULE_DIR/src/main/res"

echo "🚀 ERDINPLAYER SIFIRDAN KURULUYOR (STABLE EDITION)..."

# 1. TEMİZLİK
rm -rf $PROJECT_ROOT
mkdir -p $PKG_DIR/model $PKG_DIR/adapter
mkdir -p $RES_DIR/layout $RES_DIR/values $RES_DIR/drawable $PROJECT_ROOT/gradle/wrapper

# 2. KEYSTORE (İMZA)
keytool -genkey -v -keystore $MODULE_DIR/release.keystore -alias erdinplayer -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=Erdin, O=Player, C=TR" 2>/dev/null

# 3. GRADLE WRAPPER
cat << 'EOF' > $PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# 4. SETTINGS & BUILD GRADLE
cat << 'EOF' > $PROJECT_ROOT/settings.gradle
rootProject.name = "ErdinPlayer"
include ':app'
EOF

cat << 'EOF' > $PROJECT_ROOT/build.gradle
plugins { id 'com.android.application' version '8.1.1' apply false }
EOF

cat << 'EOF' > $PROJECT_ROOT/gradle.properties
android.useAndroidX=true
android.enableJetifier=true
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
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.github.bumptech.glide:glide:4.16.0'
}
EOF

# 5. RESOURCES (TASARIMLAR)
cat << 'EOF' > $RES_DIR/values/strings.xml
<resources><string name="app_name">ErdinPlayer</string></resources>
EOF

cat << 'EOF' > $RES_DIR/values/colors.xml
<resources>
    <color name="black">#000000</color>
    <color name="white">#FFFFFF</color>
    <color name="red">#E50914</color>
    <color name="dark_gray">#1A1A1A</color>
</resources>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_launcher_background.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#000000" android:pathData="M0,0h108v108h-108z"/></vector>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_login.xml
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#101010" android:fillViewport="true">
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="vertical" android:gravity="center" android:padding="30dp">
        <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="ERDIN PLAYER" android:textColor="#E50914" android:textSize="32sp" android:textStyle="bold" android:layout_marginBottom="40dp"/>
        <EditText android:id="@+id/etUser" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Kullanıcı Adı" android:textColor="#FFF" android:layout_marginBottom="15dp"/>
        <EditText android:id="@+id/etPass" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Şifre" android:inputType="textPassword" android:textColor="#FFF" android:layout_marginBottom="15dp"/>
        <EditText android:id="@+id/etDns" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="http://dns-adresi.com:8080" android:textColor="#FFF" android:layout_marginBottom="30dp"/>
        <Button android:id="@+id/btnLogin" android:layout_width="match_parent" android:layout_height="60dp" android:text="GİRİŞ YAP" android:backgroundTint="#E50914" android:textColor="#FFF"/>
    </LinearLayout>
</ScrollView>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_dashboard.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:background="#000" android:gravity="center">
    <TextView android:id="@+id/tvWelcome" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:textSize="18sp" android:layout_marginBottom="20dp"/>
    <Button android:id="@+id/btnLive" android:layout_width="200dp" android:layout_height="100dp" android:text="CANLI TV" android:backgroundTint="#E50914"/>
    <Button android:id="@+id/btnLogout" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="ÇIKIŞ" android:layout_marginTop="50dp" android:backgroundTint="#333"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_list.xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#101010">
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/recyclerView" android:layout_width="match_parent" android:layout_height="match_parent"/>
    <ProgressBar android:id="@+id/progressBar" android:layout_width="wrap_content" android:layout_height="wrap_content" android:layout_centerInParent="true"/>
</RelativeLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/item_channel.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="horizontal" android:padding="10dp" android:focusable="true" android:clickable="true" android:background="?attr/selectableItemBackground">
    <ImageView android:id="@+id/ivIcon" android:layout_width="50dp" android:layout_height="50dp" android:src="@drawable/ic_launcher_background"/>
    <TextView android:id="@+id/tvName" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:layout_gravity="center" android:layout_marginLeft="15dp" android:textSize="18sp"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_player.xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000">
    <com.google.android.exoplayer2.ui.StyledPlayerView android:id="@+id/video_view" android:layout_width="match_parent" android:layout_height="match_parent"/>
</FrameLayout>
EOF

# 6. JAVA MODELS & ADAPTER
cat << EOF > $PKG_DIR/model/LoginResponse.java
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
public class LoginResponse {
    @SerializedName("user_info") public UserInfo userInfo;
    public class UserInfo { @SerializedName("auth") public int auth; @SerializedName("username") public String username; }
}
EOF

cat << EOF > $PKG_DIR/model/StreamItem.java
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
public class StreamItem {
    @SerializedName("name") public String name;
    @SerializedName("stream_id") public int streamId;
    @SerializedName("stream_icon") public String streamIcon;
}
EOF

cat << EOF > $PKG_DIR/adapter/ChannelAdapter.java
package com.merdolda.player.adapter;
import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.merdolda.player.R;
import com.merdolda.player.model.StreamItem;
import java.util.List;

public class ChannelAdapter extends RecyclerView.Adapter<ChannelAdapter.VH> {
    private List<StreamItem> list;
    private OnClick listener;
    public interface OnClick { void onClick(StreamItem item); }
    public ChannelAdapter(List<StreamItem> list, OnClick listener) { this.list = list; this.listener = listener; }
    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_channel, p, false));
    }
    @Override public void onBindViewHolder(@NonNull VH h, int p) {
        StreamItem i = list.get(p);
        h.t.setText(i.name);
        Glide.with(h.itemView.getContext()).load(i.streamIcon).placeholder(R.drawable.ic_launcher_background).into(h.i);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
    }
    @Override public int getItemCount() { return list.size(); }
    class VH extends RecyclerView.ViewHolder {
        TextView t; ImageView i;
        VH(View v) { super(v); t = v.findViewById(R.id.tvName); i = v.findViewById(R.id.ivIcon); }
    }
}
EOF

# 7. MAIN JAVA LOGIC (CRASH PROTECTED)
cat << EOF > $PKG_DIR/ApiService.java
package com.merdolda.player;
import retrofit2.Call;
import retrofit2.http.*;
import java.util.List;
import com.merdolda.player.model.*;

public interface ApiService {
    @GET Call<LoginResponse> login(@Url String url, @Query("username") String u, @Query("password") String p);
    @GET Call<List<StreamItem>> getStreams(@Url String url, @Query("username") String u, @Query("password") String p, @Query("action") String a);
}
EOF

cat << EOF > $PKG_DIR/LoginActivity.java
package com.merdolda.player;
import android.content.*;
import android.os.Bundle;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;
import com.merdolda.player.model.LoginResponse;

public class LoginActivity extends AppCompatActivity {
    SharedPreferences sp;
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        sp = getSharedPreferences("ErdinPref", MODE_PRIVATE);
        if(!sp.getString("user", "").isEmpty()) { start(); return; }
        setContentView(R.layout.activity_login);
        EditText uE = findViewById(R.id.etUser), pE = findViewById(R.id.etPass), dE = findViewById(R.id.etDns);
        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String u = uE.getText().toString(), p = pE.getText().toString(), d = dE.getText().toString();
            if(u.isEmpty() || p.isEmpty() || d.isEmpty()) return;
            if(!d.startsWith("http")) d = "http://" + d;
            login(d, u, p);
        });
    }
    void login(String d, String u, String p) {
        Retrofit r = new Retrofit.Builder().baseUrl("http://localhost/").addConverterFactory(GsonConverterFactory.create()).build();
        r.create(ApiService.class).login(d + "/player_api.php", u, p).enqueue(new Callback<LoginResponse>() {
            public void onResponse(Call<LoginResponse> c, Response<LoginResponse> res) {
                if(res.body() != null && res.body().userInfo != null && res.body().userInfo.auth == 1) {
                    sp.edit().putString("dns", d).putString("user", u).putString("pass", p).apply();
                    start();
                } else Toast.makeText(LoginActivity.this, "Hatalı Giriş!", Toast.LENGTH_SHORT).show();
            }
            public void onFailure(Call<LoginResponse> c, Throwable t) { Toast.makeText(LoginActivity.this, "Bağlantı Hatası", Toast.LENGTH_SHORT).show(); }
        });
    }
    void start() { startActivity(new Intent(this, DashboardActivity.class)); finish(); }
}
EOF

cat << EOF > $PKG_DIR/DashboardActivity.java
package com.merdolda.player;
import android.content.*;
import android.os.Bundle;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class DashboardActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dashboard);
        SharedPreferences sp = getSharedPreferences("ErdinPref", MODE_PRIVATE);
        ((TextView)findViewById(R.id.tvWelcome)).setText("Hoşgeldin: " + sp.getString("user", ""));
        findViewById(R.id.btnLive).setOnClickListener(v -> startActivity(new Intent(this, LiveListActivity.class)));
        findViewById(R.id.btnLogout).setOnClickListener(v -> {
            sp.edit().clear().apply();
            startActivity(new Intent(this, LoginActivity.class));
            finish();
        });
    }
}
EOF

cat << EOF > $PKG_DIR/LiveListActivity.java
package com.merdolda.player;
import android.content.*;
import android.os.Bundle;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.*;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;
import java.util.List;
import com.merdolda.player.adapter.ChannelAdapter;
import com.merdolda.player.model.StreamItem;

public class LiveListActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list);
        RecyclerView rv = findViewById(R.id.recyclerView);
        ProgressBar pb = findViewById(R.id.progressBar);
        rv.setLayoutManager(new LinearLayoutManager(this));
        SharedPreferences sp = getSharedPreferences("ErdinPref", MODE_PRIVATE);
        String d = sp.getString("dns", ""), u = sp.getString("user", ""), p = sp.getString("pass", "");
        Retrofit r = new Retrofit.Builder().baseUrl("http://localhost/").addConverterFactory(GsonConverterFactory.create()).build();
        r.create(ApiService.class).getStreams(d + "/player_api.php", u, p, "get_live_streams").enqueue(new Callback<List<StreamItem>>() {
            public void onResponse(Call<List<StreamItem>> c, Response<List<StreamItem>> res) {
                pb.setVisibility(View.GONE);
                if(res.body() != null) rv.setAdapter(new ChannelAdapter(res.body(), i -> {
                    Intent intent = new Intent(LiveListActivity.this, PlayerActivity.class);
                    intent.putExtra("url", d + "/live/" + u + "/" + p + "/" + i.streamId + ".ts");
                    startActivity(intent);
                }));
            }
            public void onFailure(Call<List<StreamItem>> c, Throwable t) { pb.setVisibility(View.GONE); }
        });
    }
}
EOF

cat << 'EOF' > $PKG_DIR/PlayerActivity.java
package com.merdolda.player;
import android.net.Uri;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.*;
import com.google.android.exoplayer2.ui.StyledPlayerView;

public class PlayerActivity extends AppCompatActivity {
    ExoPlayer p;
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_player);
        StyledPlayerView v = findViewById(R.id.video_view);
        p = new ExoPlayer.Builder(this).build();
        v.setPlayer(p);
        String url = getIntent().getStringExtra("url");
        if(url != null) { p.setMediaItem(MediaItem.fromUri(Uri.parse(url))); p.prepare(); p.play(); }
    }
    @Override protected void onDestroy() { super.onDestroy(); if(p != null) p.release(); }
}
EOF

# 8. MANIFEST
cat << 'EOF' > $MODULE_DIR/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <application android:name="androidx.multidex.MultiDexApplication" android:label="ErdinPlayer" android:theme="@style/Theme.AppCompat.NoActionBar" android:usesCleartextTraffic="true">
        <activity android:name=".LoginActivity" android:exported="true">
            <intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter>
        </activity>
        <activity android:name=".DashboardActivity" /><activity android:name=".LiveListActivity" /><activity android:name=".PlayerActivity" />
    </application>
</manifest>
EOF

# 9. WRAPPER GENERATE
cd $PROJECT_ROOT
gradle wrapper --gradle-version 8.2 --distribution-type bin
cd ..

echo "✅ ERDINPLAYER TAMAMLANDI."
