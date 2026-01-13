#!/bin/bash
set -e

echo "=============================================="
echo " UPDATE (REPO ROOT): Unity inter aktif + AdMob banner"
echo " Series + Episodes (Xtream) eklenecek"
echo " Package: com.erdin.xtream"
echo "=============================================="

# ----------------------------------------------------
# 0) SABİT AYARLAR
# ----------------------------------------------------
APP_NAME="ERDINXTREAM"
PACKAGE_NAME="com.erdin.xtream"

VERSION_CODE=1
VERSION_NAME="1.0"

# Ads mode
# - Unity inter + reward aktif
# - AdMob sadece banner aktif
UNITY_GAME_ID="5497808"
UNITY_INTER_PLACEMENT="Interstitial_Android"
UNITY_REWARD_PLACEMENT="Rewarded_Android"

ADMOB_APP_ID="ca-app-pub-3940256099942544~3347511713"
ADMOB_BANNER_ID="ca-app-pub-3940256099942544/6300978111"

# Tıklama aralığı (Unity inter)
INTER_INTERVAL=3
REWARD_ON_START=0

PROJECT_NAME="ERDINXTREAM"
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
RES_DIR="$MODULE_DIR/src/main/res"
PKG_PATH="${PACKAGE_NAME//./\/}"

echo "APP_NAME     = $APP_NAME"
echo "PACKAGE_NAME = $PACKAGE_NAME"
echo "PROJECT_ROOT = $PROJECT_ROOT"
echo "PKG_PATH     = $PKG_PATH"

# ----------------------------------------------------
# 1) TEMİZLİK & KLASÖR
# ----------------------------------------------------
rm -rf "$PROJECT_ROOT"
mkdir -p "$MODULE_DIR/src/main/java/$PKG_PATH/model"
mkdir -p "$MODULE_DIR/src/main/java/$PKG_PATH/api"
mkdir -p "$MODULE_DIR/src/main/java/$PKG_PATH/utils"
mkdir -p "$MODULE_DIR/src/main/java/$PKG_PATH/adapter"
mkdir -p "$MODULE_DIR/src/main/java/$PKG_PATH/ui"
mkdir -p "$RES_DIR"/{layout,values,drawable,mipmap-xxxhdpi}
mkdir -p "$PROJECT_ROOT/gradle/wrapper"

# ----------------------------------------------------
# 2) settings.gradle / root build.gradle / gradle.properties
# ----------------------------------------------------
cat > "$PROJECT_ROOT/settings.gradle" <<EOF
rootProject.name = "$PROJECT_NAME"
include ':app'
EOF

cat > "$PROJECT_ROOT/build.gradle" <<'EOF'
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

cat > "$PROJECT_ROOT/gradle.properties" <<'EOF'
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx4096m
EOF

# ----------------------------------------------------
# 3) app/build.gradle  (BuildConfig + Unity + AdMob Banner)
# ----------------------------------------------------
cat > "$MODULE_DIR/build.gradle" <<EOF
plugins {
    id 'com.android.application'
}

