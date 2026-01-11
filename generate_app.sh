#!/bin/bash

# --- AYARLAR (HATA BURADAYDI, DÜZELTİLDİ) ---
PROJECT_ROOT="theapp"  # GitHub Workflow'un beklediği isim
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="com/merdolda/player"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "💎 ERDINPLAYER ULTIMATE v11.0: KLASÖR YAPISI ONARILIYOR VE SİSTEM KURULUYOR..."

# 1. TEMİZLİK & KLASÖRLER
if [ -d "$PROJECT_ROOT" ]; then rm -rf "$PROJECT_ROOT"; fi

mkdir -p "$PKG_DIR"/{model,adapter,api,utils,ui}
mkdir -p "$RES_DIR"/{layout,values,drawable,anim,menu,color}
mkdir -p "$PROJECT_ROOT/gradle/wrapper"

# 2. KEYSTORE
echo "Generating Keystore..."
keytool -genkey -v -keystore "$MODULE_DIR/release.keystore" -alias erdinplayer -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=Erdin, O=ErdinPlayer, C=TR" 2>/dev/null

# 3. GRADLE SETUP
cat << 'EOF' > "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat << 'EOF' > "$PROJECT_ROOT/build.gradle"
buildscript { repositories { google(); mavenCentral() }; dependencies { classpath 'com.android.tools.build:gradle:8.1.1' } }
allprojects { repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } } }
EOF

cat << 'EOF' > "$PROJECT_ROOT/settings.gradle"
rootProject.name = "ErdinPlayer"
include ':app'
EOF

cat << 'EOF' > "$PROJECT_ROOT/gradle.properties"
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx4048m
EOF

