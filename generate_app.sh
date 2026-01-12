#!/bin/bash
set -e

echo "======================================="
echo "   ERDINPLAYER - MEGA GENERATE APP v5  "
echo "======================================="

# -------------------------------
# 0. VARSAYILAN AYARLAR
# -------------------------------
APP_NAME="ErdinPlayer"
PACKAGE_NAME="com.merdolda.player"
VERSION_CODE="13"
VERSION_NAME="13.0"

AD_MODE="admob"          # admob / unity / hybrid
BANNER_INTERVAL="0"
INTER_INTERVAL="0"
REWARD_ON_START="0"

ADMOB_APP_ID=""
ADMOB_BANNER_ID=""
ADMOB_INTER_ID=""
ADMOB_REWARD_ID=""

UNITY_GAME_ID=""
UNITY_BANNER_ID=""
UNITY_INTER_ID=""
UNITY_REWARD_ID=""

ICON_URL=""

# -------------------------------
# 1. app_config.json VARSA OKU
# -------------------------------
if [ -f "app_config.json" ]; then
  echo "📄 app_config.json bulundu, ayarlar yükleniyor..."
  eval "$(python - << 'PY'
import json, shlex, os

cfg = json.load(open("app_config.json", "r", encoding="utf-8"))

def emit(key, var):
    v = cfg.get(key)
    if v is None:
        return
    if isinstance(v, bool):
        v = "1" if v else "0"
    s = str(v)
    print(f'{var}={shlex.quote(s)}')

emit("app_name", "APP_NAME")
emit("package_name", "PACKAGE_NAME")
emit("version_code", "VERSION_CODE")
emit("version_name", "VERSION_NAME")

emit("ad_mode", "AD_MODE")
emit("banner_interval", "BANNER_INTERVAL")
emit("inter_interval", "INTER_INTERVAL")
emit("reward_on_start", "REWARD_ON_START")

emit("admob_app_id", "ADMOB_APP_ID")
emit("admob_banner_id", "ADMOB_BANNER_ID")
emit("admob_inter_id", "ADMOB_INTER_ID")
emit("admob_reward_id", "ADMOB_REWARD_ID")

emit("unity_game_id", "UNITY_GAME_ID")
emit("unity_banner_id", "UNITY_BANNER_ID")
emit("unity_inter_id", "UNITY_INTER_ID")
emit("unity_reward_id", "UNITY_REWARD_ID")

emit("icon_url", "ICON_URL")
PY
)"
else
  echo "⚠️ app_config.json yok, varsayılan ayarlar kullanılacak."
fi

# Güvenlik: version_code mutlaka sayı olsun
if ! [[ "$VERSION_CODE" =~ ^[0-9]+$ ]]; then
  VERSION_CODE="1"
fi

PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="${PACKAGE_NAME//.//}"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "APP_NAME        = $APP_NAME"
echo "PACKAGE_NAME    = $PACKAGE_NAME"
echo "VERSION_CODE    = $VERSION_CODE"
echo "VERSION_NAME    = $VERSION_NAME"
echo "AD_MODE         = $AD_MODE"
echo "BANNER_INTERVAL = $BANNER_INTERVAL"
echo "INTER_INTERVAL  = $INTER_INTERVAL"
echo "REWARD_ON_START = $REWARD_ON_START"
echo "ICON_URL        = $ICON_URL"
echo "Klasör: $PROJECT_ROOT  Paket yolu: $PKG_PATH"

# -------------------------------
# 2. TEMİZLİK & KLASÖR
# -------------------------------
if [ -d "$PROJECT_ROOT" ]; then
  rm -rf "$PROJECT_ROOT"
fi

mkdir -p "$PKG_DIR"/{model,adapter,api,utils,ui}
mkdir -p "$RES_DIR"/{layout,values,drawable,mipmap-xxxhdpi}
mkdir -p "$PROJECT_ROOT/gradle/wrapper"

# -------------------------------
# 3. KEYSTORE
# -------------------------------
echo "🔐 Keystore üretiliyor..."
keytool -genkey -v \
  -keystore "$MODULE_DIR/release.keystore" \
  -alias erdinplayer \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass 123456 -keypass 123456 \
  -dname "CN=Erdin, O=ErdinPlayer, C=TR" \
  2>/dev/null || true

# -------------------------------
# 4. GRADLE ROOT
# -------------------------------
cat > "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties" << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat > "$PROJECT_ROOT/build.gradle" << 'EOF'
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

