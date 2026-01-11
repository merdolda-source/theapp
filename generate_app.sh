#!/bin/bash

# --- AYARLAR ---
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="com/merdolda/player"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "💎 ERDINPLAYER MEGA PRO: FULL XTREAM & M3U ENGINE OLUŞTURULUYOR..."

# 1. TEMİZLİK VE KLASÖR YAPISI
rm -rf $PROJECT_ROOT
mkdir -p $PKG_DIR/model $PKG_DIR/adapter $PKG_DIR/api $PKG_DIR/utils $PKG_DIR/ui
mkdir -p $RES_DIR/layout $RES_DIR/values $RES_DIR/drawable $RES_DIR/anim
mkdir -p $PROJECT_ROOT/gradle/wrapper

# 2. KEYSTORE (İMZA)
keytool -genkey -v -keystore $MODULE_DIR/release.keystore -alias erdinplayer -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=Erdin, O=ErdinPlayer, C=TR" 2>/dev/null

# 3. PROJE YAPILANDIRMASI (GRADLE 8.4)
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
        release { storeFile file("release.keystore"); storePassword "123456"; keyAlias "erdinplayer"; keyPassword "123456" }
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
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.19.1'
    implementation 'com.github.bumptech.glide:glide:4.16.0'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
}
EOF

# 4. MODELLER (HATALI OLAN BÖLÜM DÜZELTİLDİ)
cat << EOF > $PKG_DIR/model/XtreamData.java
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class XtreamData {
    
    public static class UserInfo implements Serializable {
        @SerializedName("username") public String username;
        @SerializedName("auth") public int auth;
        @SerializedName("status") public String status;
        @SerializedName("expiry_date") public String expiry;
    }

    public static class ServerInfo implements Serializable {
        @SerializedName("url") public String url;
        @SerializedName("port") public String port;
    }

    public static class LoginResponse implements Serializable {
        @SerializedName("user_info") public UserInfo userInfo;
        @SerializedName("server_info") public ServerInfo serverInfo;
    }

    public static class Category implements Serializable {
        @SerializedName("category_id") public String id;
        @SerializedName("category_name") public String name;
    }

    public static class StreamItem implements Serializable {
        @SerializedName("name") public String name;
        @SerializedName("stream_id") public String streamId;
        @SerializedName("stream_icon") public String icon;
        @SerializedName("category_id") public String catId;
        @SerializedName("stream_type") public String type;
    }
}
EOF

# 5. ADAPTERLER (SMARTERS STİLİ)
# Kategori Adaptörü
cat << EOF > $PKG_DIR/adapter/CategoryAdapter.java
package com.merdolda.player.adapter;
import android.graphics.Color;
import android.view.*;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.merdolda.player.R;
import com.merdolda.player.model.XtreamData.Category;
import java.util.List;

public class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.VH> {
    private List<Category> list;
    private OnClick listener;
    private int selectedPos = 0;
    public interface OnClick { void onClick(Category item); }
    public CategoryAdapter(List<Category> list, OnClick listener) { this.list = list; this.listener = listener; }
    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_category, p, false));
    }
    @Override public void onBindViewHolder(@NonNull VH h, int p) {
        Category item = list.get(p);
        h.t.setText(item.name);
        h.itemView.setBackgroundColor(selectedPos == p ? Color.parseColor("#E50914") : Color.TRANSPARENT);
        h.itemView.setOnClickListener(v -> {
            int old = selectedPos; selectedPos = h.getAdapterPosition();
            notifyItemChanged(old); notifyItemChanged(selectedPos);
            listener.onClick(item);
        });
    }
    @Override public int getItemCount() { return list.size(); }
    class VH extends RecyclerView.ViewHolder { TextView t; VH(View v) { super(v); t = v.findViewById(R.id.tvCatName); } }
}
EOF

# Kanal Adaptörü
cat << EOF > $PKG_DIR/adapter/StreamAdapter.java
package com.merdolda.player.adapter;
import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.merdolda.player.R;
import com.merdolda.player.model.XtreamData.StreamItem;
import java.util.List;

