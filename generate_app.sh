#!/bin/bash
set -e

echo "======================================="
echo "  ERDINPLAYER - MEGA GENERATE APP v4   "
echo "======================================="

CONFIG_FILE="app_config.json"

# Varsayılan değerler
APP_NAME="ErdinPlayer"
APP_PKG="com.merdolda.player"
VERSION_CODE=13
VERSION_NAME="13.0"
BANNER_INTERVAL=0
INTER_INTERVAL=0
REWARD_ON_START=0
ICON_URL=""
AD_MODE="none"   # admob / unity / hybrid / none

# Panel config varsa oku
if [ -f "$CONFIG_FILE" ] && command -v jq >/dev/null 2>&1; then
  echo "📄 $CONFIG_FILE bulundu, panel ayarları okunuyor..."
  APP_NAME=$(jq -r '.app_name // "ErdinPlayer"' "$CONFIG_FILE")
  APP_PKG=$(jq -r '.package_name // "com.merdolda.player"' "$CONFIG_FILE")
  VERSION_CODE=$(jq -r '.version_code // 13' "$CONFIG_FILE")
  VERSION_NAME=$(jq -r '.version_name // "13.0"' "$CONFIG_FILE")
  BANNER_INTERVAL=$(jq -r '.banner_interval // 0' "$CONFIG_FILE")
  INTER_INTERVAL=$(jq -r '.inter_interval // 0' "$CONFIG_FILE")
  REWARD_ON_START=$(jq -r '.reward_on_start // 0' "$CONFIG_FILE")
  ICON_URL=$(jq -r '.icon_url // ""' "$CONFIG_FILE")
  AD_MODE=$(jq -r '.ad_mode // "none"' "$CONFIG_FILE")
else
  echo "⚠️  $CONFIG_FILE yok veya jq yüklü değil, varsayılan değerler kullanılacak."
fi

echo "APP_NAME        = $APP_NAME"
echo "APP_PKG         = $APP_PKG"
echo "VERSION_CODE    = $VERSION_CODE"
echo "VERSION_NAME    = $VERSION_NAME"
echo "BANNER_INTERVAL = $BANNER_INTERVAL"
echo "INTER_INTERVAL  = $INTER_INTERVAL"
echo "REWARD_ON_START = $REWARD_ON_START"
echo "AD_MODE         = $AD_MODE"
echo "ICON_URL        = ${ICON_URL:-(yok)}"

# Proje yolları
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH=$(echo "$APP_PKG" | tr '.' '/')
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "📂 Proje klasörü: $PROJECT_ROOT"
echo "📦 Paket yolu:   $PKG_PATH"

# 1. TEMİZLİK & KLASÖRLER
if [ -d "$PROJECT_ROOT" ]; then rm -rf "$PROJECT_ROOT"; fi

mkdir -p "$PKG_DIR"/{model,adapter,api,utils,ui}
mkdir -p "$RES_DIR"/{layout,values,drawable,mipmap-xxxhdpi,anim,menu,color,font}
mkdir -p "$PROJECT_ROOT/gradle/wrapper"

################################
# 2. KEYSTORE
################################
echo "🔐 Keystore üretiliyor..."
keytool -genkey -v \
  -keystore "$MODULE_DIR/release.keystore" \
  -alias erdinplayer \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass 123456 -keypass 123456 \
  -dname "CN=Erdin, O=ErdinPlayer, C=TR" 2>/dev/null || true

################################
# 3. GRADLE / PROJE AYARLARI
################################
cat << 'EOF' > "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat << EOF > "$PROJECT_ROOT/build.gradle"
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

cat << EOF > "$MODULE_DIR/build.gradle"
plugins { id 'com.android.application' }

