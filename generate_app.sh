#!/bin/bash

# --- KONFİGÜRASYON ---
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="com/merdolda/player"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "💎 ERDINPLAYER FULL PRO: SİSTEM İNŞA EDİLYOR..."

# 1. KLASÖR YAPILANDIRMASI
rm -rf $PROJECT_ROOT
mkdir -p $PKG_DIR/{model,adapter,api,utils,ui}
mkdir -p $RES_DIR/{layout,values,drawable,anim}
mkdir -p $PROJECT_ROOT/gradle/wrapper

# 2. KEYSTORE (İMZA)
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
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
}
EOF

# 4. KAYNAKLAR (COLORS & DRAWABLES)
cat << 'EOF' > $RES_DIR/values/colors.xml
<resources>
    <color name="bg_dark">#0F172A</color>
    <color name="bg_card">#1E293B</color>
    <color name="accent_red">#BD081C</color>
    <color name="white">#FFFFFF</color>
    <color name="gray_text">#94A3B8</color>
</resources>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_launcher_background.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#0F172A" android:pathData="M0,0h108v108h-108z"/></vector>
EOF

cat << 'EOF' > $RES_DIR/drawable/btn_selector.xml
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:state_focused="true" android:drawable="@color/accent_red" />
    <item android:drawable="@color/bg_card" />
</selector>
EOF

# 5. MODELLER (XTREAM DATA SCHEMA)
cat << EOF > $PKG_DIR/model/AppModels.java
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
public class AppModels {
    public static class UserInfo implements Serializable { @SerializedName("username") public String username; @SerializedName("auth") public int auth; }
    public static class ServerInfo implements Serializable { @SerializedName("url") public String url; @SerializedName("port") public String port; }
    public static class LoginResponse implements Serializable { @SerializedName("user_info") public UserInfo userInfo; @SerializedName("server_info") public ServerInfo serverInfo; }
    public static class Category implements Serializable { @SerializedName("category_id") public String id; @SerializedName("category_name") public String name; }
    public static class StreamItem implements Serializable { 
        @SerializedName("name") public String name; @SerializedName("stream_id") public String streamId; 
        @SerializedName("series_id") public String seriesId; @SerializedName("stream_icon") public String icon; 
        @SerializedName("container_extension") public String ext; 
    }
}
EOF

# 6. ADAPTERLER
cat << EOF > $PKG_DIR/adapter/CategoryAdapter.java
package com.merdolda.player.adapter;
import android.graphics.Color;
import android.view.*;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.merdolda.player.R;
import com.merdolda.player.model.AppModels.Category;
import java.util.List;
public class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.VH> {
    private List<Category> list; private OnClick listener; private int selected = 0;
    public interface OnClick { void onClick(Category item); }
    public CategoryAdapter(List<Category> list, OnClick listener) { this.list = list; this.listener = listener; }
    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) { return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_category, p, false)); }
    @Override public void onBindViewHolder(@NonNull VH h, int p) {
        h.t.setText(list.get(p).name); h.t.setTextColor(selected == p ? Color.parseColor("#BD081C") : Color.WHITE);
        h.itemView.setOnClickListener(v -> { int old = selected; selected = h.getAdapterPosition(); notifyItemChanged(old); notifyItemChanged(selected); listener.onClick(list.get(p)); });
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
import com.merdolda.player.model.AppModels.StreamItem;
import java.util.List;
public class StreamAdapter extends RecyclerView.Adapter<StreamAdapter.VH> {
    private List<StreamItem> list; private OnItemClick listener;
    public interface OnItemClick { void onClick(StreamItem item); }
    public StreamAdapter(List<StreamItem> list, OnItemClick listener) { this.list = list; this.listener = listener; }
    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) { return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_channel, p, false)); }
    @Override public void onBindViewHolder(@NonNull VH h, int p) {
        StreamItem i = list.get(p); h.txt.setText(i.name);
        Glide.with(h.itemView.getContext()).load(i.icon).placeholder(R.drawable.ic_launcher_background).into(h.img);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
    }
    @Override public int getItemCount() { return list == null ? 0 : list.size(); }
    public void update(List<StreamItem> newList) { this.list = newList; notifyDataSetChanged(); }
    class VH extends RecyclerView.ViewHolder { TextView txt; ImageView img; VH(View v) { super(v); txt = v.findViewById(R.id.tvName); img = v.findViewById(R.id.ivIcon); } }
}
EOF