cat << 'EOF' > "$MODULE_DIR/build.gradle"
plugins { id 'com.android.application' }
android {
    namespace 'com.merdolda.player'
    compileSdk 34
    defaultConfig { applicationId "com.merdolda.player"; minSdk 21; targetSdk 34; versionCode 1; versionName "1.0"; multiDexEnabled true }
    signingConfigs { release { storeFile file("release.keystore"); storePassword "123456"; keyAlias "erdinplayer"; keyPassword "123456" } }
    buildTypes { release { minifyEnabled false; signingConfig signingConfigs.release; proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro' } }
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
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
}
EOF

# 4. RESOURCES (COLORS & STYLES)
cat << 'EOF' > "$RES_DIR/values/colors.xml"
<resources>
    <color name="bg_main">#0F172A</color>
    <color name="bg_card">#1E293B</color>
    <color name="primary_accent">#E50914</color>
    <color name="white">#FFFFFF</color>
    <color name="gray_text">#94A3B8</color>
    <color name="input_bg">#334155</color>
    <color name="bg_gradient_start">#1E293B</color>
    <color name="bg_gradient_end">#0F172A</color>
</resources>
EOF

cat << 'EOF' > "$RES_DIR/values/styles.xml"
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.NoActionBar">
        <item name="android:windowBackground">@drawable/bg_main_gradient</item>
        <item name="colorPrimary">@color/bg_main</item>
        <item name="colorAccent">@color/primary_accent</item>
        <item name="android:statusBarColor">@color/bg_main</item>
    </style>
    <style name="ModernButton" parent="Widget.MaterialComponents.Button">
        <item name="backgroundTint">@null</item>
        <item name="android:background">@drawable/btn_gradient</item>
        <item name="android:textColor">@color/white</item>
    </style>
    <style name="ModernInput">
        <item name="android:background">@drawable/bg_input</item>
        <item name="android:textColor">@color/white</item>
        <item name="android:padding">16dp</item>
    </style>
</resources>
EOF

# DRAWABLES
cat << 'EOF' > "$RES_DIR/drawable/bg_main_gradient.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android"><gradient android:startColor="#1E293B" android:endColor="#020617" android:angle="270"/></shape>
EOF
cat << 'EOF' > "$RES_DIR/drawable/btn_gradient.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android"><solid android:color="#E50914"/><corners android:radius="12dp"/></shape>
EOF
cat << 'EOF' > "$RES_DIR/drawable/bg_input.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android"><solid android:color="#0F172A"/><corners android:radius="10dp"/><stroke android:width="1dp" android:color="#334155"/></shape>
EOF
cat << 'EOF' > "$RES_DIR/drawable/bg_card.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android"><solid android:color="#1E293B"/><corners android:radius="10dp"/></shape>
EOF
cat << 'EOF' > "$RES_DIR/drawable/ic_launcher_background.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#0F172A" android:pathData="M0,0h108v108h-108z"/></vector>
EOF

# 5. MODELS
cat << EOF > "$PKG_DIR/model/AppModels.java"
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
public class AppModels {
    public static class Playlist implements Serializable {
        public String id, name, type, url, user, pass, ref, ori, expiry;
    }
    public static class LoginResponse implements Serializable { 
        @SerializedName("user_info") public UserInfo userInfo; 
        @SerializedName("server_info") public ServerInfo serverInfo;
    }
    public static class UserInfo implements Serializable { 
        @SerializedName("username") public String username; 
        @SerializedName("auth") public int auth;
        @SerializedName("exp_date") public String expDate;
    }
    public static class ServerInfo implements Serializable { @SerializedName("url") public String url; }
    public static class Category implements Serializable { @SerializedName("category_id") public String id; @SerializedName("category_name") public String name; }
    public static class StreamItem implements Serializable { 
        @SerializedName("name") public String name; @SerializedName("stream_id") public String streamId; 
        @SerializedName("series_id") public String seriesId; @SerializedName("stream_icon") public String icon; 
        @SerializedName("container_extension") public String ext;
    }
}
EOF

# 6. API & UTILS
cat << EOF > "$PKG_DIR/api/XtreamApi.java"
package com.merdolda.player.api;
import com.merdolda.player.model.AppModels.*;
import java.util.List;
import retrofit2.Call;
import retrofit2.http.*;
public interface XtreamApi {
    @GET Call<LoginResponse> login(@Url String url, @Query("username") String u, @Query("password") String p);
    @GET Call<List<Category>> getCategories(@Url String url, @Query("username") String u, @Query("password") String p, @Query("action") String a);
    @GET Call<List<StreamItem>> getStreams(@Url String url, @Query("username") String u, @Query("password") String p, @Query("action") String a, @Query("category_id") String c);
}
EOF

cat << EOF > "$PKG_DIR/utils/PrefUtils.java"
package com.merdolda.player.utils;
import android.content.*;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.merdolda.player.model.AppModels.Playlist;
import java.util.*;
public class PrefUtils {
    private static SharedPreferences get(Context c) { return c.getSharedPreferences("ERD_PREF", 0); }
    public static void savePlaylist(Context c, Playlist p) {
        List<Playlist> l = getPlaylists(c); l.add(p);
        get(c).edit().putString("L", new Gson().toJson(l)).putString("A", p.id).apply();
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
    public static void deletePlaylist(Context c, String id) {
        List<Playlist> l = getPlaylists(c); l.removeIf(p -> p.id.equals(id));
        get(c).edit().putString("L", new Gson().toJson(l)).apply();
    }
    public static void logout(Context c) { get(c).edit().remove("A").apply(); }
}
EOF

# 7. ADAPTERS
cat << EOF > "$PKG_DIR/adapter/PlaylistAdapter.java"
package com.merdolda.player.adapter;
import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.merdolda.player.R;
import com.merdolda.player.model.AppModels.Playlist;
import java.util.List;
public class PlaylistAdapter extends RecyclerView.Adapter<PlaylistAdapter.VH> {
    private List<Playlist> list; private OnClick listener;
    public interface OnClick { void onClick(Playlist p); void onDelete(Playlist p); }
    public PlaylistAdapter(List<Playlist> list, OnClick listener) { this.list = list; this.listener = listener; }
    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) { return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_playlist, p, false)); }
    @Override public void onBindViewHolder(@NonNull VH h, int p) {
        Playlist i = list.get(p); h.n.setText(i.name); h.t.setText(i.type + (i.expiry!=null ? " | Exp: "+i.expiry : ""));
        h.itemView.setOnClickListener(v -> listener.onClick(i));
        h.d.setOnClickListener(v -> listener.onDelete(i));
    }
    @Override public int getItemCount() { return list.size(); }
    class VH extends RecyclerView.ViewHolder { TextView n, t; ImageButton d; VH(View v) { super(v); n=v.findViewById(R.id.tvPlayName); t=v.findViewById(R.id.tvPlayInfo); d=v.findViewById(R.id.btnDel); } }
}
EOF

