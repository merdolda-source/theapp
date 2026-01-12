#!/bin/bash

# ============================================================
# ERDINPLAYER V14 - M3U + XTREAM PRO PLAYER
# Spor Yeşili Tema, Arama, M3U Header (Referer/Origin), Ads Hazır
# ============================================================

PROJECT_NAME="ErdinPlayer"
PROJECT_ROOT="theapp"       # GitHub Actions bu klasörü bekliyor
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="com/merdolda/player"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "💎 ERDINPLAYER v14: PROJE OLUŞTURULUYOR..."

# 1. TEMİZLİK & KLASÖRLER
if [ -d "$PROJECT_ROOT" ]; then rm -rf "$PROJECT_ROOT"; fi

mkdir -p "$PKG_DIR"/{model,adapter,api,utils,ui}
mkdir -p "$RES_DIR"/{layout,values,drawable,anim,menu,color,font}
mkdir -p "$PROJECT_ROOT/gradle/wrapper"

# 2. KEYSTORE
echo "🔑 Keystore oluşturuluyor..."
mkdir -p "$MODULE_DIR"
keytool -genkey -v \
  -keystore "$MODULE_DIR/release.keystore" \
  -alias erdinplayer \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass 123456 -keypass 123456 \
  -dname "CN=Erdin, O=ErdinPlayer, C=TR" 2>/dev/null