android {
    namespace '$PACKAGE_NAME'
    compileSdk 34

    defaultConfig {
        applicationId '$PACKAGE_NAME'
        minSdk 21
        targetSdk 34
        versionCode $VERSION_CODE
        versionName '$VERSION_NAME'
        multiDexEnabled true
    }

    buildFeatures {
        buildConfig true
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'

            // BuildConfig alanları
            buildConfigField "int", "INTER_INTERVAL", "$INTER_INTERVAL"
            buildConfigField "int", "REWARD_ON_START", "$REWARD_ON_START"

            // Unity
            buildConfigField "String", "UNITY_GAME_ID", "\"$UNITY_GAME_ID\""
            buildConfigField "String", "UNITY_INTER_PLACEMENT", "\"$UNITY_INTER_PLACEMENT\""
            buildConfigField "String", "UNITY_REWARD_PLACEMENT", "\"$UNITY_REWARD_PLACEMENT\""

            // AdMob (banner only)
            buildConfigField "String", "ADMOB_APP_ID", "\"$ADMOB_APP_ID\""
            buildConfigField "String", "ADMOB_BANNER_ID", "\"$ADMOB_BANNER_ID\""
        }

        debug {
            minifyEnabled false

            buildConfigField "int", "INTER_INTERVAL", "$INTER_INTERVAL"
            buildConfigField "int", "REWARD_ON_START", "$REWARD_ON_START"

            buildConfigField "String", "UNITY_GAME_ID", "\"$UNITY_GAME_ID\""
            buildConfigField "String", "UNITY_INTER_PLACEMENT", "\"$UNITY_INTER_PLACEMENT\""
            buildConfigField "String", "UNITY_REWARD_PLACEMENT", "\"$UNITY_REWARD_PLACEMENT\""

            buildConfigField "String", "ADMOB_APP_ID", "\"$ADMOB_APP_ID\""
            buildConfigField "String", "ADMOB_BANNER_ID", "\"$ADMOB_BANNER_ID\""
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
    implementation 'androidx.recyclerview:recyclerview:1.3.1'

    // ExoPlayer
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.19.1'

    // Glide
    implementation 'com.github.bumptech.glide:glide:4.16.0'

    // Retrofit + OkHttp + Gson
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'

    // ✅ AdMob SDK (banner kullanacağız)
    implementation 'com.google.android.gms:play-services-ads:23.0.0'

    // ✅ Unity Ads SDK
    implementation 'com.unity3d.ads:unity-ads:4.9.2'
}
EOF

cat > "$MODULE_DIR/proguard-rules.pro" <<EOF
-keep class $PACKAGE_NAME.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn com.google.gson.**
-dontwarn okhttp3.**
EOF

# ----------------------------------------------------
# 4) colors/styles (basit)
# ----------------------------------------------------
cat > "$RES_DIR/values/colors.xml" <<'EOF'
<resources>
    <color name="bg_dark">#050A08</color>
    <color name="accent">#00C853</color>
    <color name="text_primary">#FFFFFF</color>
    <color name="text_secondary">#B0B0B0</color>
</resources>
EOF

cat > "$RES_DIR/values/styles.xml" <<'EOF'
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.NoActionBar">
        <item name="android:windowBackground">@color/bg_dark</item>
        <item name="colorPrimary">@color/accent</item>
        <item name="colorPrimaryVariant">@color/accent</item>
        <item name="colorAccent">@color/accent</item>
        <item name="android:statusBarColor">@color/bg_dark</item>
        <item name="android:navigationBarColor">@color/bg_dark</item>
    </style>
</resources>
EOF

# ----------------------------------------------------
# 5) Basit launcher icon (fallback 1x1)
# ----------------------------------------------------
ICON_TARGET="$RES_DIR/mipmap-xxxhdpi/ic_launcher.png"
cat > /tmp/icon_base64.txt <<'B64EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/6XWuk0AAAAASUVORK5CYII=
B64EOF
base64 -d /tmp/icon_base64.txt > "$ICON_TARGET" 2>/dev/null || base64 --decode /tmp/icon_base64.txt > "$ICON_TARGET" 2>/dev/null || true
rm -f /tmp/icon_base64.txt

# ----------------------------------------------------
# 6) Layoutlar (çok minimal)
# ----------------------------------------------------
cat > "$RES_DIR/layout/activity_selection.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:background="@color/bg_dark"
    android:padding="20dp"
    android:orientation="vertical"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <TextView
        android:text="PLAYLISTS"
        android:textColor="@color/text_primary"
        android:textSize="22sp"
        android:textStyle="bold"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvPlaylists"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:paddingTop="12dp"/>

    <Button
        android:id="@+id/btnXtream"
        android:text="ADD XTREAM"
        android:layout_width="match_parent"
        android:layout_height="56dp"/>

    <Button
        android:id="@+id/btnM3u"
        android:text="ADD M3U"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:layout_marginTop="10dp"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/item_playlist.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:padding="12dp"
    android:orientation="vertical"
    android:layout_width="match_parent"
    android:layout_height="wrap_content">

    <TextView
        android:id="@+id/tvPlayName"
        android:textColor="@color/text_primary"
        android:textStyle="bold"
        android:textSize="16sp"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"/>

    <TextView
        android:id="@+id/tvPlayInfo"
        android:textColor="@color/text_secondary"
        android:textSize="13sp"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_dashboard.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:background="@color/bg_dark"
    android:padding="20dp"
    android:orientation="vertical"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <TextView
        android:id="@+id/tvUser"
        android:textColor="@color/text_primary"
        android:textStyle="bold"
        android:textSize="20sp"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"/>

    <Button
        android:id="@+id/btnLive"
        android:text="LIVE"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:layout_marginTop="18dp"/>

    <Button
        android:id="@+id/btnMovies"
        android:text="MOVIES"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:layout_marginTop="10dp"/>

    <Button
        android:id="@+id/btnSeries"
        android:text="SERIES"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:layout_marginTop="10dp"/>

    <Button
        android:id="@+id/btnLogout"
        android:text="SWITCH PLAYLIST"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:layout_marginTop="18dp"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_list.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvCats"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:padding="6dp"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvStreams"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:padding="6dp"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/item_category.xml" <<'EOF'
<TextView xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/tvCatName"
    android:padding="10dp"
    android:textColor="@color/text_primary"
    android:textStyle="bold"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"/>
EOF

cat > "$RES_DIR/layout/item_channel.xml" <<'EOF'
<TextView xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/tvName"
    android:padding="14dp"
    android:textColor="@color/text_primary"
    android:textStyle="bold"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"/>
EOF

cat > "$RES_DIR/layout/activity_player.xml" <<'EOF'
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:background="#000000"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <com.google.android.exoplayer2.ui.StyledPlayerView
        android:id="@+id/player_view"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</FrameLayout>
EOF

# ----------------------------------------------------
# 7) AndroidManifest + strings
# ----------------------------------------------------
cat > "$RES_DIR/values/strings.xml" <<EOF
<resources>
    <string name="app_name">$APP_NAME</string>
</resources>
EOF

cat > "$MODULE_DIR/src/main/AndroidManifest.xml" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PACKAGE_NAME">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:name="androidx.multidex.MultiDexApplication"
        android:label="@string/app_name"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true"
        android:icon="@mipmap/ic_launcher">

        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="\${applicationId}.admob_dummy" />

        <activity
            android:name=".ui.SelectionActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name=".ui.LoginXtreamActivity" />
        <activity android:name=".ui.LoginM3uActivity" />
        <activity android:name=".ui.DashboardActivity" />
        <activity android:name=".ui.CommonListActivity" />
        <activity android:name=".ui.SeriesEpisodesActivity" />
        <activity android:name=".ui.PlayerActivity"
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize" />
    </application>
</manifest>
EOF

# ----------------------------------------------------
# 8) MODELS + API (Xtream: live, vod, series, episodes)
# ----------------------------------------------------
cat > "$MODULE_DIR/src/main/java/$PKG_PATH/model/AppModels.java" <<EOF
package $PACKAGE_NAME.model;

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
      @SerializedName("server_info") public ServerInfo serverInfo;
  }

  public static class UserInfo implements Serializable {
      @SerializedName("username") public String username;
      @SerializedName("auth") public int auth;
  }

  public static class ServerInfo implements Serializable {
      @SerializedName("url") public String url;
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
      public String ref;
      public String origin;
  }

  // Series list item
  public static class SeriesItem implements Serializable {
      @SerializedName("name") public String name;
      @SerializedName("series_id") public String seriesId;
      @SerializedName("cover") public String cover;
  }

  public static class SeriesInfoResponse implements Serializable {
      @SerializedName("seasons") public List<Season> seasons;
      @SerializedName("episodes") public List<Episode> episodes; // bazı panellerde farklı olabilir
  }

  public static class Season implements Serializable {
      @SerializedName("season_number") public int seasonNumber;
      @SerializedName("name") public String name;
  }

  public static class Episode implements Serializable {
      @SerializedName("id") public String id;
      @SerializedName("title") public String title;
      @SerializedName("episode_num") public int episodeNum;
      @SerializedName("season") public int season;
      @SerializedName("container_extension") public String ext;
  }
}
EOF