public class StreamAdapter extends RecyclerView.Adapter<StreamAdapter.VH> {
    private List<StreamItem> list;
    private OnItemClick listener;
    public interface OnItemClick { void onClick(StreamItem item); }
    public StreamAdapter(List<StreamItem> list, OnItemClick listener) { this.list = list; this.listener = listener; }
    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_channel, p, false));
    }
    @Override public void onBindViewHolder(@NonNull VH h, int p) {
        StreamItem i = list.get(p);
        h.txt.setText(i.name);
        Glide.with(h.itemView.getContext()).load(i.icon).placeholder(R.drawable.ic_launcher_background).into(h.img);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
    }
    @Override public int getItemCount() { return list == null ? 0 : list.size(); }
    public void update(List<StreamItem> newList) { this.list = newList; notifyDataSetChanged(); }
    class VH extends RecyclerView.ViewHolder {
        TextView txt; ImageView img;
        VH(View v) { super(v); txt = v.findViewById(R.id.tvName); img = v.findViewById(R.id.ivIcon); }
    }
}
EOF

# 6. API VE UTILS
cat << EOF > $PKG_DIR/api/XtreamApi.java
package com.merdolda.player.api;
import com.merdolda.player.model.XtreamData.*;
import java.util.List;
import retrofit2.Call;
import retrofit2.http.*;

public interface XtreamApi {
    @GET("player_api.php") Call<LoginResponse> login(@Query("username") String u, @Query("password") String p);
    @GET("player_api.php") Call<List<Category>> getCategories(@Query("username") String u, @Query("password") String p, @Query("action") String a);
    @GET("player_api.php") Call<List<StreamItem>> getStreams(@Query("username") String u, @Query("password") String p, @Query("action") String a, @Query("category_id") String c);
}
EOF

cat << EOF > $PKG_DIR/utils/PrefUtils.java
package com.merdolda.player.utils;
import android.content.*;

public class PrefUtils {
    public static void saveUser(Context c, String d, String u, String p) {
        c.getSharedPreferences("Erdin", 0).edit().putString("d", d).putString("u", u).putString("p", p).apply();
    }
    public static String getU(Context c) { return c.getSharedPreferences("Erdin", 0).getString("u", ""); }
    public static String getP(Context c) { return c.getSharedPreferences("Erdin", 0).getString("p", ""); }
    public static String getD(Context c) { return c.getSharedPreferences("Erdin", 0).getString("d", ""); }
    public static void logout(Context c) { c.getSharedPreferences("Erdin", 0).edit().clear().apply(); }
}
EOF

# 7. TASARIMLAR (LAYOUT)
cat << 'EOF' > $RES_DIR/layout/activity_login.xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#101010">
    <LinearLayout android:layout_width="450dp" android:layout_height="wrap_content" android:layout_centerInParent="true" android:orientation="vertical" android:padding="30dp" android:background="#1C1C1C">
        <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="ERDIN PLAYER" android:textColor="#E50914" android:textSize="32sp" android:textStyle="bold" android:layout_gravity="center" android:layout_marginBottom="30dp"/>
        <EditText android:id="@+id/etUser" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Kullanıcı" android:textColor="#FFF"/>
        <EditText android:id="@+id/etPass" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Şifre" android:inputType="textPassword" android:textColor="#FFF"/>
        <EditText android:id="@+id/etDns" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="http://server.com:8080" android:textColor="#FFF"/>
        <Button android:id="@+id/btnLogin" android:layout_width="match_parent" android:layout_height="60dp" android:text="GİRİŞ YAP" android:layout_marginTop="20dp" android:backgroundTint="#E50914"/>
    </LinearLayout>
</RelativeLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_dashboard.xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000" android:padding="20dp">
    <TextView android:id="@+id/tvUser" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:textSize="18sp" android:layout_alignParentTop="true"/>
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_centerInParent="true" android:gravity="center" android:orientation="horizontal">
        <Button android:id="@+id/btnLive" android:layout_width="250dp" android:layout_height="180dp" android:text="CANLI TV" android:backgroundTint="#E50914" android:textSize="22sp" android:layout_margin="10dp"/>
        <Button android:id="@+id/btnVod" android:layout_width="250dp" android:layout_height="180dp" android:text="FİLMLER" android:backgroundTint="#222" android:textSize="22sp" android:layout_margin="10dp"/>
    </LinearLayout>
    <Button android:id="@+id/btnLogout" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="ÇIKIŞ" android:layout_alignParentBottom="true" android:backgroundTint="#333"/>
</RelativeLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_live.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="horizontal" android:background="#0A0A0A">
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvCats" android:layout_width="300dp" android:layout_height="match_parent" android:background="#151515"/>
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvStreams" android:layout_width="match_parent" android:layout_height="match_parent" android:padding="10dp"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/item_category.xml
<TextView xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/tvCatName" android:layout_width="match_parent" android:layout_height="60dp" android:gravity="center_vertical" android:paddingLeft="20dp" android:textColor="#FFF" android:textSize="16sp" android:textStyle="bold" android:focusable="true" android:clickable="true" android:background="?attr/selectableItemBackground"/>
EOF

cat << 'EOF' > $RES_DIR/layout/item_channel.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="wrap_content" android:padding="10dp" android:focusable="true" android:clickable="true" android:background="?attr/selectableItemBackground">
    <ImageView android:id="@+id/ivIcon" android:layout_width="70dp" android:layout_height="70dp" android:scaleType="centerInside"/>
    <TextView android:id="@+id/tvName" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:textSize="18sp" android:layout_marginLeft="15dp" android:layout_gravity="center"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_player.xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000">
    <com.google.android.exoplayer2.ui.StyledPlayerView android:id="@+id/player_view" android:layout_width="match_parent" android:layout_height="match_parent"/>
</FrameLayout>
EOF

cat << 'EOF' > $RES_DIR/values/strings.xml
<resources><string name="app_name">ErdinPlayer</string></resources>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_launcher_background.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#000000" android:pathData="M0,0h108v108h-108z"/></vector>
EOF

# 8. ANA KODLAR (UI)
cat << EOF > $PKG_DIR/ui/LoginActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.api.XtreamApi;
import com.merdolda.player.model.XtreamData.LoginResponse;
import com.merdolda.player.utils.PrefUtils;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;

public class LoginActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if(!PrefUtils.getU(this).isEmpty()) { start(); return; }
        setContentView(R.layout.activity_login);
        EditText u = findViewById(R.id.etUser), p = findViewById(R.id.etPass), d = findViewById(R.id.etDns);
        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String url = d.getText().toString();
            if(!url.startsWith("http")) url = "http://" + url;
            if(url.endsWith("/")) url = url.substring(0, url.length()-1);
            final String fU = url;
            Retrofit r = new Retrofit.Builder().baseUrl(fU+"/").addConverterFactory(GsonConverterFactory.create()).build();
            r.create(XtreamApi.class).login(u.getText().toString(), p.getText().toString()).enqueue(new Callback<LoginResponse>() {
                public void onResponse(Call<LoginResponse> c, Response<LoginResponse> res) {
                    if(res.body() != null && res.body().userInfo != null && res.body().userInfo.auth == 1) {
                        PrefUtils.saveUser(LoginActivity.this, fU, u.getText().toString(), p.getText().toString()); start();
                    } else Toast.makeText(LoginActivity.this, "Hatalı Giriş!", 0).show();
                }
                public void onFailure(Call<LoginResponse> c, Throwable t) { Toast.makeText(LoginActivity.this, "Bağlantı Hatası!", 0).show(); }
            });
        });
    }
    void start() { startActivity(new Intent(this, DashboardActivity.class)); finish(); }
}
EOF

cat << EOF > $PKG_DIR/ui/DashboardActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.utils.PrefUtils;