# 3. GRADLE SETUP
cat << 'EOF' > "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat << 'EOF' > "$PROJECT_ROOT/build.gradle"
buildscript {
    repositories { google(); mavenCentral() }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.1'
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
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

# --- MODULE build.gradle (ADS + DRAWER + EXO) ---
cat << 'EOF' > "$MODULE_DIR/build.gradle"
plugins { id 'com.android.application' }

android {
    namespace 'com.merdolda.player'
    compileSdk 34

    defaultConfig {
        applicationId "com.merdolda.player"
        minSdk 21
        targetSdk 34
        versionCode 14
        versionName "14.0"
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

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.1'
    implementation 'androidx.drawerlayout:drawerlayout:1.1.1'

    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.19.1'

    implementation 'com.github.bumptech.glide:glide:4.16.0'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'

    // Reklam tarafı için (panelden ID/aktiflik gelecek)
    implementation 'com.google.android.gms:play-services-ads:22.6.0'
    implementation 'com.unity3d.ads:unity-ads:4.9.3'
}
EOF

# 4. RESOURCES (SPOR YEŞİLİ TEMA)

cat << 'EOF' > "$RES_DIR/values/colors.xml"
<resources>
    <color name="bg_dark">#020B09</color>
    <color name="accent">#00C853</color>
    <color name="accent_soft">#00E676</color>
    <color name="glass_bg">#1AFFFFFF</color>
    <color name="glass_stroke">#33FFFFFF</color>
    <color name="text_primary">#FFFFFF</color>
    <color name="text_secondary">#B0C4BA</color>
    <color name="black_overlay">#CC000000</color>
</resources>
EOF

cat << 'EOF' > "$RES_DIR/values/styles.xml"
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.NoActionBar">
        <item name="android:windowBackground">@color/bg_dark</item>
        <item name="colorPrimary">@color/bg_dark</item>
        <item name="colorAccent">@color/accent</item>
        <item name="android:statusBarColor">@color/bg_dark</item>
        <item name="android:navigationBarColor">@color/bg_dark</item>
    </style>

    <style name="GlassCard">
        <item name="android:background">@drawable/bg_glass</item>
        <item name="android:padding">16dp</item>
    </style>

    <style name="NeonButton" parent="Widget.MaterialComponents.Button">
        <item name="backgroundTint">@null</item>
        <item name="android:background">@drawable/bg_neon_btn</item>
        <item name="android:textColor">#FFFFFF</item>
        <item name="android:textAllCaps">true</item>
        <item name="android:textStyle">bold</item>
    </style>

    <style name="GlassInput">
        <item name="android:background">@drawable/bg_glass_input</item>
        <item name="android:textColor">#FFFFFF</item>
        <item name="android:textColorHint">#88FFFFFF</item>
        <item name="android:padding">12dp</item>
    </style>
</resources>
EOF

# Drawables
cat << 'EOF' > "$RES_DIR/drawable/bg_glass.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#1AFFFFFF"/>
    <corners android:radius="16dp"/>
    <stroke android:width="1dp" android:color="#33FFFFFF"/>
</shape>
EOF

cat << 'EOF' > "$RES_DIR/drawable/bg_glass_input.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#0DFFFFFF"/>
    <corners android:radius="12dp"/>
    <stroke android:width="1dp" android:color="#22FFFFFF"/>
</shape>
EOF

cat << 'EOF' > "$RES_DIR/drawable/bg_neon_btn.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <gradient
        android:startColor="#00E676"
        android:endColor="#00C853"
        android:angle="45"/>
    <corners android:radius="12dp"/>
</shape>
EOF

cat << 'EOF' > "$RES_DIR/drawable/ic_play.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF" android:pathData="M8,5v14l11,-7z"/>
</vector>
EOF

cat << 'EOF' > "$RES_DIR/drawable/ic_delete.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FF5252" android:pathData="M6,19c0,1.1 0.9,2 2,2h8c1.1,0 2,-0.9 2,-2V7H6v12zM19,4h-3.5l-1,-1h-5l-1,1H5v2h14V4z"/>
</vector>
EOF

cat << 'EOF' > "$RES_DIR/drawable/ic_zoom.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF" android:pathData="M15,3l2.3,2.3 -2.89,2.87 1.42,1.42L18.7,6.7 21,9V3zM3,9l2.3,-2.3 2.87,2.89 1.42,-1.42L6.7,5.3 9,3H3zM9,21l-2.3,-2.3 2.89,-2.87 -1.42,-1.42L5.3,17.3 3,15v6zM21,15l-2.3,2.3 -2.87,-2.89 -1.42,1.42L17.3,18.7 15,21h6z"/>
</vector>
EOF

cat << 'EOF' > "$RES_DIR/drawable/ic_launcher_background.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#020B09" android:pathData="M0,0h108v108h-108z"/>
</vector>
EOF

# 5. MODELLER (Playlist + StreamItem geliştirilmiş)

cat << 'EOF' > "$PKG_DIR/model/AppModels.java"
package com.merdolda.player.model;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class AppModels {

    public static class Playlist implements Serializable {
        public String id, name, type, url, user, pass;
        public String m3uContent;
        public String expiry; // Xtream bitiş tarihi (exp_date)
    }

    public static class LoginResponse implements Serializable {
        @SerializedName("user_info")  public UserInfo userInfo;
        @SerializedName("server_info") public ServerInfo serverInfo;
    }

    public static class UserInfo implements Serializable {
        @SerializedName("username") public String username;
        @SerializedName("auth")     public int auth;
        @SerializedName("exp_date") public String expDate;
    }

    public static class ServerInfo implements Serializable {
        @SerializedName("url") public String url;
    }

    public static class Category implements Serializable {
        @SerializedName("category_id")   public String id;
        @SerializedName("category_name") public String name;
        public Category(String id, String name) { this.id = id; this.name = name; }
    }

    public static class StreamItem implements Serializable {
        @SerializedName("name")          public String name;
        @SerializedName("stream_id")     public String streamId;
        @SerializedName("stream_icon")   public String icon;
        @SerializedName("container_extension") public String ext;

        public String directUrl;
        public String group;

        // M3U özel header'ları
        public String referrer;
        public String origin;
    }
}
EOF

# 6. API & UTILS (M3U Parser + Pref)

cat << 'EOF' > "$PKG_DIR/api/XtreamApi.java"
package com.merdolda.player.api;

import com.merdolda.player.model.AppModels.LoginResponse;
import com.merdolda.player.model.AppModels.Category;
import com.merdolda.player.model.AppModels.StreamItem;

import java.util.List;

import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Query;
import retrofit2.http.Url;

public interface XtreamApi {

    @GET
    Call<LoginResponse> login(
            @Url String url,
            @Query("username") String u,
            @Query("password") String p
    );

    @GET
    Call<List<Category>> getCategories(
            @Url String url,
            @Query("username") String u,
            @Query("password") String p,
            @Query("action") String a
    );

    @GET
    Call<List<StreamItem>> getStreams(
            @Url String url,
            @Query("username") String u,
            @Query("password") String p,
            @Query("action") String a,
            @Query("category_id") String c
    );
}
EOF

cat << 'EOF' > "$PKG_DIR/utils/M3UParser.java"
package com.merdolda.player.utils;

import com.merdolda.player.model.AppModels.StreamItem;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class M3UParser {

    public static Map<String, List<StreamItem>> parse(String content) {
        Map<String, List<StreamItem>> map = new LinkedHashMap<>();
        String[] lines = content.split("\\n");
        String currentGroup = "Uncategorized";
        StreamItem currentItem = null;

        Pattern pGroup = Pattern.compile("group-title=\"([^\"]*)\"");
        Pattern pLogo  = Pattern.compile("tvg-logo=\"([^\"]*)\"");

        for (String raw : lines) {
            String line = raw.trim();

            if (line.startsWith("#EXTINF")) {
                currentItem = new StreamItem();

                int comma = line.lastIndexOf(",");
                if (comma > 0) currentItem.name = line.substring(comma + 1).trim();
                else currentItem.name = "Unknown Channel";

                Matcher mGroup = pGroup.matcher(line);
                if (mGroup.find()) currentGroup = mGroup.group(1);
                else currentGroup = "Uncategorized";

                Matcher mLogo = pLogo.matcher(line);
                if (mLogo.find()) currentItem.icon = mLogo.group(1);

                currentItem.group = currentGroup;

            } else if (line.startsWith("#EXTVLCOPT:http-referrer=")) {
                if (currentItem != null) {
                    currentItem.referrer = line.substring(line.indexOf('=') + 1).trim();
                }

            } else if (line.startsWith("#EXTVLCOPT:http-origin=")) {
                if (currentItem != null) {
                    currentItem.origin = line.substring(line.indexOf('=') + 1).trim();
                }

            } else if (!line.startsWith("#") && !line.isEmpty() && currentItem != null) {
                // gerçek stream URL satırı
                currentItem.directUrl = line;
                if (!map.containsKey(currentGroup)) {
                    map.put(currentGroup, new ArrayList<>());
                }
                map.get(currentGroup).add(currentItem);
                currentItem = null;
            }
        }
        return map;
    }
}
EOF

cat << 'EOF' > "$PKG_DIR/utils/PrefUtils.java"
package com.merdolda.player.utils;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.merdolda.player.model.AppModels.Playlist;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class PrefUtils {

    private static SharedPreferences get(Context c) {
        return c.getSharedPreferences("ERD_V14", 0);
    }

    public static List<Playlist> getPlaylists(Context c) {
        String j = get(c).getString("L", "[]");
        List<Playlist> list = new Gson().fromJson(j, new TypeToken<List<Playlist>>(){}.getType());
        if (list == null) list = new ArrayList<>();
        return list;
    }

    public static void savePlaylist(Context c, Playlist p) {
        List<Playlist> l = getPlaylists(c);

        if (p.id == null || p.id.isEmpty()) {
            p.id = UUID.randomUUID().toString();
        }

        // aynı id varsa güncelle
        boolean updated = false;
        for (int i = 0; i < l.size(); i++) {
            if (l.get(i).id.equals(p.id)) {
                l.set(i, p);
                updated = true;
                break;
            }
        }
        if (!updated) {
            l.add(p);
        }

        get(c).edit()
                .putString("L", new Gson().toJson(l))
                .putString("A", p.id)
                .apply();
    }

    public static Playlist getActive(Context c) {
        String id = get(c).getString("A", "");
        for (Playlist p : getPlaylists(c)) {
            if (p.id != null && p.id.equals(id)) return p;
        }
        return null;
    }

    public static void setActive(Context c, String id) {
        get(c).edit().putString("A", id).apply();
    }

    public static void deletePlaylist(Context c, String id) {
        List<Playlist> l = getPlaylists(c);
        List<Playlist> n = new ArrayList<>();
        for (Playlist p : l) {
            if (!p.id.equals(id)) n.add(p);
        }
        get(c).edit().putString("L", new Gson().toJson(n)).apply();
    }

    public static void logout(Context c) {
        get(c).edit().remove("A").apply();
    }
}
EOF

# 7. ADAPTERLER

cat << 'EOF' > "$PKG_DIR/adapter/PlaylistAdapter.java"
package com.merdolda.player.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.merdolda.player.R;
import com.merdolda.player.model.AppModels.Playlist;

import java.util.List;

public class PlaylistAdapter extends RecyclerView.Adapter<PlaylistAdapter.VH> {

    private List<Playlist> list;
    private OnClick listener;

    public interface OnClick {
        void onClick(Playlist p);
        void onDelete(Playlist p);
    }

    public PlaylistAdapter(List<Playlist> list, OnClick listener) {
        this.list = list;
        this.listener = listener;
    }

    public void update(List<Playlist> n) {
        this.list = n;
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_playlist, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Playlist i = list.get(pos);
        h.n.setText(i.name != null ? i.name : "Playlist");
        String info = i.type != null ? i.type : "";
        if (i.expiry != null && !i.expiry.isEmpty()) {
            info += " • Exp: " + i.expiry;
        }
        h.t.setText(info);

        h.itemView.setOnClickListener(v -> {
            if (listener != null) listener.onClick(i); // tek tık
        });

        h.d.setOnClickListener(v -> {
            if (listener != null) listener.onDelete(i);
        });
    }

    @Override
    public int getItemCount() { return list != null ? list.size() : 0; }

    static class VH extends RecyclerView.ViewHolder {
        TextView n, t;
        ImageView d;
        VH(View v) {
            super(v);
            n = v.findViewById(R.id.tvPlayName);
            t = v.findViewById(R.id.tvPlayInfo);
            d = v.findViewById(R.id.btnDel);
        }
    }
}
EOF

cat << 'EOF' > "$PKG_DIR/adapter/CategoryAdapter.java"
package com.merdolda.player.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.merdolda.player.R;
import com.merdolda.player.model.AppModels.Category;

import java.util.List;

public class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.VH> {

    private List<Category> list;
    private OnClick listener;
    private int sel = 0;

    public interface OnClick { void onClick(Category item); }

    public CategoryAdapter(List<Category> list, OnClick listener) {
        this.list = list;
        this.listener = listener;
    }

    public void setSelectedIndex(int index) {
        int old = sel;
        sel = index;
        notifyItemChanged(old);
        notifyItemChanged(sel);
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_category, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Category c = list.get(pos);
        h.t.setText(c.name);

        h.itemView.setBackgroundResource(sel == pos ? R.drawable.bg_neon_btn : R.drawable.bg_glass_input);

        h.itemView.setOnClickListener(v -> {
            int adapterPos = h.getAdapterPosition();
            if (adapterPos == RecyclerView.NO_POSITION) return;
            int old = sel;
            sel = adapterPos;
            notifyItemChanged(old);
            notifyItemChanged(sel);
            if (listener != null) listener.onClick(list.get(adapterPos)); // tek tık
        });
    }

    @Override
    public int getItemCount() { return list != null ? list.size() : 0; }

    static class VH extends RecyclerView.ViewHolder {
        TextView t;
        VH(View v) {
            super(v);
            t = v.findViewById(R.id.tvCatName);
        }
    }
}
EOF

cat << 'EOF' > "$PKG_DIR/adapter/StreamAdapter.java"
package com.merdolda.player.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.merdolda.player.R;
import com.merdolda.player.model.AppModels.StreamItem;

import java.util.ArrayList;
import java.util.List;

public class StreamAdapter extends RecyclerView.Adapter<StreamAdapter.VH> {

    private List<StreamItem> list;
    private OnItemClick listener;

    public interface OnItemClick { void onClick(StreamItem item); }

    public StreamAdapter(List<StreamItem> list, OnItemClick listener) {
        this.list = list != null ? list : new ArrayList<>();
        this.listener = listener;
    }

    public void update(List<StreamItem> n) {
        this.list = n != null ? n : new ArrayList<>();
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_channel, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        StreamItem i = list.get(pos);
        h.t.setText(i.name);

        Glide.with(h.itemView.getContext())
                .load(i.icon)
                .placeholder(R.drawable.ic_play)
                .into(h.i);

        h.itemView.setOnClickListener(v -> {
            if (listener != null) listener.onClick(i); // tek tık
        });
    }

    @Override
    public int getItemCount() { return list != null ? list.size() : 0; }

    static class VH extends RecyclerView.ViewHolder {
        TextView t;
        ImageView i;
        VH(View v) {
            super(v);
            t = v.findViewById(R.id.tvName);
            i = v.findViewById(R.id.ivIcon);
        }
    }
}
EOF

# 8. LAYOUTLAR (ARAMA ALANLARI EKLENDİ)

# Selection (Playlist listesi + arama)
cat << 'EOF' > "$RES_DIR/layout/activity_selection.xml"
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/bg_dark">

    <ImageView
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:alpha="0.25"
        android:scaleType="centerCrop"
        android:src="@android:drawable/ic_menu_gallery"/>

    <View
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:background="@color/black_overlay"/>

    <TextView
        android:id="@+id/header"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="MY PLAYLISTS"
        android:textColor="@color/text_primary"
        android:textSize="30sp"
        android:textStyle="bold"
        android:layout_centerHorizontal="true"
        android:layout_marginTop="40dp"/>

    <EditText
        android:id="@+id/etSearchPlaylists"
        android:layout_width="match_parent"
        android:layout_height="40dp"
        android:layout_below="@id/header"
        android:layout_margin="16dp"
        android:hint="Search playlists..."
        android:paddingLeft="16dp"
        android:paddingRight="16dp"
        style="@style/GlassInput"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvPlaylists"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_below="@id/etSearchPlaylists"
        android:layout_above="@+id/btnGroup"
        android:padding="20dp"
        android:clipToPadding="false"/>

    <LinearLayout
        android:id="@+id/btnGroup"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:layout_alignParentBottom="true"
        android:padding="20dp">

        <Button
            android:id="@+id/btnXtream"
            android:layout_width="match_parent"
            android:layout_height="60dp"
            android:text="ADD XTREAM API"
            style="@style/NeonButton"
            android:layout_marginBottom="12dp"/>

        <Button
            android:id="@+id/btnM3u"
            android:layout_width="match_parent"
            android:layout_height="60dp"
            android:text="ADD M3U LINK"
            style="@style/GlassInput"
            android:textColor="#FFFFFF"/>
    </LinearLayout>

</RelativeLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_playlist.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    style="@style/GlassCard"
    android:layout_marginBottom="12dp"
    android:orientation="horizontal"
    android:gravity="center_vertical">

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:orientation="vertical">

        <TextView
            android:id="@+id/tvPlayName"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:textColor="#FFFFFF"
            android:textSize="18sp"
            android:textStyle="bold"/>

        <TextView
            android:id="@+id/tvPlayInfo"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginTop="4dp"
            android:textColor="@color/text_secondary"
            android:textSize="13sp"/>
    </LinearLayout>

    <ImageView
        android:id="@+id/btnDel"
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:src="@drawable/ic_delete"
        android:padding="4dp"/>
</LinearLayout>
EOF

# Dashboard
cat << 'EOF' > "$RES_DIR/layout/activity_dashboard.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:padding="30dp"
    android:gravity="center">

    <TextView
        android:id="@+id/tvUser"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="#FFFFFF"
        android:gravity="center"
        android:textSize="24sp"
        android:layout_marginBottom="16dp"
        android:textStyle="bold"/>

    <TextView
        android:id="@+id/tvExp"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="@color/text_secondary"
        android:gravity="center"
        android:textSize="14sp"
        android:layout_marginBottom="40dp"/>

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:weightSum="2"
        android:layout_marginBottom="40dp">

        <LinearLayout
            android:id="@+id/btnLive"
            android:layout_width="0dp"
            android:layout_height="160dp"
            android:layout_weight="1"
            android:layout_marginRight="10dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical">

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="LIVE TV"
                android:textColor="#FFFFFF"
                android:textSize="22sp"
                android:textStyle="bold"/>
        </LinearLayout>

        <LinearLayout
            android:id="@+id/btnMovies"
            android:layout_width="0dp"
            android:layout_height="160dp"
            android:layout_weight="1"
            android:layout_marginLeft="10dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical">

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="VOD"
                android:textColor="#FFFFFF"
                android:textSize="22sp"
                android:textStyle="bold"/>
        </LinearLayout>
    </LinearLayout>

    <Button
        android:id="@+id/btnLogout"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="SWITCH PLAYLIST"
        style="@style/NeonButton"
        android:paddingLeft="40dp"
        android:paddingRight="40dp"/>
</LinearLayout>
EOF

# XTREAM LOGIN
cat << 'EOF' > "$RES_DIR/layout/activity_login_xtream.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:padding="30dp"
    android:gravity="center">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="XTREAM LOGIN"
        android:textColor="#FFFFFF"
        android:textSize="28sp"
        android:textStyle="bold"
        android:layout_marginBottom="40dp"/>

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp"/>

    <EditText
        android:id="@+id/etUser"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Username"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp"/>

    <EditText
        android:id="@+id/etPass"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Password"
        android:inputType="textPassword"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp"/>

    <EditText
        android:id="@+id/etDns"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="http://url:port"
        style="@style/GlassInput"
        android:layout_marginBottom="40dp"/>

    <Button
        android:id="@+id/btnLogin"
        android:layout_width="match_parent"
        android:layout_height="60dp"
        android:text="CONNECT"
        style="@style/NeonButton"/>
</LinearLayout>
EOF

# M3U LOGIN
cat << 'EOF' > "$RES_DIR/layout/activity_login_m3u.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:padding="30dp"
    android:gravity="center">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="M3U LINK"
        android:textColor="#FFFFFF"
        android:textSize="28sp"
        android:textStyle="bold"
        android:layout_marginBottom="40dp"/>

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp"/>

    <EditText
        android:id="@+id/etUrl"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="http://example.com/playlist.m3u"
        style="@style/GlassInput"
        android:layout_marginBottom="40dp"/>

    <Button
        android:id="@+id/btnSave"
        android:layout_width="match_parent"
        android:layout_height="60dp"
        android:text="DOWNLOAD &amp; SAVE"
        style="@style/NeonButton"/>
</LinearLayout>
EOF

# Liste ekranı (kategori + arama + stream)
cat << 'EOF' > "$RES_DIR/layout/activity_list.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@color/bg_dark">

    <EditText
        android:id="@+id/etSearchStreams"
        android:layout_width="match_parent"
        android:layout_height="40dp"
        android:layout_margin="8dp"
        android:hint="Search channels..."
        android:paddingLeft="16dp"
        android:paddingRight="16dp"
        style="@style/GlassInput"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvCats"
        android:layout_width="match_parent"
        android:layout_height="60dp"
        android:padding="8dp"
        android:clipToPadding="false"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvStreams"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:padding="8dp"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_channel.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:padding="12dp"
    style="@style/GlassCard"
    android:layout_marginBottom="8dp"
    android:orientation="horizontal"
    android:gravity="center_vertical">

    <ImageView
        android:id="@+id/ivIcon"
        android:layout_width="40dp"
        android:layout_height="40dp"
        android:src="@drawable/ic_play"/>

    <TextView
        android:id="@+id/tvName"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textColor="#FFFFFF"
        android:textSize="16sp"
        android:layout_marginLeft="15dp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_category.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:padding="10dp"
    android:layout_marginRight="8dp"
    android:gravity="center">

    <TextView
        android:id="@+id/tvCatName"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textColor="#FFFFFF"
        android:textSize="14sp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

# Player
cat << 'EOF' > "$RES_DIR/layout/activity_player.xml"
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#000000">

    <com.google.android.exoplayer2.ui.StyledPlayerView
        android:id="@+id/player_view"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_gravity="center" />

    <ImageButton
        android:id="@+id/btnZoom"
        android:layout_width="50dp"
        android:layout_height="50dp"
        android:src="@drawable/ic_zoom"
        android:background="@drawable/bg_glass"
        android:layout_gravity="top|right"
        android:layout_margin="30dp"
        android:padding="10dp"/>
</FrameLayout>
EOF

# 9. JAVA UI SINIFLARI

# SelectionActivity
cat << 'EOF' > "$PKG_DIR/ui/SelectionActivity.java"
package com.merdolda.player.ui;

import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.EditText;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.merdolda.player.R;
import com.merdolda.player.adapter.PlaylistAdapter;
import com.merdolda.player.model.AppModels.Playlist;
import com.merdolda.player.utils.PrefUtils;

import java.util.ArrayList;
import java.util.List;

public class SelectionActivity extends AppCompatActivity {

    private PlaylistAdapter adapter;
    private List<Playlist> allList = new ArrayList<>();
    private RecyclerView rv;

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_selection);

        rv = findViewById(R.id.rvPlaylists);
        rv.setLayoutManager(new LinearLayoutManager(this));

        findViewById(R.id.btnXtream).setOnClickListener(v ->
                startActivity(new Intent(this, LoginXtreamActivity.class)));

        findViewById(R.id.btnM3u).setOnClickListener(v ->
                startActivity(new Intent(this, LoginM3uActivity.class)));

        EditText etSearch = findViewById(R.id.etSearchPlaylists);
        etSearch.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c, int i, int i1, int i2) {}
            @Override public void onTextChanged(CharSequence c, int i, int i1, int i2) {}
            @Override public void afterTextChanged(Editable e) {
                filterPlaylists(e.toString());
            }
        });

        load();
    }

    @Override
    protected void onResume() {
        super.onResume();
        load();
    }

    private void load() {
        allList = PrefUtils.getPlaylists(this);
        if (adapter == null) {
            adapter = new PlaylistAdapter(allList, new PlaylistAdapter.OnClick() {
                @Override
                public void onClick(Playlist p) {
                    PrefUtils.setActive(SelectionActivity.this, p.id);
                    startActivity(new Intent(SelectionActivity.this, DashboardActivity.class));
                }

                @Override
                public void onDelete(Playlist p) {
                    PrefUtils.deletePlaylist(SelectionActivity.this, p.id);
                    allList = PrefUtils.getPlaylists(SelectionActivity.this);
                    adapter.update(allList);
                }
            });
            rv.setAdapter(adapter);
        } else {
            adapter.update(allList);
        }
    }

    private void filterPlaylists(String q) {
        if (adapter == null) return;
        if (q == null) q = "";
        q = q.toLowerCase().trim();

        List<Playlist> filtered = new ArrayList<>();
        for (Playlist p : allList) {
            String name = p.name != null ? p.name.toLowerCase() : "";
            String type = p.type != null ? p.type.toLowerCase() : "";
            if (name.contains(q) || type.contains(q)) {
                filtered.add(p);
            }
        }
        adapter.update(filtered);
    }
}
EOF