android {
    namespace '$APP_PKG'
    compileSdk 34

    defaultConfig {
        applicationId '$APP_PKG'
        minSdk 21
        targetSdk 34
        versionCode $VERSION_CODE
        versionName '$VERSION_NAME'
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

cat << 'EOF' > "$MODULE_DIR/proguard-rules.pro"
# ExoPlayer gibi kütüphaneleri koru
-keep class com.google.android.exoplayer2.** { *; }
-keep class com.google.android.exoplayer2.ui.** { *; }
EOF

################################
# 4. RENKLER / STYLES (KOYU SPOR YEŞİL)
################################
cat << 'EOF' > "$RES_DIR/values/colors.xml"
<resources>
    <!-- Koyu spor yeşili tema -->
    <color name="bg_dark">#020B08</color>
    <color name="accent">#00E676</color>
    <color name="accent_dark">#00C853</color>

    <color name="glass_bg">#1AFFFFFF</color>
    <color name="glass_stroke">#33FFFFFF</color>
    <color name="text_primary">#FFFFFF</color>
    <color name="text_secondary">#B0B0B0</color>
    <color name="black_overlay">#CC000000</color>
</resources>
EOF

cat << 'EOF' > "$RES_DIR/values/styles.xml"
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.NoActionBar">
        <item name="android:windowBackground">@color/bg_dark</item>
        <item name="colorPrimary">@color/bg_dark</item>
        <item name="colorSecondary">@color/accent</item>
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

# Drawables
cat << 'EOF' > "$RES_DIR/drawable/bg_glass.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="@color/glass_bg" />
    <corners android:radius="16dp" />
    <stroke android:width="1dp" android:color="@color/glass_stroke" />
</shape>
EOF

cat << 'EOF' > "$RES_DIR/drawable/bg_glass_input.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#0DFFFFFF" />
    <corners android:radius="12dp" />
    <stroke android:width="1dp" android:color="#22FFFFFF" />
</shape>
EOF

cat << 'EOF' > "$RES_DIR/drawable/bg_neon_btn.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <gradient
        android:startColor="@color/accent"
        android:endColor="@color/accent_dark"
        android:angle="45" />
    <corners android:radius="12dp" />
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
    <path android:fillColor="#FF3D00"
        android:pathData="M6,19c0,1.1 0.9,2 2,2h8c1.1,0 2,-0.9 2,-2V7H6v12zM19,4h-3.5l-1,-1h-5l-1,1H5v2h14V4z"/>
</vector>
EOF

cat << 'EOF' > "$RES_DIR/drawable/ic_zoom.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF"
        android:pathData="M15,3l2.3,2.3 -2.89,2.87 1.42,1.42L18.7,6.7 21,9V3zM3,9l2.3,-2.3 2.87,2.89 1.42,-1.42L6.7,5.3 9,3H3zM9,21l-2.3,-2.3 2.89,-2.87 -1.42,-1.42L5.3,17.3 3,15v6zM21,15l-2.3,2.3 -2.87,-2.89 -1.42,1.42L17.3,18.7 15,21h6z"/>
</vector>
EOF

cat << 'EOF' > "$RES_DIR/drawable/ic_launcher_background.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#020B08" android:pathData="M0,0h108v108h-108z"/>
</vector>
EOF

########################################
# 5. ICON (PANEL + GÜVENLİ PLACEHOLDER)
########################################

MIPMAP_DIR="$RES_DIR/mipmap-xxxhdpi"
mkdir -p "$MIPMAP_DIR"

ICON_TARGET="$MIPMAP_DIR/ic_launcher.png"
TEMP_ICON="$(mktemp /tmp/icon_XXXX.png)"

echo "🎨 Launcher icon hazırlanıyor..."

# Panelden icon indir (varsa)
if [ -n "$ICON_URL" ] && [ "$ICON_URL" != "null" ]; then
    echo "  → ICON_URL: $ICON_URL"
    if command -v curl >/dev/null 2>&1; then
        curl -s -L -k -A "Mozilla/5.0" -o "$TEMP_ICON" "$ICON_URL" || rm -f "$TEMP_ICON"
    else
        wget -q -O "$TEMP_ICON" "$ICON_URL" || rm -f "$TEMP_ICON"
    fi
fi

# convert varsa PNG'e çevir
if [ -s "$TEMP_ICON" ]; then
    if command -v convert >/dev/null 2>&1; then
        echo "  → ImageMagick bulundu, icon dönüştürülüyor..."
        convert "$TEMP_ICON" -resize 512x512^ -gravity center -extent 512x512 PNG32:"$ICON_TARGET" || rm -f "$ICON_TARGET"
    else
        echo "  → convert yok, ham dosya kopyalanıyor..."
        cp "$TEMP_ICON" "$ICON_TARGET" || rm -f "$ICON_TARGET"
    fi
fi

rm -f "$TEMP_ICON"

# Icon gerçekten PNG mi?
if [ -f "$ICON_TARGET" ] && command -v file >/dev/null 2>&1; then
    if ! file "$ICON_TARGET" | grep -qi "PNG image"; then
        echo "⚠️  Icon PNG değil / bozuk, varsayılan icon kullanılacak."
        rm -f "$ICON_TARGET"
    fi
fi

# Hâlâ icon yoksa: güvenli placeholder PNG
if [ ! -f "$ICON_TARGET" ]; then
    echo "🧩 Güvenli placeholder icon oluşturuluyor..."
    base64 -d > "$ICON_TARGET" << 'EOF_ICON'
iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAJ0lEQVR4nO3BAQ0AAADCoPdPbQ43
oAAAAAAAAAAAAAAAAAAAAAB4GxQkAAE3dn1XAAAAAElFTkSuQmCC
EOF_ICON
fi

################################
# 6. MODELLER
################################
cat << 'EOF' > "$PKG_DIR/model/AppModels.java"
package __PKG__.model;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.List;
import java.util.ArrayList;

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

        // M3U'dan gelecek olan header'lar
        public String origin;
        public String referer;
    }
}
EOF
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/model/AppModels.java"