cat > "$PROJECT_ROOT/settings.gradle" << EOF
rootProject.name = "$APP_NAME"
include ':app'
EOF

cat > "$PROJECT_ROOT/gradle.properties" << 'EOF'
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx4048m
EOF

# 5. APP MODÜLÜ GRADLE (REKLAM CONFIGLERİ DAHİL)
cat > "$MODULE_DIR/build.gradle" <<EOF
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.merdolda.player'
    compileSdk 34

    defaultConfig {
        applicationId "$PACKAGE_NAME"
        minSdk 21
        targetSdk 34
        versionCode $VERSION_CODE
        versionName "$VERSION_NAME"
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

            // Panelden gelen değerler BuildConfig'e yazılıyor
            buildConfigField "String", "PRIMARY_AD_MODE", "\"$AD_MODE\""
            buildConfigField "int", "BANNER_INTERVAL", "$BANNER_INTERVAL"
            buildConfigField "int", "INTER_INTERVAL", "$INTER_INTERVAL"
            buildConfigField "int", "REWARD_ON_START", "$REWARD_ON_START"
        }

        debug {
            minifyEnabled false
            signingConfig signingConfigs.release

            buildConfigField "String", "PRIMARY_AD_MODE", "\"$AD_MODE\""
            buildConfigField "int", "BANNER_INTERVAL", "$BANNER_INTERVAL"
            buildConfigField "int", "INTER_INTERVAL", "$INTER_INTERVAL"
            buildConfigField "int", "REWARD_ON_START", "$REWARD_ON_START"
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

    // Reklamlar
    implementation 'com.google.android.gms:play-services-ads:22.6.0'
    implementation 'com.unity3d.ads:unity-ads:4.9.3'
}
EOF


# -------------------------------
# 6. RESOURCES (RENKLER, STİLLER)
# -------------------------------
cat > "$RES_DIR/values/colors.xml" << 'EOF'
<resources>
    <color name="bg_dark">#050505</color>
    <color name="accent">#00C853</color>
    <color name="accent_dark">#009624</color>
    <color name="glass_bg">#1AFFFFFF</color>
    <color name="glass_stroke">#33FFFFFF</color>
    <color name="text_primary">#FFFFFF</color>
    <color name="text_secondary">#B0B0B0</color>
    <color name="black_overlay">#CC000000</color>
</resources>
EOF

cat > "$RES_DIR/values/styles.xml" << 'EOF'
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.NoActionBar">
        <item name="android:windowBackground">@color/bg_dark</item>
        <item name="colorPrimary">@color/accent</item>
        <item name="colorPrimaryVariant">@color/accent_dark</item>
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
        <item name="android:textColor">#FFF</item>
        <item name="android:textAllCaps">true</item>
        <item name="android:textStyle">bold</item>
    </style>

    <style name="GlassInput">
        <item name="android:background">@drawable/bg_glass_input</item>
        <item name="android:textColor">#FFF</item>
        <item name="android:textColorHint">#888</item>
        <item name="android:padding">16dp</item>
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
        android:startColor="#00C853"
        android:endColor="#009624"
        android:angle="45" />
    <corners android:radius="12dp"/>
</shape>
EOF

cat > "$RES_DIR/drawable/ic_play.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFF" android:pathData="M8,5v14l11,-7z"/>
</vector>
EOF

cat > "$RES_DIR/drawable/ic_delete.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FF3D00"
        android:pathData="M6,19c0,1.1 0.9,2 2,2h8c1.1,0 2,-0.9 2,-2V7H6v12zM19,4h-3.5l-1,-1h-5l-1,1H5v2h14V4z"/>
</vector>
EOF

cat > "$RES_DIR/drawable/ic_zoom.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFF"
        android:pathData="M15,3l2.3,2.3 -2.89,2.87 1.42,1.42L18.7,6.7 21,9V3zM3,9l2.3,-2.3 2.87,2.89 1.42,-1.42L6.7,5.3 9,3H3zM9,21l-2.3,-2.3 2.89,-2.87 -1.42,-1.42L5.3,17.3 3,15v6zM21,15l-2.3,2.3 -2.87,-2.89 -1.42,1.42L17.3,18.7 15,21h6z"/>
</vector>
EOF

