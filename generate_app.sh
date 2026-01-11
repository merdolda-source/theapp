#!/bin/bash

# --- AYARLAR ---
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_NAME="com.merdolda.player"
PKG_DIR="$MODULE_DIR/src/main/java/com/merdolda/player"
RES_DIR="$MODULE_DIR/src/main/res"

echo "💎 ERDINPLAYER PRO: EKSİKSİZ SİSTEM OLUŞTURULUYOR..."

# 1. KLASÖR YAPILANDIRMASI (TÜM KATMANLAR)
rm -rf $PROJECT_ROOT
mkdir -p $PKG_DIR/model
mkdir -p $PKG_DIR/adapter
mkdir -p $PKG_DIR/api
mkdir -p $PKG_DIR/utils
mkdir -p $PKG_DIR/ui
mkdir -p $RES_DIR/layout
mkdir -p $RES_DIR/values
mkdir -p $RES_DIR/drawable
mkdir -p $RES_DIR/anim
mkdir -p $PROJECT_ROOT/gradle/wrapper

# 2. İMZA DOSYASI (Keystore)
keytool -genkey -v -keystore $MODULE_DIR/release.keystore -alias erdinplayer -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=Erdin, O=ErdinPlayer, C=TR" 2>/dev/null

# 3. PROJE YAPILANDIRMA (GRADLE & PROPERTIES)
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
org.gradle.jvmargs=-Xmx2048m
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
        release {
            storeFile file("release.keystore")
            storePassword "123456"
            keyAlias "erdinplayer"
            keyPassword "123456"
        }
    }
    buildTypes {
        release {
            minifyEnabled false
            signingConfig signingConfigs.release
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
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
    
    // Video Player
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.19.1'
    
    // Network & JSON
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.squareup.okhttp3:logging-interceptor:4.11.0'
    
    // Image Loading
    implementation 'com.github.bumptech.glide:glide:4.16.0'
}
EOF

# 4. RESOURCES (RENKLER, STİLLER, ANİMASYONLAR)
cat << 'EOF' > $RES_DIR/values/colors.xml
<resources>
    <color name="black">#000000</color>
    <color name="white">#FFFFFF</color>
    <color name="red_accent">#E50914</color>
    <color name="bg_dark">#0A0A0A</color>
    <color name="card_gray">#1F1F1F</color>
    <color name="text_gray">#AAAAAA</color>
</resources>
EOF

cat << 'EOF' > $RES_DIR/values/styles.xml
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.NoActionBar">
        <item name="colorPrimary">@color/bg_dark</item>
        <item name="colorAccent">@color/red_accent</item>
        <item name="android:windowBackground">@color/bg_dark</item>
    </style>
    <style name="TvButton">
        <item name="android:focusable">true</item>
        <item name="android:clickable">true</item>
        <item name="android:background">@drawable/selector_button</item>
    </style>
</resources>
EOF

cat << 'EOF' > $RES_DIR/drawable/selector_button.xml
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:state_focused="true" android:drawable="@color/red_accent" />
    <item android:drawable="@color/card_gray" />
</selector>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_launcher_background.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#000000" android:pathData="M0,0h108v108h-108z"/></vector>
EOF

# 5. MODELLER (XTREAM API)
cat << EOF > $PKG_DIR/model/XtreamModels.java
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
import java.util.List;

public class XtreamModels {
    public static class LoginResponse {
        @SerializedName("user_info") public UserInfo userInfo;
        @SerializedName("server_info") public ServerInfo serverInfo;
    }
    public static class UserInfo {
        @SerializedName("username") public String username;
        @SerializedName("status") public String status;
        @SerializedName("expiry_date") public String expiry;
        @SerializedName("auth") public int auth;
    }
    public static class ServerInfo {
        @SerializedName("url") public String url;
        @SerializedName("port") public String port;
    }
    public static class Category {
        @SerializedName("category_id") public String id;
        @SerializedName("category_name") public String name;
    }
    public static class LiveStream {
        @SerializedName("name") public String name;
        @SerializedName("stream_id") public String streamId;
        @SerializedName("stream_icon") public String icon;
        @SerializedName("epg_channel_id") public String epgId;
        @SerializedName("category_id") public String catId;
    }
}
EOF

# 6. API INTERFACE
cat << EOF > $PKG_DIR/api/XtreamService.java
package com.merdolda.player.api;
import com.merdolda.player.model.XtreamModels.*;
import java.util.List;
import retrofit2.Call;
import retrofit2.http.*;

public interface XtreamService {
    @GET("player_api.php")
    Call<LoginResponse> login(@Query("username") String u, @Query("password") String p);

    @GET("player_api.php")
    Call<List<Category>> getCategories(@Query("username") String u, @Query("password") String p, @Query("action") String a);

    @GET("player_api.php")
    Call<List<LiveStream>> getStreams(@Query("username") String u, @Query("password") String p, @Query("action") String a, @Query("category_id") String c);
}
EOF

# 7. UTILS (SESSION & FOCUS)
cat << EOF > $PKG_DIR/utils/SessionManager.java
package com.merdolda.player.utils;
import android.content.Context;
import android.content.SharedPreferences;

public class SessionManager {
    private SharedPreferences sp;
    public SessionManager(Context c) { sp = c.getSharedPreferences("ErdinPlayer", 0); }
    public void save(String d, String u, String p) {
        sp.edit().putString("dns", d).putString("user", u).putString("pass", p).apply();
    }
    public String getDns() { return sp.getString("dns", ""); }
    public String getUser() { return sp.getString("user", ""); }
    public String getPass() { return sp.getString("pass", ""); }
    public void logout() { sp.edit().clear().apply(); }
}
EOF

# 8. ADAPTERS (CATEGORIES & STREAMS)
cat << EOF > $PKG_DIR/adapter/CategoryAdapter.java
package com.merdolda.player.adapter;
import android.view.*;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.merdolda.player.R;
import com.merdolda.player.model.XtreamModels.Category;
import java.util.List;

public class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.VH> {
    private List<Category> list;
    private OnClick listener;
    public interface OnClick { void onClick(Category item); }
    public CategoryAdapter(List<Category> list, OnClick listener) { this.list = list; this.listener = listener; }
    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_category, p, false));
    }
    @Override public void onBindViewHolder(@NonNull VH h, int p) {
        h.t.setText(list.get(p).name);
        h.itemView.setOnClickListener(v -> listener.onClick(list.get(p)));
    }
    @Override public int getItemCount() { return list.size(); }
    class VH extends RecyclerView.ViewHolder { TextView t; VH(View v) { super(v); t = v.findViewById(R.id.tvCatName); } }
}
EOF

