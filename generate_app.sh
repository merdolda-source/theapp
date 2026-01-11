#!/bin/bash

# --- KONFİGÜRASYON ---
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="com/merdolda/player"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "💎 ERDINPLAYER v5.0: TÜM SİSTEM VE SINIFLAR İNŞA EDİLİYOR..."

# 1. KLASÖR YAPILANDIRMASI
rm -rf $PROJECT_ROOT
mkdir -p $PKG_DIR/{model,adapter,api,utils,ui}
mkdir -p $RES_DIR/{layout,values,drawable,anim,menu}
mkdir -p $PROJECT_ROOT/gradle/wrapper

# 2. KEYSTORE
keytool -genkey -v -keystore $MODULE_DIR/release.keystore -alias erdinplayer -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=Erdin, O=ErdinPlayer, C=TR" 2>/dev/null

# 3. GRADLE 8.4 VE BAĞIMLILIKLAR
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

# 4. RESOURCES (COLORS & XMLS)
cat << 'EOF' > $RES_DIR/values/colors.xml
<resources>
    <color name="bg_dark">#0A0E14</color>
    <color name="bg_card">#161B22</color>
    <color name="accent_cyan">#00E5FF</color>
    <color name="primary_red">#BD081C</color>
    <color name="white">#FFFFFF</color>
    <color name="gray_text">#8B949E</color>
</resources>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_launcher_background.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#0A0E14" android:pathData="M0,0h108v108h-108z"/></vector>
EOF

cat << 'EOF' > $RES_DIR/menu/bottom_nav_menu.xml
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:id="@+id/nav_home" android:title="Home" android:icon="@android:drawable/ic_menu_today"/>
    <item android:id="@+id/nav_live" android:title="Live" android:icon="@android:drawable/ic_menu_view"/>
    <item android:id="@+id/nav_movies" android:title="Movies" android:icon="@android:drawable/ic_menu_slideshow"/>
    <item android:id="@+id/nav_series" android:title="Series" android:icon="@android:drawable/ic_menu_gallery"/>
</menu>
EOF

# 5. MODELLER
cat << EOF > $PKG_DIR/model/AppModels.java
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.List;
public class AppModels {
    public static class Playlist implements Serializable {
        public String id, name, type, url, user, pass, ref, ori;
    }
    public static class XtreamLogin implements Serializable { @SerializedName("user_info") public UserInfo userInfo; }
    public static class UserInfo implements Serializable { @SerializedName("username") public String username; @SerializedName("auth") public int auth; }
    public static class Category implements Serializable { @SerializedName("category_id") public String id; @SerializedName("category_name") public String name; }
    public static class StreamItem implements Serializable { 
        @SerializedName("name") public String name; @SerializedName("stream_id") public String streamId; 
        @SerializedName("series_id") public String seriesId; @SerializedName("stream_icon") public String icon; 
        @SerializedName("container_extension") public String ext; 
    }
}
EOF

# 6. UTILS & API
cat << EOF > $PKG_DIR/utils/PrefUtils.java
package com.merdolda.player.utils;
import android.content.*;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.merdolda.player.model.AppModels.Playlist;
import java.util.*;
public class PrefUtils {
    private static SharedPreferences get(Context c) { return c.getSharedPreferences("PRO_P",0); }
    public static void savePlaylist(Context c, Playlist p) {
        List<Playlist> list = getPlaylists(c); list.add(p);
        get(c).edit().putString("L", new Gson().toJson(list)).putString("A", p.id).apply();
    }
    public static List<Playlist> getPlaylists(Context c) {
        String j = get(c).getString("L", "[]");
        return new Gson().fromJson(j, new TypeToken<List<Playlist>>(){}.getType());
    }
    public static Playlist getActive(Context c) {
        String id = get(c).getString("A", "");
        for(Playlist p : getPlaylists(c)) if(p.id.equals(id)) return p;
        return null;
    }
    public static void logout(Context c) { get(c).edit().clear().apply(); }
}
EOF

cat << EOF > $PKG_DIR/api/XtreamApi.java
package com.merdolda.player.api;
import com.merdolda.player.model.AppModels.*;
import java.util.List;
import retrofit2.Call;
import retrofit2.http.*;
public interface XtreamApi {
    @GET("player_api.php") Call<LoginResponse> login(@Url String url, @Query("username") String u, @Query("password") String p);
    @GET("player_api.php") Call<List<Category>> getCategories(@Url String url, @Query("username") String u, @Query("password") String p, @Query("action") String a);
    @GET("player_api.php") Call<List<StreamItem>> getStreams(@Url String url, @Query("username") String u, @Query("password") String p, @Query("action") String a, @Query("category_id") String c);
}
EOF