public class DashboardActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dashboard);
        ((TextView)findViewById(R.id.tvUser)).setText("Hoşgeldin: " + PrefUtils.getU(this));
        findViewById(R.id.btnLive).setOnClickListener(v -> startActivity(new Intent(this, LiveActivity.class)));
        findViewById(R.id.btnLogout).setOnClickListener(v -> { PrefUtils.logout(this); startActivity(new Intent(this, LoginActivity.class)); finish(); });
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
import com.merdolda.player.api.XtreamApi;
import com.merdolda.player.model.XtreamData.*;
import com.merdolda.player.utils.PrefUtils;
import java.util.ArrayList;
import java.util.List;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;

public class LiveActivity extends AppCompatActivity {
    XtreamApi api; RecyclerView rvC, rvS; StreamAdapter sAdapter;
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_live);
        rvC = findViewById(R.id.rvCats); rvS = findViewById(R.id.rvStreams);
        rvC.setLayoutManager(new LinearLayoutManager(this));
        rvS.setLayoutManager(new GridLayoutManager(this, 3));
        sAdapter = new StreamAdapter(new ArrayList<>(), s -> {
            Intent i = new Intent(this, PlayerActivity.class);
            i.putExtra("url", PrefUtils.getD(this)+"/live/"+PrefUtils.getU(this)+"/"+PrefUtils.getP(this)+"/"+s.streamId+".ts");
            startActivity(i);
        });
        rvS.setAdapter(sAdapter);
        api = new Retrofit.Builder().baseUrl(PrefUtils.getD(this)+"/").addConverterFactory(GsonConverterFactory.create()).build().create(XtreamApi.class);
        loadCats();
    }
    void loadCats() {
        api.getCategories(PrefUtils.getU(this), PrefUtils.getP(this), "get_live_categories").enqueue(new Callback<List<Category>>() {
            public void onResponse(Call<List<Category>> c, Response<List<Category>> r) {
                if(r.body() != null) rvC.setAdapter(new CategoryAdapter(r.body(), cat -> loadStreams(cat.id)));
            }
            public void onFailure(Call<List<Category>> c, Throwable t) {}
        });
    }
    void loadStreams(String id) {
        api.getStreams(PrefUtils.getU(this), PrefUtils.getP(this), "get_live_streams", id).enqueue(new Callback<List<StreamItem>>() {
            public void onResponse(Call<List<StreamItem>> c, Response<List<StreamItem>> r) {
                if(r.body() != null) sAdapter.update(r.body());
            }
            public void onFailure(Call<List<StreamItem>> c, Throwable t) {}
        });
    }
}
EOF

cat << EOF > $PKG_DIR/ui/PlayerActivity.java
package com.merdolda.player.ui;
import android.net.Uri;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.*;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.merdolda.player.R;

public class PlayerActivity extends AppCompatActivity {
    ExoPlayer p;
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_player);
        StyledPlayerView v = findViewById(R.id.player_view);
        p = new ExoPlayer.Builder(this).build();
        v.setPlayer(p);
        String url = getIntent().getStringExtra("url");
        if(url != null) { p.setMediaItem(MediaItem.fromUri(Uri.parse(url))); p.prepare(); p.play(); }
    }
    @Override protected void onDestroy() { super.onDestroy(); if(p != null) p.release(); }
}
EOF

# 9. MANIFEST
cat << 'EOF' > $MODULE_DIR/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <application android:name="androidx.multidex.MultiDexApplication" android:label="ErdinPlayer" android:theme="@style/Theme.AppCompat.NoActionBar" android:usesCleartextTraffic="true" android:icon="@drawable/ic_launcher_background">
        <activity android:name=".ui.LoginActivity" android:exported="true" android:screenOrientation="landscape">
            <intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /><category android:name="android.intent.category.LEANBACK_LAUNCHER" /></intent-filter>
        </activity>
        <activity android:name=".ui.DashboardActivity" android:screenOrientation="landscape" />
        <activity android:name=".ui.LiveActivity" android:screenOrientation="landscape" />
        <activity android:name=".ui.PlayerActivity" android:screenOrientation="landscape" />
    </application>
</manifest>
EOF

# 10. GRADLEW OLUŞTURUCU
cd $PROJECT_ROOT
gradle wrapper --gradle-version 8.4
chmod +x gradlew
cd ..

echo "✅ TÜM SİSTEM VE MODELLER HAZIR."