################################
# 7. API & UTILS
################################
cat << 'EOF' > "$PKG_DIR/api/XtreamApi.java"
package __PKG__.api;

import __PKG__.model.AppModels.*;
import java.util.List;
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
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/api/XtreamApi.java"

cat << 'EOF' > "$PKG_DIR/utils/M3UParser.java"
package __PKG__.utils;

import __PKG__.model.AppModels.StreamItem;
import java.util.*;
import java.util.regex.*;

public class M3UParser {
    public static Map<String, List<StreamItem>> parse(String content) {
        Map<String, List<StreamItem>> map = new LinkedHashMap<>();
        String[] lines = content.split("\\n");
        String currentGroup = "Uncategorized";
        StreamItem currentItem = null;

        for (String raw : lines) {
            String line = raw.trim();
            if (line.startsWith("#EXTINF")) {
                currentItem = new StreamItem();

                int comma = line.lastIndexOf(",");
                if (comma > 0) currentItem.name = line.substring(comma + 1).trim();
                else currentItem.name = "Unknown Channel";

                Pattern pGroup = Pattern.compile("group-title=\"([^\"]*)\"");
                Matcher mGroup = pGroup.matcher(line);
                if (mGroup.find()) currentGroup = mGroup.group(1);

                Pattern pLogo = Pattern.compile("tvg-logo=\"([^\"]*)\"");
                Matcher mLogo = pLogo.matcher(line);
                if (mLogo.find()) currentItem.icon = mLogo.group(1);

                currentItem.group = currentGroup;
            } else if (line.startsWith("#EXTVLCOPT:http-referrer=")) {
                if (currentItem != null) {
                    currentItem.referer = line.replace("#EXTVLCOPT:http-referrer=", "").trim();
                }
            } else if (line.startsWith("#EXTVLCOPT:http-origin=")) {
                if (currentItem != null) {
                    currentItem.origin = line.replace("#EXTVLCOPT:http-origin=", "").trim();
                }
            } else if (!line.startsWith("#") && !line.isEmpty() && currentItem != null) {
                currentItem.directUrl = line;
                if (!map.containsKey(currentGroup)) map.put(currentGroup, new ArrayList<StreamItem>());
                map.get(currentGroup).add(currentItem);
                currentItem = null;
            }
        }
        return map;
    }
}
EOF
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/utils/M3UParser.java"

