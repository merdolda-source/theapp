#!/bin/bash

# --- AYARLAR (HATA BURADA DÜZELTİLDİ: "theapp" OLARAK SABİTLENDİ) ---
PROJECT_NAME="ErdinPlayer"
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="com/merdolda/player"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "💎 ERDINPLAYER v14.0: SIDEBAR UI & ADVANCED M3U ENGINE..."

# 1. TEMİZLİK
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
    defaultConfig { applicationId "com.merdolda.player"; minSdk 21; targetSdk 34; versionCode 14; versionName "14.0"; multiDexEnabled true }
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

# 4. RESOURCES (SIDEBAR & GLASS THEME)
cat << 'EOF' > "$RES_DIR/values/colors.xml"
<resources>
    <color name="bg_main">#0B0C15</color>
    <color name="sidebar_bg">#151621</color>
    <color name="accent">#FF5722</color>
    <color name="glass_white">#1FFFFFFF</color>
    <color name="text_primary">#FFFFFF</color>
    <color name="text_secondary">#9E9E9E</color>
</resources>
EOF

cat << 'EOF' > "$RES_DIR/values/styles.xml"
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.NoActionBar">
        <item name="android:windowBackground">@color/bg_main</item>
        <item name="colorPrimary">@color/bg_main</item>
        <item name="colorAccent">@color/accent</item>
        <item name="android:statusBarColor">@color/sidebar_bg</item>
    </style>
    <style name="SidebarButton">
        <item name="android:layout_width">match_parent</item>
        <item name="android:layout_height">wrap_content</item>
        <item name="android:padding">15dp</item>
        <item name="android:textColor">@color/text_secondary</item>
        <item name="android:textSize">14sp</item>
        <item name="android:background">?attr/selectableItemBackground</item>
        <item name="android:drawablePadding">10dp</item>
        <item name="android:gravity">center_vertical|left</item>
    </style>
    <style name="GlassInput">
        <item name="android:background">@drawable/bg_glass</item>
        <item name="android:textColor">#FFF</item>
        <item name="android:padding">15dp</item>
    </style>
</resources>
EOF

# DRAWABLES
cat << 'EOF' > "$RES_DIR/drawable/bg_glass.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android"><solid android:color="#1AFFFFFF"/><corners android:radius="8dp"/><stroke android:width="1dp" android:color="#33FFFFFF"/></shape>
EOF
cat << 'EOF' > "$RES_DIR/drawable/bg_btn_accent.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android"><solid android:color="@color/accent"/><corners android:radius="8dp"/></shape>
EOF
cat << 'EOF' > "$RES_DIR/drawable/ic_tv.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24"><path android:fillColor="#FFF" android:pathData="M21,3H3C1.9,3 1,3.9 1,5v12c0,1.1 0.9,2 2,2h5v2h8v-2h5c1.1,0 1.99,-0.9 1.99,-2L23,5C23,3.9 22.1,3 21,3zM21,17H3V5h18V17z"/></vector>
EOF
cat << 'EOF' > "$RES_DIR/drawable/ic_movie.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24"><path android:fillColor="#FFF" android:pathData="M18,4l2,4h-3l-2,-4h-2l2,4h-3l-2,-4h-2l2,4h-3l-2,-4h-2l2,4h-3l-2,-4H1v16h22V4H18z"/></vector>
EOF
cat << 'EOF' > "$RES_DIR/drawable/ic_list.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24"><path android:fillColor="#FFF" android:pathData="M3,13h2v-2H3V13zM3,17h2v-2H3V17zM3,9h2V7H3V9zM7,13h14v-2H7V13zM7,17h14v-2H7V17zM7,7v2h14V7H7z"/></vector>
EOF
cat << 'EOF' > "$RES_DIR/drawable/ic_launcher_background.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#0B0C15" android:pathData="M0,0h108v108h-108z"/></vector>
EOF

# 5. MODELLER
cat << EOF > "$PKG_DIR/model/AppModels.java"
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.List;