# DashboardActivity
cat << 'EOF' > "$PKG_DIR/ui/DashboardActivity.java"
package com.merdolda.player.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.merdolda.player.R;
import com.merdolda.player.model.AppModels.Playlist;
import com.merdolda.player.utils.PrefUtils;

public class DashboardActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_dashboard);

        TextView tvUser = findViewById(R.id.tvUser);
        TextView tvExp  = findViewById(R.id.tvExp);

        Playlist p = PrefUtils.getActive(this);
        if (p != null) {
            tvUser.setText(p.name != null ? p.name : "Active Playlist");
            if (p.expiry != null && !p.expiry.isEmpty()) {
                tvExp.setText("Expires at: " + p.expiry);
            } else {
                tvExp.setText("");
            }
        }

        findViewById(R.id.btnLive).setOnClickListener(v -> {
            Intent i = new Intent(this, CommonListActivity.class);
            i.putExtra("type", "live");
            startActivity(i);
        });

        findViewById(R.id.btnMovies).setOnClickListener(v -> {
            Intent i = new Intent(this, CommonListActivity.class);
            i.putExtra("type", "vod");
            startActivity(i);
        });

        findViewById(R.id.btnLogout).setOnClickListener(v -> {
            PrefUtils.logout(this);
            startActivity(new Intent(this, SelectionActivity.class));
            finish();
        });
    }
}
EOF

