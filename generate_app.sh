#!/bin/bash

# ============================================
# ERDINPLAYER v14 - STABLE BUILD
# - M3U #EXTVLCOPT:http-referrer / http-origin desteği
# - Uzantısız ve yönlendirmeli linkler (ExoPlayer + HttpDataSource)
# - Xtream abonelik bitiş tarihi gösterimi
# - Koyu spor yeşili tema
# - Kategoride ilk seçim otomatik doldurulur (boş liste yok)
# - Tek tıklamada çalışır, double-click ihtiyacı yok
# - Player zoom butonu 3 saniye sonra gizlenir, dokununca geri gelir
# ============================================

set -e

PROJECT_NAME="ErdinPlayer"
PROJECT_ROOT="theapp"     # GitHub Actions bu klasörü baz alıyor
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="com/merdolda/player"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "💎 ERDINPLAYER v14: PROJE OLUŞTURULUYOR..."

# 1) TEMİZLİK
if [ -d "$PROJECT_ROOT" ]; then
  rm -rf "$PROJECT_ROOT"
fi

mkdir -p "$PKG_DIR"/{model,adapter,api,utils,ui}
mkdir -p "$RES_DIR"/{layout,values,drawable,anim,menu,color,font}
mkdir -p "$PROJECT_ROOT/gradle/wrapper"

# 2) KEYSTORE
echo "🔐 Keystore oluşturuluyor..."
mkdir -p "$MODULE_DIR"
keytool -genkey -v \
  -keystore "$MODULE_DIR/release.keystore" \
  -alias erdinplayer \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass 123456 -keypass 123456 \
  -dname "CN=Erdin, O=ErdinPlayer, C=TR" 2>/dev/null || true