public class AppModels {
    public static class Playlist implements Serializable {
        public String id, name, type, url, user, pass;
        public String m3uContent; 
    }
    public static class LoginResponse implements Serializable { 
        @SerializedName("user_info") public UserInfo userInfo; 
    }
    public static class UserInfo implements Serializable { 
        @SerializedName("username") public String username; 
        @SerializedName("auth") public int auth;
    }
    public static class Category implements Serializable { 
        @SerializedName("category_id") public String id; 
        @SerializedName("category_name") public String name;
        public Category(String id, String name) { this.id=id; this.name=name; }
    }
    public static class StreamItem implements Serializable { 
        @SerializedName("name") public String name; 
        @SerializedName("stream_id") public String streamId; 
        @SerializedName("stream_icon") public String icon; 
        @SerializedName("container_extension") public String ext;
        public String directUrl;
        public String group;
        public String referer;
        public String origin;
    }
}
EOF

# 6. M3U PARSER (VLCOPT SUPPORT)
cat << EOF > "$PKG_DIR/utils/M3UParser.java"
package com.merdolda.player.utils;
import com.merdolda.player.model.AppModels.*;
import java.util.*;
import java.util.regex.*;

public class M3UParser {
    public static Map<String, List<StreamItem>> parse(String content) {
        Map<String, List<StreamItem>> map = new LinkedHashMap<>();
        String[] lines = content.split("\\n");
        String currentGroup = "Genel";
        StreamItem currentItem = null;

        for (String line : lines) {
            line = line.trim();
            if (line.isEmpty()) continue;

            if (line.startsWith("#EXTINF")) {
                currentItem = new StreamItem();
                // Name parse
                int comma = line.lastIndexOf(",");
                if (comma > 0) currentItem.name = line.substring(comma + 1).trim();
                else currentItem.name = "Kanal";

                // Group parse
                Pattern pGroup = Pattern.compile("group-title=\"([^\"]*)\"");
                Matcher mGroup = pGroup.matcher(line);
                if (mGroup.find()) currentGroup = mGroup.group(1);
                
                // Logo parse
                Pattern pLogo = Pattern.compile("tvg-logo=\"([^\"]*)\"");
                Matcher mLogo = pLogo.matcher(line);
                if (mLogo.find()) currentItem.icon = mLogo.group(1);
                
                currentItem.group = currentGroup;
            
            } else if (line.startsWith("#EXTVLCOPT")) {
                // EXTVLCOPT Support for Headers
                if (currentItem != null) {
                    if (line.contains("http-referrer=")) currentItem.referer = line.split("http-referrer=")[1].trim();
                    if (line.contains("http-origin=")) currentItem.origin = line.split("http-origin=")[1].trim();
                    if (line.contains("http-user-agent=")) {/* Agent desteği eklenebilir */}
                }
            } else if (!line.startsWith("#")) {
                // It's a URL
                if (currentItem != null) {
                    currentItem.directUrl = line;
                    if (!map.containsKey(currentGroup)) map.put(currentGroup, new ArrayList<>());
                    map.get(currentGroup).add(currentItem);
                    currentItem = null; 
                }
            }
        }
        return map;
    }
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
    private static SharedPreferences get(Context c) { return c.getSharedPreferences("ERD_V14", 0); }
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

# 7. API INTERFACE
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

# 8. ADAPTERS
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
        h.t.setTextColor(sel == p ? Color.parseColor("#FF5722") : Color.WHITE);
        h.itemView.setOnClickListener(v -> { int o = sel; sel = h.getAdapterPosition(); notifyItemChanged(o); notifyItemChanged(sel); listener.onClick(list.get(p)); });
    }
    @Override public int getItemCount() { return list.size(); }
    class VH extends RecyclerView.ViewHolder { TextView t; VH(View v) { super(v); t = v.findViewById(R.id.tvCatName); } }
}
EOF