# LoginXtreamActivity
cat << 'EOF' > "$PKG_DIR/ui/LoginXtreamActivity.java"
package com.merdolda.player.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.merdolda.player.R;
import com.merdolda.player.api.XtreamApi;
import com.merdolda.player.model.AppModels.LoginResponse;
import com.merdolda.player.model.AppModels.Playlist;
import com.merdolda.player.utils.PrefUtils;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class LoginXtreamActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_login_xtream);

        EditText name = findViewById(R.id.etName);
        EditText u    = findViewById(R.id.etUser);
        EditText p    = findViewById(R.id.etPass);
        EditText d    = findViewById(R.id.etDns);

        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String url = d.getText().toString().trim();
            if (!url.startsWith("http")) url = "http://" + url;

            Retrofit r = new Retrofit.Builder()
                    .baseUrl(url + "/")
                    .addConverterFactory(GsonConverterFactory.create())
                    .build();

            String finalUrl = url;

            r.create(XtreamApi.class)
                    .login(finalUrl + "/player_api.php",
                            u.getText().toString().trim(),
                            p.getText().toString().trim())
                    .enqueue(new Callback<LoginResponse>() {
                        @Override
                        public void onResponse(Call<LoginResponse> c, Response<LoginResponse> res) {
                            if (res.body() != null && res.body().userInfo != null) {
                                LoginResponse body = res.body();
                                Playlist pl = new Playlist();
                                pl.id   = null; // yeni
                                pl.type = "Xtream";
                                pl.url  = finalUrl;
                                pl.user = u.getText().toString().trim();
                                pl.pass = p.getText().toString().trim();
                                pl.name = name.getText().toString().trim();
                                if (body.userInfo.expDate != null) {
                                    pl.expiry = body.userInfo.expDate;
                                }

                                PrefUtils.savePlaylist(LoginXtreamActivity.this, pl);
                                startActivity(new Intent(LoginXtreamActivity.this, DashboardActivity.class));
                                finish();
                            } else {
                                Toast.makeText(LoginXtreamActivity.this, "Login Failed", Toast.LENGTH_SHORT).show();
                            }
                        }

                        @Override
                        public void onFailure(Call<LoginResponse> c, Throwable t) {
                            Toast.makeText(LoginXtreamActivity.this, "Connection Error", Toast.LENGTH_SHORT).show();
                        }
                    });
        });
    }
}
EOF

