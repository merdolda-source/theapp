#!/bin/bash
set -e

echo "======================================="
echo "   ERDINPLAYER - MEGA GENERATE APP     "
echo "======================================="

# 1) build.env oku (panel.php'den geliyor)
if [ -f "./build.env" ]; then
    echo "📄 build.env bulundu, panel ayarları okunuyor..."
    # shellcheck disable=SC1091
    source ./build.env
else
    echo "⚠️ build.env bulunamadı, varsayılan ayarlar kullanılıyor."
fi

APP_NAME="${APP_NAME:-ErdinPlayer}"
PACKAGE_NAME="${PACKAGE_NAME:-com.merdolda.player}"
VERSION_CODE="${VERSION_CODE:-1}"
VERSION_NAME="${VERSION_NAME:-1.0}"
ICON_URL="${ICON_URL:-}"

PRIMARY_ADS="${PRIMARY_ADS:-admob}"
BANNER_INTERVAL="${BANNER_INTERVAL:-0}"
INTER_INTERVAL="${INTER_INTERVAL:-0}"
REWARD_ON_START="${REWARD_ON_START:-0}"
HYBRID_STRATEGY="${HYBRID_STRATEGY:-admob_first}"

ADMOB_APP_ID="${ADMOB_APP_ID:-}"
ADMOB_BANNER_ID="${ADMOB_BANNER_ID:-}"
ADMOB_INTER_ID="${ADMOB_INTER_ID:-}"
ADMOB_REWARD_ID="${ADMOB_REWARD_ID:-}"

UNITY_GAME_ID="${UNITY_GAME_ID:-}"
UNITY_BANNER_ID="${UNITY_BANNER_ID:-}"
UNITY_INTER_ID="${UNITY_INTER_ID:-}"
UNITY_REWARD_ID="${UNITY_REWARD_ID:-}"

PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="${PACKAGE_NAME//.//}"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "APP_NAME        = $APP_NAME"
echo "PACKAGE_NAME    = $PACKAGE_NAME"
echo "VERSION_CODE    = $VERSION_CODE"
echo "VERSION_NAME    = $VERSION_NAME"
echo "PRIMARY_ADS     = $PRIMARY_ADS"

# 2) Eski projeyi sil
if [ -d "$PROJECT_ROOT" ]; then
  rm -rf "$PROJECT_ROOT"
fi

# 3) Klasörler
mkdir -p "$PKG_DIR"/{model,adapter,api,utils,ui}
mkdir -p "$RES_DIR"/{layout,values,drawable,anim,menu,color,font,mipmap-xxxhdpi}
mkdir -p "$PROJECT_ROOT/gradle/wrapper"

# 4) Keystore
echo "🔐 Keystore üretiliyor..."
mkdir -p "$MODULE_DIR"
keytool -genkey -v \
  -keystore "$MODULE_DIR/release.keystore" \
  -alias erdinplayer \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass 123456 -keypass 123456 \
  -dname "CN=Erdin, O=ErdinPlayer, C=TR" 2>/dev/null || true

# 5) Gradle dosyaları
cat << 'EOF' > "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat << EOF > "$PROJECT_ROOT/build.gradle"
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath 'com.android.tools.build:gradle:8.1.1' }
}
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
EOF

cat << EOF > "$PROJECT_ROOT/settings.gradle"
rootProject.name = "$APP_NAME"
include ':app'
EOF

cat << 'EOF' > "$PROJECT_ROOT/gradle.properties"
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx4048m
EOF

# 6) app/build.gradle
cat << EOF > "$MODULE_DIR/build.gradle"
plugins { id 'com.android.application' }