cat << EOF > "$PKG_DIR/adapter/StreamAdapter.java"
package com.merdolda.player.adapter;
import android.view.*;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
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
        h.itemView.setOnClickListener(v -> listener.onClick(i));
    }
    @Override public int getItemCount() { return list == null ? 0 : list.size(); }
    public void update(List<StreamItem> n) { this.list = n; notifyDataSetChanged(); }
    class VH extends RecyclerView.ViewHolder { TextView t; VH(View v) { super(v); t = v.findViewById(R.id.tvName); } }
}
EOF

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
        Playlist i = list.get(p); h.n.setText(i.name); h.t.setText(i.type);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
        h.d.setOnClickListener(v -> listener.onDelete(i));
    }
    @Override public int getItemCount() { return list.size(); }
    class VH extends RecyclerView.ViewHolder { TextView n, t; View d; VH(View v) { super(v); n=v.findViewById(R.id.tvName); t=v.findViewById(R.id.tvType); d=v.findViewById(R.id.btnDel); } }
}
EOF

# 9. LAYOUTS (SIDEBAR UI)
cat << 'EOF' > "$RES_DIR/layout/activity_dashboard.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="horizontal" android:background="@color/bg_main">
    <LinearLayout android:layout_width="80dp" android:layout_height="match_parent" android:orientation="vertical" android:background="@color/sidebar_bg" android:gravity="center_horizontal" android:paddingTop="20dp">
        <TextView android:id="@+id/btnLive" android:layout_width="match_parent" android:layout_height="wrap_content" android:text="TV" android:textColor="#FFF" android:gravity="center" android:drawableTop="@drawable/ic_tv" android:padding="15dp" android:background="?attr/selectableItemBackground"/>
        <TextView android:id="@+id/btnMovies" android:layout_width="match_parent" android:layout_height="wrap_content" android:text="VOD" android:textColor="#FFF" android:gravity="center" android:drawableTop="@drawable/ic_movie" android:padding="15dp" android:background="?attr/selectableItemBackground"/>
        <View android:layout_width="match_parent" android:layout_height="0dp" android:layout_weight="1"/>
        <TextView android:id="@+id/btnLogout" android:layout_width="match_parent" android:layout_height="wrap_content" android:text="EXIT" android:textColor="@color/accent" android:gravity="center" android:padding="15dp" android:textStyle="bold" android:background="?attr/selectableItemBackground"/>
    </LinearLayout>
    
    <LinearLayout android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical">
        <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvCats" android:layout_width="match_parent" android:layout_height="50dp" android:background="@color/glass_white"/>
        <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvStreams" android:layout_width="match_parent" android:layout_height="match_parent" android:padding="10dp"/>
    </LinearLayout>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_channel.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="horizontal" android:padding="15dp" android:background="@drawable/bg_glass" android:layout_marginBottom="8dp" android:gravity="center_vertical">
    <TextView android:id="@+id/tvName" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:textSize="16sp" android:textStyle="bold"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_category.xml"