# 7. ADAPTERLER
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
    private List<Category> list; private OnClick listener; private int sel = 0;
    public interface OnClick { void onClick(Category item); }
    public CategoryAdapter(List<Category> list, OnClick listener) { this.list = list; this.listener = listener; }
    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) { return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_category, p, false)); }
    @Override public void onBindViewHolder(@NonNull VH h, int p) {
        h.t.setText(list.get(p).name); h.t.setTextColor(sel == p ? Color.CYAN : Color.WHITE);
        h.itemView.setOnClickListener(v -> { int o = sel; sel = h.getAdapterPosition(); notifyItemChanged(o); notifyItemChanged(sel); listener.onClick(list.get(p)); });
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
    private List<StreamItem> list; private OnClick listener;
    public interface OnClick { void onClick(StreamItem item); }
    public StreamAdapter(List<StreamItem> list, OnClick listener) { this.list = list; this.listener = listener; }
    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) { return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_channel, p, false)); }
    @Override public void onBindViewHolder(@NonNull VH h, int p) {
        StreamItem i = list.get(p); h.t.setText(i.name);
        Glide.with(h.itemView.getContext()).load(i.icon).placeholder(R.drawable.ic_launcher_background).into(h.i);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
    }
    @Override public int getItemCount() { return list == null ? 0 : list.size(); }
    public void update(List<StreamItem> n) { this.list = n; notifyDataSetChanged(); }
    class VH extends RecyclerView.ViewHolder { TextView t; ImageView i; VH(View v) { super(v); t = v.findViewById(R.id.tvName); i = v.findViewById(R.id.ivIcon); } }
}
EOF

# 8. LAYOUTS (R.layout HATALARINI ÇÖZEN KISIM)
cat << 'EOF' > $RES_DIR/layout/activity_selection.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_dark" android:orientation="vertical" android:gravity="center" android:padding="20dp">
    <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="ERDIN PLAYER" android:textColor="@color/accent_cyan" android:textSize="36sp" android:textStyle="bold" android:layout_marginBottom="60dp"/>
    <Button android:id="@+id/btnXtream" android:layout_width="match_parent" android:height="70dp" android:layout_height="70dp" android:text="Xtream API Codes" android:backgroundTint="@color/primary_red" android:layout_marginBottom="15dp"/>
    <Button android:id="@+id/btnSingle" android:layout_width="match_parent" android:height="70dp" android:layout_height="70dp" android:text="1 Akışı Oynat" android:backgroundTint="@color/primary_red"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_login_xtream.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_dark" android:orientation="vertical" android:padding="25dp" android:gravity="center">
    <EditText android:id="@+id/etUser" android:layout_width="match_parent" android:layout_height="60dp" android:hint="User" android:textColor="#FFF" android:background="@color/bg_card" android:padding="10dp" android:layout_marginBottom="15dp"/>
    <EditText android:id="@+id/etPass" android:layout_width="match_parent" android:layout_height="60dp" android:hint="Pass" android:inputType="textPassword" android:textColor="#FFF" android:background="@color/bg_card" android:padding="10dp" android:layout_marginBottom="15dp"/>
    <EditText android:id="@+id/etDns" android:layout_width="match_parent" android:layout_height="60dp" android:hint="URL" android:textColor="#FFF" android:background="@color/bg_card" android:padding="10dp" android:layout_marginBottom="30dp"/>
    <Button android:id="@+id/btnLogin" android:layout_width="match_parent" android:layout_height="60dp" android:text="ADD PLAYLIST" android:backgroundTint="@color/primary_red"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_dashboard.xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android" xmlns:app="http://schemas.android.com/apk/res-auto" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_dark">
    <LinearLayout android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="15dp" android:layout_above="@+id/bottomNav">
        <Button android:id="@+id/btnLive" android:layout_width="match_parent" android:layout_height="120dp" android:text="LIVE TV" android:backgroundTint="@color/bg_card" android:layout_marginBottom="15dp"/>
        <Button android:id="@+id/btnMovies" android:layout_width="match_parent" android:layout_height="120dp" android:text="MOVIES" android:backgroundTint="@color/bg_card"/>
    </LinearLayout>
    <com.google.android.material.bottomnavigation.BottomNavigationView android:id="@+id/bottomNav" android:layout_width="match_parent" android:layout_height="70dp" android:layout_alignParentBottom="true" app:menu="@menu/bottom_nav_menu" android:background="@color/bg_card" app:itemIconTint="@color/accent_cyan"/>
</RelativeLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_list.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_dark" android:orientation="vertical">
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvCats" android:layout_width="match_parent" android:layout_height="60dp" android:background="@color/bg_card"/>
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvStreams" android:layout_width="match_parent" android:layout_height="match_parent" android:padding="10dp"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_player.xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000">
    <com.google.android.exoplayer2.ui.StyledPlayerView android:id="@+id/player_view" android:layout_width="match_parent" android:layout_height="match_parent"/>
</FrameLayout>
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

cat << 'EOF' > $RES_DIR/layout/activity_login_single.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_dark" android:orientation="vertical" android:padding="25dp" android:gravity="center">
    <EditText android:id="@+id/etUrl" android:layout_width="match_parent" android:layout_height="60dp" android:hint="Stream URL" android:textColor="#FFF" android:background="@color/bg_card" android:padding="10dp" android:layout_marginBottom="15dp"/>
    <EditText android:id="@+id/etRef" android:layout_width="match_parent" android:layout_height="60dp" android:hint="Referer" android:textColor="#FFF" android:background="@color/bg_card" android:padding="10dp" android:layout_marginBottom="15dp"/>
    <EditText android:id="@+id/etOri" android:layout_width="match_parent" android:layout_height="60dp" android:hint="Origin" android:textColor="#FFF" android:background="@color/bg_card" android:padding="10dp" android:layout_marginBottom="30dp"/>
    <Button android:id="@+id/btnPlay" android:layout_width="match_parent" android:layout_height="60dp" android:text="ADD PLAYLIST" android:backgroundTint="@color/primary_red"/>
</LinearLayout>
EOF

# 9. UI ACTIVITIES (FULL CODE)
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
        if(PrefUtils.getActive(this) != null) { startActivity(new Intent(this, DashboardActivity.class)); finish(); return; }
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
import com.merdolda.player.model.AppModels.*;
import com.merdolda.player.utils.PrefUtils;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;
public class LoginXtreamActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_login_xtream);
        EditText u = findViewById(R.id.etUser), p = findViewById(R.id.etPass), d = findViewById(R.id.etDns);
        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String url = d.getText().toString(); if(!url.startsWith("http")) url = "http://"+url;
            Retrofit r = new Retrofit.Builder().baseUrl(url+"/").addConverterFactory(GsonConverterFactory.create()).build();
            final String fU = url;
            r.create(XtreamApi.class).login(fU+"/player_api.php", u.getText().toString(), p.getText().toString()).enqueue(new Callback<LoginResponse>() {
                public void onResponse(Call<LoginResponse> c, Response<LoginResponse> res) {
                    if(res.body()!=null && res.body().userInfo.auth==1) {
                        Playlist pl = new Playlist(); pl.id = UUID.randomUUID().toString(); pl.type="X"; pl.url=fU; pl.user=u.getText().toString(); pl.pass=p.getText().toString();
                        PrefUtils.savePlaylist(LoginXtreamActivity.this, pl); startActivity(new Intent(LoginXtreamActivity.this, DashboardActivity.class)); finish();
                    } else Toast.makeText(LoginXtreamActivity.this, "Error!", 0).show();
                }
                public void onFailure(Call<LoginResponse> c, Throwable t) { Toast.makeText(LoginXtreamActivity.this, "Network Error!", 0).show(); }
            });
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
import com.merdolda.player.model.AppModels.Playlist;
import com.merdolda.player.utils.PrefUtils;
import java.util.UUID;
public class LoginSingleActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_login_single);
        EditText u = findViewById(R.id.etUrl), r = findViewById(R.id.etRef), o = findViewById(R.id.etOri);
        findViewById(R.id.btnPlay).setOnClickListener(v -> {
            Playlist pl = new Playlist(); pl.id = UUID.randomUUID().toString(); pl.type="S"; pl.url=u.getText().toString(); pl.ref=r.getText().toString(); pl.ori=o.getText().toString();
            PrefUtils.savePlaylist(this, pl); startActivity(new Intent(this, DashboardActivity.class)); finish();
        });
    }
}
EOF