cat > "$MODULE_DIR/src/main/java/$PKG_PATH/api/XtreamApi.java" <<EOF
package $PACKAGE_NAME.api;

import java.util.List;

import $PACKAGE_NAME.model.AppModels.Category;
import $PACKAGE_NAME.model.AppModels.LoginResponse;
import $PACKAGE_NAME.model.AppModels.StreamItem;
import $PACKAGE_NAME.model.AppModels.SeriesItem;
import $PACKAGE_NAME.model.AppModels.SeriesInfoResponse;

import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Query;
import retrofit2.http.Url;

public interface XtreamApi {

  @GET
  Call<LoginResponse> login(@Url String url, @Query("username") String u, @Query("password") String p);

  @GET
  Call<List<Category>> getCategories(@Url String url, @Query("username") String u, @Query("password") String p,
                                    @Query("action") String a);

  @GET
  Call<List<StreamItem>> getStreams(@Url String url, @Query("username") String u, @Query("password") String p,
                                   @Query("action") String a, @Query("category_id") String c);

  @GET
  Call<List<SeriesItem>> getSeries(@Url String url, @Query("username") String u, @Query("password") String p,
                                  @Query("action") String a, @Query("category_id") String c);

  @GET
  Call<SeriesInfoResponse> getSeriesInfo(@Url String url, @Query("username") String u, @Query("password") String p,
                                        @Query("action") String a, @Query("series_id") String seriesId);
}
EOF

# ----------------------------------------------------
# 9) UTILS: PrefUtils (basit)
# ----------------------------------------------------
cat > "$MODULE_DIR/src/main/java/$PKG_PATH/utils/PrefUtils.java" <<EOF
package $PACKAGE_NAME.utils;

import android.content.Context;
import android.content.SharedPreferences;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import java.util.ArrayList;
import java.util.List;
import $PACKAGE_NAME.model.AppModels.Playlist;

public class PrefUtils {
  private static SharedPreferences sp(Context c){ return c.getSharedPreferences("ERD_XTREAM", 0); }

  public static void savePlaylist(Context c, Playlist p){
    List<Playlist> list = getPlaylists(c);
    List<Playlist> out = new ArrayList<>();
    for(Playlist x: list) if(!x.id.equals(p.id)) out.add(x);
    out.add(p);
    sp(c).edit().putString("L", new Gson().toJson(out)).putString("A", p.id).apply();
  }