<TextView xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/tvCatName" android:layout_width="wrap_content" android:layout_height="match_parent" android:gravity="center" android:padding="15dp" android:textColor="#FFF" android:textStyle="bold"/>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_selection.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_main" android:orientation="vertical" android:padding="20dp" android:gravity="center">
    <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="MY PLAYLISTS" android:textColor="#FFF" android:textSize="24sp" android:textStyle="bold" android:layout_marginBottom="20dp"/>
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/rvPlaylists" android:layout_width="match_parent" android:layout_height="0dp" android:layout_weight="1" android:layout_marginBottom="20dp"/>
    <Button android:id="@+id/btnAdd" android:layout_width="match_parent" android:layout_height="60dp" android:text="ADD PLAYLIST" android:background="@drawable/bg_btn_accent" android:textColor="#FFF"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_playlist.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="horizontal" android:padding="15dp" android:background="@drawable/bg_glass" android:layout_marginBottom="10dp" android:gravity="center_vertical">
    <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:orientation="vertical">
        <TextView android:id="@+id/tvName" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:textSize="18sp" android:textStyle="bold"/>
        <TextView android:id="@+id/tvType" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#AAA" android:textSize="12sp"/>
    </LinearLayout>
    <ImageView android:id="@+id/btnDel" android:layout_width="30dp" android:layout_height="30dp" android:src="@drawable/ic_list" android:tint="@color/accent"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_login.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_main" android:orientation="vertical" android:padding="30dp" android:gravity="center">
    <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="ADD M3U / XTREAM" android:textColor="#FFF" android:textSize="22sp" android:layout_marginBottom="30dp"/>
    <EditText android:id="@+id/etName" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Name" style="@style/GlassInput" android:layout_marginBottom="10dp"/>
    <EditText android:id="@+id/etUrl" android:layout_width="match_parent" android:layout_height="100dp" android:hint="M3U URL or Content" style="@style/GlassInput" android:gravity="top" android:layout_marginBottom="20dp"/>
    <Button android:id="@+id/btnSave" android:layout_width="match_parent" android:layout_height="60dp" android:text="SAVE" android:background="@drawable/bg_btn_accent" android:textColor="#FFF"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_player.xml"
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000">
    <com.google.android.exoplayer2.ui.StyledPlayerView android:id="@+id/player_view" android:layout_width="match_parent" android:layout_height="match_parent"/>
</FrameLayout>
EOF

# 10. JAVA (SIDEBAR LOGIC & VLCOPT)

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
public class SelectionActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_selection);
        RecyclerView rv = findViewById(R.id.rvPlaylists);
        rv.setLayoutManager(new LinearLayoutManager(this));
        
        List<Playlist> list = PrefUtils.getPlaylists(this);
        rv.setAdapter(new PlaylistAdapter(list, new PlaylistAdapter.OnClick() {
            @Override public void onClick(Playlist p) { 
                PrefUtils.savePlaylist(SelectionActivity.this, p); 
                startActivity(new Intent(SelectionActivity.this, DashboardActivity.class)); 
            }
            @Override public void onDelete(Playlist p) { 
                PrefUtils.deletePlaylist(SelectionActivity.this, p.id); 
                startActivity(new Intent(SelectionActivity.this, SelectionActivity.class)); finish();
            }
        }));
        
        findViewById(R.id.btnAdd).setOnClickListener(v -> startActivity(new Intent(this, LoginActivity.class)));
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/LoginActivity.java"
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.model.AppModels.Playlist;
import com.merdolda.player.utils.PrefUtils;
import java.util.UUID;
import okhttp3.*;
import java.io.IOException;