# 7. UTILS & API
cat << EOF > $PKG_DIR/utils/PrefUtils.java
package com.merdolda.player.utils;
import android.content.*;
public class PrefUtils {
    public static void save(Context c, String d, String u, String p) { c.getSharedPreferences("X",0).edit().putString("d",d).putString("u",u).putString("p",p).apply(); }
    public static String get(Context c, String k) { return c.getSharedPreferences("X",0).getString(k, ""); }
    public static void logout(Context c) { c.getSharedPreferences("X",0).edit().clear().apply(); }
}
EOF

cat << EOF > $PKG_DIR/api/XtreamApi.java
package com.merdolda.player.api;
import com.merdolda.player.model.AppModels.*;
import java.util.List;
import retrofit2.Call;
import retrofit2.http.*;
public interface XtreamApi {
    @GET("player_api.php") Call<LoginResponse> login(@Query("username") String u, @Query("password") String p);
    @GET("player_api.php") Call<List<Category>> getCategories(@Query("username") String u, @Query("password") String p, @Query("action") String a);
    @GET("player_api.php") Call<List<StreamItem>> getStreams(@Query("username") String u, @Query("password") String p, @Query("action") String a, @Query("category_id") String c);
}
EOF

# 8. LAYOUTS
cat << 'EOF' > $RES_DIR/layout/activity_selection.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_dark" android:orientation="vertical" android:gravity="center" android:padding="20dp">
    <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="ERDIN PLAYER" android:textColor="@color/accent_red" android:textSize="36sp" android:textStyle="bold" android:layout_marginBottom="60dp"/>
    <Button android:id="@+id/btnXtream" android:layout_width="match_parent" android:layout_height="75dp" android:text="Add API Codes (Xtream Ui)" android:backgroundTint="@color/accent_red" android:layout_marginBottom="15dp"/>
    <Button android:id="@+id/btnSingle" android:layout_width="match_parent" android:layout_height="75dp" android:text="1 Akışı Oynat" android:backgroundTint="@color/accent_red"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_login_xtream.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_dark" android:orientation="vertical" android:padding="25dp" android:gravity="center">
    <EditText android:id="@+id/etUser" android:layout_width="match_parent" android:layout_height="60dp" android:hint="Kullanıcı Adı" android:textColor="#FFF" android:background="@color/bg_card" android:padding="15dp" android:layout_marginBottom="15dp"/>
    <EditText android:id="@+id/etPass" android:layout_width="match_parent" android:layout_height="60dp" android:hint="Şifre" android:inputType="textPassword" android:textColor="#FFF" android:background="@color/bg_card" android:padding="15dp" android:layout_marginBottom="15dp"/>
    <EditText android:id="@+id/etDns" android:layout_width="match_parent" android:layout_height="60dp" android:hint="http://dns.com:80" android:textColor="#FFF" android:background="@color/bg_card" android:padding="15dp" android:layout_marginBottom="30dp"/>
    <Button android:id="@+id/btnLogin" android:layout_width="match_parent" android:layout_height="60dp" android:text="GİRİŞ YAP" android:backgroundTint="@color/accent_red"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_dashboard.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_dark" android:orientation="vertical" android:padding="20dp" android:gravity="center">
    <TextView android:id="@+id/tvUser" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="@color/white" android:textSize="18sp" android:layout_marginBottom="30dp" android:text="Kullanıcı"/>
    <Button android:id="@+id/btnLive" android:layout_width="match_parent" android:layout_height="120dp" android:text="CANLI TV" android:backgroundTint="@color/bg_card" android:layout_marginBottom="15dp"/>
    <Button android:id="@+id/btnMovies" android:layout_width="match_parent" android:layout_height="120dp" android:text="FİLMLER" android:backgroundTint="@color/bg_card" android:layout_marginBottom="15dp"/>
    <Button android:id="@+id/btnLogout" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="ÇIKIŞ" android:backgroundTint="@color/accent_red"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_list.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:background="@color/bg_dark">
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvCats" android:layout_width="match_parent" android:layout_height="60dp" android:background="@color/bg_card"/>
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvStreams" android:layout_width="match_parent" android:layout_height="match_parent" android:padding="10dp"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/item_channel.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="wrap_content" android:padding="10dp" android:background="@color/bg_card" android:layout_marginBottom="5dp" android:orientation="horizontal">
    <ImageView android:id="@+id/ivIcon" android:layout_width="60dp" android:layout_height="80dp" android:scaleType="centerInside"/>
    <TextView android:id="@+id/tvName" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:textSize="16sp" android:layout_marginLeft="15dp" android:layout_gravity="center"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/item_category.xml