  public static List<Playlist> getPlaylists(Context c){
    String j = sp(c).getString("L","[]");
    List<Playlist> list = new Gson().fromJson(j, new TypeToken<List<Playlist>>(){}.getType());
    if(list==null) list = new ArrayList<>();
    return list;
  }

  public static Playlist getActive(Context c){
    String id = sp(c).getString("A","");
    for(Playlist p: getPlaylists(c)) if(p.id.equals(id)) return p;
    return null;
  }

  public static void logout(Context c){ sp(c).edit().remove("A").apply(); }

  public static void deletePlaylist(Context c, String id){
    List<Playlist> out = new ArrayList<>();
    for(Playlist p: getPlaylists(c)) if(!p.id.equals(id)) out.add(p);
    sp(c).edit().putString("L", new Gson().toJson(out)).apply();
  }
}
EOF

# ----------------------------------------------------
# 10) UTILS: UnityAdsManager + AdMobBannerManager
# ----------------------------------------------------
cat > "$MODULE_DIR/src/main/java/$PKG_PATH/utils/UnityAdsManager.java" <<EOF
package $PACKAGE_NAME.utils;

import android.app.Activity;
import android.util.Log;

import com.unity3d.ads.IUnityAdsInitializationListener;
import com.unity3d.ads.IUnityAdsShowListener;
import com.unity3d.ads.UnityAds;
import com.unity3d.ads.UnityAdsShowOptions;

public class UnityAdsManager {

  private static boolean inited = false;

  public static void init(Activity a){
    if(inited) return;
    String gameId = BuildConfig.UNITY_GAME_ID;
    UnityAds.initialize(a, gameId, false, new IUnityAdsInitializationListener() {
      @Override public void onInitializationComplete() {
        inited = true;
        Log.d("UnityAds","init ok");
      }
      @Override public void onInitializationFailed(UnityAds.UnityAdsInitializationError error, String message) {
        Log.e("UnityAds","init fail: "+message);
      }
    });
  }

  public static void showInterstitial(Activity a){
    init(a);
    if(!UnityAds.isInitialized()) return;
    String placement = BuildConfig.UNITY_INTER_PLACEMENT;
    UnityAds.show(a, placement, new UnityAdsShowOptions(), new IUnityAdsShowListener() {
      @Override public void onUnityAdsShowFailure(String placementId, UnityAds.UnityAdsShowError error, String message) {}
      @Override public void onUnityAdsShowStart(String placementId) {}
      @Override public void onUnityAdsShowClick(String placementId) {}
      @Override public void onUnityAdsShowComplete(String placementId, UnityAds.UnityAdsShowCompletionState state) {}
    });
  }
}
EOF

cat > "$MODULE_DIR/src/main/java/$PKG_PATH/utils/AdMobBannerManager.java" <<EOF
package $PACKAGE_NAME.utils;

import android.app.Activity;
import android.view.ViewGroup;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.MobileAds;

public class AdMobBannerManager {

  public static AdView attachBanner(Activity a, ViewGroup container){
    MobileAds.initialize(a, initStatus -> {});
    AdView adView = new AdView(a);
    adView.setAdUnitId(BuildConfig.ADMOB_BANNER_ID);
    adView.setAdSize(com.google.android.gms.ads.AdSize.BANNER);
    container.addView(adView);
    adView.loadAd(new AdRequest.Builder().build());
    return adView;
  }
}
EOF

# ----------------------------------------------------
# 11) ADAPTERS (basit)
# ----------------------------------------------------
cat > "$MODULE_DIR/src/main/java/$PKG_PATH/adapter/PlaylistAdapter.java" <<EOF
package $PACKAGE_NAME.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Playlist;

public class PlaylistAdapter extends RecyclerView.Adapter<PlaylistAdapter.VH> {

  public interface OnClick {
    void onClick(Playlist p);
    void onDelete(Playlist p);
  }

  private final List<Playlist> list;
  private final OnClick cb;

  public PlaylistAdapter(List<Playlist> list, OnClick cb){
    this.list=list; this.cb=cb;
  }

  @NonNull @Override
  public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType){
    View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_playlist, parent, false);
    return new VH(v);
  }

  @Override
  public void onBindViewHolder(@NonNull VH h, int pos){
    Playlist p = list.get(pos);
    h.n.setText(p.name == null ? "Playlist" : p.name);
    h.t.setText(p.type == null ? "" : p.type);
    h.itemView.setOnClickListener(v -> cb.onClick(p));
    h.itemView.setOnLongClickListener(v -> { cb.onDelete(p); return true; });
  }

  @Override public int getItemCount(){ return list==null?0:list.size(); }

  static class VH extends RecyclerView.ViewHolder {
    TextView n,t;
    VH(@NonNull View v){
      super(v);
      n = v.findViewById(R.id.tvPlayName);
      t = v.findViewById(R.id.tvPlayInfo);
    }
  }
}
EOF