cat > "$RES_DIR/drawable/ic_launcher_background.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#050505" android:pathData="M0,0h108v108h-108z"/>
</vector>
EOF

# strings.xml (app adı burada)
cat > "$RES_DIR/values/strings.xml" << EOF
<resources>
    <string name="app_name">$APP_NAME</string>
</resources>
EOF

# ads.xml (reklam id'leri)
cat > "$RES_DIR/values/ads.xml" << EOF
<resources>
    <string name="ad_mode">$AD_MODE</string>

    <string name="admob_app_id">$ADMOB_APP_ID</string>
    <string name="admob_banner_id">$ADMOB_BANNER_ID</string>
    <string name="admob_inter_id">$ADMOB_INTER_ID</string>
    <string name="admob_reward_id">$ADMOB_REWARD_ID</string>

    <string name="unity_game_id">$UNITY_GAME_ID</string>
    <string name="unity_banner_id">$UNITY_BANNER_ID</string>
    <string name="unity_inter_id">$UNITY_INTER_ID</string>
    <string name="unity_reward_id">$UNITY_REWARD_ID</string>
</resources>
EOF

# -------------------------------
# 7. İKON (ESKİ MANTIK + PNG KONTROL)
# -------------------------------
ICON_TARGET="$RES_DIR/mipmap-xxxhdpi/ic_launcher.png"
TEMP_ICON="icon_temp.png"

if [ -n "$ICON_URL" ]; then
  echo "🎨 Launcher icon hazırlanıyor..."
  echo "  → ICON_URL: $ICON_URL"
  curl -s -L -k -A "Mozilla/5.0" -o "$TEMP_ICON" "$ICON_URL" || true
fi

if [ -s "$TEMP_ICON" ] && command -v file >/dev/null 2>&1; then
  if ! file "$TEMP_ICON" | grep -qi "PNG image data"; then
    echo "⚠️ İndirilen dosya PNG değil, varsayılan ikon kullanılacak."
    rm -f "$TEMP_ICON"
  fi
fi

if [ -s "$TEMP_ICON" ]; then
  if command -v convert >/dev/null 2>&1; then
    convert "$TEMP_ICON" -resize 512x512! -background none -flatten "$ICON_TARGET"
  else
    echo "ℹ️ convert yok, ham PNG kopyalanıyor..."
    cp "$TEMP_ICON" "$ICON_TARGET"
  fi
else
  echo "ℹ️ ICON_URL kullanılamadı, fallback ikon oluşturuluyor..."
  if command -v convert >/dev/null 2>&1; then
    convert -size 512x512 xc:#00C853 \
      -fill white -gravity center -pointsize 150 \
      -annotate 0 "TV" "$ICON_TARGET"
  else
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==" | base64 -d > "$ICON_TARGET"
  fi
fi
rm -f "$TEMP_ICON"

# -------------------------------
# 8. MODEL / API / UTILS
# -------------------------------
cat > "$PKG_DIR/model/AppModels.java" << 'EOF'
package PACKAGE_REPLACE.model;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.List;

public class AppModels {
    public static class Playlist implements Serializable {
        public String id, name, type, url, user, pass;
        public String m3uContent;
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
        public String httpReferrer;
        public String httpOrigin;
    }
}
EOF

cat > "$PKG_DIR/api/XtreamApi.java" << 'EOF'
package PACKAGE_REPLACE.api;

import java.util.List;

import PACKAGE_REPLACE.model.AppModels.Category;
import PACKAGE_REPLACE.model.AppModels.LoginResponse;
import PACKAGE_REPLACE.model.AppModels.StreamItem;
import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Query;
import retrofit2.http.Url;

public interface XtreamApi {
    @GET
    Call<LoginResponse> login(@Url String url,
                              @Query("username") String u,
                              @Query("password") String p);

    @GET
    Call<List<Category>> getCategories(@Url String url,
                                       @Query("username") String u,
                                       @Query("password") String p,
                                       @Query("action") String a);

    @GET
    Call<List<StreamItem>> getStreams(@Url String url,
                                      @Query("username") String u,
                                      @Query("password") String p,
                                      @Query("action") String a,
                                      @Query("category_id") String c);
}
EOF

cat > "$PKG_DIR/utils/M3UParser.java" << 'EOF'
package PACKAGE_REPLACE.utils;

import java.util.*;
import java.util.regex.*;

import PACKAGE_REPLACE.model.AppModels.StreamItem;