cat << EOF > $PKG_DIR/ui/DashboardActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.utils.PrefUtils;
public class DashboardActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_dashboard);
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
    XtreamApi api; RecyclerView rvC, rvS; StreamAdapter adp; String type; Playlist p;
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_list);
        type = getIntent().getStringExtra("type"); p = PrefUtils.getActive(this);
        rvC = findViewById(R.id.rvCats); rvS = findViewById(R.id.rvStreams);
        rvC.setLayoutManager(new LinearLayoutManager(this, 0, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));
        adp = new StreamAdapter(new ArrayList<>(), i -> {
            Intent in = new Intent(this, PlayerActivity.class);
            String url = p.url + "/" + (type.equals("live") ? "live" : "movie") + "/" + p.user + "/" + p.pass + "/" + i.streamId + "." + (i.ext!=null?i.ext:"ts");
            in.putExtra("url", url); startActivity(in);
        });
        rvS.setAdapter(adp);
        api = new Retrofit.Builder().baseUrl(p.url+"/").addConverterFactory(GsonConverterFactory.create()).build().create(XtreamApi.class);
        load();
    }
    void load() {
        String a = type.equals("live") ? "get_live_categories" : "get_vod_categories";
        api.getCategories(p.url+"/player_api.php", p.user, p.pass, a).enqueue(new Callback<List<Category>>() {
            public void onResponse(Call<List<Category>> c, Response<List<Category>> r) { if(r.body()!=null) rvC.setAdapter(new CategoryAdapter(r.body(), cat -> loadItems(cat.id))); }
            public void onFailure(Call<List<Category>> c, Throwable t) {}
        });
    }
    void loadItems(String id) {
        String a = type.equals("live") ? "get_live_streams" : "get_vod_streams";
        api.getStreams(p.url+"/player_api.php", p.user, p.pass, a, id).enqueue(new Callback<List<StreamItem>>() {
            public void onResponse(Call<List<StreamItem>> c, Response<List<StreamItem>> r) { if(r.body()!=null) adp.update(r.body()); }
            public void onFailure(Call<List<StreamItem>> c, Throwable t) {}
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
import com.merdolda.player.utils.PrefUtils;
import com.merdolda.player.model.AppModels.Playlist;
import java.util.*;
public class PlayerActivity extends AppCompatActivity {
    ExoPlayer p;
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        setContentView(R.layout.activity_player);
        StyledPlayerView pv = findViewById(R.id.player_view);
        String url = getIntent().getStringExtra("url");
        Playlist pl = PrefUtils.getActive(this);
        DefaultHttpDataSource.Factory f = new DefaultHttpDataSource.Factory();
        Map<String, String> h = new HashMap<>();
        if(pl != null) {
            if(pl.ref != null && !pl.ref.isEmpty()) h.put("Referer", pl.ref);
            if(pl.ori != null && !pl.ori.isEmpty()) h.put("Origin", pl.ori);
        }
        f.setDefaultRequestProperties(h);
        p = new ExoPlayer.Builder(this).setMediaSourceFactory(new DefaultMediaSourceFactory(f)).build();
        pv.setPlayer(p);
        if(url != null) { p.setMediaItem(MediaItem.fromUri(Uri.parse(url))); p.prepare(); p.play(); }
    }
    @Override protected void onDestroy() { super.onDestroy(); if(p != null) p.release(); }
}
EOF

# 10. MANIFEST (CONFIGCHANGES DAHİL)
cat << 'EOF' > $MODULE_DIR/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application android:name="androidx.multidex.MultiDexApplication" android:label="ErdinPlayer" android:theme="@style/Theme.AppCompat.NoActionBar" android:usesCleartextTraffic="true" android:icon="@drawable/ic_launcher_background">
        <activity android:name=".ui.SelectionActivity" android:exported="true" android:screenOrientation="portrait"><intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter></activity>
        <activity android:name=".ui.LoginXtreamActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.LoginSingleActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.DashboardActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.CommonListActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.PlayerActivity" android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize" android:screenOrientation="sensor" />
    </application>
</manifest>
EOF

# 11. GRADLEW OLUŞTURMA VE BİTİRİŞ
cd $PROJECT_ROOT
gradle wrapper --gradle-version 8.4
chmod +x gradlew
cd ..

echo "✅ TÜM SİSTEM VE SINIFLAR (FULL VERSION) HAZIR. ŞİMDİ PUSH YAPIN!"