cat > "$MODULE_DIR/src/main/java/$PKG_PATH/adapter/CategoryAdapter.java" <<EOF
package $PACKAGE_NAME.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Category;

public class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.VH> {

  public interface OnClick { void onClick(Category c); }

  private final List<Category> list;
  private final OnClick cb;
  private int sel = 0;

  public CategoryAdapter(List<Category> list, OnClick cb){
    this.list=list; this.cb=cb;
  }

  @NonNull @Override
  public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType){
    View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_category, parent, false);
    return new VH(v);
  }

  @Override
  public void onBindViewHolder(@NonNull VH h, int pos){
    Category c = list.get(pos);
    h.t.setText(c.name);
    h.itemView.setAlpha(sel==pos?1f:0.6f);
    h.itemView.setOnClickListener(v -> {
      int old=sel; sel=h.getAdapterPosition();
      notifyItemChanged(old); notifyItemChanged(sel);
      cb.onClick(c);
    });
  }

  @Override public int getItemCount(){ return list==null?0:list.size(); }

  static class VH extends RecyclerView.ViewHolder{
    TextView t;
    VH(@NonNull View v){ super(v); t=v.findViewById(R.id.tvCatName); }
  }
}
EOF

cat > "$MODULE_DIR/src/main/java/$PKG_PATH/adapter/StreamAdapter.java" <<EOF
package $PACKAGE_NAME.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import $PACKAGE_NAME.R;

public class StreamAdapter<T> extends RecyclerView.Adapter<StreamAdapter.VH> {

  public interface OnItemClick<T> { void onClick(T item); }

  private List<T> list;
  private final OnItemClick<T> cb;
  private final StringName<T> nameProvider;

  public interface StringName<T> { String getName(T item); }

  public StreamAdapter(List<T> list, OnItemClick<T> cb, StringName<T> nameProvider){
    this.list=list; this.cb=cb; this.nameProvider=nameProvider;
  }

  @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType){
    View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_channel, parent, false);
    return new VH(v);
  }

  @Override public void onBindViewHolder(@NonNull VH h, int pos){
    T item = list.get(pos);
    h.t.setText(nameProvider.getName(item));
    h.itemView.setOnClickListener(v -> cb.onClick(item));
  }

  @Override public int getItemCount(){ return list==null?0:list.size(); }

  public void update(List<T> newList){ this.list=newList; notifyDataSetChanged(); }

  static class VH extends RecyclerView.ViewHolder{
    TextView t;
    VH(@NonNull View v){ super(v); t=v.findViewById(R.id.tvName); }
  }
}
EOF

# ----------------------------------------------------
# 12) UI: Selection/Dashboard/LoginXtream/CommonList/SeriesEpisodes/Player
# ----------------------------------------------------
cat > "$MODULE_DIR/src/main/java/$PKG_PATH/ui/SelectionActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.adapter.PlaylistAdapter;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;

public class SelectionActivity extends AppCompatActivity {

  private RecyclerView rv;
  private PlaylistAdapter adapter;

  @Override protected void onCreate(Bundle b){
    super.onCreate(b);
    setContentView(R.layout.activity_selection);

    rv = findViewById(R.id.rvPlaylists);
    rv.setLayoutManager(new LinearLayoutManager(this));

    findViewById(R.id.btnXtream).setOnClickListener(v ->
        startActivity(new Intent(this, LoginXtreamActivity.class)));

    findViewById(R.id.btnM3u).setOnClickListener(v ->
        startActivity(new Intent(this, LoginM3uActivity.class)));
  }

  @Override protected void onResume(){
    super.onResume();
    load();
  }

  private void load(){
    List<Playlist> list = PrefUtils.getPlaylists(this);
    adapter = new PlaylistAdapter(list, new PlaylistAdapter.OnClick() {
      @Override public void onClick(Playlist p){
        PrefUtils.savePlaylist(SelectionActivity.this, p);
        startActivity(new Intent(SelectionActivity.this, DashboardActivity.class));
      }
      @Override public void onDelete(Playlist p){
        PrefUtils.deletePlaylist(SelectionActivity.this, p.id);
        load();
      }
    });
    rv.setAdapter(adapter);
  }
}
EOF

cat > "$MODULE_DIR/src/main/java/$PKG_PATH/ui/DashboardActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;

public class DashboardActivity extends AppCompatActivity {

  @Override protected void onCreate(Bundle b){
    super.onCreate(b);
    setContentView(R.layout.activity_dashboard);

    Playlist p = PrefUtils.getActive(this);
    if(p!=null) ((TextView)findViewById(R.id.tvUser)).setText(p.name);

    findViewById(R.id.btnLive).setOnClickListener(v -> open("live"));
    findViewById(R.id.btnMovies).setOnClickListener(v -> open("vod"));
    findViewById(R.id.btnSeries).setOnClickListener(v -> open("series"));

    findViewById(R.id.btnLogout).setOnClickListener(v -> {
      PrefUtils.logout(this);
      startActivity(new Intent(this, SelectionActivity.class));
      finish();
    });
  }