cat << EOF > "$PKG_DIR/adapter/CategoryAdapter.java"
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
        h.t.setText(list.get(p).name); 
        h.t.setBackgroundResource(sel == p ? R.drawable.btn_gradient : R.drawable.bg_input);
        h.itemView.setOnClickListener(v -> { int o = sel; sel = h.getAdapterPosition(); notifyItemChanged(o); notifyItemChanged(sel); listener.onClick(list.get(p)); });
    }
    @Override public int getItemCount() { return list.size(); }
    class VH extends RecyclerView.ViewHolder { TextView t; VH(View v) { super(v); t = v.findViewById(R.id.tvCatName); } }
}
EOF

cat << EOF > "$PKG_DIR/adapter/StreamAdapter.java"
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
        StreamItem i = list.get(p); h.t.setText(i.name);
        Glide.with(h.itemView.getContext()).load(i.icon).placeholder(R.drawable.ic_launcher_background).into(h.i);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
    }
    @Override public int getItemCount() { return list == null ? 0 : list.size(); }
    public void update(List<StreamItem> n) { this.list = n; notifyDataSetChanged(); }
    class VH extends RecyclerView.ViewHolder { TextView t; ImageView i; VH(View v) { super(v); t = v.findViewById(R.id.tvName); i = v.findViewById(R.id.ivIcon); } }
}
EOF

# 8. LAYOUTS
cat << 'EOF' > "$RES_DIR/layout/activity_selection.xml"
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@drawable/bg_main_gradient">
    <TextView android:id="@+id/header" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="PLAYLISTS" android:textColor="@color/white" android:textSize="28sp" android:textStyle="bold" android:layout_centerHorizontal="true" android:layout_marginTop="30dp"/>
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvPlaylists" android:layout_width="match_parent" android:layout_height="match_parent" android:layout_below="@id/header" android:layout_above="@+id/btnGroup" android:padding="15dp" android:clipToPadding="false"/>
    <LinearLayout android:id="@+id/btnGroup" android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="vertical" android:layout_alignParentBottom="true" android:padding="20dp">
        <Button android:id="@+id/btnXtream" android:layout_width="match_parent" android:layout_height="65dp" android:text="Add Xtream API" style="@style/ModernButton" android:layout_marginBottom="10dp"/>
        <Button android:id="@+id/btnSingle" android:layout_width="match_parent" android:layout_height="65dp" android:text="Paste M3U / Link" style="@style/ModernButton"/>
    </LinearLayout>
</RelativeLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_playlist.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="wrap_content" android:background="@drawable/bg_card" android:padding="15dp" android:layout_marginBottom="10dp" android:orientation="horizontal" android:gravity="center_vertical"><LinearLayout android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:orientation="vertical"><TextView android:id="@+id/tvPlayName" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:textSize="18sp" android:textStyle="bold"/><TextView android:id="@+id/tvPlayInfo" android:layout_width="wrap_content" android:layout_height="wrap_content" android:layout_marginTop="3dp" android:textColor="@color/gray_text" android:textSize="13sp"/></LinearLayout><ImageButton android:id="@+id/btnDel" android:layout_width="40dp" android:layout_height="40dp" android:background="?attr/selectableItemBackgroundBorderless" android:src="@android:drawable/ic_menu_delete" android:tint="@color/primary_accent"/></LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_dashboard.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" xmlns:app="http://schemas.android.com/apk/res-auto" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@drawable/bg_main_gradient" android:orientation="vertical" android:gravity="center" android:padding="20dp">
    <TextView android:id="@+id/tvUser" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFF" android:gravity="center" android:textSize="20sp" android:layout_marginBottom="40dp" android:textStyle="bold"/>
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="horizontal" android:weightSum="2" android:layout_marginBottom="30dp">
        <androidx.cardview.widget.CardView android:id="@+id/btnLive" android:layout_width="0dp" android:layout_height="150dp" android:layout_weight="1" android:layout_marginRight="10dp" app:cardBackgroundColor="@color/bg_card" app:cardCornerRadius="15dp"><TextView android:layout_width="match_parent" android:layout_height="match_parent" android:text="LIVE" android:gravity="center" android:textColor="#FFF" android:textSize="24sp" android:textStyle="bold"/></androidx.cardview.widget.CardView>
        <androidx.cardview.widget.CardView android:id="@+id/btnMovies" android:layout_width="0dp" android:layout_height="150dp" android:layout_weight="1" android:layout_marginLeft="10dp" app:cardBackgroundColor="@color/bg_card" app:cardCornerRadius="15dp"><TextView android:layout_width="match_parent" android:layout_height="match_parent" android:text="VOD" android:gravity="center" android:textColor="#FFF" android:textSize="24sp" android:textStyle="bold"/></androidx.cardview.widget.CardView>
    </LinearLayout>
    <Button android:id="@+id/btnLogout" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="CHANGE PLAYLIST" style="@style/ModernButton" android:backgroundTint="@color/primary_accent"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_login_xtream.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@drawable/bg_main_gradient" android:orientation="vertical" android:padding="30dp" android:gravity="center">
    <EditText android:id="@+id/etName" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Name" style="@style/ModernInput" android:layout_marginBottom="15dp"/>
    <EditText android:id="@+id/etUser" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Username" style="@style/ModernInput" android:layout_marginBottom="15dp"/>
    <EditText android:id="@+id/etPass" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Password" android:inputType="textPassword" style="@style/ModernInput" android:layout_marginBottom="15dp"/>
    <EditText android:id="@+id/etDns" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="http://url:port" style="@style/ModernInput" android:layout_marginBottom="30dp"/>
    <Button android:id="@+id/btnLogin" android:layout_width="match_parent" android:layout_height="60dp" android:text="Login" style="@style/ModernButton"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_login_single.xml"
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@drawable/bg_main_gradient" android:fillViewport="true">
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="vertical" android:padding="30dp" android:gravity="center">
        <TextView android:layout_width="match_parent" android:layout_height="wrap_content" android:text="Paste M3U Content or Link" android:textColor="#FFF" android:textSize="18sp" android:layout_marginBottom="15dp"/>
        <EditText android:id="@+id/etName" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Playlist Name (Optional)" style="@style/ModernInput" android:layout_marginBottom="15dp"/>
        <EditText android:id="@+id/etUrl" android:layout_width="match_parent" android:layout_height="150dp" android:gravity="top" android:hint="#EXTINF... or http://..." style="@style/ModernInput" android:layout_marginBottom="30dp"/>
        <Button android:id="@+id/btnPlay" android:layout_width="match_parent" android:layout_height="60dp" android:text="Save & Play" style="@style/ModernButton"/>
    </LinearLayout>
</ScrollView>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_list.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:background="@drawable/bg_main_gradient">
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvCats" android:layout_width="match_parent" android:layout_height="50dp" android:padding="5dp" android:clipToPadding="false"/>
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvStreams" android:layout_width="match_parent" android:layout_height="match_parent" android:padding="8dp"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_channel.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="wrap_content" android:padding="10dp" android:background="@drawable/bg_card" android:layout_marginBottom="8dp" android:orientation="horizontal" android:gravity="center_vertical">
    <ImageView android:id="@+id/ivIcon" android:layout_width="50dp" android:layout_height="50dp" android:src="@drawable/ic_launcher_background"/>
    <TextView android:id="@+id/tvName" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:textSize="16sp" android:layout_marginLeft="15dp" android:textStyle="bold"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_category.xml"
<TextView xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/tvCatName" android:layout_width="wrap_content" android:layout_height="wrap_content" android:padding="10dp" android:textColor="#FFF" android:textSize="14sp" android:textStyle="bold" android:layout_margin="5dp"/>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_player.xml"
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000"><com.google.android.exoplayer2.ui.StyledPlayerView android:id="@+id/player_view" android:layout_width="match_parent" android:layout_height="match_parent"/></FrameLayout>
EOF

# 9. JAVA CLASSES (FULL LOGIC)