<TextView xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/tvCatName" android:layout_width="wrap_content" android:layout_height="match_parent" android:gravity="center" android:paddingLeft="20dp" android:paddingRight="20dp" android:textColor="#FFF" android:textSize="14sp" android:textStyle="bold"/>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_player.xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000"><com.google.android.exoplayer2.ui.StyledPlayerView android:id="@+id/player_view" android:layout_width="match_parent" android:layout_height="match_parent"/></FrameLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_login_single.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_dark" android:orientation="vertical" android:padding="25dp" android:gravity="center">
    <EditText android:id="@+id/etUrl" android:layout_width="match_parent" android:layout_height="60dp" android:hint="Akış URL'si" android:textColor="#FFF" android:background="@color/bg_card" android:padding="15dp" android:layout_marginBottom="15dp"/>
    <EditText android:id="@+id/etRef" android:layout_width="match_parent" android:layout_height="60dp" android:hint="Referer" android:textColor="#FFF" android:background="@color/bg_card" android:padding="15dp" android:layout_marginBottom="15dp"/>
    <EditText android:id="@+id/etOri" android:layout_width="match_parent" android:layout_height="60dp" android:hint="Origin" android:textColor="#FFF" android:background="@color/bg_card" android:padding="15dp" android:layout_marginBottom="30dp"/>
    <Button android:id="@+id/btnPlay" android:layout_width="match_parent" android:layout_height="60dp" android:text="Add Playlist" android:backgroundTint="@color/accent_red"/>
</LinearLayout>
EOF

# 9. UI ACTIVITIES (TAM İÇERİKLİ)

cat << EOF > $PKG_DIR/ui/SelectionActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.utils.PrefUtils;
public class SelectionActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        if(!PrefUtils.get(this, "u").isEmpty()){ startActivity(new Intent(this, DashboardActivity.class)); finish(); }
        setContentView(R.layout.activity_selection);
        findViewById(R.id.btnXtream).setOnClickListener(v -> startActivity(new Intent(this, LoginXtreamActivity.class)));
        findViewById(R.id.btnSingle).setOnClickListener(v -> startActivity(new Intent(this, LoginSingleActivity.class)));
    }
}
EOF

cat << EOF > $PKG_DIR/ui/LoginXtreamActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.api.XtreamApi;
import com.merdolda.player.model.AppModels.LoginResponse;
import com.merdolda.player.utils.PrefUtils;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;
public class LoginXtreamActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_login_xtream);
        EditText u = findViewById(R.id.etUser), p = findViewById(R.id.etPass), d = findViewById(R.id.etDns);
        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String url = d.getText().toString(); if(!url.startsWith("http")) url = "http://" + url;
            Retrofit r = new Retrofit.Builder().baseUrl(url+"/").addConverterFactory(GsonConverterFactory.create()).build();
            final String finalUrl = url;
            r.create(XtreamApi.class).login(u.getText().toString(), p.getText().toString()).enqueue(new Callback<LoginResponse>() {
                public void onResponse(Call<LoginResponse> c, Response<LoginResponse> res) {
                    if(res.body() != null && res.body().userInfo != null && res.body().userInfo.auth == 1) {
                        PrefUtils.save(LoginXtreamActivity.this, finalUrl, u.getText().toString(), p.getText().toString());
                        startActivity(new Intent(LoginXtreamActivity.this, DashboardActivity.class)); finish();
                    } else Toast.makeText(LoginXtreamActivity.this, "Hata!", 0).show();
                }
                public void onFailure(Call<LoginResponse> c, Throwable t) { Toast.makeText(LoginXtreamActivity.this, "Bağlantı Yok!", 0).show(); }
            });
        });
    }
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
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_dashboard);
        ((TextView)findViewById(R.id.tvUser)).setText("Hoşgeldin: " + PrefUtils.get(this, "u"));
        findViewById(R.id.btnLive).setOnClickListener(v -> { Intent i = new Intent(this, CommonListActivity.class); i.putExtra("type", "live"); startActivity(i); });
        findViewById(R.id.btnMovies).setOnClickListener(v -> { Intent i = new Intent(this, CommonListActivity.class); i.putExtra("type", "vod"); startActivity(i); });
        findViewById(R.id.btnLogout).setOnClickListener(v -> { PrefUtils.logout(this); startActivity(new Intent(this, SelectionActivity.class)); finish(); });
    }
}
EOF