  private void open(String type){
    Intent i = new Intent(this, CommonListActivity.class);
    i.putExtra("type", type);
    startActivity(i);
  }
}
EOF

cat > "$MODULE_DIR/src/main/java/$PKG_PATH/ui/LoginXtreamActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

import java.util.UUID;

import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.api.XtreamApi;
import $PACKAGE_NAME.model.AppModels.LoginResponse;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;

public class LoginXtreamActivity extends AppCompatActivity {

  @Override protected void onCreate(Bundle b){
    super.onCreate(b);
    setContentView(R.layout.activity_login_xtream);

    EditText name = findViewById(R.id.etName);
    EditText u = findViewById(R.id.etUser);
    EditText p = findViewById(R.id.etPass);
    EditText d = findViewById(R.id.etDns);

    findViewById(R.id.btnLogin).setOnClickListener(v -> {
      String base = d.getText().toString().trim();
      if(!base.startsWith("http")) base = "http://" + base;

      Retrofit r = new Retrofit.Builder()
          .baseUrl(base + "/")
          .addConverterFactory(GsonConverterFactory.create())
          .build();

      XtreamApi api = r.create(XtreamApi.class);

      api.login(base + "/player_api.php", u.getText().toString(), p.getText().toString())
        .enqueue(new Callback<LoginResponse>() {
          @Override public void onResponse(Call<LoginResponse> call, Response<LoginResponse> res) {
            if(res.body()!=null && res.body().userInfo!=null && res.body().userInfo.auth==1){
              Playlist pl = new Playlist();
              pl.id = UUID.randomUUID().toString();
              pl.type = "Xtream";
              pl.url = base;
              pl.user = u.getText().toString();
              pl.pass = p.getText().toString();
              pl.name = name.getText().toString();

              PrefUtils.savePlaylist(LoginXtreamActivity.this, pl);
              startActivity(new Intent(LoginXtreamActivity.this, DashboardActivity.class));
              finish();
            } else {
              Toast.makeText(LoginXtreamActivity.this, "Login Failed", Toast.LENGTH_SHORT).show();
            }
          }
          @Override public void onFailure(Call<LoginResponse> call, Throwable t) {
            Toast.makeText(LoginXtreamActivity.this, "Connection Error", Toast.LENGTH_SHORT).show();
          }
        });
    });
  }
}
EOF

# Login M3U layout + activity minimal (koyuyorum ama series işine engel değil)
cat > "$RES_DIR/layout/activity_login_xtream.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:background="@color/bg_dark"
    android:padding="20dp"
    android:orientation="vertical"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <EditText android:id="@+id/etName"
        android:hint="Playlist Name"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"/>

    <EditText android:id="@+id/etUser"
        android:hint="Username"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"/>

    <EditText android:id="@+id/etPass"
        android:hint="Password"
        android:inputType="textPassword"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"/>

    <EditText android:id="@+id/etDns"
        android:hint="http://url:port"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"/>

    <Button android:id="@+id/btnLogin"
        android:text="CONNECT"
        android:layout_width="match_parent"
        android:layout_height="56dp"/>
</LinearLayout>
EOF

cat > "$RES_DIR/layout/activity_login_m3u.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:background="@color/bg_dark"
    android:padding="20dp"
    android:orientation="vertical"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <EditText android:id="@+id/etName"
        android:hint="Playlist Name"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"/>

    <EditText android:id="@+id/etUrl"
        android:hint="http://example.com/playlist.m3u"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"/>

    <Button android:id="@+id/btnSave"
        android:text="SAVE"
        android:layout_width="match_parent"
        android:layout_height="56dp"/>
</LinearLayout>
EOF

cat > "$MODULE_DIR/src/main/java/$PKG_PATH/ui/LoginM3uActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

import java.io.IOException;
import java.util.UUID;

import okhttp3.*;
import $PACKAGE_NAME.R;
import $PACKAGE_NAME.model.AppModels.Playlist;
import $PACKAGE_NAME.utils.PrefUtils;

public class LoginM3uActivity extends AppCompatActivity {

  @Override protected void onCreate(Bundle b){
    super.onCreate(b);
    setContentView(R.layout.activity_login_m3u);

    EditText n = findViewById(R.id.etName);
    EditText u = findViewById(R.id.etUrl);

    findViewById(R.id.btnSave).setOnClickListener(v -> {
      String url = u.getText().toString().trim();
      if(url.isEmpty()){
        Toast.makeText(this, "URL boş", Toast.LENGTH_SHORT).show();
        return;
      }

      new OkHttpClient().newCall(new Request.Builder().url(url).build()).enqueue(new Callback() {
        @Override public void onFailure(Call call, IOException e){
          runOnUiThread(() -> Toast.makeText(LoginM3uActivity.this, "M3U indirilemedi", Toast.LENGTH_SHORT).show());
        }
        @Override public void onResponse(Call call, Response response) throws IOException{
          if(!response.isSuccessful()){
            runOnUiThread(() -> Toast.makeText(LoginM3uActivity.this, "HTTP hata", Toast.LENGTH_SHORT).show());
            return;
          }
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
        }
      });
    });
  }
}
EOF