# LoginM3uActivity
cat << 'EOF' > "$PKG_DIR/ui/LoginM3uActivity.java"
package com.merdolda.player.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.merdolda.player.R;
import com.merdolda.player.model.AppModels.Playlist;
import com.merdolda.player.utils.PrefUtils;

import java.io.IOException;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class LoginM3uActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_login_m3u);

        EditText n = findViewById(R.id.etName);
        EditText u = findViewById(R.id.etUrl);

        findViewById(R.id.btnSave).setOnClickListener(v -> {
            String url = u.getText().toString().trim();
            if (url.isEmpty()) {
                Toast.makeText(this, "URL is empty", Toast.LENGTH_SHORT).show();
                return;
            }

            OkHttpClient client = new OkHttpClient();
            Request request = new Request.Builder().url(url).build();

            new Thread(() -> {
                try {
                    Response response = client.newCall(request).execute();
                    if (response.isSuccessful() && response.body() != null) {
                        String content = response.body().string();

                        runOnUiThread(() -> {
                            Playlist pl = new Playlist();
                            pl.id   = null;
                            pl.type = "M3U";
                            pl.name = n.getText().toString().trim();
                            pl.url  = url;
                            pl.m3uContent = content;

                            PrefUtils.savePlaylist(this, pl);
                            startActivity(new Intent(this, DashboardActivity.class));
                            finish();
                        });
                    } else {
                        runOnUiThread(() ->
                                Toast.makeText(this, "Failed to download M3U", Toast.LENGTH_SHORT).show());
                    }
                } catch (IOException e) {
                    runOnUiThread(() ->
                            Toast.makeText(this, "Failed to download M3U", Toast.LENGTH_SHORT).show());
                }
            }).start();
        });
    }
}
EOF