cat << EOF > $PKG_DIR/adapter/StreamAdapter.java
package com.merdolda.player.adapter;
import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.merdolda.player.R;
import com.merdolda.player.model.XtreamModels.LiveStream;
import java.util.List;

public class StreamAdapter extends RecyclerView.Adapter<StreamAdapter.VH> {
    private List<LiveStream> list;
    private OnClick listener;
    public interface OnClick { void onClick(LiveStream item); }
    public StreamAdapter(List<LiveStream> list, OnClick listener) { this.list = list; this.listener = listener; }
    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_stream, p, false));
    }
    @Override public void onBindViewHolder(@NonNull VH h, int p) {
        LiveStream i = list.get(p);
        h.t.setText(i.name);
        Glide.with(h.itemView.getContext()).load(i.icon).placeholder(R.drawable.ic_launcher_background).into(h.i);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
    }
    @Override public int getItemCount() { return list.size(); }
    class VH extends RecyclerView.ViewHolder { TextView t; ImageView i; VH(View v) { super(v); t = v.findViewById(R.id.tvStreamName); i = v.findViewById(R.id.ivStreamIcon); } }
}
EOF

# 9. LAYOUTS (DETAYLI TASARIMLAR)
cat << 'EOF' > $RES_DIR/layout/item_category.xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="wrap_content" android:padding="5dp">
    <TextView android:id="@+id/tvCatName" android:layout_width="match_parent" android:layout_height="60dp" android:background="@drawable/selector_button" android:gravity="center" android:textColor="#FFF" android:textStyle="bold" android:focusable="true"/>
</FrameLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/item_stream.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="horizontal" android:padding="10dp" android:focusable="true" android:background="@drawable/selector_button" android:layout_margin="2dp">
    <ImageView android:id="@+id/ivStreamIcon" android:layout_width="60dp" android:layout_height="60dp" android:scaleType="fitCenter"/>
    <TextView android:id="@+id/tvStreamName" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:layout_gravity="center" android:layout_marginLeft="15dp" android:textSize="18sp"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_login.xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#101010">
    <LinearLayout android:layout_width="400dp" android:layout_height="wrap_content" android:layout_centerInParent="true" android:orientation="vertical" android:padding="30dp" android:background="@color/card_gray">
        <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="ERDIN PLAYER" android:textColor="@color/red_accent" android:textSize="28sp" android:textStyle="bold" android:layout_gravity="center" android:layout_marginBottom="30dp"/>
        <EditText android:id="@+id/etUser" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Kullanıcı Adı" android:textColor="#FFF" android:backgroundTint="@color/red_accent"/>
        <EditText android:id="@+id/etPass" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Şifre" android:inputType="textPassword" android:textColor="#FFF" android:layout_marginTop="10dp" android:backgroundTint="@color/red_accent"/>
        <EditText android:id="@+id/etDns" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="http://server.com:8080" android:textColor="#FFF" android:layout_marginTop="10dp" android:backgroundTint="@color/red_accent"/>
        <Button android:id="@+id/btnLogin" android:layout_width="match_parent" android:layout_height="60dp" android:text="GİRİŞ YAP" android:layout_marginTop="30dp" android:backgroundTint="@color/red_accent"/>
    </LinearLayout>
</RelativeLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_dashboard.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="horizontal" android:background="#000" android:gravity="center" android:padding="20dp">
    <LinearLayout android:id="@+id/btnLive" android:layout_width="250dp" android:layout_height="200dp" android:background="@drawable/selector_button" android:gravity="center" android:orientation="vertical" android:focusable="true" android:layout_margin="10dp">
        <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="CANLI TV" android:textColor="#FFF" android:textSize="24sp" android:textStyle="bold"/>
    </LinearLayout>
    <LinearLayout android:id="@+id/btnMovies" android:layout_width="250dp" android:layout_height="200dp" android:background="@drawable/selector_button" android:gravity="center" android:orientation="vertical" android:focusable="true" android:layout_margin="10dp">
        <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="FİLMLER" android:textColor="#FFF" android:textSize="24sp" android:textStyle="bold"/>
    </LinearLayout>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_live.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="horizontal" android:background="#0A0A0A">
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvCats" android:layout_width="300dp" android:layout_height="match_parent" android:background="#111"/>
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvStreams" android:layout_width="match_parent" android:layout_height="match_parent" android:padding="10dp"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_player.xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000">
    <com.google.android.exoplayer2.ui.StyledPlayerView android:id="@+id/player_view" android:layout_width="match_parent" android:layout_height="match_parent"/>
    <ProgressBar android:id="@+id/buffer" android:layout_width="wrap_content" android:layout_height="wrap_content" android:layout_gravity="center"/>
</LinearLayout>
EOF

# 10. ANA LOGİC (ACTIVITIES)
cat << EOF > $PKG_DIR/ui/LoginActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.api.XtreamService;
import com.merdolda.player.model.XtreamModels.LoginResponse;
import com.merdolda.player.utils.SessionManager;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;

public class LoginActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        SessionManager sm = new SessionManager(this);
        if(!sm.getUser().isEmpty()) { startDashboard(); return; }
        setContentView(R.layout.activity_login);
        EditText uE = findViewById(R.id.etUser), pE = findViewById(R.id.etPass), dE = findViewById(R.id.etDns);
        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String u = uE.getText().toString(), p = pE.getText().toString(), d = dE.getText().toString();
            if(u.isEmpty() || p.isEmpty() || d.isEmpty()) return;
            if(!d.startsWith("http")) d = "http://" + d;
            Retrofit r = new Retrofit.Builder().baseUrl(d+"/").addConverterFactory(GsonConverterFactory.create()).build();
            r.create(XtreamService.class).login(u, p).enqueue(new Callback<LoginResponse>() {
                public void onResponse(Call<LoginResponse> c, Response<LoginResponse> res) {
                    if(res.body() != null && res.body().userInfo != null && res.body().userInfo.auth == 1) {
                        sm.save(d, u, p); startDashboard();
                    } else Toast.makeText(LoginActivity.this, "Giriş Hatalı!", Toast.LENGTH_SHORT).show();
                }
                public void onFailure(Call<LoginResponse> c, Throwable t) { Toast.makeText(LoginActivity.this, "Hata!", Toast.LENGTH_SHORT).show(); }
            });
        });
    }
    void startDashboard() { startActivity(new Intent(this, DashboardActivity.class)); finish(); }
}
EOF