cat << 'EOF' > "$PKG_DIR/utils/PrefUtils.java"
package __PKG__.utils;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import __PKG__.model.AppModels.Playlist;
import java.util.List;
import java.util.ArrayList;

public class PrefUtils {
    private static SharedPreferences get(Context c) {
        return c.getSharedPreferences("ERD_V13", 0);
    }

    public static void savePlaylist(Context c, Playlist p) {
        List<Playlist> l = getPlaylists(c);
        boolean found = false;
        for (Playlist pl : l) {
            if (pl.id.equals(p.id)) {
                found = true;
                break;
            }
        }
        if (!found) {
            l.add(p);
        }
        get(c).edit()
                .putString("L", new Gson().toJson(l))
                .putString("A", p.id)
                .apply();
    }

    public static List<Playlist> getPlaylists(Context c) {
        String j = get(c).getString("L", "[]");
        List<Playlist> list = new Gson().fromJson(j, new TypeToken<List<Playlist>>(){}.getType());
        if (list == null) list = new ArrayList<>();
        return list;
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
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/utils/PrefUtils.java"

# Panelden gelen reklam sayıları vs için küçük config sınıfı
cat << EOF > "$PKG_DIR/utils/AppRemoteConfig.java"
package $APP_PKG.utils;

public class AppRemoteConfig {
    public static final int BANNER_INTERVAL = $BANNER_INTERVAL;
    public static final int INTER_INTERVAL  = $INTER_INTERVAL;
    public static final int REWARD_ON_START = $REWARD_ON_START;
    public static final String AD_MODE = "$AD_MODE"; // admob / unity / hybrid / none
}
EOF

################################
# 8. ADAPTERLER
################################
cat << 'EOF' > "$PKG_DIR/adapter/PlaylistAdapter.java"
package __PKG__.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import __PKG__.R;
import __PKG__.model.AppModels.Playlist;
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

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_playlist, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        Playlist i = list.get(position);
        h.n.setText(i.name);
        h.t.setText(i.type);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
        h.d.setOnClickListener(v -> listener.onDelete(i));
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
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/adapter/PlaylistAdapter.java"

cat << 'EOF' > "$PKG_DIR/adapter/CategoryAdapter.java"
package __PKG__.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import __PKG__.R;
import __PKG__.model.AppModels.Category;
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

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_category, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        Category item = list.get(position);
        h.t.setText(item.name);
        h.itemView.setBackgroundResource(sel == position ? R.drawable.bg_neon_btn : R.drawable.bg_glass_input);
        h.itemView.setOnClickListener(v -> {
            int o = sel;
            sel = h.getAdapterPosition();
            notifyItemChanged(o);
            notifyItemChanged(sel);
            listener.onClick(item);
        });
    }

    @Override
    public int getItemCount() { return list.size(); }

    class VH extends RecyclerView.ViewHolder {
        TextView t;
        VH(View v) {
            super(v);
            t = v.findViewById(R.id.tvCatName);
        }
    }
}
EOF
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/adapter/CategoryAdapter.java"

cat << 'EOF' > "$PKG_DIR/adapter/StreamAdapter.java"
package __PKG__.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;

import __PKG__.R;
import __PKG__.model.AppModels.StreamItem;
import java.util.List;

public class StreamAdapter extends RecyclerView.Adapter<StreamAdapter.VH> {
    private List<StreamItem> list;
    private OnItemClick listener;

    public interface OnItemClick { void onClick(StreamItem item); }

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
    public void onBindViewHolder(@NonNull VH h, int position) {
        StreamItem i = list.get(position);
        h.t.setText(i.name);
        Glide.with(h.itemView.getContext())
                .load(i.icon)
                .placeholder(R.drawable.ic_play)
                .into(h.i);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
    }

    @Override
    public int getItemCount() { return list == null ? 0 : list.size(); }