android {
    namespace '$PACKAGE_NAME'
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

touch "$MODULE_DIR/proguard-rules.pro"

# 7) COLORS / STRINGS / STYLES / ADS
cat << 'EOF' > "$RES_DIR/values/colors.xml"
<resources>
    <color name="bg_dark">#02030A</color>
    <color name="accent">#00FF6A</color>
    <color name="glass_bg">#1AFFFFFF</color>
    <color name="glass_stroke">#33FFFFFF</color>
    <color name="text_primary">#FFFFFF</color>
    <color name="text_secondary">#B0B0B0</color>
    <color name="black_overlay">#CC000000</color>
</resources>
EOF

cat << EOF > "$RES_DIR/values/strings.xml"
<resources>
    <string name="app_name">$APP_NAME</string>
</resources>
EOF

cat << 'EOF' > "$RES_DIR/values/styles.xml"
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.NoActionBar">
        <item name="android:windowBackground">@color/bg_dark</item>
        <item name="colorPrimary">@color:bg_dark</item>
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

cat << EOF > "$RES_DIR/values/ads_ids.xml"
<resources>
    <string name="admob_app_id">$ADMOB_APP_ID</string>
    <string name="admob_banner_id">$ADMOB_BANNER_ID</string>
    <string name="admob_inter_id">$ADMOB_INTER_ID</string>
    <string name="admob_reward_id">$ADMOB_REWARD_ID</string>

    <string name="unity_game_id">$UNITY_GAME_ID</string>
    <string name="unity_banner_id">$UNITY_BANNER_ID</string>
    <string name="unity_inter_id">$UNITY_INTER_ID</string>
    <string name="unity_reward_id">$UNITY_REWARD_ID</string>

    <integer name="banner_interval">$BANNER_INTERVAL</integer>
    <integer name="inter_interval">$INTER_INTERVAL</integer>
    <integer name="reward_on_start">$REWARD_ON_START</integer>
    <string name="primary_ads">$PRIMARY_ADS</string>
    <string name="hybrid_strategy">$HYBRID_STRATEGY</string>
</resources>
EOF

# 8) DRAWABLELAR
cat << 'EOF' > "$RES_DIR/drawable/bg_glass.xml"
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="@color/glass_bg"/>
    <corners android:radius="16dp"/>
    <stroke android:width="1dp" android:color="@color/glass_stroke"/>
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
        android:startColor="#00FF6A"
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

# 3. İKON (ESKİ MANTIK + PNG KONTROL + FALLBACK)
ICON_TARGET="app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
TEMP_ICON="icon_temp.png"

mkdir -p "$(dirname "$ICON_TARGET")"

if [ -n "$ICON_URL" ]; then
    echo "🎨 Launcher icon hazırlanıyor..."
    echo "  → ICON_URL: $ICON_URL"
    curl -s -L -k -A "Mozilla/5.0" -o "$TEMP_ICON" "$ICON_URL" || true
fi

# indirilen dosya gerçekten PNG mi?
if [ -s "$TEMP_ICON" ] && command -v file >/dev/null 2>&1; then
    if ! file "$TEMP_ICON" | grep -qi "PNG image data"; then
        echo "⚠️ İndirilen dosya PNG değil, varsayılan ikon kullanılacak."
        rm -f "$TEMP_ICON"
    fi
fi

if [ -s "$TEMP_ICON" ]; then
    # Eski mantığın birebir korunmuş hali
    if command -v convert >/dev/null 2>&1; then
        convert "$TEMP_ICON" -resize 512x512! -background none -flatten "$ICON_TARGET"
    else
        echo "ℹ️ convert yok, ham PNG kopyalanıyor..."
        cp "$TEMP_ICON" "$ICON_TARGET"
    fi
else
    echo "ℹ️ ICON_URL kullanılamadı, fallback ikon oluşturuluyor..."
    if command -v convert >/dev/null 2>&1; then
        # Basit 512x512 mavi-yeşil bir ikon
        convert -size 512x512 xc:#2196F3 \
            -fill white -gravity center -pointsize 150 \
            -annotate 0 "TV" "$ICON_TARGET"
    else
        # convert de yoksa 1x1 valid PNG yaz (AAPT hatasız)
        echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==" | base64 -d > "$ICON_TARGET"
    fi
fi

rm -f "$TEMP_ICON"


# 10) LAYOUTLAR

# Playlist seçimi
cat << 'EOF' > "$RES_DIR/layout/activity_selection.xml"
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="@color/bg_dark">

    <ImageView
        android:layout_width="match_parent" android:layout_height="match_parent"
        android:alpha="0.25" android:scaleType="centerCrop"
        android:src="@android:drawable/ic_menu_gallery"/>

    <View
        android:layout_width="match_parent" android:layout_height="match_parent"
        android:background="@color/black_overlay"/>

    <TextView
        android:id="@+id/header"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="MY PLAYLISTS"
        android:textColor="@color/text_primary"
        android:textSize="32sp"
        android:textStyle="bold"
        android:layout_centerHorizontal="true"
        android:layout_marginTop="50dp"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvPlaylists"
        android:layout_width="match_parent" android:layout_height="match_parent"
        android:layout_below="@id/header"
        android:layout_above="@+id/btnGroup"
        android:padding="20dp"
        android:clipToPadding="false"/>

    <LinearLayout
        android:id="@+id/btnGroup"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:layout_alignParentBottom="true"
        android:padding="20dp"
        android:orientation="vertical">

        <Button
            android:id="@+id/btnXtream"
            android:layout_width="match_parent" android:layout_height="60dp"
            android:text="ADD XTREAM API"
            style="@style/NeonButton"
            android:layout_marginBottom="15dp"/>

        <Button
            android:id="@+id/btnM3u"
            android:layout_width="match_parent" android:layout_height="60dp"
            android:text="ADD M3U LINK"
            style="@style/GlassInput"
            android:textColor="#FFF"/>
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
        android:layout_width="0dp" android:layout_height="wrap_content"
        android:layout_weight="1" android:orientation="vertical">

        <TextView
            android:id="@+id/tvPlayName"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:textColor="#FFF" android:textSize="18sp" android:textStyle="bold"/>

        <TextView
            android:id="@+id/tvPlayInfo"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:layout_marginTop="4dp"
            android:textColor="@color/text_secondary" android:textSize="14sp"/>
    </LinearLayout>

    <ImageView
        android:id="@+id/btnDel"
        android:layout_width="32dp" android:layout_height="32dp"
        android:src="@drawable/ic_play"
        android:padding="4dp"/>
</LinearLayout>
EOF

# Dashboard
cat << 'EOF' > "$RES_DIR/layout/activity_dashboard.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:gravity="center"
    android:padding="30dp">

    <TextView
        android:id="@+id/tvUser"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:textColor="#FFF"
        android:gravity="center"
        android:textSize="24sp"
        android:layout_marginBottom="40dp"
        android:textStyle="bold"/>

    <LinearLayout
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:weightSum="3"
        android:layout_marginBottom="40dp">

        <LinearLayout
            android:id="@+id/btnLive"
            android:layout_width="0dp" android:layout_height="160dp"
            android:layout_weight="1"
            android:layout_marginRight="10dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical">
            <TextView
                android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="LIVE TV"
                android:textColor="#FFF"
                android:textSize="20sp"
                android:textStyle="bold"/>
        </LinearLayout>

        <LinearLayout
            android:id="@+id/btnMovies"
            android:layout_width="0dp" android:layout_height="160dp"
            android:layout_weight="1"
            android:layout_marginRight="10dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical">
            <TextView
                android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="VOD"
                android:textColor="#FFF"
                android:textSize="20sp"
                android:textStyle="bold"/>
        </LinearLayout>

        <LinearLayout
            android:id="@+id/btnSeries"
            android:layout_width="0dp" android:layout_height="160dp"
            android:layout_weight="1"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical">
            <TextView
                android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="SERIES"
                android:textColor="#FFF"
                android:textSize="20sp"
                android:textStyle="bold"/>
        </LinearLayout>
    </LinearLayout>

    <Button
        android:id="@+id/btnLogout"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="SWITCH PLAYLIST"
        style="@style/NeonButton"
        android:paddingLeft="40dp" android:paddingRight="40dp"/>
</LinearLayout>
EOF

# Xtream login
cat << 'EOF' > "$RES_DIR/layout/activity_login_xtream.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:padding="30dp"
    android:gravity="center">

    <TextView
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="XTREAM LOGIN"
        android:textColor="#FFF"
        android:textSize="28sp"
        android:textStyle="bold"
        android:layout_marginBottom="40dp"/>

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp"/>

    <EditText
        android:id="@+id/etUser"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Username"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp"/>

    <EditText
        android:id="@+id/etPass"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Password"
        android:inputType="textPassword"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp"/>

    <EditText
        android:id="@+id/etDns"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="http://url:port"
        style="@style/GlassInput"
        android:layout_marginBottom="40dp"/>

    <Button
        android:id="@+id/btnLogin"
        android:layout_width="match_parent" android:layout_height="60dp"
        android:text="CONNECT"
        style="@style/NeonButton"/>
</LinearLayout>
EOF

# M3U login
cat << 'EOF' > "$RES_DIR/layout/activity_login_m3u.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:padding="30dp"
    android:gravity="center">

    <TextView
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="M3U LINK"
        android:textColor="#FFF"
        android:textSize="28sp"
        android:textStyle="bold"
        android:layout_marginBottom="40dp"/>

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Playlist Name"
        style="@style/GlassInput"
        android:layout_marginBottom="15dp"/>

    <EditText
        android:id="@+id/etUrl"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="http://example.com/playlist.m3u"
        style="@style/GlassInput"
        android:layout_marginBottom="40dp"/>

    <Button
        android:id="@+id/btnSave"
        android:layout_width="match_parent" android:layout_height="60dp"
        android:text="DOWNLOAD &amp; SAVE"
        style="@style/NeonButton"/>
</LinearLayout>
EOF

# Yandan kategori menülü liste ekranı
cat << 'EOF' > "$RES_DIR/layout/activity_list.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="horizontal"
    android:background="@color/bg_dark">

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvCats"
        android:layout_width="0dp" android:layout_height="match_parent"
        android:layout_weight="1"
        android:padding="8dp"
        android:clipToPadding="false"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvStreams"
        android:layout_width="0dp" android:layout_height="match_parent"
        android:layout_weight="3"
        android:padding="8dp"/>
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
        android:layout_width="40dp" android:layout_height="40dp"
        android:src="@drawable/ic_play"/>

    <TextView
        android:id="@+id/tvName"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:textColor="#FFF"
        android:textSize="16sp"
        android:layout_marginLeft="15dp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_category.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:padding="10dp"
    android:layout_marginBottom="6dp"
    android:gravity="center"
    android:background="@drawable/bg_glass_input">

    <TextView
        android:id="@+id/tvCatName"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:textColor="#FFF"
        android:textSize="14sp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

# Player layout
cat << 'EOF' > "$RES_DIR/layout/activity_player.xml"
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="#000">

    <com.google.android.exoplayer2.ui.StyledPlayerView
        android:id="@+id/player_view"
        android:layout_width="match_parent" android:layout_height="match_parent"
        android:layout_gravity="center"/>

    <ImageButton
        android:id="@+id/btnZoom"
        android:layout_width="50dp" android:layout_height="50dp"
        android:src="@drawable/ic_play"
        android:background="@drawable/bg_glass"
        android:layout_gravity="top|right"
        android:layout_margin="30dp"
        android:padding="10dp"/>
</FrameLayout>
EOF

# 11) MODELLER

cat << EOF > "$PKG_DIR/model/AppModels.java"
package $PACKAGE_NAME.model;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class AppModels {

    public static class Playlist implements Serializable {
        public String id, name, type, url, user, pass;
        public String m3uContent;
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
        public Category(String id, String name) { this.id = id; this.name = name; }
    }

    public static class StreamItem implements Serializable {
        @SerializedName("name") public String name;
        @SerializedName("stream_id") public String streamId;
        @SerializedName("stream_icon") public String icon;
        @SerializedName("container_extension") public String ext;

        public String directUrl;
        public String group;

        // M3U özel: referer / origin
        public String ref;
        public String origin;
    }
}
EOF

# 12) API

cat << EOF > "$PKG_DIR/api/XtreamApi.java"
package $PACKAGE_NAME.api;

import $PACKAGE_NAME.model.AppModels.Category;
import $PACKAGE_NAME.model.AppModels.LoginResponse;
import $PACKAGE_NAME.model.AppModels.StreamItem;
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

# 13) UTILS – M3U PARSER (EXTVLCOPT destekli) + PrefUtils

cat << EOF > "$PKG_DIR/utils/M3UParser.java"
package $PACKAGE_NAME.utils;

import $PACKAGE_NAME.model.AppModels.StreamItem;
import java.util.*;
import java.util.regex.*;

public class M3UParser {

    public static Map<String, List<StreamItem>> parse(String content) {
        Map<String, List<StreamItem>> map = new LinkedHashMap<>();
        if (content == null) return map;

        String[] lines = content.split("\\n");
        String currentGroup = "Uncategorized";
        StreamItem currentItem = null;
        String pendingRef = null;
        String pendingOrigin = null;

        Pattern pGroup = Pattern.compile("group-title=\"([^\"]*)\"");
        Pattern pLogo = Pattern.compile("tvg-logo=\"([^\"]*)\"");

        for (String rawLine : lines) {
            String line = rawLine.trim();
            if (line.isEmpty()) continue;

            if (line.startsWith("#EXTVLCOPT:")) {
                String lower = line.toLowerCase();
                int idx = line.indexOf('=');
                String val = idx > 0 ? line.substring(idx + 1).trim() : "";
                if (lower.contains("http-referrer")) {
                    pendingRef = val;
                } else if (lower.contains("http-origin")) {
                    pendingOrigin = val;
                }
            } else if (line.startsWith("#EXTINF")) {
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
                currentItem.ref = pendingRef;
                currentItem.origin = pendingOrigin;
                pendingRef = null;
                pendingOrigin = null;

            } else if (!line.startsWith("#") && currentItem != null) {
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

cat << EOF > "$PKG_DIR/utils/PrefUtils.java"
package $PACKAGE_NAME.utils;

import android.content.Context;
import android.content.SharedPreferences;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import $PACKAGE_NAME.model.AppModels.Playlist;
import java.util.ArrayList;
import java.util.List;

public class PrefUtils {

    private static SharedPreferences get(Context c) {
        return c.getSharedPreferences("ERD_V13", 0);
    }

    public static void savePlaylist(Context c, Playlist p) {
        List<Playlist> l = getPlaylists(c);
        boolean found = false;
        for (Playlist item : l) {
            if (item.id != null && item.id.equals(p.id)) {
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
            if (p.id != null && p.id.equals(id)) return p;
        }
        return null;
    }

    public static void deletePlaylist(Context c, String id) {
        List<Playlist> l = getPlaylists(c);
        List<Playlist> result = new ArrayList<>();
        for (Playlist p : l) {
            if (p.id == null || !p.id.equals(id)) {
                result.add(p);
            }
        }
        get(c).edit().putString("L", new Gson().toJson(result)).apply();
    }

    public static void logout(Context c) {
        get(c).edit().remove("A").apply();
    }
}
EOF

# 14) ADAPTERLER

cat << EOF > "$PKG_DIR/adapter/PlaylistAdapter.java"
package $PACKAGE_NAME.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Playlist;
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
        View v = LayoutInflater.from(p.getContext()).inflate(R.layout.item_playlist, p, false);
        return new VH(v);
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
        return list == null ? 0 : list.size();
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

cat << EOF > "$PKG_DIR/adapter/CategoryAdapter.java"
package $PACKAGE_NAME.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Category;
import java.util.List;

public class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.VH> {

    private List<Category> list;
    private OnClick listener;
    private int sel = 0;

    public interface OnClick {
        void onClick(Category item, int position);
    }

    public CategoryAdapter(List<Category> list, OnClick listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        View v = LayoutInflater.from(p.getContext()).inflate(R.layout.item_category, p, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        Category c = list.get(position);
        h.t.setText(c.name);
        h.itemView.setSelected(sel == position);
        h.itemView.setOnClickListener(v -> {
            int old = sel;
            sel = h.getAdapterPosition();
            notifyItemChanged(old);
            notifyItemChanged(sel);
            listener.onClick(c, sel);
        });
    }

    @Override
    public int getItemCount() {
        return list == null ? 0 : list.size();
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

cat << EOF > "$PKG_DIR/adapter/StreamAdapter.java"
package $PACKAGE_NAME.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.StreamItem;
import java.util.ArrayList;
import java.util.List;

public class StreamAdapter extends RecyclerView.Adapter<StreamAdapter.VH> {

    private List<StreamItem> list = new ArrayList<>();
    private OnItemClick listener;

    public interface OnItemClick {
        void onClick(StreamItem item);
    }

    public StreamAdapter(OnItemClick listener) {
        this.listener = listener;
    }

    public void update(List<StreamItem> n) {
        list = n == null ? new ArrayList<>() : n;
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        View v = LayoutInflater.from(p.getContext()).inflate(R.layout.item_channel, p, false);
        return new VH(v);
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
    public int getItemCount() {
        return list == null ? 0 : list.size();
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

# 15) UI – Activities

# SelectionActivity
cat << EOF > "$PKG_DIR/ui/SelectionActivity.java"
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import $PACKAGE_NAME.R;
import $PACKAGE_NAME.adapter.PlaylistAdapter;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;
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

# DashboardActivity
cat << EOF > "$PKG_DIR/ui/DashboardActivity.java"
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;

public class DashboardActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_dashboard);

        Playlist p = PrefUtils.getActive(this);
        if (p != null) {
            ((TextView) findViewById(R.id.tvUser)).setText(p.name);
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

        findViewById(R.id.btnSeries).setOnClickListener(v -> {
            Intent i = new Intent(this, CommonListActivity.class);
            i.putExtra("type", "series");
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

# LoginXtreamActivity – final/effectively final URL fix
cat << EOF > "$PKG_DIR/ui/LoginXtreamActivity.java"
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import $PACKAGE_NAME.R;
import $PACKAGE_NAME.api.XtreamApi;
import $PACKAGE_NAME.model.AppModels.LoginResponse;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;
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
            String dns = d.getText().toString().trim();
            if (!dns.startsWith("http")) dns = "http://" + dns;
            final String baseUrl = dns;

            Retrofit r = new Retrofit.Builder()
                    .baseUrl(baseUrl + "/")
                    .addConverterFactory(GsonConverterFactory.create())
                    .build();

            XtreamApi api = r.create(XtreamApi.class);
            api.login(baseUrl + "/player_api.php",
                    u.getText().toString().trim(),
                    p.getText().toString().trim())
                    .enqueue(new Callback<LoginResponse>() {
                        @Override
                        public void onResponse(Call<LoginResponse> call, Response<LoginResponse> res) {
                            if (res.body() != null && res.body().userInfo != null) {
                                Playlist pl = new Playlist();
                                pl.id = UUID.randomUUID().toString();
                                pl.type = "Xtream";
                                pl.url = baseUrl;
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
                        public void onFailure(Call<LoginResponse> call, Throwable t) {
                            Toast.makeText(LoginXtreamActivity.this, "Connection Error", Toast.LENGTH_SHORT).show();
                        }
                    });
        });
    }
}
EOF

# LoginM3uActivity
cat << EOF > "$PKG_DIR/ui/LoginM3uActivity.java"
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;
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
                Toast.makeText(this, "M3U URL boş olamaz", Toast.LENGTH_SHORT).show();
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
                            Toast.makeText(LoginM3uActivity.this, "M3U hatası: " + e.getMessage(), Toast.LENGTH_SHORT).show());
                }
            }).start();
        });
    }
}
EOF

# CommonListActivity – live/vod + M3U + referer/origin
cat << EOF > "$PKG_DIR/ui/CommonListActivity.java"
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import $PACKAGE_NAME.R;
import $PACKAGE_NAME.adapter.CategoryAdapter;
import $PACKAGE_NAME.adapter.StreamAdapter;
import $PACKAGE_NAME.api.XtreamApi;
import $PACKAGE_NAME.model.AppModels.Category;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.model.AppModels.StreamItem;
import $PACKAGE_NAME.utils.M3UParser;
import $PACKAGE_NAME.utils.PrefUtils;
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
        if (p == null) {
            finish();
            return;
        }

        rvC = findViewById(R.id.rvCats);
        rvS = findViewById(R.id.rvStreams);
        rvC.setLayoutManager(new LinearLayoutManager(this));
        rvS.setLayoutManager(new LinearLayoutManager(this));

        adp = new StreamAdapter(item -> {
            Intent in = new Intent(this, PlayerActivity.class);
            String url;

            if ("Xtream".equals(p.type)) {
                String actionPath;
                if ("live".equals(type)) {
                    actionPath = "live";
                } else {
                    actionPath = "movie";
                }
                String ext = (item.ext != null && !item.ext.isEmpty()) ? item.ext : "ts";
                url = p.url + "/" + actionPath + "/" + p.user + "/" + p.pass + "/" + item.streamId + "." + ext;
                in.putExtra("url", url);
            } else {
                // M3U
                url = item.directUrl;
                in.putExtra("url", url);
                if (item.ref != null) in.putExtra("ref", item.ref);
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

    void loadM3u() {
        m3uMap = M3UParser.parse(p.m3uContent);
        List<Category> cats = new ArrayList<>();
        for (String key : m3uMap.keySet()) {
            cats.add(new Category(key, key));
        }
        if (cats.isEmpty()) {
            return;
        }
        rvC.setAdapter(new CategoryAdapter(cats, (cat, pos) -> {
            List<StreamItem> list = m3uMap.get(cat.id);
            adp.update(list);
        }));
        adp.update(m3uMap.get(cats.get(0).id));
    }

    void loadXtream() {
        Retrofit r = new Retrofit.Builder()
                .baseUrl(p.url + "/")
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        api = r.create(XtreamApi.class);

        String a;
        if ("live".equals(type)) {
            a = "get_live_categories";
        } else if ("series".equals(type)) {
            a = "get_series_categories";
        } else {
            a = "get_vod_categories";
        }

        api.getCategories(p.url + "/player_api.php", p.user, p.pass, a)
                .enqueue(new Callback<List<Category>>() {
                    @Override
                    public void onResponse(Call<List<Category>> call, Response<List<Category>> res) {
                        List<Category> body = res.body();
                        if (body == null || body.isEmpty()) return;

                        rvC.setAdapter(new CategoryAdapter(body, (cat, pos) -> loadItems(cat.id)));

                        // İlk kategori otomatik
                        loadItems(body.get(0).id);
                    }

                    @Override
                    public void onFailure(Call<List<Category>> call, Throwable t) {
                    }
                });
    }

    void loadItems(String id) {
        String a;
        if ("live".equals(type)) {
            a = "get_live_streams";
        } else if ("series".equals(type)) {
            a = "get_series";
        } else {
            a = "get_vod_streams";
        }

        api.getStreams(p.url + "/player_api.php", p.user, p.pass, a, id)
                .enqueue(new Callback<List<StreamItem>>() {
                    @Override
                    public void onResponse(Call<List<StreamItem>> call, Response<List<StreamItem>> res) {
                        if (res.body() != null) {
                            adp.update(res.body());
                        }
                    }

                    @Override
                    public void onFailure(Call<List<StreamItem>> call, Throwable t) {
                    }
                });
    }
}
EOF

# PlayerActivity – referer/origin + 3sn controller hide + zoom
cat << EOF > "$PKG_DIR/ui/PlayerActivity.java"
package $PACKAGE_NAME.ui;

import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.WindowManager;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.ProgressiveMediaSource;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import $PACKAGE_NAME.R;

public class PlayerActivity extends AppCompatActivity {

    ExoPlayer p;
    StyledPlayerView pv;
    int resizeMode = 0; // 0: FIT, 1: FILL, 2: ZOOM

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // FULL SCREEN + ekran açık kalsın
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
            getWindow().getAttributes().layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        setContentView(R.layout.activity_player);
        pv = findViewById(R.id.player_view);

        // Controller 3 sn sonra kaybolsun
        pv.setControllerShowTimeoutMs(3000);
        pv.setControllerHideOnTouch(true);

        findViewById(R.id.btnZoom).setOnClickListener(v -> toggleZoom());

        p = new ExoPlayer.Builder(this).build();
        pv.setPlayer(p);

        String url = getIntent().getStringExtra("url");
        String ref = getIntent().getStringExtra("ref");
        String origin = getIntent().getStringExtra("origin");

        if (url != null && !url.isEmpty()) {
            try {
                DefaultHttpDataSource.Factory dsFactory = new DefaultHttpDataSource.Factory();
                dsFactory.setUserAgent("ErdinPlayer/1.0 (Android)");

                if (ref != null && !ref.isEmpty()) {
                    dsFactory.setDefaultRequestProperty("Referer", ref);
                }
                if (origin != null && !origin.isEmpty()) {
                    dsFactory.setDefaultRequestProperty("Origin", origin);
                }

                MediaItem mediaItem = MediaItem.fromUri(Uri.parse(url));
                MediaSource mediaSource = new ProgressiveMediaSource.Factory(dsFactory)
                        .createMediaSource(mediaItem);

                p.setMediaSource(mediaSource);
                p.prepare();
                p.play();
            } catch (Exception e) {
                Toast.makeText(this, "Play error: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            }
        } else {
            Toast.makeText(this, "URL boş", Toast.LENGTH_SHORT).show();
        }
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
        if (p != null) {
            p.release();
        }
    }
}
EOF

# 16) ANDROIDMANIFEST
cat << EOF > "$MODULE_DIR/src/main/AndroidManifest.xml"
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PACKAGE_NAME">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:name="androidx.multidex.MultiDexApplication"
        android:label="$APP_NAME"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".$PACKAGE_NAME.ui.SelectionActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name=".$PACKAGE_NAME.ui.LoginXtreamActivity"
            android:screenOrientation="portrait" />

        <activity android:name=".$PACKAGE_NAME.ui.LoginM3uActivity"
            android:screenOrientation="portrait" />

        <activity android:name=".$PACKAGE_NAME.ui.DashboardActivity"
            android:screenOrientation="portrait" />

        <activity android:name=".$PACKAGE_NAME.ui.CommonListActivity"
            android:screenOrientation="portrait" />

        <activity
            android:name=".$PACKAGE_NAME.ui.PlayerActivity"
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize"
            android:screenOrientation="sensor" />
    </application>
</manifest>
EOF

# AndroidManifest içindeki activity name'leri düzelt (.ui.* biçiminde olsun)
# (Bazı Android sürümleri package ile concat ediyor, bu hali yeterli)

# 17) Gradle Wrapper üret
echo "Generating Gradle Wrapper..."
cd "$PROJECT_ROOT"
gradle wrapper --gradle-version 8.4
chmod +x gradlew || true
cd ..

echo "✅ ERDINPLAYER: Proje oluşturuldu."
echo "⚙️  GitHub Actions içinde: cd theapp && gradle assembleRelease --no-daemon çalışacak."