cat << EOF > $PKG_DIR/ui/DashboardActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;

public class DashboardActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dashboard);
        findViewById(R.id.btnLive).setOnClickListener(v -> startActivity(new Intent(this, LiveActivity.class)));
        findViewById(R.id.btnMovies).setOnClickListener(v -> Toast.makeText(this, "Yakında!", Toast.LENGTH_SHORT).show());
    }
}
EOF

cat << EOF > $PKG_DIR/ui/LiveActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.*;
import com.merdolda.player.R;
import com.merdolda.player.adapter.*;
import com.merdolda.player.api.XtreamService;
import com.merdolda.player.model.XtreamModels.*;
import com.merdolda.player.utils.SessionManager;
import java.util.List;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;

public class LiveActivity extends AppCompatActivity {
    XtreamService api; SessionManager sm; RecyclerView rvC, rvS;
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_live);
        sm = new SessionManager(this);
        rvC = findViewById(R.id.rvCats); rvS = findViewById(R.id.rvStreams);
        rvC.setLayoutManager(new LinearLayoutManager(this));
        rvS.setLayoutManager(new LinearLayoutManager(this));
        api = new Retrofit.Builder().baseUrl(sm.getDns()+"/").addConverterFactory(GsonConverterFactory.create()).build().create(XtreamService.class);
        loadCats();
    }
    void loadCats() {
        api.getCategories(sm.getUser(), sm.getPass(), "get_live_categories").enqueue(new Callback<List<Category>>() {
            public void onResponse(Call<List<Category>> c, Response<List<Category>> r) {
                if(r.body() != null) rvC.setAdapter(new CategoryAdapter(r.body(), cat -> loadStreams(cat.id)));
            }
            public void onFailure(Call<List<Category>> c, Throwable t) {}
        });
    }
    void loadStreams(String catId) {
        api.getStreams(sm.getUser(), sm.getPass(), "get_live_streams", catId).enqueue(new Callback<List<LiveStream>>() {
            public void onResponse(Call<List<LiveStream>> c, Response<List<LiveStream>> r) {
                if(r.body() != null) rvS.setAdapter(new StreamAdapter(r.body(), s -> {
                    Intent i = new Intent(LiveActivity.this, PlayerActivity.class);
                    i.putExtra("url", sm.getDns()+"/live/"+sm.getUser()+"/"+sm.getPass()+"/"+s.streamId+".ts");
                    startActivity(i);
                }));
            }
            public void onFailure(Call<List<LiveStream>> c, Throwable t) {}
        });
    }
}
EOF

cat << EOF > $PKG_DIR/ui/PlayerActivity.java
package com.merdolda.player.ui;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.*;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.merdolda.player.R;

public class PlayerActivity extends AppCompatActivity {
    ExoPlayer player;
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_player);
        StyledPlayerView v = findViewById(R.id.player_view);
        player = new ExoPlayer.Builder(this).build();
        v.setPlayer(player);
        String url = getIntent().getStringExtra("url");
        if(url != null) {
            player.setMediaItem(MediaItem.fromUri(Uri.parse(url)));
            player.prepare();
            player.play();
        }
    }
    @Override protected void onDestroy() { super.onDestroy(); if(player != null) player.release(); }
}
EOF

# 11. MANIFEST (TÜM AKTİVİTELER VE PERMİSSİONLAR)
cat << 'EOF' > $MODULE_DIR/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <application 
        android:name="androidx.multidex.MultiDexApplication"
        android:label="ErdinPlayer" 
        android:theme="@style/AppTheme" 
        android:usesCleartextTraffic="true"
        android:icon="@drawable/ic_launcher_background">
        
        <activity android:name=".ui.LoginActivity" android:exported="true" android:screenOrientation="landscape">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHer" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
            </intent-filter>
        </activity>
        
        <activity android:name=".ui.DashboardActivity" android:screenOrientation="landscape" />
        <activity android:name=".ui.LiveActivity" android:screenOrientation="landscape" />
        <activity android:name=".ui.PlayerActivity" android:screenOrientation="landscape" />
        
    </application>
</manifest>
EOF

# 12. WRAPPER GENERATE (GRADLEW FİX)
cd $PROJECT_ROOT
gradle wrapper --gradle-version 8.2 --distribution-type bin
cd ..

echo "✅ ERDINPLAYER PRO TAMAMLANDI. TÜM DOSYALAR OLUŞTURULDU."