public class LoginActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_login);
        EditText n = findViewById(R.id.etName), u = findViewById(R.id.etUrl);
        findViewById(R.id.btnSave).setOnClickListener(v -> {
            String url = u.getText().toString();
            String name = n.getText().toString();
            
            // If it's just raw content or #EXT, save directly
            if(url.contains("#EXTINF")) {
                save(name, url, "M3U");
            } else {
                // Try download
                new Thread(() -> {
                    try {
                        OkHttpClient client = new OkHttpClient();
                        Request req = new Request.Builder().url(url).build();
                        Response res = client.newCall(req).execute();
                        String content = res.body().string();
                        runOnUiThread(() -> save(name, content, "M3U"));
                    } catch(Exception e) {
                        runOnUiThread(() -> Toast.makeText(this, "Error downloading playlist", 0).show());
                    }
                }).start();
            }
        });
    }
    void save(String n, String c, String t) {
        Playlist p = new Playlist(); p.id=UUID.randomUUID().toString(); p.name=n; p.type=t; p.m3uContent=c;
        PrefUtils.savePlaylist(this, p);
        startActivity(new Intent(this, DashboardActivity.class)); finish();
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/DashboardActivity.java"
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.*;
import com.merdolda.player.R;
import com.merdolda.player.adapter.*;
import com.merdolda.player.model.AppModels.*;
import com.merdolda.player.utils.*;
import java.util.*;

public class DashboardActivity extends AppCompatActivity {
    RecyclerView rvC, rvS; StreamAdapter adp; Playlist p;
    Map<String, List<StreamItem>> m3uMap;

    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_dashboard);
        p = PrefUtils.getActive(this);
        
        rvC = findViewById(R.id.rvCats); rvS = findViewById(R.id.rvStreams);
        rvC.setLayoutManager(new LinearLayoutManager(this, 0, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));
        
        adp = new StreamAdapter(new ArrayList<>(), i -> {
            Intent in = new Intent(this, PlayerActivity.class);
            in.putExtra("url", i.directUrl); 
            in.putExtra("ref", i.referer); 
            in.putExtra("ori", i.origin);
            startActivity(in);
        });
        rvS.setAdapter(adp);
        
        // M3U Logic
        m3uMap = M3UParser.parse(p.m3uContent);
        List<Category> cats = new ArrayList<>();
        for(String k : m3uMap.keySet()) cats.add(new Category(k, k));
        
        rvC.setAdapter(new CategoryAdapter(cats, cat -> adp.update(m3uMap.get(cat.id))));
        if(!cats.isEmpty()) adp.update(m3uMap.get(cats.get(0).id));
        
        findViewById(R.id.btnLogout).setOnClickListener(v -> { PrefUtils.logout(this); startActivity(new Intent(this, SelectionActivity.class)); finish(); });
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/PlayerActivity.java"
package com.merdolda.player.ui;
import android.net.Uri;
import android.os.Bundle;
import android.view.*;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.*;
import com.google.android.exoplayer2.source.DefaultMediaSourceFactory;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.merdolda.player.R;
import java.util.*;

public class PlayerActivity extends AppCompatActivity {
    ExoPlayer p;
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        // IMMERSIVE MODE
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        );
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        
        setContentView(R.layout.activity_player);
        
        String url = getIntent().getStringExtra("url");
        String ref = getIntent().getStringExtra("ref");
        String ori = getIntent().getStringExtra("ori");
        
        DefaultHttpDataSource.Factory f = new DefaultHttpDataSource.Factory().setAllowCrossProtocolRedirects(true);
        f.setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
        Map<String, String> h = new HashMap<>();
        if(ref!=null && !ref.isEmpty()) h.put("Referer", ref);
        if(ori!=null && !ori.isEmpty()) h.put("Origin", ori);
        f.setDefaultRequestProperties(h);
        
        p = new ExoPlayer.Builder(this).setMediaSourceFactory(new DefaultMediaSourceFactory(f)).build();
        ((StyledPlayerView)findViewById(R.id.player_view)).setPlayer(p);
        
        if(url!=null) { p.setMediaItem(MediaItem.fromUri(Uri.parse(url))); p.prepare(); p.play(); }
    }
    @Override protected void onDestroy() { super.onDestroy(); if(p!=null) p.release(); }
}
EOF

# 11. MANIFEST
cat << 'EOF' > "$MODULE_DIR/src/main/AndroidManifest.xml"
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application android:name="androidx.multidex.MultiDexApplication" android:label="ErdinPlayer" android:theme="@style/AppTheme" android:usesCleartextTraffic="true" android:icon="@drawable/ic_tv">
        <activity android:name=".ui.SelectionActivity" android:exported="true" android:screenOrientation="landscape"><intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter></activity>
        <activity android:name=".ui.LoginActivity" android:screenOrientation="landscape" />
        <activity android:name=".ui.DashboardActivity" android:screenOrientation="landscape" />
        <activity android:name=".ui.PlayerActivity" android:screenOrientation="sensorLandscape" android:configChanges="orientation|screenSize|layoutDirection" />
    </application>
</manifest>
EOF

# 12. WRAPPER
cd "$PROJECT_ROOT"
gradle wrapper --gradle-version 8.4
chmod +x gradlew
cd ..

echo "✅ ERDINPLAYER v14.0: FIXED FOLDER & VLCOPT SUPPORT READY."
