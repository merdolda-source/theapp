#!/bin/bash
set -e

echo "======================================="
echo "  ERDINPLAYER - MEGA GENERATE APP v2  "
echo "======================================="

# -----------------------------
# 1) PANEL CONFIG OKUMA
# -----------------------------
APP_NAME="ErdinPlayer"
APP_PKG="com.merdolda.player"

ADMOB_APP_ID=""
ADMOB_BANNER_ID=""
ADMOB_INTER_ID=""
ADMOB_REWARD_ID=""

UNITY_GAME_ID=""
UNITY_BANNER_ID=""
UNITY_INTER_ID=""
UNITY_REWARD_ID=""

BANNER_INTERVAL=0
INTER_INTERVAL=0
REWARD_ON_START=0

if [ -f "app_config.json" ]; then
  echo "📄 app_config.json bulundu, panel ayarları okunuyor..."
  eval "$(
    python - << 'PY'
import json, sys

p = "app_config.json"
try:
    with open(p, "r", encoding="utf-8") as f:
        cfg = json.load(f)
except Exception:
    sys.exit(0)

def out(key, var):
    v = cfg.get(key, "")
    if v is None:
        v = ""
    v = str(v)
    v = v.replace("\\", "\\\\").replace('"', '\\"')
    print(f'{var}="{v}"')

mapping = {
  "app_name":"APP_NAME",
  "package_name":"APP_PKG",
  "admob_app_id":"ADMOB_APP_ID",
  "admob_banner_id":"ADMOB_BANNER_ID",
  "admob_interstitial_id":"ADMOB_INTER_ID",
  "admob_rewarded_id":"ADMOB_REWARD_ID",
  "unity_game_id":"UNITY_GAME_ID",
  "unity_banner_id":"UNITY_BANNER_ID",
  "unity_interstitial_id":"UNITY_INTER_ID",
  "unity_rewarded_id":"UNITY_REWARD_ID",
}
for k,v in mapping.items():
    out(k, v)

ints = {
  "banner_interval":"BANNER_INTERVAL",
  "interstitial_interval":"INTER_INTERVAL",
  "reward_on_start":"REWARD_ON_START"
}
for k,v in ints.items():
    val = cfg.get(k, 0)
    try:
        ival = int(val)
    except:
        ival = 0
    print(f'{v}="{ival}"')
PY
  )"
fi

[ -z "$APP_NAME" ] && APP_NAME="ErdinPlayer"
[ -z "$APP_PKG" ] && APP_PKG="com.merdolda.player"

echo "APP_NAME        = $APP_NAME"
echo "APP_PKG         = $APP_PKG"
echo "BANNER_INTERVAL = $BANNER_INTERVAL"
echo "INTER_INTERVAL  = $INTER_INTERVAL"
echo "REWARD_ON_START = $REWARD_ON_START"

# -----------------------------
# 2) PROJE YOL AYARLARI
# -----------------------------
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="${APP_PKG//./\/}"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "Klasör: $PROJECT_ROOT  Paket yolu: $PKG_PATH"

if [ -d "$PROJECT_ROOT" ]; then
  rm -rf "$PROJECT_ROOT"
fi

mkdir -p "$PKG_DIR"/{model,adapter,api,utils,ui}
mkdir -p "$RES_DIR"/{layout,values,drawable,anim,menu,color,font}
mkdir -p "$PROJECT_ROOT/gradle/wrapper"

# -----------------------------
# 3) KEYSTORE
# -----------------------------
echo "🔐 Keystore üretiliyor..."
mkdir -p "$MODULE_DIR"
keytool -genkey -v -keystore "$MODULE_DIR/release.keystore" \
  -alias erdinplayer \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass 123456 -keypass 123456 \
  -dname "CN=Erdin, O=ErdinPlayer, C=TR" 2>/dev/null || true

# -----------------------------
# 4) GRADLE / SETTINGS
# -----------------------------
cat > "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties" << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat > "$PROJECT_ROOT/build.gradle" << 'EOF'
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

cat > "$PROJECT_ROOT/settings.gradle" << EOF
rootProject.name = "$APP_NAME"
include ':app'
EOF