public class M3UParser {
    public static Map<String, List<StreamItem>> parse(String content) {
        Map<String, List<StreamItem>> map = new LinkedHashMap<>();
        String[] lines = content.split("\\n");
        String currentGroup = "Uncategorized";
        StreamItem currentItem = null;
        String pendingRef = null;
        String pendingOrigin = null;

        for (String line : lines) {
            line = line.trim();
            if (line.startsWith("#EXTINF")) {
                currentItem = new StreamItem();
                int comma = line.lastIndexOf(",");
                if (comma > 0) currentItem.name = line.substring(comma + 1).trim();
                else currentItem.name = "Unknown Channel";

                Matcher mGroup = Pattern.compile("group-title=\"([^\"]*)\"").matcher(line);
                if (mGroup.find()) currentGroup = mGroup.group(1);

                Matcher mLogo = Pattern.compile("tvg-logo=\"([^\"]*)\"").matcher(line);
                if (mLogo.find()) currentItem.icon = mLogo.group(1);

                currentItem.group = currentGroup;
                currentItem.httpReferrer = pendingRef;
                currentItem.httpOrigin = pendingOrigin;
                pendingRef = null;
                pendingOrigin = null;

            } else if (line.startsWith("#EXTVLCOPT:http-referrer=")) {
                pendingRef = line.replace("#EXTVLCOPT:http-referrer=", "").trim();
            } else if (line.startsWith("#EXTVLCOPT:http-origin=")) {
                pendingOrigin = line.replace("#EXTVLCOPT:http-origin=", "").trim();
            } else if (!line.startsWith("#") && !line.isEmpty() && currentItem != null) {
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

cat > "$PKG_DIR/utils/PrefUtils.java" << 'EOF'
package PACKAGE_REPLACE.utils;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.util.ArrayList;
import java.util.List;

import PACKAGE_REPLACE.model.AppModels.Playlist;

public class PrefUtils {
    private static SharedPreferences get(Context c) {
        return c.getSharedPreferences("ERD_V13", 0);
    }

    public static void savePlaylist(Context c, Playlist p) {
        List<Playlist> l = getPlaylists(c);
        // aynı id varsa sil
        List<Playlist> copy = new ArrayList<>();
        for (Playlist x : l) {
            if (!x.id.equals(p.id)) copy.add(x);
        }
        copy.add(p);
        get(c).edit()
                .putString("L", new Gson().toJson(copy))
                .putString("A", p.id)
                .apply();
    }

    public static List<Playlist> getPlaylists(Context c) {
        String j = get(c).getString("L", "[]");
        return new Gson().fromJson(j, new TypeToken<List<Playlist>>() {}.getType());
    }

    public static Playlist getActive(Context c) {
        String id = get(c).getString("A", "");
        for (Playlist p : getPlaylists(c)) {
            if (p.id.equals(id)) return p;
        }
        return null;
    }

    public static void deletePlaylist(Context c, String id) {
        List<Playlist> l = getPlaylists(c);
        List<Playlist> copy = new ArrayList<>();
        for (Playlist p : l) {
            if (!p.id.equals(id)) copy.add(p);
        }
        get(c).edit().putString("L", new Gson().toJson(copy)).apply();
    }

    public static void logout(Context c) {
        get(c).edit().remove("A").apply();
    }
}
EOF

# -------------------------------
# 9. ADAPTERLER
# -------------------------------
cat > "$PKG_DIR/adapter/PlaylistAdapter.java" << 'EOF'
package PACKAGE_REPLACE.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import PACKAGE_REPLACE.R;
import PACKAGE_REPLACE.model.AppModels.Playlist;

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

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_playlist, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int p) {
        Playlist i = list.get(p);
        h.n.setText(i.name);
        h.t.setText(i.type);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
        h.d.setOnClickListener(v -> listener.onDelete(i));
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

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

cat > "$PKG_DIR/adapter/CategoryAdapter.java" << 'EOF'
package PACKAGE_REPLACE.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import PACKAGE_REPLACE.R;
import PACKAGE_REPLACE.model.AppModels.Category;

public class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.VH> {
    private List<Category> list;
    private OnClick listener;
    private int sel = 0;

    public interface OnClick {
        void onClick(Category item);
    }

    public CategoryAdapter(List<Category> list, OnClick listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_category, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int p) {
        h.t.setText(list.get(p).name);
        h.itemView.setBackgroundResource(sel == p ? R.drawable.bg_neon_btn : R.drawable.bg_glass_input);
        h.itemView.setOnClickListener(v -> {
            int o = sel;
            sel = h.getAdapterPosition();
            notifyItemChanged(o);
            notifyItemChanged(sel);
            listener.onClick(list.get(p));
        });
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView t;

        VH(View v) {
            super(v);
            t = v.findViewById(R.id.tvCatName);
        }
    }
}
EOF

cat > "$PKG_DIR/adapter/StreamAdapter.java" << 'EOF'
package PACKAGE_REPLACE.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;

import java.util.List;

import PACKAGE_REPLACE.R;
import PACKAGE_REPLACE.model.AppModels.StreamItem;

public class StreamAdapter extends RecyclerView.Adapter<StreamAdapter.VH> {
    private List<StreamItem> list;
    private OnItemClick listener;

    public interface OnItemClick {
        void onClick(StreamItem item);
    }

    public StreamAdapter(List<StreamItem> list, OnItemClick listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_channel, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int p) {
        StreamItem i = list.get(p);
        h.t.setText(i.name);
        Glide.with(h.itemView.getContext())
                .load(i.icon)
                .placeholder(R.drawable.ic_play)
                .into(h.i);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
    }

    @Override
    public int getItemCount() {
        return list == null ? 0 : list.size();
    }

    public void update(List<StreamItem> n) {
        this.list = n;
        notifyDataSetChanged();
    }

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

# -------------------------------
# 10. LAYOUTLAR
# -------------------------------
cat > "$RES_DIR/layout/activity_selection.xml" << 'EOF'
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/bg_dark">

    <ImageView
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:alpha="0.3"
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
        android:textSize="32sp"
        android:textStyle="bold"
        android:layout_centerHorizontal="true"
        android:layout_marginTop="50dp" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvPlaylists"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_below="@id/header"
        android:layout_above="@+id/btnGroup"
        android:padding="20dp"
        android:clipToPadding="false" />

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
            android:layout_marginBottom="15dp" />

        <Button
            android:id="@+id/btnM3u"
            android:layout_width="match_parent"
            android:layout_height="60dp"
            android:text="ADD M3U LINK"
            style="@style/GlassInput"
            android:textColor="#FFF" />
    </LinearLayout>
</RelativeLayout>
EOF

cat > "$RES_DIR/layout/item_playlist.xml" << 'EOF'
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
            android:textColor="#FFF"
            android:textSize="18sp"
            android:textStyle="bold" />

        <TextView
            android:id="@+id/tvPlayInfo"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginTop="4dp"
            android:textColor="@color/text_secondary"
            android:textSize="14sp" />
    </LinearLayout>

    <ImageView
        android:id="@+id/btnDel"
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:src="@drawable/ic_delete"
        android:padding="4dp" />
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
        android:textColor="#FFF"
        android:gravity="center"
        android:textSize="24sp"
        android:layout_marginBottom="60dp"
        android:textStyle="bold" />

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
                android:textColor="#FFF"
                android:textSize="22sp"
                android:textStyle="bold" />
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
                android:textColor="#FFF"
                android:textSize="22sp"
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
        android:textColor="#FFF"
        android:textSize="28sp"
        android:textStyle="bold"
        android:layout_marginBottom="40dp" />

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp" />

    <EditText
        android:id="@+id/etUser"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Username"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp" />

    <EditText
        android:id="@+id/etPass"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Password"
        android:inputType="textPassword"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp" />

    <EditText
        android:id="@+id/etDns"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="http://url:port"
        style="@style/GlassInput"
        android:layout_marginBottom="40dp" />

    <Button
        android:id="@+id/btnLogin"
        android:layout_width="match_parent"
        android:layout_height="60dp"
        android:text="CONNECT"
        style="@style/NeonButton" />
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
        android:textColor="#FFF"
        android:textSize="28sp"
        android:textStyle="bold"
        android:layout_marginBottom="40dp" />

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp" />

    <EditText
        android:id="@+id/etUrl"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="http://example.com/playlist.m3u"
        style="@style/GlassInput"
        android:layout_marginBottom="40dp" />

    <Button
        android:id="@+id/btnSave"
        android:layout_width="match_parent"
        android:layout_height="60dp"
        android:text="DOWNLOAD &amp; SAVE"
        style="@style/NeonButton" />
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
        android:clipToPadding="false" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvStreams"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:padding="8dp" />
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
        android:src="@drawable/ic_play" />

    <TextView
        android:id="@+id/tvName"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textColor="#FFF"
        android:textSize="16sp"
        android:layout_marginLeft="15dp"
        android:textStyle="bold" />
</LinearLayout>
EOF

cat > "$RES_DIR/layout/item_category.xml" << 'EOF'
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
        android:textColor="#FFF"
        android:textSize="14sp"
        android:textStyle="bold" />
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_player.xml" << 'EOF'
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#000">

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
        android:padding="10dp" />
</FrameLayout>
EOF

# -------------------------------
# 11. UI JAVA SINIFLARI
# -------------------------------
cat > "$PKG_DIR/ui/SelectionActivity.java" << 'EOF'
package PACKAGE_REPLACE.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import PACKAGE_REPLACE.R;
import PACKAGE_REPLACE.adapter.PlaylistAdapter;
import PACKAGE_REPLACE.model.AppModels.Playlist;
import PACKAGE_REPLACE.utils.PrefUtils;

public class SelectionActivity extends AppCompatActivity {
    PlaylistAdapter adapter;
    List<Playlist> list;

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_selection);

        RecyclerView rv = findViewById(R.id.rvPlaylists);
        rv.setLayoutManager(new LinearLayoutManager(this));

        load();

        findViewById(R.id.btnXtream).setOnClickListener(v ->
                startActivity(new Intent(this, LoginXtreamActivity.class)));

        findViewById(R.id.btnM3u).setOnClickListener(v ->
                startActivity(new Intent(this, LoginM3uActivity.class)));
    }

    @Override
    protected void onResume() {
        super.onResume();
        load();
    }

    void load() {
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
        ((RecyclerView) findViewById(R.id.rvPlaylists)).setAdapter(adapter);
    }
}
EOF

cat > "$PKG_DIR/ui/DashboardActivity.java" << 'EOF'
package PACKAGE_REPLACE.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import PACKAGE_REPLACE.R;
import PACKAGE_REPLACE.model.AppModels.Playlist;
import PACKAGE_REPLACE.utils.PrefUtils;

public class DashboardActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_dashboard);

        Playlist p = PrefUtils.getActive(this);
        if (p != null) ((TextView) findViewById(R.id.tvUser)).setText(p.name);

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

cat > "$PKG_DIR/ui/LoginXtreamActivity.java" << 'EOF'
package PACKAGE_REPLACE.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import java.util.UUID;

import PACKAGE_REPLACE.R;
import PACKAGE_REPLACE.api.XtreamApi;
import PACKAGE_REPLACE.model.AppModels.LoginResponse;
import PACKAGE_REPLACE.model.AppModels.Playlist;
import PACKAGE_REPLACE.utils.PrefUtils;
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

        EditText name = findViewById(R.id.etName),
                u = findViewById(R.id.etUser),
                p = findViewById(R.id.etPass),
                d = findViewById(R.id.etDns);

        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String url = d.getText().toString().trim();
            if (!url.startsWith("http")) url = "http://" + url;
            final String fU = url;

            Retrofit r = new Retrofit.Builder()
                    .baseUrl(fU + "/")
                    .addConverterFactory(GsonConverterFactory.create())
                    .build();

            r.create(XtreamApi.class)
                    .login(fU + "/player_api.php",
                            u.getText().toString().trim(),
                            p.getText().toString().trim())
                    .enqueue(new Callback<LoginResponse>() {
                        @Override
                        public void onResponse(Call<LoginResponse> c, Response<LoginResponse> res) {
                            if (res.body() != null && res.body().userInfo != null) {
                                Playlist pl = new Playlist();
                                pl.id = UUID.randomUUID().toString();
                                pl.type = "Xtream";
                                pl.url = fU;
                                pl.user = u.getText().toString().trim();
                                pl.pass = p.getText().toString().trim();
                                pl.name = name.getText().toString().trim();

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

cat > "$PKG_DIR/ui/LoginM3uActivity.java" << 'EOF'
package PACKAGE_REPLACE.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import java.util.UUID;

import PACKAGE_REPLACE.R;
import PACKAGE_REPLACE.model.AppModels.Playlist;
import PACKAGE_REPLACE.utils.PrefUtils;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class LoginM3uActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_login_m3u);

        EditText n = findViewById(R.id.etName),
                u = findViewById(R.id.etUrl);

        findViewById(R.id.btnSave).setOnClickListener(v -> {
            String url = u.getText().toString().trim();
            if (url.isEmpty()) {
                Toast.makeText(this, "URL boş olamaz", Toast.LENGTH_SHORT).show();
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
                            pl.id = UUID.randomUUID().toString();
                            pl.type = "M3U";
                            pl.name = n.getText().toString().trim();
                            pl.url = url;
                            pl.m3uContent = content;

                            PrefUtils.savePlaylist(this, pl);
                            startActivity(new Intent(this, DashboardActivity.class));
                            finish();
                        });
                    } else {
                        runOnUiThread(() ->
                                Toast.makeText(this, "M3U indirilemedi", Toast.LENGTH_SHORT).show()
                        );
                    }
                } catch (Exception e) {
                    runOnUiThread(() ->
                            Toast.makeText(this, "M3U indirilemedi", Toast.LENGTH_SHORT).show()
                    );
                }
            }).start();
        });
    }
}
EOF