# 3) GRADLE & SETTINGS
cat << 'EOF' > "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat << 'EOF' > "$PROJECT_ROOT/build.gradle"
buildscript {
    repositories {
        google()
        mavenCentral()
    }
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

cat << 'EOF' > "$MODULE_DIR/build.gradle"
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
        versionCode 14
        versionName "14.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            signingConfig signingConfigs.debug
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            signingConfig signingConfigs.debug
        }
    }

    signingConfigs {
        debug {
            storeFile file("release.keystore")
            storePassword "123456"
            keyAlias "erdinplayer"
            keyPassword "123456"
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.1'
    implementation 'androidx.drawerlayout:drawerlayout:1.2.0'

    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.19.1'

    implementation 'com.github.bumptech.glide:glide:4.16.0'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
}
EOF

# 4) RENKLER & STYLES (KOYU SPOR YEŞİL TEMA)
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
        <item name="android:padding">12dp</item>
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
        <item name="android:padding">10dp</item>
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
    <corners android:radius="14dp"/>
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

# 5) MODELLER

cat << 'EOF' > "$PKG_DIR/model/AppModels.java"
package com.merdolda.player.model;

import com.google.gson.annotations.SerializedName;

import java.io.Serializable;
import java.util.List;
import java.util.ArrayList;

public class AppModels {

    public static class Playlist implements Serializable {
        public String id;
        public String name;
        public String type;   // Xtream / M3U
        public String url;
        public String user;
        public String pass;
        public String m3uContent;
        public String expDate;   // Xtream bitiş (timestamp string)
    }

    public static class LoginResponse implements Serializable {
        @SerializedName("user_info")
        public UserInfo userInfo;
        @SerializedName("server_info")
        public ServerInfo serverInfo;
    }

    public static class UserInfo implements Serializable {
        @SerializedName("username")
        public String username;
        @SerializedName("auth")
        public int auth;
        @SerializedName("exp_date")
        public String expDate;
    }

    public static class ServerInfo implements Serializable {
        @SerializedName("url")
        public String url;
    }

    public static class Category implements Serializable {
        @SerializedName("category_id")
        public String id;
        @SerializedName("category_name")
        public String name;

        public Category(String id, String name) {
            this.id = id;
            this.name = name;
        }
    }

    public static class StreamItem implements Serializable {
        @SerializedName("name")
        public String name;
        @SerializedName("stream_id")
        public String streamId;
        @SerializedName("stream_icon")
        public String icon;
        @SerializedName("container_extension")
        public String ext;

        public String directUrl;
        public String group;

        // M3U #EXTVLCOPT header desteği
        public String headerReferrer;
        public String headerOrigin;
    }
}
EOF

# 6) API & UTILS

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

import java.util.LinkedHashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * M3U PARSER
 * - #EXTINF'den isim / logo / grup alır
 * - #EXTVLCOPT:http-referrer / http-origin satırlarını okur
 * - Altındaki URL'yi directUrl yapar
 */
public class M3UParser {

    public static Map<String, List<StreamItem>> parse(String content) {
        Map<String, List<StreamItem>> map = new LinkedHashMap<>();
        if (content == null) return map;

        String[] lines = content.split("\\r?\\n");
        String currentGroup = "Uncategorized";
        StreamItem currentItem = null;

        Pattern pGroup = Pattern.compile("group-title=\"([^\"]*)\"");
        Pattern pLogo  = Pattern.compile("tvg-logo=\"([^\"]*)\"");

        for (String rawLine : lines) {
            String line = rawLine.trim();
            if (line.isEmpty()) continue;

            if (line.startsWith("#EXTINF")) {
                currentItem = new StreamItem();
                int comma = line.lastIndexOf(",");
                if (comma > 0 && comma < line.length() - 1) {
                    currentItem.name = line.substring(comma + 1).trim();
                } else {
                    currentItem.name = "Unknown Channel";
                }

                Matcher mGroup = pGroup.matcher(line);
                if (mGroup.find()) {
                    currentGroup = mGroup.group(1);
                } else {
                    currentGroup = "Uncategorized";
                }

                Matcher mLogo = pLogo.matcher(line);
                if (mLogo.find()) {
                    currentItem.icon = mLogo.group(1);
                }

                currentItem.group = currentGroup;
                currentItem.headerReferrer = null;
                currentItem.headerOrigin = null;

            } else if (line.startsWith("#EXTVLCOPT") && currentItem != null) {
                // #EXTVLCOPT:http-referrer=http://...
                // #EXTVLCOPT:http-origin=http://...
                String lower = line.toLowerCase();
                int eqIndex = line.indexOf('=');
                if (eqIndex > 0 && eqIndex < line.length() - 1) {
                    String value = line.substring(eqIndex + 1).trim();
                    if (lower.contains("http-referrer")) {
                        currentItem.headerReferrer = value;
                    } else if (lower.contains("http-origin")) {
                        currentItem.headerOrigin = value;
                    }
                }

            } else if (!line.startsWith("#") && currentItem != null) {
                // URL satırı
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

public class PrefUtils {

    private static SharedPreferences get(Context c) {
        return c.getSharedPreferences("ERD_V14", Context.MODE_PRIVATE);
    }

    public static void savePlaylist(Context c, Playlist p) {
        List<Playlist> list = getPlaylists(c);
        // Aynı ID varsa sil ve sona ekle (çakışmayı önlemek için)
        List<Playlist> newList = new ArrayList<>();
        for (Playlist old : list) {
            if (!old.id.equals(p.id)) {
                newList.add(old);
            }
        }
        newList.add(p);
        get(c).edit()
                .putString("L", new Gson().toJson(newList))
                .putString("A", p.id)
                .apply();
    }

    public static List<Playlist> getPlaylists(Context c) {
        String j = get(c).getString("L", "[]");
        List<Playlist> res = new Gson().fromJson(j, new TypeToken<List<Playlist>>(){}.getType());
        if (res == null) res = new ArrayList<>();
        return res;
    }

    public static Playlist getActive(Context c) {
        String id = get(c).getString("A", "");
        if (id == null || id.isEmpty()) return null;
        for (Playlist p : getPlaylists(c)) {
            if (id.equals(p.id)) return p;
        }
        return null;
    }

    public static void deletePlaylist(Context c, String id) {
        List<Playlist> list = getPlaylists(c);
        List<Playlist> newList = new ArrayList<>();
        for (Playlist p : list) {
            if (!p.id.equals(id)) newList.add(p);
        }
        get(c).edit().putString("L", new Gson().toJson(newList)).apply();
    }

    public static void logout(Context c) {
        get(c).edit().remove("A").apply();
    }
}
EOF

# 7) ADAPTERLER

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

    public interface OnClick {
        void onClick(Playlist p);
        void onDelete(Playlist p);
    }

    private final List<Playlist> list;
    private final OnClick listener;

    public PlaylistAdapter(List<Playlist> list, OnClick listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_playlist, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH holder, int position) {
        Playlist item = list.get(position);
        holder.n.setText(item.name);
        holder.t.setText(item.type != null ? item.type : "");

        holder.itemView.setOnClickListener(v -> {
            if (listener != null) listener.onClick(item);
        });
        holder.d.setOnClickListener(v -> {
            if (listener != null) listener.onDelete(item);
        });
    }

    @Override
    public int getItemCount() {
        return list != null ? list.size() : 0;
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView n, t;
        ImageView d;
        VH(@NonNull View v) {
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

    public interface OnClick {
        void onClick(Category item, int position);
    }

    private final List<Category> list;
    private final OnClick listener;
    private int selected = 0;

    public CategoryAdapter(List<Category> list, OnClick listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_category, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH holder, int position) {
        Category item = list.get(position);
        holder.t.setText(item.name);

        holder.itemView.setBackgroundResource(
                selected == position ? R.drawable.bg_neon_btn : R.drawable.bg_glass_input
        );

        holder.itemView.setOnClickListener(v -> {
            int old = selected;
            selected = holder.getAdapterPosition();
            notifyItemChanged(old);
            notifyItemChanged(selected);
            if (listener != null) listener.onClick(item, selected);
        });
    }

    @Override
    public int getItemCount() {
        return list != null ? list.size() : 0;
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView t;
        VH(@NonNull View v) {
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

    public interface OnItemClick {
        void onClick(StreamItem item);
    }

    private final OnItemClick listener;
    private List<StreamItem> list = new ArrayList<>();

    public StreamAdapter(OnItemClick listener) {
        this.listener = listener;
    }

    public void update(List<StreamItem> newList) {
        if (newList == null) {
            this.list = new ArrayList<>();
        } else {
            this.list = newList;
        }
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_channel, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH holder, int position) {
        StreamItem item = list.get(position);
        holder.t.setText(item.name);
        Glide.with(holder.itemView.getContext())
                .load(item.icon)
                .placeholder(R.drawable.ic_play)
                .into(holder.i);

        holder.itemView.setOnClickListener(v -> {
            if (listener != null) listener.onClick(item);
        });
    }

    @Override
    public int getItemCount() {
        return list != null ? list.size() : 0;
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView t;
        ImageView i;
        VH(@NonNull View v) {
            super(v);
            t = v.findViewById(R.id.tvName);
            i = v.findViewById(R.id.ivIcon);
        }
    }
}
EOF

# 8) LAYOUTLAR

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
        android:src="@android:drawable/ic_menu_gallery" />

    <View
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:background="@color/black_overlay" />

    <TextView
        android:id="@+id/header"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="MY PLAYLISTS"
        android:textColor="@color/text_primary"
        android:textSize="28sp"
        android:textStyle="bold"
        android:layout_centerHorizontal="true"
        android:layout_marginTop="40dp" />

    <EditText
        android:id="@+id/etSearchPlaylists"
        android:layout_width="match_parent"
        android:layout_height="40dp"
        android:layout_below="@id/header"
        android:layout_marginTop="12dp"
        android:layout_marginLeft="20dp"
        android:layout_marginRight="20dp"
        android:hint="Ara..."
        android:paddingLeft="12dp"
        android:paddingRight="12dp"
        android:textColor="@color/text_primary"
        android:textColorHint="@color/text_secondary"
        android:background="@drawable/bg_glass_input" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvPlaylists"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_below="@id/etSearchPlaylists"
        android:layout_above="@+id/btnGroup"
        android:layout_margin="20dp"
        android:clipToPadding="false" />

    <LinearLayout
        android:id="@+id/btnGroup"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_alignParentBottom="true"
        android:padding="20dp"
        android:orientation="vertical">

        <Button
            android:id="@+id/btnXtream"
            android:layout_width="match_parent"
            android:layout_height="52dp"
            android:text="ADD XTREAM API"
            style="@style/NeonButton"
            android:layout_marginBottom="10dp" />

        <Button
            android:id="@+id/btnM3u"
            android:layout_width="match_parent"
            android:layout_height="52dp"
            android:text="ADD M3U LINK"
            style="@style/GlassInput"
            android:textColor="@color/text_primary" />
    </LinearLayout>

</RelativeLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_playlist.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    style="@style/GlassCard"
    android:layout_marginBottom="10dp"
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
            android:textColor="@color/text_primary"
            android:textSize="18sp"
            android:textStyle="bold" />

        <TextView
            android:id="@+id/tvPlayInfo"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginTop="2dp"
            android:textColor="@color/text_secondary"
            android:textSize="12sp" />
    </LinearLayout>

    <ImageView
        android:id="@+id/btnDel"
        android:layout_width="28dp"
        android:layout_height="28dp"
        android:src="@drawable/ic_delete"
        android:padding="4dp" />

</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_dashboard.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:gravity="center"
    android:padding="30dp">

    <TextView
        android:id="@+id/tvUser"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:gravity="center"
        android:textSize="22sp"
        android:textStyle="bold"
        android:layout_marginBottom="4dp" />

    <TextView
        android:id="@+id/tvExpiry"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="@color/text_secondary"
        android:gravity="center"
        android:textSize="12sp"
        android:layout_marginBottom="30dp" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:weightSum="2"
        android:layout_marginBottom="40dp">

        <LinearLayout
            android:id="@+id/btnLive"
            android:layout_width="0dp"
            android:layout_height="140dp"
            android:layout_weight="1"
            android:layout_marginRight="10dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical">

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="LIVE TV"
                android:textColor="@color/text_primary"
                android:textSize="20sp"
                android:textStyle="bold" />
        </LinearLayout>

        <LinearLayout
            android:id="@+id/btnMovies"
            android:layout_width="0dp"
            android:layout_height="140dp"
            android:layout_weight="1"
            android:layout_marginLeft="10dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical">

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="VOD"
                android:textColor="@color/text_primary"
                android:textSize="20sp"
                android:textStyle="bold" />
        </LinearLayout>
    </LinearLayout>

    <Button
        android:id="@+id/btnLogout"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="SWITCH PLAYLIST"
        style="@style/NeonButton"
        android:paddingLeft="40dp"
        android:paddingRight="40dp" />

</LinearLayout>
EOF

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
        android:textColor="@color/text_primary"
        android:textSize="26sp"
        android:textStyle="bold"
        android:layout_marginBottom="30dp" />

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="12dp" />

    <EditText
        android:id="@+id/etUser"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Username"
        style="@style/GlassInput"
        android:layout_marginBottom="12dp" />

    <EditText
        android:id="@+id/etPass"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Password"
        android:inputType="textPassword"
        style="@style/GlassInput"
        android:layout_marginBottom="12dp" />

    <EditText
        android:id="@+id/etDns"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="http://url:port"
        style="@style/GlassInput"
        android:layout_marginBottom="25dp" />

    <Button
        android:id="@+id/btnLogin"
        android:layout_width="match_parent"
        android:layout_height="52dp"
        android:text="CONNECT"
        style="@style/NeonButton" />

</LinearLayout>
EOF

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
        android:textColor="@color/text_primary"
        android:textSize="26sp"
        android:textStyle="bold"
        android:layout_marginBottom="30dp" />

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="12dp" />

    <EditText
        android:id="@+id/etUrl"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="http://example.com/playlist.m3u"
        style="@style/GlassInput"
        android:layout_marginBottom="25dp" />

    <Button
        android:id="@+id/btnSave"
        android:layout_width="match_parent"
        android:layout_height="52dp"
        android:text="DOWNLOAD &amp; SAVE"
        style="@style/NeonButton" />

</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_list.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@color/bg_dark">

    <EditText
        android:id="@+id/etSearch"
        android:layout_width="match_parent"
        android:layout_height="40dp"
        android:layout_margin="8dp"
        android:hint="Ara..."
        android:textColor="@color/text_primary"
        android:textColorHint="@color/text_secondary"
        android:background="@drawable/bg_glass_input"
        android:paddingLeft="10dp"
        android:paddingRight="10dp" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvCats"
        android:layout_width="match_parent"
        android:layout_height="52dp"
        android:padding="6dp"
        android:clipToPadding="false" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvStreams"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:padding="8dp" />

</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_channel.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:padding="10dp"
    style="@style/GlassCard"
    android:layout_marginBottom="8dp"
    android:orientation="horizontal"
    android:gravity="center_vertical">

    <ImageView
        android:id="@+id/ivIcon"
        android:layout_width="40dp"
        android:layout_height="40dp"
        android:src="@drawable/ic_play" />

    <TextView
        android:id="@+id/tvName"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textSize="16sp"
        android:layout_marginLeft="12dp"
        android:textStyle="bold" />

</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_category.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:padding="8dp"
    android:layout_marginRight="6dp"
    android:gravity="center">

    <TextView
        android:id="@+id/tvCatName"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textSize="13sp"
        android:textStyle="bold" />
</LinearLayout>
EOF

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
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:src="@drawable/ic_zoom"
        android:background="@drawable/bg_glass"
        android:layout_gravity="top|right"
        android:layout_margin="20dp"
        android:padding="10dp" />

</FrameLayout>
EOF

# 9) JAVA UI SINIFLARI

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
    private List<Playlist> fullList = new ArrayList<>();
    private List<Playlist> filteredList = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_selection);

        RecyclerView rv = findViewById(R.id.rvPlaylists);
        rv.setLayoutManager(new LinearLayoutManager(this));

        EditText etSearch = findViewById(R.id.etSearchPlaylists);

        loadData();

        etSearch.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                filterPlaylists(s.toString());
            }
            @Override public void afterTextChanged(Editable s) {}
        });

        findViewById(R.id.btnXtream).setOnClickListener(v ->
                startActivity(new Intent(this, LoginXtreamActivity.class)));

        findViewById(R.id.btnM3u).setOnClickListener(v ->
                startActivity(new Intent(this, LoginM3uActivity.class)));
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadData();
    }

    private void loadData() {
        fullList = PrefUtils.getPlaylists(this);
        filteredList = new ArrayList<>(fullList);

        adapter = new PlaylistAdapter(filteredList, new PlaylistAdapter.OnClick() {
            @Override
            public void onClick(Playlist p) {
                // Sadece aktif playlist olarak kaydet, sonra Dashboard'a git
                PrefUtils.savePlaylist(SelectionActivity.this, p);
                startActivity(new Intent(SelectionActivity.this, DashboardActivity.class));
            }

            @Override
            public void onDelete(Playlist p) {
                PrefUtils.deletePlaylist(SelectionActivity.this, p.id);
                fullList.remove(p);
                filteredList.remove(p);
                adapter.notifyDataSetChanged();
            }
        });

        RecyclerView rv = findViewById(R.id.rvPlaylists);
        rv.setAdapter(adapter);
    }

    private void filterPlaylists(String query) {
        filteredList.clear();
        if (query == null || query.trim().isEmpty()) {
            filteredList.addAll(fullList);
        } else {
            String lower = query.toLowerCase();
            for (Playlist p : fullList) {
                if (p.name != null && p.name.toLowerCase().contains(lower)) {
                    filteredList.add(p);
                }
            }
        }
        if (adapter != null) adapter.notifyDataSetChanged();
    }
}
EOF

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
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dashboard);

        TextView tvUser = findViewById(R.id.tvUser);
        TextView tvExpiry = findViewById(R.id.tvExpiry);

        Playlist p = PrefUtils.getActive(this);
        if (p != null) {
            tvUser.setText(p.name != null ? p.name : "Active Playlist");
            if (p.expDate != null && !p.expDate.isEmpty() && !"null".equals(p.expDate)) {
                try {
                    long expSeconds = Long.parseLong(p.expDate);
                    long expMillis = expSeconds * 1000L;
                    long now = System.currentTimeMillis();
                    long diff = expMillis - now;
                    long days = diff / (1000L * 60L * 60L * 24L);
                    if (days >= 0) {
                        tvExpiry.setText("Abonelik bitişi: " + days + " gün sonra");
                    } else {
                        tvExpiry.setText("Abonelik süresi dolmuş.");
                    }
                } catch (Exception e) {
                    tvExpiry.setText("Süre bilgisi okunamadı.");
                }
            } else {
                tvExpiry.setText("Süre bilgisi yok.");
            }
        } else {
            tvUser.setText("Playlist seçilmedi");
            tvExpiry.setText("");
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

import java.util.UUID;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class LoginXtreamActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login_xtream);

        EditText name = findViewById(R.id.etName);
        EditText u = findViewById(R.id.etUser);
        EditText p = findViewById(R.id.etPass);
        EditText d = findViewById(R.id.etDns);

        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String url = d.getText().toString().trim();
            if (!url.startsWith("http")) {
                url = "http://" + url;
            }

            String base = url.endsWith("/") ? url : url + "/";
            Retrofit r = new Retrofit.Builder()
                    .baseUrl(base)
                    .addConverterFactory(GsonConverterFactory.create())
                    .build();

            XtreamApi api = r.create(XtreamApi.class);

            api.login(base + "player_api.php",
                    u.getText().toString().trim(),
                    p.getText().toString().trim())
                    .enqueue(new Callback<LoginResponse>() {
                        @Override
                        public void onResponse(Call<LoginResponse> call, Response<LoginResponse> response) {
                            if (response.body() != null && response.body().userInfo != null) {
                                LoginResponse body = response.body();
                                Playlist pl = new Playlist();
                                pl.id = UUID.randomUUID().toString();
                                pl.type = "Xtream";
                                pl.url = url;
                                pl.user = u.getText().toString().trim();
                                pl.pass = p.getText().toString().trim();
                                pl.name = name.getText().toString().trim();
                                if (body.userInfo != null) {
                                    pl.expDate = body.userInfo.expDate;
                                }
                                PrefUtils.savePlaylist(LoginXtreamActivity.this, pl);
                                startActivity(new Intent(LoginXtreamActivity.this, DashboardActivity.class));
                                finish();
                            } else {
                                Toast.makeText(LoginXtreamActivity.this, "Login Failed", Toast.LENGTH_SHORT).show();
                            }
                        }

                        @Override
                        public void onFailure(Call<LoginResponse> call, Throwable t) {
                            Toast.makeText(LoginXtreamActivity.this, "Connection Error", Toast.LENGTH_SHORT).show();
                        }
                    });
        });
    }
}
EOF

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