# CommonListActivity (live/vod/series)
cat > "$MODULE_DIR/src/main/java/$PKG_PATH/ui/CommonListActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.*;

import java.util.*;

import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.adapter.CategoryAdapter;
import $PACKAGE_NAME.adapter.StreamAdapter;
import $PACKAGE_NAME.api.XtreamApi;
import $PACKAGE_NAME.model.AppModels.*;
import $PACKAGE_NAME.utils.PrefUtils;
import $PACKAGE_NAME.utils.UnityAdsManager;

public class CommonListActivity extends AppCompatActivity {

  private XtreamApi api;
  private RecyclerView rvC, rvS;
  private String type;
  private Playlist playlist;

  private int clickCount = 0;

  @Override protected void onCreate(Bundle b){
    super.onCreate(b);
    setContentView(R.layout.activity_list);

    type = getIntent().getStringExtra("type");
    playlist = PrefUtils.getActive(this);

    rvC = findViewById(R.id.rvCats);
    rvS = findViewById(R.id.rvStreams);

    rvC.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
    rvS.setLayoutManager(new LinearLayoutManager(this));

    if(!"Xtream".equals(playlist.type)){
      // M3U tarafı burada yok (istersen ekleriz)
      finish();
      return;
    }

    Retrofit r = new Retrofit.Builder()
        .baseUrl(playlist.url + "/")
        .addConverterFactory(GsonConverterFactory.create())
        .build();
    api = r.create(XtreamApi.class);

    String actionCat;
    if("live".equals(type)) actionCat = "get_live_categories";
    else if("vod".equals(type)) actionCat = "get_vod_categories";
    else actionCat = "get_series_categories";

    api.getCategories(playlist.url + "/player_api.php", playlist.user, playlist.pass, actionCat)
      .enqueue(new Callback<List<Category>>() {
        @Override public void onResponse(Call<List<Category>> call, Response<List<Category>> res){
          List<Category> cats = res.body();
          if(cats==null) return;

          CategoryAdapter ca = new CategoryAdapter(cats, c -> loadItems(c.id));
          rvC.setAdapter(ca);
          if(!cats.isEmpty()) loadItems(cats.get(0).id);
        }
        @Override public void onFailure(Call<List<Category>> call, Throwable t){}
      });
  }

  private void loadItems(String catId){
    if("series".equals(type)){
      api.getSeries(playlist.url + "/player_api.php", playlist.user, playlist.pass, "get_series", catId)
        .enqueue(new Callback<List<SeriesItem>>() {
          @Override public void onResponse(Call<List<SeriesItem>> call, Response<List<SeriesItem>> res){
            List<SeriesItem> list = res.body();
            if(list==null) list = new ArrayList<>();

            StreamAdapter<SeriesItem> sa = new StreamAdapter<>(
              list,
              item -> {
                clickCount++;
                if(clickCount % Math.max(1, BuildConfig.INTER_INTERVAL) == 0){
                  UnityAdsManager.showInterstitial(CommonListActivity.this);
                }
                Intent i = new Intent(CommonListActivity.this, SeriesEpisodesActivity.class);
                i.putExtra("series_id", item.seriesId);
                i.putExtra("series_name", item.name);
                startActivity(i);
              },
              item -> item.name
            );
            rvS.setAdapter(sa);
          }
          @Override public void onFailure(Call<List<SeriesItem>> call, Throwable t){}
        });
      return;
    }

    String action = "live".equals(type) ? "get_live_streams" : "get_vod_streams";
    api.getStreams(playlist.url + "/player_api.php", playlist.user, playlist.pass, action, catId)
      .enqueue(new Callback<List<StreamItem>>() {
        @Override public void onResponse(Call<List<StreamItem>> call, Response<List<StreamItem>> res){
          List<StreamItem> list = res.body();
          if(list==null) list = new ArrayList<>();

          StreamAdapter<StreamItem> sa = new StreamAdapter<>(
            list,
            item -> {
              clickCount++;
              if(clickCount % Math.max(1, BuildConfig.INTER_INTERVAL) == 0){
                UnityAdsManager.showInterstitial(CommonListActivity.this);
              }
              Intent i = new Intent(CommonListActivity.this, PlayerActivity.class);
              String path = "live".equals(type) ? "live" : "movie";
              String ext = (item.ext!=null && !item.ext.isEmpty()) ? item.ext : "ts";
              String url = playlist.url + "/" + path + "/" + playlist.user + "/" + playlist.pass + "/" + item.streamId + "." + ext;
              i.putExtra("url", url);
              startActivity(i);
            },
            item -> item.name
          );
          rvS.setAdapter(sa);
        }
        @Override public void onFailure(Call<List<StreamItem>> call, Throwable t){}
      });
  }
}
EOF