    public void update(List<StreamItem> n) {
        this.list = n;
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
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/adapter/StreamAdapter.java"

################################
# 9. LAYOUTLAR
################################
cat << 'EOF' > "$RES_DIR/layout/activity_selection.xml"
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
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
        android:textSize="30sp"
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
            android:layout_marginBottom="15dp"/>

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

cat << 'EOF' > "$RES_DIR/layout/item_playlist.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
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
            android:textStyle="bold"/>

        <TextView
            android:id="@+id/tvPlayInfo"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginTop="4dp"
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

cat << 'EOF' > "$RES_DIR/layout/activity_dashboard.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
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
        android:textStyle="bold"/>

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
                android:textColor="#FFF"
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

cat << 'EOF' > "$RES_DIR/layout/activity_login_xtream.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
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

cat << 'EOF' > "$RES_DIR/layout/activity_login_m3u.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
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

cat << 'EOF' > "$RES_DIR/layout/activity_list.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
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

cat << 'EOF' > "$RES_DIR/layout/item_channel.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
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
        android:textColor="#FFF"
        android:textSize="16sp"
        android:layout_marginLeft="15dp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_category.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="wrap_content" android:layout_height="wrap_content"
    android:padding="10dp"
    android:layout_marginRight="8dp"
    android:gravity="center">

    <TextView
        android:id="@+id/tvCatName"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textColor="#FFF"
        android:textSize="14sp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_player.xml"
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
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
        android:layout_margin="30dp"
        android:padding="10dp"/>
</FrameLayout>
EOF

################################
# 10. ACTIVITY JAVALARI
################################
cat << 'EOF' > "$PKG_DIR/ui/SelectionActivity.java"
package __PKG__.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import __PKG__.R;
import __PKG__.adapter.PlaylistAdapter;
import __PKG__.model.AppModels.Playlist;
import __PKG__.utils.PrefUtils;

import java.util.List;

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
        ((RecyclerView)findViewById(R.id.rvPlaylists)).setAdapter(adapter);
    }
}
EOF
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/ui/SelectionActivity.java"

cat << EOF > "$PKG_DIR/ui/DashboardActivity.java"
package $APP_PKG.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import $APP_PKG.R;
import $APP_PKG.utils.PrefUtils;
import $APP_PKG.model.AppModels.Playlist;

public class DashboardActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_dashboard);

        Playlist p = PrefUtils.getActive(this);
        if (p != null) ((TextView)findViewById(R.id.tvUser)).setText(p.name);

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
package __PKG__.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import __PKG__.R;
import __PKG__.api.XtreamApi;
import __PKG__.model.AppModels.LoginResponse;
import __PKG__.model.AppModels.Playlist;
import __PKG__.utils.PrefUtils;

import java.util.UUID;

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
        EditText u = findViewById(R.id.etUser);
        EditText p = findViewById(R.id.etPass);
        EditText d = findViewById(R.id.etDns);

        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String base = d.getText().toString().trim();
            if (!base.startsWith("http")) base = "http://" + base;
            final String fixedBase = base;

            Retrofit r = new Retrofit.Builder()
                    .baseUrl(fixedBase + "/")
                    .addConverterFactory(GsonConverterFactory.create())
                    .build();

            r.create(XtreamApi.class)
                    .login(fixedBase + "/player_api.php",
                            u.getText().toString().trim(),
                            p.getText().toString().trim())
                    .enqueue(new Callback<LoginResponse>() {
                        @Override
                        public void onResponse(Call<LoginResponse> c, Response<LoginResponse> res) {
                            if (res.body() != null && res.body().userInfo != null) {
                                Playlist pl = new Playlist();
                                pl.id = UUID.randomUUID().toString();
                                pl.type = "Xtream";
                                pl.url = fixedBase;
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
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/ui/LoginXtreamActivity.java"

cat << 'EOF' > "$PKG_DIR/ui/LoginM3uActivity.java"
package __PKG__.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import __PKG__.R;
import __PKG__.model.AppModels.Playlist;
import __PKG__.utils.PrefUtils;

import java.util.UUID;

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
                                Toast.makeText(this, "M3U indirilemedi", Toast.LENGTH_SHORT).show());
                    }
                } catch (Exception e) {
                    runOnUiThread(() ->
                            Toast.makeText(this, "Hata: " + e.getMessage(), Toast.LENGTH_SHORT).show());
                }
            }).start();
        });
    }
}
EOF
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/ui/LoginM3uActivity.java"