cat << EOF > "$PKG_DIR/ui/SelectionActivity.java"
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.merdolda.player.R;
import com.merdolda.player.adapter.PlaylistAdapter;
import com.merdolda.player.model.AppModels.Playlist;
import com.merdolda.player.utils.PrefUtils;
import java.util.List;
public class SelectionActivity extends AppCompatActivity {
    PlaylistAdapter adapter; List<Playlist> list;
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_selection);
        RecyclerView rv = findViewById(R.id.rvPlaylists);
        rv.setLayoutManager(new LinearLayoutManager(this));
        list = PrefUtils.getPlaylists(this);
        adapter = new PlaylistAdapter(list, new PlaylistAdapter.OnClick() {
            @Override public void onClick(Playlist p) { 
                PrefUtils.savePlaylist(SelectionActivity.this, p); // Updates active
                if("Xtream".equals(p.type)) startActivity(new Intent(SelectionActivity.this, DashboardActivity.class)); 
                else {
                    Intent in = new Intent(SelectionActivity.this, PlayerActivity.class);
                    in.putExtra("url", p.url); in.putExtra("referer", p.ref); in.putExtra("origin", p.ori);
                    startActivity(in);
                }
            }
            @Override public void onDelete(Playlist p) { PrefUtils.deletePlaylist(SelectionActivity.this, p.id); list.remove(p); adapter.notifyDataSetChanged(); }
        });
        rv.setAdapter(adapter);
        findViewById(R.id.btnXtream).setOnClickListener(v -> startActivity(new Intent(this, LoginXtreamActivity.class)));
        findViewById(R.id.btnSingle).setOnClickListener(v -> startActivity(new Intent(this, LoginSingleActivity.class)));
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/DashboardActivity.java"
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.utils.PrefUtils;
import com.merdolda.player.model.AppModels.Playlist;
public class DashboardActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_dashboard);
        Playlist p = PrefUtils.getActive(this);
        if(p != null) ((TextView)findViewById(R.id.tvUser)).setText(p.name + "\n" + (p.expiry != null ? "Exp: " + p.expiry : "Unlimited"));
        findViewById(R.id.btnLive).setOnClickListener(v -> { if(p!=null && "Xtream".equals(p.type)) { Intent i = new Intent(this, CommonListActivity.class); i.putExtra("type", "live"); startActivity(i); } });
        findViewById(R.id.btnMovies).setOnClickListener(v -> { if(p!=null && "Xtream".equals(p.type)) { Intent i = new Intent(this, CommonListActivity.class); i.putExtra("type", "vod"); startActivity(i); } });
        findViewById(R.id.btnLogout).setOnClickListener(v -> { PrefUtils.logout(this); startActivity(new Intent(this, SelectionActivity.class)); finish(); });
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/LoginXtreamActivity.java"
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.api.XtreamApi;
import com.merdolda.player.model.AppModels.*;
import com.merdolda.player.utils.PrefUtils;
import java.util.UUID;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;
public class LoginXtreamActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_login_xtream);
        EditText name = findViewById(R.id.etName), u = findViewById(R.id.etUser), p = findViewById(R.id.etPass), d = findViewById(R.id.etDns);
        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String url = d.getText().toString(); if(!url.startsWith("http")) url = "http://"+url;
            Retrofit r = new Retrofit.Builder().baseUrl(url+"/").addConverterFactory(GsonConverterFactory.create()).build();
            final String fU = url;
            r.create(XtreamApi.class).login(fU+"/player_api.php", u.getText().toString(), p.getText().toString()).enqueue(new Callback<LoginResponse>() {
                @Override public void onResponse(Call<LoginResponse> c, Response<LoginResponse> res) {
                    if(res.body()!=null && res.body().userInfo != null && res.body().userInfo.auth==1) {
                        Playlist pl = new Playlist(); pl.id = UUID.randomUUID().toString(); pl.type="Xtream"; pl.url=fU; pl.user=u.getText().toString(); pl.pass=p.getText().toString(); pl.name=name.getText().toString();
                        if(res.body().userInfo.expDate != null) pl.expiry = new java.util.Date(Long.parseLong(res.body().userInfo.expDate)*1000).toString();
                        PrefUtils.savePlaylist(LoginXtreamActivity.this, pl); startActivity(new Intent(LoginXtreamActivity.this, DashboardActivity.class)); finish();
                    } else Toast.makeText(LoginXtreamActivity.this, "Failed", 0).show();
                }
                @Override public void onFailure(Call<LoginResponse> c, Throwable t) { Toast.makeText(LoginXtreamActivity.this, "Error", 0).show(); }
            });
        });
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/LoginSingleActivity.java"
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
        EditText n = findViewById(R.id.etName), u = findViewById(R.id.etUrl);
        findViewById(R.id.btnPlay).setOnClickListener(v -> {
            String raw = u.getText().toString();
            String link = raw, ref = "", ori = "";
            // SIMPLE PARSER FOR #EXTVLCOPT
            if(raw.contains("#EXTVLCOPT")) {
                String[] lines = raw.split("\\n");
                for(String l : lines) {
                    if(l.startsWith("http")) link = l.trim();
                    if(l.contains("http-referrer=")) ref = l.split("referrer=")[1].trim();
                    if(l.contains("http-origin=")) ori = l.split("origin=")[1].trim();
                }
            }
            Playlist pl = new Playlist(); pl.id = UUID.randomUUID().toString(); pl.type="Single"; pl.name=n.getText().toString(); pl.url=link; pl.ref=ref; pl.ori=ori;
            PrefUtils.savePlaylist(this, pl);
            Intent in = new Intent(this, PlayerActivity.class); in.putExtra("url", pl.url); in.putExtra("referer", pl.ref); in.putExtra("origin", pl.ori); startActivity(in);
        });
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/CommonListActivity.java"
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