import java.util.UUID;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class LoginM3uActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login_m3u);

        EditText n = findViewById(R.id.etName);
        EditText u = findViewById(R.id.etUrl);

        findViewById(R.id.btnSave).setOnClickListener(v -> {
            String url = u.getText().toString().trim();
            if (url.isEmpty()) {
                Toast.makeText(LoginM3uActivity.this, "URL boş olamaz", Toast.LENGTH_SHORT).show();
                return;
            }

            OkHttpClient client = new OkHttpClient();

            new Thread(() -> {
                try {
                    Request request = new Request.Builder().url(url).build();
                    Response response = client.newCall(request).execute();
                    if (response.isSuccessful() && response.body() != null) {
                        String content = response.body().string();
                        runOnUiThread(() -> {
                            Playlist pl = new Playlist();
                            pl.id = UUID.randomUUID().toString();
                            pl.type = "M3U";
                            pl.name = n.getText().toString().trim();
                            pl.url = url;
                            pl.m3uContent = content;
                            PrefUtils.savePlaylist(LoginM3uActivity.this, pl);
                            startActivity(new Intent(LoginM3uActivity.this, DashboardActivity.class));
                            finish();
                        });
                    } else {
                        runOnUiThread(() ->
                                Toast.makeText(LoginM3uActivity.this, "M3U indirilemedi", Toast.LENGTH_SHORT).show());
                    }
                } catch (Exception e) {
                    runOnUiThread(() ->
                            Toast.makeText(LoginM3uActivity.this, "Hata: " + e.getMessage(), Toast.LENGTH_SHORT).show());
                }
            }).start();
        });
    }
}
EOF

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
    private StreamAdapter streamAdapter;
    private String type;
    private Playlist p;

    private Map<String, List<StreamItem>> m3uMap = new LinkedHashMap<>();
    private List<StreamItem> currentList = new ArrayList<>();
    private List<StreamItem> filteredList = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list);

        type = getIntent().getStringExtra("type");
        p = PrefUtils.getActive(this);

        rvC = findViewById(R.id.rvCats);
        rvS = findViewById(R.id.rvStreams);
        EditText etSearch = findViewById(R.id.etSearch);

        rvC.setLayoutManager(new LinearLayoutManager(this, RecyclerView.HORIZONTAL, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));

        streamAdapter = new StreamAdapter(item -> {
            String url;
            String ref = item.headerReferrer;
            String org = item.headerOrigin;

            if ("Xtream".equals(p.type)) {
                String path = "live";
                if ("vod".equals(type)) path = "movie";
                String ext = item.ext != null && !item.ext.isEmpty() ? item.ext : "ts";
                url = p.url + "/" + path + "/" + p.user + "/" + p.pass + "/" + item.streamId + "." + ext;
                ref = null;
                org = null;
            } else {
                url = item.directUrl;
            }

            Intent in = new Intent(this, PlayerActivity.class);
            in.putExtra("url", url);
            if (ref != null) in.putExtra("ref", ref);
            if (org != null) in.putExtra("org", org);
            startActivity(in);
        });

        rvS.setAdapter(streamAdapter);

        etSearch.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                filterStreams(s.toString());
            }
            @Override public void afterTextChanged(Editable s) {}
        });

        if (p != null && "Xtream".equals(p.type)) {
            loadXtream();
        } else if (p != null && "M3U".equals(p.type)) {
            loadM3u();
        }
    }

    private void filterStreams(String query) {
        filteredList.clear();
        if (query == null || query.trim().isEmpty()) {
            filteredList.addAll(currentList);
        } else {
            String lower = query.toLowerCase();
            for (StreamItem item : currentList) {
                if (item.name != null && item.name.toLowerCase().contains(lower)) {
                    filteredList.add(item);
                }
            }
        }
        streamAdapter.update(filteredList);
    }

    private void loadM3u() {
        m3uMap = M3UParser.parse(p.m3uContent);
        List<Category> cats = new ArrayList<>();
        for (String key : m3uMap.keySet()) {
            cats.add(new Category(key, key));
        }

        if (cats.isEmpty()) {
            rvC.setAdapter(null);
            currentList.clear();
            filteredList.clear();
            streamAdapter.update(new ArrayList<>());
            return;
        }

        CategoryAdapter catAdapter = new CategoryAdapter(cats, (cat, pos) -> {
            currentList = m3uMap.get(cat.id);
            if (currentList == null) currentList = new ArrayList<>();
            filterStreams(((EditText)findViewById(R.id.etSearch)).getText().toString());
        });
        rvC.setAdapter(catAdapter);

        // İlk kategori otomatik seçilsin
        currentList = m3uMap.get(cats.get(0).id);
        if (currentList == null) currentList = new ArrayList<>();
        filteredList = new ArrayList<>(currentList);
        streamAdapter.update(filteredList);
    }

    private void loadXtream() {
        String base = p.url;
        if (!base.startsWith("http")) base = "http://" + base;
        if (!base.endsWith("/")) base += "/";
        Retrofit r = new Retrofit.Builder()
                .baseUrl(base)
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        api = r.create(XtreamApi.class);

        String action = "get_live_categories";
        if ("vod".equals(type)) action = "get_vod_categories";

        api.getCategories(base + "player_api.php", p.user, p.pass, action)
                .enqueue(new Callback<List<Category>>() {
                    @Override
                    public void onResponse(Call<List<Category>> call, Response<List<Category>> response) {
                        List<Category> cats = response.body();
                        if (cats == null) cats = new ArrayList<>();
                        CategoryAdapter catAdapter = new CategoryAdapter(cats, (cat, pos) -> loadItems(cat.id));
                        rvC.setAdapter(catAdapter);

                        if (!cats.isEmpty()) {
                            loadItems(cats.get(0).id);
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Category>> call, Throwable t) {
                    }
                });
    }

    private void loadItems(String id) {
        if (api == null) return;
        String base = p.url;
        if (!base.startsWith("http")) base = "http://" + base;
        if (!base.endsWith("/")) base += "/";

        String action = "get_live_streams";
        if ("vod".equals(type)) action = "get_vod_streams";

        api.getStreams(base + "player_api.php", p.user, p.pass, action, id)
                .enqueue(new Callback<List<StreamItem>>() {
                    @Override
                    public void onResponse(Call<List<StreamItem>> call, Response<List<StreamItem>> response) {
                        List<StreamItem> list = response.body();
                        if (list == null) list = new ArrayList<>();
                        currentList = list;
                        filterStreams(((EditText)findViewById(R.id.etSearch)).getText().toString());
                    }

                    @Override
                    public void onFailure(Call<List<StreamItem>> call, Throwable t) {
                    }
                });
    }
}
EOF