cat << 'EOF' > "$PKG_DIR/ui/CommonListActivity.java"
package __PKG__.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import __PKG__.R;
import __PKG__.adapter.CategoryAdapter;
import __PKG__.adapter.StreamAdapter;
import __PKG__.api.XtreamApi;
import __PKG__.model.AppModels.Category;
import __PKG__.model.AppModels.Playlist;
import __PKG__.model.AppModels.StreamItem;
import __PKG__.utils.M3UParser;
import __PKG__.utils.PrefUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

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

        rvC.setLayoutManager(new LinearLayoutManager(this, RecyclerView.HORIZONTAL, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));

        adp = new StreamAdapter(new ArrayList<>(), i -> {
            Intent in = new Intent(this, PlayerActivity.class);
            String url;
            if ("Xtream".equals(p.type)) {
                String actionPath = type.equals("live") ? "live" : "movie";
                url = p.url + "/" + actionPath + "/" + p.user + "/" + p.pass + "/" + i.streamId + "." + (i.ext != null ? i.ext : "ts");
                in.putExtra("url", url);
            } else {
                url = i.directUrl;
                in.putExtra("url", url);
                if (i.referer != null) in.putExtra("ref", i.referer);
                if (i.origin != null) in.putExtra("origin", i.origin);
            }
            startActivity(in);
        });
        rvS.setAdapter(adp);

        if ("Xtream".equals(p.type)) loadXtream();
        else loadM3u();
    }

    void loadM3u() {
        m3uMap = M3UParser.parse(p.m3uContent);
        List<Category> cats = new ArrayList<>();
        for (String key : m3uMap.keySet()) {
            cats.add(new Category(key, key));
        }
        rvC.setAdapter(new CategoryAdapter(cats, cat -> adp.update(m3uMap.get(cat.id))));
        if (!cats.isEmpty()) {
            adp.update(m3uMap.get(cats.get(0).id));
        }
    }

    void loadXtream() {
        Retrofit r = new Retrofit.Builder()
                .baseUrl(p.url + "/")
                .addConverterFactory(GsonConverterFactory.create())
                .build();

        api = r.create(XtreamApi.class);
        String a = type.equals("live") ? "get_live_categories" : "get_vod_categories";

        api.getCategories(p.url + "/player_api.php", p.user, p.pass, a)
                .enqueue(new Callback<List<Category>>() {
                    @Override
                    public void onResponse(Call<List<Category>> c, Response<List<Category>> r) {
                        if (r.body() != null) {
                            rvC.setAdapter(new CategoryAdapter(r.body(), cat -> loadItems(cat.id)));
                            // İlk kategoriyi otomatik yükle
                            if (!r.body().isEmpty()) {
                                loadItems(r.body().get(0).id);
                            }
                        }
                    }

                    @Override
                    public void onFailure(Call<List<Category>> c, Throwable t) {}
                });
    }

    void loadItems(String id) {
        String a = type.equals("live") ? "get_live_streams" : "get_vod_streams";
        api.getStreams(p.url + "/player_api.php", p.user, p.pass, a, id)
                .enqueue(new Callback<List<StreamItem>>() {
                    @Override
                    public void onResponse(Call<List<StreamItem>> c, Response<List<StreamItem>> r) {
                        if (r.body() != null) adp.update(r.body());
                    }

                    @Override
                    public void onFailure(Call<List<StreamItem>> c, Throwable t) {}
                });
    }
}
EOF
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/ui/CommonListActivity.java"

# PlayerActivity: DefaultHttpDataSource.Factory + referer/origin + 3sn controller
cat << 'EOF' > "$PKG_DIR/ui/PlayerActivity.java"
package __PKG__.ui;