cat > "$PKG_DIR/ui/CommonListActivity.java" << 'EOF'
package PACKAGE_REPLACE.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import PACKAGE_REPLACE.R;
import PACKAGE_REPLACE.adapter.CategoryAdapter;
import PACKAGE_REPLACE.adapter.StreamAdapter;
import PACKAGE_REPLACE.api.XtreamApi;
import PACKAGE_REPLACE.model.AppModels.Category;
import PACKAGE_REPLACE.model.AppModels.Playlist;
import PACKAGE_REPLACE.model.AppModels.StreamItem;
import PACKAGE_REPLACE.utils.M3UParser;
import PACKAGE_REPLACE.utils.PrefUtils;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class CommonListActivity extends AppCompatActivity {
    XtreamApi api;
    RecyclerView rvC, rvS;
    StreamAdapter adp;
    String type;
    Playlist p;
    Map<String, List<StreamItem>> m3uMap;

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_list);

        type = getIntent().getStringExtra("type");
        p = PrefUtils.getActive(this);

        rvC = findViewById(R.id.rvCats);
        rvS = findViewById(R.id.rvStreams);

        rvC.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));

        adp = new StreamAdapter(new ArrayList<>(), i -> {
            Intent in = new Intent(this, PlayerActivity.class);
            String url;
            String ref = null;
            String origin = null;

            if ("Xtream".equals(p.type)) {
                url = p.url + "/" + (type.equals("live") ? "live" : "movie") + "/" +
                        p.user + "/" + p.pass + "/" + i.streamId + "." + (i.ext != null ? i.ext : "ts");
            } else {
                url = i.directUrl;
                ref = i.httpReferrer;
                origin = i.httpOrigin;
            }

            in.putExtra("url", url);
            if (ref != null) in.putExtra("ref", ref);
            if (origin != null) in.putExtra("origin", origin);
            startActivity(in);
        });
        rvS.setAdapter(adp);

        if ("Xtream".equals(p.type)) loadXtream();
        else loadM3u();
    }

    void loadM3u() {
        if (p.m3uContent == null) return;
        m3uMap = M3UParser.parse(p.m3uContent);
        List<Category> cats = new ArrayList<>();
        for (String key : m3uMap.keySet()) {
            cats.add(new Category(key, key));
        }
        rvC.setAdapter(new CategoryAdapter(cats, cat -> adp.update(m3uMap.get(cat.id))));
        if (!cats.isEmpty()) adp.update(m3uMap.get(cats.get(0).id));
    }

    void loadXtream() {
        api = new Retrofit.Builder()
                .baseUrl(p.url + "/")
                .addConverterFactory(GsonConverterFactory.create())
                .build()
                .create(XtreamApi.class);

        String a = type.equals("live") ? "get_live_categories" : "get_vod_categories";
        api.getCategories(p.url + "/player_api.php", p.user, p.pass, a)
                .enqueue(new Callback<List<Category>>() {
                    public void onResponse(Call<List<Category>> c, Response<List<Category>> r) {
                        if (r.body() != null) {
                            rvC.setAdapter(new CategoryAdapter(r.body(), cat -> loadItems(cat.id)));
                            if (!r.body().isEmpty())
                                loadItems(r.body().get(0).id); // ilk kategori otomatik
                        }
                    }

                    public void onFailure(Call<List<Category>> c, Throwable t) {
                    }
                });
    }

    void loadItems(String id) {
        String a = type.equals("live") ? "get_live_streams" : "get_vod_streams";
        api.getStreams(p.url + "/player_api.php", p.user, p.pass, a, id)
                .enqueue(new Callback<List<StreamItem>>() {
                    public void onResponse(Call<List<StreamItem>> c, Response<List<StreamItem>> r) {
                        if (r.body() != null) adp.update(r.body());
                    }

                    public void onFailure(Call<List<StreamItem>> c, Throwable t) {
                    }
                });
    }
}
EOF