cat << 'EOF' > "$PKG_DIR/ui/PlayerActivity.java"
package com.merdolda.player.ui;

import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageButton;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.source.DefaultMediaSourceFactory;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.merdolda.player.R;

import java.util.HashMap;
import java.util.Map;

public class PlayerActivity extends AppCompatActivity {

    private ExoPlayer player;
    private StyledPlayerView playerView;
    private ImageButton btnZoom;
    private int resizeMode = 0;
    private final Handler handler = new Handler();

    private final Runnable hideZoomRunnable = () -> {
        if (btnZoom != null) btnZoom.setVisibility(View.GONE);
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Tam ekran, ekran açık kalsın
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
            getWindow().getAttributes().layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        setContentView(R.layout.activity_player);

        playerView = findViewById(R.id.player_view);
        btnZoom = findViewById(R.id.btnZoom);

        // 3 sn sonra Zoom butonu gizlensin
        handler.postDelayed(hideZoomRunnable, 3000);

        playerView.setOnClickListener(v -> {
            if (btnZoom.getVisibility() == View.VISIBLE) {
                btnZoom.setVisibility(View.GONE);
            } else {
                btnZoom.setVisibility(View.VISIBLE);
                handler.removeCallbacks(hideZoomRunnable);
                handler.postDelayed(hideZoomRunnable, 3000);
            }
        });

        btnZoom.setOnClickListener(v -> toggleZoom());

        String url = getIntent().getStringExtra("url");
        String ref = getIntent().getStringExtra("ref");
        String org = getIntent().getStringExtra("org");

        DefaultHttpDataSource.Factory dataSourceFactory = new DefaultHttpDataSource.Factory()
                .setAllowCrossProtocolRedirects(true);

        Map<String, String> headers = new HashMap<>();
        headers.put("User-Agent", "Mozilla/5.0 (Android) ErdinPlayer/14");
        if (ref != null && !ref.isEmpty()) {
            headers.put("Referer", ref);
        }
        if (org != null && !org.isEmpty()) {
            headers.put("Origin", org);
        }
        dataSourceFactory.setDefaultRequestProperties(headers);

        player = new ExoPlayer.Builder(this)
                .setMediaSourceFactory(new DefaultMediaSourceFactory(dataSourceFactory))
                .build();

        playerView.setPlayer(player);

        if (url != null && !url.isEmpty()) {
            MediaItem mediaItem = new MediaItem.Builder()
                    .setUri(Uri.parse(url))
                    .build();
            player.setMediaItem(mediaItem);
            player.prepare();
            player.play();
        } else {
            Toast.makeText(this, "URL bulunamadı", Toast.LENGTH_SHORT).show();
        }
    }

    private void toggleZoom() {
        resizeMode++;
        if (resizeMode > 2) resizeMode = 0;

        if (resizeMode == 0) {
            playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT);
            Toast.makeText(this, "MODE: FIT", Toast.LENGTH_SHORT).show();
        } else if (resizeMode == 1) {
            playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FILL);
            Toast.makeText(this, "MODE: FILL", Toast.LENGTH_SHORT).show();
        } else {
            playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);
            Toast.makeText(this, "MODE: ZOOM", Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        handler.removeCallbacks(hideZoomRunnable);
        if (player != null) {
            player.release();
            player = null;
        }
    }
}
EOF

# 10) MANIFEST

cat << 'EOF' > "$MODULE_DIR/src/main/AndroidManifest.xml"
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
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

# 11) WRAPPER (İsteğe bağlı; GitHub Actions gradle komutu kullanıyor)

echo "⚙️ Gradle wrapper hazırlanıyor..."
cd "$PROJECT_ROOT"
gradle wrapper --gradle-version 8.4 || true
chmod +x gradlew || true
cd ..

echo "✅ ERDINPLAYER v14 HAZIR."
echo "👉 GitHub Actions zaten: gradle assembleRelease --no-daemon çalıştırıyor."