# CommonListActivity (ilk kategori otomatik, arama, M3U header)
cat << 'EOF' > "$PKG_DIR/ui/CommonListActivity.java"
package com.merdolda.player.ui;

import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.EditText;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.merdolda.player.R;
import com.merdolda.player.adapter.CategoryAdapter;
import com.merdolda.player.adapter.StreamAdapter;
import com.merdolda.player.api.XtreamApi;
import com.merdolda.player.model.AppModels.Category;
import com.merdolda.player.model.AppModels.Playlist;
import com.merdolda.player.model.AppModels.StreamItem;
import com.merdolda.player.utils.M3UParser;
import com.merdolda.player.utils.PrefUtils;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class CommonListActivity extends AppCompatActivity {

    private XtreamApi api;
    private RecyclerView rvC, rvS;
    private StreamAdapter adp;
    private String type;
    private Playlist p;

    private Map<String, List<StreamItem>> m3uMap = new LinkedHashMap<>();
    private List<Category> catList = new ArrayList<>();
    private List<StreamItem> currentList = new ArrayList<>();

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_list);

        type = getIntent().getStringExtra("type");
        p    = PrefUtils.getActive(this);

        rvC = findViewById(R.id.rvCats);
        rvS = findViewById(R.id.rvStreams);

        rvC.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));

        adp = new StreamAdapter(new ArrayList<>(), item -> {
            if (p == null) return;
            Intent in = new Intent(this, PlayerActivity.class);

            String url;
            String ref = null;
            String org = null;

            if ("Xtream".equals(p.type)) {
                String path = type.equals("live") ? "live" : "movie";
                String ext = (item.ext != null && !item.ext.isEmpty()) ? item.ext : "ts";
                url = p.url + "/" + path + "/" + p.user + "/" + p.pass + "/" + item.streamId + "." + ext;
            } else {
                url = item.directUrl;
                ref = item.referrer;
                org = item.origin;
            }

            in.putExtra("url", url);
            if (ref != null) in.putExtra("ref", ref);
            if (org != null) in.putExtra("org", org);
            startActivity(in);
        });
        rvS.setAdapter(adp);

        EditText etSearch = findViewById(R.id.etSearchStreams);
        etSearch.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c, int i, int i1, int i2) {}
            @Override public void onTextChanged(CharSequence c, int i, int i1, int i2) {}
            @Override public void afterTextChanged(Editable e) {
                filterStreams(e.toString());
            }
        });

        if (p != null) {
            if ("Xtream".equals(p.type)) {
                loadXtream();
            } else {
                loadM3u();
            }
        }
    }

    private void filterStreams(String q) {
        if (q == null) q = "";
        q = q.toLowerCase().trim();

        List<StreamItem> filtered = new ArrayList<>();
        for (StreamItem s : currentList) {
            String name = s.name != null ? s.name.toLowerCase() : "";
            if (name.contains(q)) filtered.add(s);
        }
        adp.update(filtered);
    }

    private void loadM3u() {
        if (p.m3uContent == null || p.m3uContent.isEmpty()) return;
        m3uMap = M3UParser.parse(p.m3uContent);
        catList.clear();
        for (String key : m3uMap.keySet()) {
            catList.add(new Category(key, key));
        }

        if (catList.isEmpty()) return;

        CategoryAdapter catAdp = new CategoryAdapter(catList, cat -> {
            List<StreamItem> list = m3uMap.get(cat.id);
            if (list == null) list = new ArrayList<>();
            currentList = list;
            adp.update(currentList);
        });
        rvC.setAdapter(catAdp);

        // İlk kategoriyi otomatik seç ve yükle
        Category first = catList.get(0);
        currentList = m3uMap.get(first.id);
        if (currentList == null) currentList = new ArrayList<>();
        adp.update(currentList);
        catAdp.setSelectedIndex(0);
    }

    private void loadXtream() {
        api = new Retrofit.Builder()
                .baseUrl(p.url + "/")
                .addConverterFactory(GsonConverterFactory.create())
                .build()
                .create(XtreamApi.class);

        String a = type.equals("live") ? "get_live_categories" : "get_vod_categories";

        api.getCategories(p.url + "/player_api.php", p.user, p.pass, a)
                .enqueue(new Callback<List<Category>>() {
                    @Override
                    public void onResponse(Call<List<Category>> c, Response<List<Category>> r) {
                        List<Category> body = r.body();
                        if (body == null || body.isEmpty()) return;

                        catList = body;
                        CategoryAdapter catAdp = new CategoryAdapter(catList, cat -> loadItems(cat.id));
                        rvC.setAdapter(catAdp);

                        // İlk kategoriyi otomatik yükle
                        Category first = catList.get(0);
                        catAdp.setSelectedIndex(0);
                        loadItems(first.id);
                    }

                    @Override
                    public void onFailure(Call<List<Category>> c, Throwable t) { }
                });
    }

    private void loadItems(String id) {
        String a = type.equals("live") ? "get_live_streams" : "get_vod_streams";
        api.getStreams(p.url + "/player_api.php", p.user, p.pass, a, id)
                .enqueue(new Callback<List<StreamItem>>() {
                    @Override
                    public void onResponse(Call<List<StreamItem>> c, Response<List<StreamItem>> r) {
                        List<StreamItem> body = r.body();
                        if (body == null) body = new ArrayList<>();
                        currentList = body;
                        adp.update(currentList);
                    }

                    @Override
                    public void onFailure(Call<List<StreamItem>> c, Throwable t) { }
                });
    }
}
EOF