cat > "$PROJECT_ROOT/gradle.properties" << 'EOF'
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx4048m
EOF

mkdir -p "$MODULE_DIR"

cat > "$MODULE_DIR/build.gradle" << EOF
plugins {
    id 'com.android.application'
}

android {
    namespace '$APP_PKG'
    compileSdk 34

    defaultConfig {
        applicationId "$APP_PKG"
        minSdk 21
        targetSdk 34
        versionCode 13
        versionName "13.0"
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

    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.19.1'

    implementation 'com.github.bumptech.glide:glide:4.16.0'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
}
EOF

echo "# Proguard" > "$MODULE_DIR/proguard-rules.pro"

# -----------------------------
# 5) COLORS / STYLES / DRAWABLE
# -----------------------------
cat > "$RES_DIR/values/colors.xml" << 'EOF'
<resources>
    <color name="bg_dark">#020B09</color>
    <color name="accent">#00E676</color>
    <color name="accent_dark">#00C853</color>
    <color name="glass_bg">#1AFFFFFF</color>
    <color name="glass_stroke">#33FFFFFF</color>
    <color name="text_primary">#FFFFFF</color>
    <color name="text_secondary">#B0CBC1</color>
    <color name="black_overlay">#CC000000</color>
</resources>
EOF

cat > "$RES_DIR/values/styles.xml" << 'EOF'
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.NoActionBar">
        <item name="android:windowBackground">@color/bg_dark</item>
        <item name="colorPrimary">@color:bg_dark</item>
        <item name="colorAccent">@color:accent</item>
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
        <item name="android:textColorHint">#8AA89E</item>
        <item name="android:padding">12dp</item>
    </style>
</resources>
EOF

cat > "$RES_DIR/drawable/bg_glass.xml" << 'EOF'
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#1AFFFFFF"/>
    <corners android:radius="16dp"/>
    <stroke android:width="1dp" android:color="#33FFFFFF"/>
</shape>
EOF

cat > "$RES_DIR/drawable/bg_glass_input.xml" << 'EOF'
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#0DFFFFFF"/>
    <corners android:radius="12dp"/>
    <stroke android:width="1dp" android:color="#22FFFFFF"/>
</shape>
EOF

cat > "$RES_DIR/drawable/bg_neon_btn.xml" << 'EOF'
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <gradient
        android:startColor="#00E676"
        android:endColor="#00C853"
        android:angle="45"/>
    <corners android:radius="12dp"/>
</shape>
EOF

cat > "$RES_DIR/drawable/ic_play.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF" android:pathData="M8,5v14l11,-7z"/>
</vector>
EOF

cat > "$RES_DIR/drawable/ic_delete.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FF5252"
        android:pathData="M6,19c0,1.1 0.9,2 2,2h8c1.1,0 2,-0.9 2,-2V7H6v12zM19,4h-3.5l-1,-1h-5l-1,1H5v2h14V4z"/>
</vector>
EOF

cat > "$RES_DIR/drawable/ic_zoom.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF"
        android:pathData="M15,3l2.3,2.3 -2.89,2.87 1.42,1.42L18.7,6.7 21,9V3zM3,9l2.3,-2.3 2.87,2.89 1.42,-1.42L6.7,5.3 9,3H3zM9,21l-2.3,-2.3 2.89,-2.87 -1.42,-1.42L5.3,17.3 3,15v6zM21,15l-2.3,2.3 -2.87,-2.89 -1.42,1.42L17.3,18.7 15,21h6z"/>
</vector>
EOF

cat > "$RES_DIR/drawable/ic_launcher_background.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#020B09" android:pathData="M0,0h108v108h-108z"/>
</vector>
EOF

# -----------------------------
# 6) STRINGS
# -----------------------------
cat > "$RES_DIR/values/strings.xml" << EOF
<resources>
    <string name="app_name">$APP_NAME</string>
</resources>
EOF

# -----------------------------
# 7) MODELLER
# -----------------------------
cat > "$PKG_DIR/model/AppModels.java" << EOF
package $APP_PKG.model;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.List;

public class AppModels {

    public static class Playlist implements Serializable {
        public String id, name, type, url, user, pass;
        public String m3uContent;
        public String expDate;
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

    public static class ServerInfo implements Serializable {
        @SerializedName("url") public String url;
    }

    public static class Category implements Serializable {
        @SerializedName("category_id") public String id;
        @SerializedName("category_name") public String name;

        public Category(String id, String name) {
            this.id = id;
            this.name = name;
        }
    }

    public static class StreamItem implements Serializable {
        @SerializedName("name") public String name;
        @SerializedName("stream_id") public String streamId;
        @SerializedName("stream_icon") public String icon;
        @SerializedName("container_extension") public String ext;

        public String directUrl;
        public String group;

        public String ref;
        public String origin;
    }
}
EOF

# -----------------------------
# 8) API / UTILS
# -----------------------------
cat > "$PKG_DIR/api/XtreamApi.java" << EOF
package $APP_PKG.api;

import $APP_PKG.model.AppModels.*;
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

cat > "$PKG_DIR/utils/M3UParser.java" << EOF
package $APP_PKG.utils;

import $APP_PKG.model.AppModels.StreamItem;

import java.util.*;
import java.util.regex.*;

public class M3UParser {

    public static Map<String, List<StreamItem>> parse(String content) {
        Map<String, List<StreamItem>> map = new LinkedHashMap<>();
        String[] lines = content.split("\\n");
        String currentGroup = "Uncategorized";
        StreamItem currentItem = null;

        Pattern pGroup = Pattern.compile("group-title=\"([^\"]*)\"");
        Pattern pLogo  = Pattern.compile("tvg-logo=\"([^\"]*)\"");

        for (String rawLine : lines) {
            String line = rawLine.trim();
            if (line.startsWith("#EXTINF")) {
                currentItem = new StreamItem();

                int comma = line.lastIndexOf(",");
                if (comma > 0) {
                    currentItem.name = line.substring(comma + 1).trim();
                } else {
                    currentItem.name = "Unknown Channel";
                }

                Matcher mGroup = pGroup.matcher(line);
                if (mGroup.find()) {
                    currentGroup = mGroup.group(1);
                }

                Matcher mLogo = pLogo.matcher(line);
                if (mLogo.find()) {
                    currentItem.icon = mLogo.group(1);
                }

                currentItem.group = currentGroup;
                currentItem.ref = null;
                currentItem.origin = null;

            } else if (line.startsWith("#EXTVLCOPT:http-referrer=")) {
                if (currentItem != null) {
                    currentItem.ref = line.replace("#EXTVLCOPT:http-referrer=", "").trim();
                }
            } else if (line.startsWith("#EXTVLCOPT:http-origin=")) {
                if (currentItem != null) {
                    currentItem.origin = line.replace("#EXTVLCOPT:http-origin=", "").trim();
                }
            } else if (!line.isEmpty() && !line.startsWith("#") && currentItem != null) {
                currentItem.directUrl = line;

                if (!map.containsKey(currentGroup)) {
                    map.put(currentGroup, new ArrayList<StreamItem>());
                }
                map.get(currentGroup).add(currentItem);
                currentItem = null;
            }
        }
        return map;
    }
}
EOF

cat > "$PKG_DIR/utils/PrefUtils.java" << EOF
package $APP_PKG.utils;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import $APP_PKG.model.AppModels.Playlist;

import java.util.ArrayList;
import java.util.List;

public class PrefUtils {

    private static SharedPreferences get(Context c) {
        return c.getSharedPreferences("ERD_V13", 0);
    }

    public static void savePlaylist(Context c, Playlist p) {
        List<Playlist> l = getPlaylists(c);
        List<Playlist> newList = new ArrayList<>();
        for (Playlist pl : l) {
            if (pl.id == null || !pl.id.equals(p.id)) newList.add(pl);
        }
        newList.add(p);

        get(c).edit()
                .putString("L", new Gson().toJson(newList))
                .putString("A", p.id)
                .apply();
    }

    public static List<Playlist> getPlaylists(Context c) {
        String j = get(c).getString("L", "[]");
        java.lang.reflect.Type type = new TypeToken<List<Playlist>>(){}.getType();
        List<Playlist> l = new Gson().fromJson(j, type);
        if (l == null) l = new ArrayList<>();
        return l;
    }

    public static Playlist getActive(Context c) {
        String id = get(c).getString("A", "");
        for (Playlist p : getPlaylists(c)) {
            if (p.id != null && p.id.equals(id)) return p;
        }
        return null;
    }

    public static void deletePlaylist(Context c, String id) {
        List<Playlist> l = getPlaylists(c);
        List<Playlist> n = new ArrayList<>();
        for (Playlist p : l) {
            if (p.id == null || !p.id.equals(id)) n.add(p);
        }
        get(c).edit().putString("L", new Gson().toJson(n)).apply();
    }

    public static void logout(Context c) {
        get(c).edit().remove("A").apply();
    }
}
EOF

# -----------------------------
# 9) ADAPTERLER
# -----------------------------
cat > "$PKG_DIR/adapter/PlaylistAdapter.java" << EOF
package $APP_PKG.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import $APP_PKG.R;
import $APP_PKG.model.AppModels.Playlist;

import java.util.List;

public class PlaylistAdapter extends RecyclerView.Adapter<PlaylistAdapter.VH> {

    public interface OnClick {
        void onClick(Playlist p);
        void onDelete(Playlist p);
    }

    private List<Playlist> list;
    private OnClick listener;

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
        holder.t.setText(item.type);

        holder.itemView.setOnClickListener(v -> listener.onClick(item));
        holder.d.setOnClickListener(v -> listener.onDelete(item));
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    class VH extends RecyclerView.ViewHolder {
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

cat > "$PKG_DIR/adapter/CategoryAdapter.java" << EOF
package $APP_PKG.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import $APP_PKG.R;
import $APP_PKG.model.AppModels.Category;

import java.util.List;

public class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.VH> {

    public interface OnClick {
        void onClick(Category item);
    }

    private List<Category> list;
    private OnClick listener;
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
            listener.onClick(list.get(selected));
        });
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    class VH extends RecyclerView.ViewHolder {
        TextView t;
        VH(View v) {
            super(v);
            t = v.findViewById(R.id.tvCatName);
        }
    }
}
EOF

cat > "$PKG_DIR/adapter/StreamAdapter.java" << EOF
package $APP_PKG.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;

import $APP_PKG.R;
import $APP_PKG.model.AppModels.StreamItem;

import java.util.ArrayList;
import java.util.List;

public class StreamAdapter extends RecyclerView.Adapter<StreamAdapter.VH> {

    public interface OnItemClick {
        void onClick(StreamItem item);
    }

    private List<StreamItem> list;
    private OnItemClick listener;

    public StreamAdapter(List<StreamItem> list, OnItemClick listener) {
        this.list = list != null ? list : new ArrayList<>();
        this.listener = listener;
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

        holder.itemView.setOnClickListener(v -> listener.onClick(item));
    }

    @Override
    public int getItemCount() {
        return list == null ? 0 : list.size();
    }

    public void update(List<StreamItem> n) {
        this.list = n != null ? n : new ArrayList<>();
        notifyDataSetChanged();
    }

    class VH extends RecyclerView.ViewHolder {
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

# -----------------------------
# 10) LAYOUTLAR
# -----------------------------
cat > "$RES_DIR/layout/activity_selection.xml" << 'EOF'
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
        android:textSize="26sp"
        android:textStyle="bold"
        android:layout_centerHorizontal="true"
        android:layout_marginTop="40dp" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvPlaylists"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_below="@id/header"
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
            android:layout_height="56dp"
            android:text="ADD XTREAM API"
            style="@style/NeonButton"
            android:layout_marginBottom="12dp"/>

        <Button
            android:id="@+id/btnM3u"
            android:layout_width="match_parent"
            android:layout_height="56dp"
            android:text="ADD M3U LINK"
            style="@style/GlassInput"
            android:textColor="@color/text_primary"/>
    </LinearLayout>
</RelativeLayout>
EOF

cat > "$RES_DIR/layout/item_playlist.xml" << 'EOF'
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
            android:textStyle="bold"/>

        <TextView
            android:id="@+id/tvPlayInfo"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginTop="3dp"
            android:textColor="@color/text_secondary"
            android:textSize="14sp"/>
    </LinearLayout>

    <ImageView
        android:id="@+id/btnDel"
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:src="@drawable/ic_delete"
        android:padding="4dp"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_dashboard.xml" << 'EOF'
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
        android:layout_marginBottom="10dp"/>

    <TextView
        android:id="@+id/tvExp"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="@color/text_secondary"
        android:gravity="center"
        android:textSize="13sp"
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
            android:layout_height="150dp"
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
                android:textStyle="bold"/>
        </LinearLayout>

        <LinearLayout
            android:id="@+id/btnMovies"
            android:layout_width="0dp"
            android:layout_height="150dp"
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

cat > "$RES_DIR/layout/activity_login_xtream.xml" << 'EOF'
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
        android:textSize="24sp"
        android:textStyle="bold"
        android:layout_marginBottom="30dp"/>

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etUser"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Username"
        style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etPass"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Password"
        android:inputType="textPassword"
        style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etDns"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="http://url:port"
        style="@style/GlassInput"
        android:layout_marginBottom="30dp"/>

    <Button
        android:id="@+id/btnLogin"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:text="CONNECT"
        style="@style/NeonButton"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_login_m3u.xml" << 'EOF'
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
        android:textSize="24sp"
        android:textStyle="bold"
        android:layout_marginBottom="30dp"/>

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etUrl"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="http://example.com/playlist.m3u"
        style="@style/GlassInput"
        android:layout_marginBottom="30dp"/>

    <Button
        android:id="@+id/btnSave"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:text="DOWNLOAD &amp; SAVE"
        style="@style/NeonButton"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_list.xml" << 'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@color/bg_dark">

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

cat > "$RES_DIR/layout/item_channel.xml" << 'EOF'
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
        android:textColor="@color/text_primary"
        android:textSize="16sp"
        android:layout_marginLeft="15dp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/item_category.xml" << 'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:padding="8dp"
    android:layout_marginRight="8dp"
    android:gravity="center">

    <TextView
        android:id="@+id/tvCatName"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textSize="14sp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_player.xml" << 'EOF'
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#000000">

    <com.google.android.exoplayer2.ui.StyledPlayerView
        android:id="@+id/player_view"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_gravity="center"/>

    <ImageButton
        android:id="@+id/btnZoom"
        android:layout_width="50dp"
        android:layout_height="50dp"
        android:src="@drawable/ic_zoom"
        android:background="@drawable/bg_glass"
        android:layout_gravity="top|right"
        android:layout_margin="24dp"
        android:padding="10dp"/>
</FrameLayout>
EOF

# -----------------------------
# 11) JAVA UI SINIFLARI
# -----------------------------
cat > "$PKG_DIR/ui/SelectionActivity.java" << EOF
package $APP_PKG.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import $APP_PKG.R;
import $APP_PKG.adapter.PlaylistAdapter;
import $APP_PKG.model.AppModels.Playlist;
import $APP_PKG.utils.PrefUtils;

public class SelectionActivity extends AppCompatActivity {

    private PlaylistAdapter adapter;
    private List<Playlist> list;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_selection);

        RecyclerView rv = findViewById(R.id.rvPlaylists);
        rv.setLayoutManager(new LinearLayoutManager(this));

        findViewById(R.id.btnXtream).setOnClickListener(v ->
                startActivity(new Intent(this, LoginXtreamActivity.class))
        );

        findViewById(R.id.btnM3u).setOnClickListener(v ->
                startActivity(new Intent(this, LoginM3uActivity.class))
        );
    }

    @Override
    protected void onResume() {
        super.onResume();
        load();
    }

    private void load() {
        list = PrefUtils.getPlaylists(this);
        adapter = new PlaylistAdapter(list, new PlaylistAdapter.OnClick() {
            @Override
            public void onClick(Playlist p) {
                PrefUtils.savePlaylist(SelectionActivity.this, p);
                startActivity(new Intent(SelectionActivity.this, DashboardActivity.class));
            }

            @Override
            public void onDelete(Playlist p) {
                PrefUtils.deletePlaylist(SelectionActivity.this, p.id);
                list.remove(p);
                adapter.notifyDataSetChanged();
            }
        });
        ((RecyclerView)findViewById(R.id.rvPlaylists)).setAdapter(adapter);
    }
}
EOF

cat > "$PKG_DIR/ui/DashboardActivity.java" << EOF
package $APP_PKG.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import $APP_PKG.R;
import $APP_PKG.model.AppModels.Playlist;
import $APP_PKG.utils.PrefUtils;

public class DashboardActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dashboard);

        Playlist p = PrefUtils.getActive(this);
        TextView tvUser = findViewById(R.id.tvUser);
        TextView tvExp  = findViewById(R.id.tvExp);

        if (p != null) {
            tvUser.setText(p.name != null ? p.name : "Active Playlist");
            if (p.expDate != null && !p.expDate.isEmpty()) {
                tvExp.setText("Expires: " + p.expDate);
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

cat > "$PKG_DIR/ui/LoginXtreamActivity.java" << EOF
package $APP_PKG.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import java.util.UUID;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

import $APP_PKG.R;
import $APP_PKG.api.XtreamApi;
import $APP_PKG.model.AppModels.LoginResponse;
import $APP_PKG.model.AppModels.Playlist;
import $APP_PKG.utils.PrefUtils;

public class LoginXtreamActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login_xtream);

        EditText name = findViewById(R.id.etName);
        EditText u    = findViewById(R.id.etUser);
        EditText p    = findViewById(R.id.etPass);
        EditText d    = findViewById(R.id.etDns);

        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String url = d.getText().toString().trim();
            if (!url.startsWith("http")) {
                url = "http://" + url;
            }
            final String baseUrl = url;

            Retrofit r = new Retrofit.Builder()
                    .baseUrl(baseUrl + "/")
                    .addConverterFactory(GsonConverterFactory.create())
                    .build();

            XtreamApi api = r.create(XtreamApi.class);

            api.login(baseUrl + "/player_api.php",
                    u.getText().toString(),
                    p.getText().toString())
                    .enqueue(new Callback<LoginResponse>() {
                        @Override
                        public void onResponse(Call<LoginResponse> call, Response<LoginResponse> response) {
                            LoginResponse body = response.body();
                            if (body != null && body.userInfo != null) {
                                Playlist pl = new Playlist();
                                pl.id   = UUID.randomUUID().toString();
                                pl.type = "Xtream";
                                pl.url  = baseUrl;
                                pl.user = u.getText().toString();
                                pl.pass = p.getText().toString();
                                pl.name = name.getText().toString();
                                pl.expDate = body.userInfo.expDate;

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

cat > "$PKG_DIR/ui/LoginM3uActivity.java" << EOF
package $APP_PKG.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import java.util.UUID;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import $APP_PKG.R;
import $APP_PKG.model.AppModels.Playlist;
import $APP_PKG.utils.PrefUtils;

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
                Toast.makeText(this, "URL gerekli", Toast.LENGTH_SHORT).show();
                return;
            }

            OkHttpClient client = new OkHttpClient();
            Request request = new Request.Builder().url(url).build();

            new Thread(() -> {
                try {
                    Response response = client.newCall(request).execute();
                    if (response.isSuccessful()) {
                        String content = response.body().string();
                        runOnUiThread(() -> {
                            Playlist pl = new Playlist();
                            pl.id = UUID.randomUUID().toString();
                            pl.type = "M3U";
                            pl.name = n.getText().toString();
                            pl.url = url;
                            pl.m3uContent = content;

                            PrefUtils.savePlaylist(LoginM3uActivity.this, pl);
                            startActivity(new Intent(LoginM3uActivity.this, DashboardActivity.class));
                            finish();
                        });
                    } else {
                        runOnUiThread(() ->
                                Toast.makeText(LoginM3uActivity.this, "M3U indirilemedi", Toast.LENGTH_SHORT).show()
                        );
                    }
                } catch (Exception e) {
                    runOnUiThread(() ->
                            Toast.makeText(LoginM3uActivity.this, "M3U hatası", Toast.LENGTH_SHORT).show()
                    );
                }
            }).start();
        });
    }
}
EOF

cat > "$PKG_DIR/ui/CommonListActivity.java" << EOF
package $APP_PKG.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

import $APP_PKG.R;
import $APP_PKG.adapter.CategoryAdapter;
import $APP_PKG.adapter.StreamAdapter;
import $APP_PKG.api.XtreamApi;
import $APP_PKG.model.AppModels.Category;
import $APP_PKG.model.AppModels.Playlist;
import $APP_PKG.model.AppModels.StreamItem;
import $APP_PKG.utils.M3UParser;
import $APP_PKG.utils.PrefUtils;

public class CommonListActivity extends AppCompatActivity {

    private XtreamApi api;
    private RecyclerView rvC, rvS;
    private StreamAdapter adp;
    private String type;
    private Playlist p;

    private Map<String, List<StreamItem>> m3uMap;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list);

        type = getIntent().getStringExtra("type");
        p = PrefUtils.getActive(this);

        rvC = findViewById(R.id.rvCats);
        rvS = findViewById(R.id.rvStreams);

        rvC.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));

        adp = new StreamAdapter(new ArrayList<>(), item -> {
            Intent in = new Intent(this, PlayerActivity.class);
            String url;

            if ("Xtream".equals(p.type)) {
                String actionPath = type.equals("live") ? "live" : "movie";
                String ext = (item.ext != null && !item.ext.isEmpty()) ? item.ext : "ts";
                url = p.url + "/" + actionPath + "/" + p.user + "/" + p.pass + "/" + item.streamId + "." + ext;
                in.putExtra("url", url);
            } else {
                url = item.directUrl;
                in.putExtra("url", url);
                if (item.ref != null)   in.putExtra("ref", item.ref);
                if (item.origin != null) in.putExtra("origin", item.origin);
            }

            startActivity(in);
        });
        rvS.setAdapter(adp);

        if ("Xtream".equals(p.type)) {
            loadXtream();
        } else {
            loadM3u();
        }
    }

    private void loadM3u() {
        m3uMap = M3UParser.parse(p.m3uContent);
        List<Category> cats = new ArrayList<>();

        for (String key : m3uMap.keySet()) {
            cats.add(new Category(key, key));
        }

        CategoryAdapter catAdp = new CategoryAdapter(cats, cat -> {
            List<StreamItem> list = m3uMap.get(cat.id);
            adp.update(list);
        });
        rvC.setAdapter(catAdp);

        if (!cats.isEmpty()) {
            List<StreamItem> firstList = m3uMap.get(cats.get(0).id);
            adp.update(firstList);
        }
    }

    private void loadXtream() {
        Retrofit r = new Retrofit.Builder()
                .baseUrl(p.url + "/")
                .addConverterFactory(GsonConverterFactory.create())
                .build();

        api = r.create(XtreamApi.class);

        String a = type.equals("live") ? "get_live_categories" : "get_vod_categories";

        api.getCategories(p.url + "/player_api.php",
                        p.user,
                        p.pass,
                        a)
                .enqueue(new Callback<List<Category>>() {
                    @Override
                    public void onResponse(Call<List<Category>> call, Response<List<Category>> response) {
                        List<Category> cats = response.body();
                        if (cats == null) return;

                        CategoryAdapter catAdp = new CategoryAdapter(cats, cat -> loadItems(cat.id));
                        rvC.setAdapter(catAdp);

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
        String a = type.equals("live") ? "get_live_streams" : "get_vod_streams";

        api.getStreams(p.url + "/player_api.php",
                        p.user,
                        p.pass,
                        a,
                        id)
                .enqueue(new Callback<List<StreamItem>>() {
                    @Override
                    public void onResponse(Call<List<StreamItem>> call, Response<List<StreamItem>> response) {
                        if (response.body() != null) {
                            adp.update(response.body());
                        }
                    }

                    @Override
                    public void onFailure(Call<List<StreamItem>> call, Throwable t) {
                    }
                });
    }
}
EOF

cat > "$PKG_DIR/ui/PlayerActivity.java" << EOF
package $APP_PKG.ui;

import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageButton;
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

import $APP_PKG.R;

public class PlayerActivity extends AppCompatActivity {

    private ExoPlayer player;
    private StyledPlayerView playerView;
    private int resizeMode = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            getWindow().setFlags(
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            );
            getWindow().getAttributes().layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        hideSystemUi();

        setContentView(R.layout.activity_player);
        playerView = findViewById(R.id.player_view);

        playerView.setControllerShowTimeoutMs(3000);

        ImageButton btnZoom = findViewById(R.id.btnZoom);
        btnZoom.setOnClickListener(v -> toggleZoom());

        String url = getIntent().getStringExtra("url");
        String ref = getIntent().getStringExtra("ref");
        String origin = getIntent().getStringExtra("origin");

        player = new ExoPlayer.Builder(this).build();
        playerView.setPlayer(player);

        if (url != null && !url.isEmpty()) {
            DefaultHttpDataSource.Factory dsFactory = new DefaultHttpDataSource.Factory();

            if (ref != null && !ref.isEmpty()) {
                dsFactory.setDefaultRequestProperty("Referer", ref);
            }
            if (origin != null && !origin.isEmpty()) {
                dsFactory.setDefaultRequestProperty("Origin", origin);
            }

            MediaItem mediaItem = MediaItem.fromUri(Uri.parse(url));
            MediaSource mediaSource;

            String lower = url.toLowerCase();
            if (lower.contains("m3u8")) {
                mediaSource = new HlsMediaSource.Factory(dsFactory).createMediaSource(mediaItem);
            } else {
                mediaSource = new ProgressiveMediaSource.Factory(dsFactory).createMediaSource(mediaItem);
            }

            player.setMediaSource(mediaSource);
            player.prepare();
            player.play();
        } else {
            Toast.makeText(this, "Geçersiz yayın URL", Toast.LENGTH_SHORT).show();
        }
    }

    private void hideSystemUi() {
        View decorView = getWindow().getDecorView();
        int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;
        decorView.setSystemUiVisibility(flags);
    }

    private void toggleZoom() {
        resizeMode++;
        if (resizeMode > 2) resizeMode = 0;

        if (resizeMode == 0) {
            playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT);
            Toast.makeText(this, "MODE: FIT", Toast.LENGTH_SHORT).show();
        } else if (resizeMode == 1) {
            playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FILL);
            Toast.makeText(this, "MODE: STRETCH FILL", Toast.LENGTH_SHORT).show();
        } else {
            playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);
            Toast.makeText(this, "MODE: ZOOM CROP", Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        hideSystemUi();
        if (player != null) {
            player.play();
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (player != null) {
            player.pause();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (player != null) {
            player.release();
            player = null;
        }
    }
}
EOF

# -----------------------------
# 12) MANIFEST
# -----------------------------
cat > "$MODULE_DIR/src/main/AndroidManifest.xml" << EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:name="androidx.multidex.MultiDexApplication"
        android:label="$APP_NAME"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true"
        android:icon="@drawable/ic_play">

        <activity
            android:name="$APP_PKG.ui.SelectionActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity
            android:name="$APP_PKG.ui.LoginXtreamActivity"
            android:screenOrientation="portrait" />

        <activity
            android:name="$APP_PKG.ui.LoginM3uActivity"
            android:screenOrientation="portrait" />

        <activity
            android:name="$APP_PKG.ui.DashboardActivity"
            android:screenOrientation="portrait" />

        <activity
            android:name="$APP_PKG.ui.CommonListActivity"
            android:screenOrientation="portrait" />

        <activity
            android:name="$APP_PKG.ui.PlayerActivity"
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize"
            android:screenOrientation="sensor" />
    </application>
</manifest>
EOF

echo "✅ Proje oluşturuldu: $PROJECT_ROOT"
echo "⚙️  Şimdi workflow içinde: cd theapp && gradle assembleRelease --no-daemon çalışacak."