cat > "$PKG_DIR/ui/PlayerActivity.java" << 'EOF'
package PACKAGE_REPLACE.ui;

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
import com.google.android.exoplayer2.source.MediaSourceFactory;
import com.google.android.exoplayer2.source.ProgressiveMediaSource;
import com.google.android.exoplayer2.source.hls.HlsMediaSource;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;

import PACKAGE_REPLACE.R;

public class PlayerActivity extends AppCompatActivity {
    ExoPlayer p;
    StyledPlayerView pv;
    int resizeMode = 0; // 0:Fit, 1:Fill, 2:Zoom

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // FULL SCREEN NO LIMITS
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
            getWindow().getAttributes().layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        setContentView(R.layout.activity_player);
        pv = findViewById(R.id.player_view);
        ImageButton btnZoom = findViewById(R.id.btnZoom);

        btnZoom.setOnClickListener(v -> toggleZoom());

        String url = getIntent().getStringExtra("url");
        String ref = getIntent().getStringExtra("ref");
        String origin = getIntent().getStringExtra("origin");

        DefaultHttpDataSource.Factory dsFactory = new DefaultHttpDataSource.Factory()
                .setAllowCrossProtocolRedirects(true);

        if (ref != null && !ref.isEmpty()) {
            dsFactory.setDefaultRequestProperty("Referer", ref);
        }
        if (origin != null && !origin.isEmpty()) {
            dsFactory.setDefaultRequestProperty("Origin", origin);
        }