cat << EOF > "$PKG_DIR/ui/PlayerActivity.java"
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
    ExoPlayer p;
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        setContentView(R.layout.activity_player);
        StyledPlayerView pv = findViewById(R.id.player_view);
        String url = getIntent().getStringExtra("url");
        String ref = getIntent().getStringExtra("referer");
        String ori = getIntent().getStringExtra("origin");
        DefaultHttpDataSource.Factory f = new DefaultHttpDataSource.Factory().setAllowCrossProtocolRedirects(true);
        Map<String, String> h = new HashMap<>();
        if(ref != null && !ref.isEmpty()) h.put("Referer", ref);
        if(ori != null && !ori.isEmpty()) h.put("Origin", ori);
        f.setDefaultRequestProperties(h);
        p = new ExoPlayer.Builder(this).setMediaSourceFactory(new DefaultMediaSourceFactory(f)).build();
        pv.setPlayer(p);
        if(url != null) { p.setMediaItem(MediaItem.fromUri(Uri.parse(url))); p.prepare(); p.play(); }
    }
    @Override protected void onSaveInstanceState(Bundle o) { super.onSaveInstanceState(o); if(p!=null) o.putLong("P", p.getCurrentPosition()); }
    @Override protected void onDestroy() { super.onDestroy(); if(p != null) p.release(); }
}
EOF

# 10. MANIFEST
cat << 'EOF' > "$MODULE_DIR/src/main/AndroidManifest.xml"
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application android:name="androidx.multidex.MultiDexApplication" android:label="ErdinPlayer" android:theme="@style/AppTheme" android:usesCleartextTraffic="true" android:icon="@drawable/ic_launcher_background">
        <activity android:name=".ui.SelectionActivity" android:exported="true" android:screenOrientation="portrait"><intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter></activity>
        <activity android:name=".ui.LoginXtreamActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.LoginSingleActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.DashboardActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.CommonListActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.PlayerActivity" android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize" android:screenOrientation="sensor" />
    </application>
</manifest>
EOF

# 11. WRAPPER GENERATION
echo "Generating Gradle Wrapper..."
cd "$PROJECT_ROOT"
gradle wrapper --gradle-version 8.4
chmod +x gradlew
cd ..

echo "✅ ERDINPLAYER v10.1: PROJECT REGENERATED SUCCESSFULLY."
echo "👉 NOW RUN: cd $PROJECT_NAME && ./gradlew assembleRelease --no-daemon"