import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
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

import __PKG__.R;

public class PlayerActivity extends AppCompatActivity {
    private ExoPlayer player;
    private StyledPlayerView playerView;
    private int resizeMode = 0; // 0: FIT, 1: FILL, 2: ZOOM

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Tam ekran, çentikleri de kullan
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

        playerView = findViewById(R.id.player_view);
        ImageButton btnZoom = findViewById(R.id.btnZoom);

        // Oynatıcı kontrolleri 3 saniye sonra otomatik saklansın
        playerView.setControllerShowTimeoutMs(3000);
        playerView.setControllerHideOnTouch(true);

        btnZoom.setOnClickListener(v -> toggleZoom());

        // ExoPlayer instance
        player = new ExoPlayer.Builder(this).build();
        playerView.setPlayer(player);

        // Intent’ten bilgiler
        String url = getIntent().getStringExtra("url");
        String ref = getIntent().getStringExtra("ref");
        String origin = getIntent().getStringExtra("origin");

        if (url == null || url.isEmpty()) {
            Toast.makeText(this, "URL bulunamadı", Toast.LENGTH_SHORT).show();
            return;
        }

        // 🔴 ÖNEMLİ: Burada TİP DefaultHttpDataSource.Factory
        DefaultHttpDataSource.Factory dsFactory =
                new DefaultHttpDataSource.Factory()
                        .setAllowCrossProtocolRedirects(true);

        // M3U’den gelen header’ları uygula
        if (ref != null && !ref.isEmpty()) {
            dsFactory.setDefaultRequestProperty("Referer", ref);
        }
        if (origin != null && !origin.isEmpty()) {
            dsFactory.setDefaultRequestProperty("Origin", origin);
        }

        Uri uri = Uri.parse(url);
        MediaItem mediaItem = MediaItem.fromUri(uri);

        MediaSource mediaSource;
        if (url.toLowerCase().contains(".m3u8")) {
            // HLS
            mediaSource = new HlsMediaSource.Factory(dsFactory).createMediaSource(mediaItem);
        } else {
            // Progressive (mp4, ts vs)
            mediaSource = new ProgressiveMediaSource.Factory(dsFactory).createMediaSource(mediaItem);
        }

        player.setMediaSource(mediaSource);
        player.prepare();
        player.play();
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
    protected void onDestroy() {
        super.onDestroy();
        if (player != null) {
            player.release();
            player = null;
        }
    }
}
EOF
sed -i "s#__PKG__#$APP_PKG#g" "$PKG_DIR/ui/PlayerActivity.java"

################################
# 11. MANIFEST
################################
cat << EOF > "$MODULE_DIR/src/main/AndroidManifest.xml"
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:name="androidx.multidex.MultiDexApplication"
        android:label="$APP_NAME"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name="$APP_PKG.ui.SelectionActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name="$APP_PKG.ui.LoginXtreamActivity"
            android:screenOrientation="portrait" />
        <activity android:name="$APP_PKG.ui.LoginM3uActivity"
            android:screenOrientation="portrait" />
        <activity android:name="$APP_PKG.ui.DashboardActivity"
            android:screenOrientation="portrait" />
        <activity android:name="$APP_PKG.ui.CommonListActivity"
            android:screenOrientation="portrait" />
        <activity
            android:name="$APP_PKG.ui.PlayerActivity"
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize"
            android:screenOrientation="sensor" />
    </application>
</manifest>
EOF

################################
# 12. GRADLE WRAPPER OLUŞTUR
################################
echo "🔧 Gradle Wrapper oluşturuluyor..."
cd "$PROJECT_ROOT"
gradle wrapper --gradle-version 8.4 || true
chmod +x gradlew || true
cd ..

echo "✅ ERDINPLAYER v4: M3U + Referer/Origin + Panel Config + Güvenli ICON hazır."
echo "👉 Şimdi workflow içinde: gradle -p theapp assembleRelease --no-daemon çalışacak."