cat << EOF > $PKG_DIR/ui/CommonListActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.*;
import com.merdolda.player.R;
import com.merdolda.player.adapter.*;
import com.merdolda.player.api.XtreamApi;
import com.merdolda.player.model.AppModels.*;
import com.merdolda.player.utils.PrefUtils;
import java.util.*;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;
public class CommonListActivity extends AppCompatActivity {
    XtreamApi api; RecyclerView rvC, rvS; StreamAdapter sAdapter; String type;
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_list);
        type = getIntent().getStringExtra("type");
        rvC = findViewById(R.id.rvCats); rvS = findViewById(R.id.rvStreams);
        rvC.setLayoutManager(new LinearLayoutManager(this, 0, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));
        sAdapter = new StreamAdapter(new ArrayList<>(), item -> {
            Intent i = new Intent(this, PlayerActivity.class);
            String url = PrefUtils.get(this,"d") + "/" + (type.equals("live") ? "live" : "movie") + "/" + PrefUtils.get(this,"u") + "/" + PrefUtils.get(this,"p") + "/" + item.streamId + "." + (item.ext!=null?item.ext:"ts");
            i.putExtra("url", url); startActivity(i);
        });
        rvS.setAdapter(sAdapter);
        api = new Retrofit.Builder().baseUrl(PrefUtils.get(this, "d")+"/").addConverterFactory(GsonConverterFactory.create()).build().create(XtreamApi.class);
        load();
    }
    void load() {
        String action = type.equals("live") ? "get_live_categories" : "get_vod_categories";
        api.getCategories(PrefUtils.get(this,"u"), PrefUtils.get(this,"p"), action).enqueue(new Callback<List<Category>>() {
            public void onResponse(Call<List<Category>> c, Response<List<Category>> r) { if(r.body()!=null) rvC.setAdapter(new CategoryAdapter(r.body(), cat -> loadItems(cat.id))); }
            public void onFailure(Call<List<Category>> c, Throwable t) {}
        });
    }
    void loadItems(String id) {
        String action = type.equals("live") ? "get_live_streams" : "get_vod_streams";
        api.getStreams(PrefUtils.get(this,"u"), PrefUtils.get(this,"p"), action, id).enqueue(new Callback<List<StreamItem>>() {
            public void onResponse(Call<List<StreamItem>> c, Response<List<StreamItem>> r) { if(r.body()!=null) sAdapter.update(r.body()); }
            public void onFailure(Call<List<StreamItem>> c, Throwable t) {}
        });
    }
}
EOF

cat << EOF > $PKG_DIR/ui/LoginSingleActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
public class LoginSingleActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_login_single);
        EditText u = findViewById(R.id.etUrl), r = findViewById(R.id.etRef), o = findViewById(R.id.etOri);
        findViewById(R.id.btnPlay).setOnClickListener(v -> {
            Intent i = new Intent(this, PlayerActivity.class);
            i.putExtra("url", u.getText().toString()); i.putExtra("referer", r.getText().toString()); i.putExtra("origin", o.getText().toString());
            startActivity(i);
        });
    }
}
EOF

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
import java.util.*;
public class PlayerActivity extends AppCompatActivity {
    ExoPlayer player;
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        setContentView(R.layout.activity_player);
        StyledPlayerView pv = findViewById(R.id.player_view);
        String url = getIntent().getStringExtra("url");
        String ref = getIntent().getStringExtra("referer");
        String ori = getIntent().getStringExtra("origin");
        DefaultHttpDataSource.Factory httpFactory = new DefaultHttpDataSource.Factory();
        Map<String, String> headers = new HashMap<>();
        if(ref != null && !ref.isEmpty()) headers.put("Referer", ref);
        if(ori != null && !ori.isEmpty()) headers.put("Origin", ori);
        httpFactory.setDefaultRequestProperties(headers);
        player = new ExoPlayer.Builder(this).setMediaSourceFactory(new DefaultMediaSourceFactory(httpFactory)).build();
        pv.setPlayer(player);
        if(url != null) { player.setMediaItem(MediaItem.fromUri(Uri.parse(url))); player.prepare(); player.play(); }
    }
    @Override protected void onDestroy() { super.onDestroy(); if(player != null) player.release(); }
}
EOF

# 10. MANIFEST
cat << 'EOF' > $MODULE_DIR/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application android:name="androidx.multidex.MultiDexApplication" android:label="ErdinPlayer" android:theme="@style/Theme.AppCompat.NoActionBar" android:usesCleartextTraffic="true" android:icon="@drawable/ic_launcher_background">
        <activity android:name=".ui.SelectionActivity" android:exported="true" android:screenOrientation="portrait"><intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter></activity>
        <activity android:name=".ui.LoginXtreamActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.LoginSingleActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.DashboardActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.CommonListActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.PlayerActivity" android:screenOrientation="sensor" />
    </application>
</manifest>
EOF

# 11. GRADLEW OLUŞTURMA
cd $PROJECT_ROOT
gradle wrapper --gradle-version 8.4
chmod +x gradlew
cd ..

echo "✅ TÜM SİSTEM (2000+ LINES CAPACITY) VE SINIFLAR HAZIR. PUSH YAPIN!"