# SeriesEpisodesActivity (fix: Activity context + brace)
cat > "$MODULE_DIR/src/main/java/$PKG_PATH/ui/SeriesEpisodesActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.*;

import java.util.*;

import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;

import $PACKAGE_NAME.R;
import $PACKAGE_NAME.adapter.StreamAdapter;
import $PACKAGE_NAME.api.XtreamApi;
import $PACKAGE_NAME.model.AppModels.*;
import $PACKAGE_NAME.utils.PrefUtils;
import $PACKAGE_NAME.utils.UnityAdsManager;

public class SeriesEpisodesActivity extends AppCompatActivity {

  private XtreamApi api;
  private Playlist playlist;
  private RecyclerView rv;
  private int clickCount = 0;

  @Override protected void onCreate(Bundle b){
    super.onCreate(b);
    setContentView(R.layout.activity_list);

    rv = findViewById(R.id.rvStreams);
    RecyclerView rvCats = findViewById(R.id.rvCats);
    rvCats.setVisibility(android.view.View.GONE);
    rv.setLayoutManager(new LinearLayoutManager(this));

    playlist = PrefUtils.getActive(this);

    String seriesId = getIntent().getStringExtra("series_id");
    if(seriesId == null) { finish(); return; }

    Retrofit r = new Retrofit.Builder()
      .baseUrl(playlist.url + "/")
      .addConverterFactory(GsonConverterFactory.create())
      .build();
    api = r.create(XtreamApi.class);

    api.getSeriesInfo(playlist.url + "/player_api.php", playlist.user, playlist.pass, "get_series_info", seriesId)
      .enqueue(new Callback<SeriesInfoResponse>() {
        @Override public void onResponse(Call<SeriesInfoResponse> call, Response<SeriesInfoResponse> res) {
          SeriesInfoResponse body = res.body();
          List<Episode> eps = (body != null && body.episodes != null) ? body.episodes : new ArrayList<>();

          StreamAdapter<Episode> sa = new StreamAdapter<>(
            eps,
            ep -> {
              clickCount++;
              if(clickCount % Math.max(1, BuildConfig.INTER_INTERVAL) == 0){
                UnityAdsManager.showInterstitial(SeriesEpisodesActivity.this);
              }

              Intent i = new Intent(SeriesEpisodesActivity.this, PlayerActivity.class);
              String ext = (ep.ext!=null && !ep.ext.isEmpty()) ? ep.ext : "mp4";
              // Xtream episode playback: /series/user/pass/episode_id.ext (çoğu panelde böyle)
              String url = playlist.url + "/series/" + playlist.user + "/" + playlist.pass + "/" + ep.id + "." + ext;
              i.putExtra("url", url);
              startActivity(i);
            },
            ep -> (ep.title != null && !ep.title.isEmpty()) ? ep.title : ("Episode " + ep.episodeNum)
          );

          rv.setAdapter(sa);
        }

        @Override public void onFailure(Call<SeriesInfoResponse> call, Throwable t) { }
      });
  }
}
EOF

# PlayerActivity (basit)
cat > "$MODULE_DIR/src/main/java/$PKG_PATH/ui/PlayerActivity.java" <<EOF
package $PACKAGE_NAME.ui;

import android.net.Uri;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.exoplayer2.*;
import com.google.android.exoplayer2.ui.StyledPlayerView;

import $PACKAGE_NAME.R;

public class PlayerActivity extends AppCompatActivity {

  private ExoPlayer player;

  @Override protected void onCreate(Bundle b){
    super.onCreate(b);
    setContentView(R.layout.activity_player);

    StyledPlayerView pv = findViewById(R.id.player_view);
    String url = getIntent().getStringExtra("url");

    player = new ExoPlayer.Builder(this).build();
    pv.setPlayer(player);

    if(url!=null && !url.isEmpty()){
      player.setMediaItem(MediaItem.fromUri(Uri.parse(url)));
      player.prepare();
      player.play();
    }
  }

  @Override protected void onDestroy(){
    super.onDestroy();
    if(player!=null) player.release();
  }
}
EOF

# ----------------------------------------------------
# 13) Gradle Wrapper (theapp içinde)
# ----------------------------------------------------
echo "🔧 Gradle Wrapper..."
pushd "$PROJECT_ROOT" >/dev/null
gradle wrapper --gradle-version 8.4 || true
chmod +x gradlew || true
popd >/dev/null

echo "✅ OK: Repo root'ta theapp/ üretildi."
echo "👉 YML zaten şunu yapacak: working-directory: ./theapp -> gradle assembleRelease"