        MediaSourceFactory mediaSourceFactory;
        if (url != null && url.toLowerCase().contains(".m3u8")) {
            mediaSourceFactory = new HlsMediaSource.Factory(dsFactory);
        } else {
            mediaSourceFactory = new ProgressiveMediaSource.Factory(dsFactory);
        }

        p = new ExoPlayer.Builder(this)
                .setMediaSourceFactory(mediaSourceFactory)
                .build();

        pv.setPlayer(p);

        if (url != null) {
            MediaItem mediaItem = MediaItem.fromUri(Uri.parse(url));
            p.setMediaItem(mediaItem);
            p.prepare();
            p.play();
        } else {
            Toast.makeText(this, "URL bulunamadı", Toast.LENGTH_SHORT).show();
        }

        // 3 saniye sonra kontrol barını sakla
        pv.setControllerShowTimeoutMs(3000);
    }

    void toggleZoom() {
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
        if (p != null) p.release();
    }
}
EOF

# -------------------------------
# 12. ANDROIDMANIFEST (DİNAMİK LABEL)
# -------------------------------
cat > "$MODULE_DIR/src/main/AndroidManifest.xml" << EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:name="androidx.multidex.MultiDexApplication"
        android:label="$APP_NAME"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".$(echo "$PKG_PATH" | awk -F/ '{print $NF}')"
            android:exported="false" />

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

# Manifestte gereksiz activity kaydı var, onu basitçe bırakıyoruz (multiDexApplication zaten yeterli)

# -------------------------------
# 13. PACKAGE_REPLACE düzelt
# -------------------------------
# Java dosyalarında PACKAGE_REPLACE -> gerçek package
find "$PKG_DIR" -type f -name "*.java" -print0 | while IFS= read -r -d '' file; do
  sed -i "s/PACKAGE_REPLACE/$PACKAGE_NAME/g" "$file"
done

# -------------------------------
# 14. Gradle Wrapper
# -------------------------------
echo "🔧 Gradle Wrapper oluşturuluyor..."
cd "$PROJECT_ROOT"
gradle wrapper --gradle-version 8.4 || true
chmod +x gradlew || true
cd ..

echo "✅ Proje oluşturuldu: $PROJECT_ROOT"
echo "⚙️  Şimdi workflow içinde: cd theapp && gradle assembleRelease --no-daemon çalışacak."