# PlayerActivity (headers + 3sn controller hide)
cat << 'EOF' > "$PKG_DIR/ui/PlayerActivity.java"
package com.merdolda.player.ui;

import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.ProgressiveMediaSource;
import com.google.android.exoplayer2.source.hls.HlsMediaSource;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.merdolda.player.R;

import java.util.HashMap;
import java.util.Map;

public class PlayerActivity extends AppCompatActivity {

    private ExoPlayer p;
    private StyledPlayerView pv;
    private int resizeMode = 0; // 0:Fit, 1:Fill, 2:Zoom

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Tam ekran, bildirim barı vs göstermeden
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            getWindow().setFlags(
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            );
            getWindow().getAttributes().layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        setContentView(R.layout.activity_player);
        pv = findViewById(R.id.player_view);

        // Kontroller 3 saniye sonra otomatik kaybolsun
        pv.setControllerShowTimeoutMs(3000);
        pv.setControllerAutoShow(true);

        findViewById(R.id.btnZoom).setOnClickListener(v -> toggleZoom());

        p = new ExoPlayer.Builder(this).build();
        pv.setPlayer(p);

        String url = getIntent().getStringExtra("url");
        String ref = getIntent().getStringExtra("ref");
        String org = getIntent().getStringExtra("org");

        if (url != null && !url.isEmpty()) {
            playWithHeaders(url, ref, org);
        } else {
            Toast.makeText(this, "URL not found", Toast.LENGTH_SHORT).show();
        }
    }

    private void playWithHeaders(String url, String ref, String org) {
        DefaultHttpDataSource.Factory factory = new DefaultHttpDataSource.Factory()
                .setAllowCrossProtocolRedirects(true);

        Map<String, String> headers = new HashMap<>();
        if (ref != null && !ref.isEmpty()) headers.put("Referer", ref);
        if (org != null && !org.isEmpty()) headers.put("Origin", org);
        if (!headers.isEmpty()) {
            factory.setDefaultRequestProperties(headers);
        }

        Uri uri = Uri.parse(url);
        MediaItem item = MediaItem.fromUri(uri);

        MediaSource mediaSource;
        // Uzantısız / yönlendirmeli linkler için HLS tespiti
        if (url.contains(".m3u8") || url.contains("m3u8?")) {
            mediaSource = new HlsMediaSource.Factory(factory).createMediaSource(item);
        } else {
            mediaSource = new ProgressiveMediaSource.Factory(factory).createMediaSource(item);
        }

        p.setMediaSource(mediaSource);
        p.prepare();
        p.play();
    }

    private void toggleZoom() {
        resizeMode++;
        if (resizeMode > 2) resizeMode = 0;

        if (resizeMode == 0) {
            pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT);
            Toast.makeText(this, "MODE: FIT", Toast.LENGTH_SHORT).show();
        } else if (resizeMode == 1) {
            pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FILL);
            Toast.makeText(this, "MODE: STRETCH FILL", Toast.LENGTH_SHORT).show();
        } else {
            pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);
            Toast.makeText(this, "MODE: ZOOM CROP", Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (p != null) {
            p.release();
            p = null;
        }
    }
}
EOF

# 10. MANIFEST
cat << 'EOF' > "$MODULE_DIR/src/main/AndroidManifest.xml"
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:name="androidx.multidex.MultiDexApplication"
        android:label="ErdinPlayer"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true"
        android:icon="@drawable/ic_play">

        <activity
            android:name=".ui.SelectionActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name=".ui.LoginXtreamActivity"
            android:screenOrientation="portrait" />

        <activity android:name=".ui.LoginM3uActivity"
            android:screenOrientation="portrait" />

        <activity android:name=".ui.DashboardActivity"
            android:screenOrientation="portrait" />

        <activity android:name=".ui.CommonListActivity"
            android:screenOrientation="portrait" />

        <activity
            android:name=".ui.PlayerActivity"
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize"
            android:screenOrientation="sensor" />
    </application>
</manifest>
EOF

# 11. WRAPPER GENERATION
echo "⚙ Gradle Wrapper oluşturuluyor..."
cd "$PROJECT_ROOT"
gradle wrapper --gradle-version 8.4
chmod +x gradlew
cd ..

echo "✅ ERDINPLAYER v14: PROJE HAZIR."
echo "👉 Şimdi GitHub Actions içinde: gradle assembleRelease --no-daemon"
