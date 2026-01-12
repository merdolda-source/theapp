#!/bin/bash

# --- AYARLAR ---
PROJECT_NAME="ErdinPlayer"
PROJECT_ROOT="theapp"  # GitHub Actions bu klasör ismini bekliyor!
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="com/merdolda/player"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "💎 ERDINPLAYER v14.0: SPOR YEŞİL TEMA, ARAMA, SIDE MENU, EXTVLCOPT, SERIES & PRO TASARIM KURULUYOR..."

# 1. TEMİZLİK & KLASÖRLER
if [ -d "$PROJECT_ROOT" ]; then rm -rf "$PROJECT_ROOT"; fi

mkdir -p "$PKG_DIR"/{model,adapter,api,utils,ui}
mkdir -p "$RES_DIR"/{layout,values,drawable,anim,menu,color,font}
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
    implementation 'androidx.drawerlayout:drawerlayout:1.1.1'

    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.19.1'

    implementation 'com.github.bumptech.glide:glide:4.16.0'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'

    # Reklam tarafı için (panelden ID gelecek)
    implementation 'com.google.android.gms:play-services-ads:22.6.0'
    implementation 'com.unity3d.ads:unity-ads:4.9.3'
}
EOF

# 4. RESOURCES (SPOR YEŞİL TEMA)
cat << 'EOF' > "$RES_DIR/values/colors.xml"
<resources>
    <color name="bg_dark">#020907</color>           <!-- çok koyu yeşilimsi siyah -->
    <color name="accent">#00C853</color>           <!-- spor yeşili -->
    <color name="accent_soft">#00E676</color>      <!-- daha açık yeşil -->
    <color name="accent_secondary">#FFC400</color> <!-- ufak vurgular için sarımsı -->
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
        <item name="android:padding">10dp</item>
    </style>
</resources>
EOF

# Drawables (yeşil temaya uygun)
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
        android:startColor="#00C853"
        android:endColor="#00E676"
        android:angle="45"/>
    <corners android:radius="12dp"/>
</shape>
EOF

cat << 'EOF' > "$RES_DIR/drawable/ic_play.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="@color/accent_soft" android:pathData="M8,5v14l11,-7z"/>
</vector>
EOF

cat << 'EOF' > "$RES_DIR/drawable/ic_delete.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="@color/accent_secondary" android:pathData="M6,19c0,1.1 0.9,2 2,2h8c1.1,0 2,-0.9 2,-2V7H6v12zM19,4h-3.5l-1,-1h-5l-1,1H5v2h14V4z"/>
</vector>
EOF

cat << 'EOF' > "$RES_DIR/drawable/ic_zoom.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="@color/accent_soft" android:pathData="M15,3l2.3,2.3 -2.89,2.87 1.42,1.42L18.7,6.7 21,9V3zM3,9l2.3,-2.3 2.87,2.89 1.42,-1.42L6.7,5.3 9,3H3zM9,21l-2.3,-2.3 2.89,-2.87 -1.42,-1.42L5.3,17.3 3,15v6zM21,15l-2.3,2.3 -2.87,-2.89 -1.42,1.42L17.3,18.7 15,21h6z"/>
</vector>
EOF

cat << 'EOF' > "$RES_DIR/drawable/ic_launcher_background.xml"
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#020907" android:pathData="M0,0h108v108h-108z"/>
</vector>
EOF

# 5. MODELLER (M3U & SERIES & EXPIRE)
cat << EOF > "$PKG_DIR/model/AppModels.java"
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class AppModels {
    public static class Playlist implements Serializable {
        public String id, name, type, url, user, pass;
        public String m3uContent;
        public String exp; // Xtream abonelik bitiş (timestamp)
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
        public Category(String id, String name) { this.id=id; this.name=name; }
    }

    public static class StreamItem implements Serializable {
        @SerializedName(value = "name") public String name;
        @SerializedName(value = "stream_id", alternate = {"series_id"}) public String streamId;
        @SerializedName(value = "stream_icon", alternate = {"cover"}) public String icon;
        @SerializedName("container_extension") public String ext;
        public String directUrl;
        public String group;
        public String origin;
        public String referrer;
    }

    public static class Episode implements Serializable {
        @SerializedName("title") public String title;
        @SerializedName("id") public String id;
        @SerializedName("container_extension") public String ext;
    }

    public static class SeriesInfo implements Serializable {
        @SerializedName("episodes")
        public java.util.Map<String, java.util.List<Episode>> episodes;
    }
}
EOF

# 6. API & UTILS (M3U + EXTVLCOPT)
cat << EOF > "$PKG_DIR/api/XtreamApi.java"
package com.merdolda.player.api;
import com.merdolda.player.model.AppModels.*;
import java.util.List;
import retrofit2.Call;
import retrofit2.http.*;

public interface XtreamApi {
    @GET
    Call<LoginResponse> login(@Url String url, @Query("username") String u, @Query("password") String p);

    @GET
    Call<List<Category>> getCategories(@Url String url, @Query("username") String u, @Query("password") String p, @Query("action") String a);

    @GET
    Call<List<StreamItem>> getStreams(@Url String url, @Query("username") String u, @Query("password") String p, @Query("action") String a, @Query("category_id") String c);

    @GET
    Call<SeriesInfo> getSeriesInfo(@Url String url,
                                   @Query("username") String u,
                                   @Query("password") String p,
                                   @Query("action") String a,
                                   @Query("series_id") String id);
}
EOF

cat << EOF > "$PKG_DIR/utils/M3UParser.java"
package com.merdolda.player.utils;
import com.merdolda.player.model.AppModels.*;
import java.util.*;
import java.util.regex.*;

public class M3UParser {
    public static Map<String, List<StreamItem>> parse(String content) {
        Map<String, List<StreamItem>> map = new LinkedHashMap<>();
        String[] lines = content.split("\\n");
        String currentGroup = "Uncategorized";
        StreamItem currentItem = null;

        for (String line : lines) {
            line = line.trim();
            if (line.startsWith("#EXTINF")) {
                currentItem = new StreamItem();
                int comma = line.lastIndexOf(",");
                currentItem.name = comma > 0 ? line.substring(comma + 1).trim()
                                             : "Unknown Channel";

                Matcher mGroup = Pattern.compile("group-title=\"([^\"]*)\"").matcher(line);
                if (mGroup.find()) currentGroup = mGroup.group(1);

                Matcher mLogo = Pattern.compile("tvg-logo=\"([^\"]*)\"").matcher(line);
                if (mLogo.find()) currentItem.icon = mLogo.group(1);

                currentItem.group = currentGroup;

            } else if (line.startsWith("#EXTVLCOPT:") && currentItem != null) {
                int idx = line.indexOf("=");
                if (idx > 0 && idx + 1 < line.length()) {
                    String val = line.substring(idx + 1).trim();
                    if (line.contains("http-referrer=")) {
                        currentItem.referrer = val;
                    } else if (line.contains("http-origin=")) {
                        currentItem.origin = val;
                    }
                }
            } else if (!line.startsWith("#") && !line.isEmpty() && currentItem != null) {
                currentItem.directUrl = line;
                if (!map.containsKey(currentGroup)) map.put(currentGroup, new ArrayList<>());
                map.get(currentGroup).add(currentItem);
                currentItem = null;
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
    private static SharedPreferences get(Context c) {
        return c.getSharedPreferences("ERD_V14", 0);
    }

    public static void savePlaylist(Context c, Playlist p) {
        List<Playlist> l = getPlaylists(c);
        l.add(p);
        get(c).edit().putString("L", new Gson().toJson(l))
                .putString("A", p.id)
                .apply();
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
        List<Playlist> l = getPlaylists(c);
        l.removeIf(p -> p.id.equals(id));
        get(c).edit().putString("L", new Gson().toJson(l)).apply();
    }

    public static void logout(Context c) {
        get(c).edit().remove("A").apply();
    }
}
EOF

# 7. ADAPTERLER (basit liste, filtre Activity'de)
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

    public PlaylistAdapter(List<Playlist> list, OnClick listener) {
        this.list = list; this.listener = listener;
    }

    public void setItems(List<Playlist> items) {
        this.list = items;
        notifyDataSetChanged();
    }

    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_playlist, p, false));
    }

    @Override public void onBindViewHolder(@NonNull VH h, int pos) {
        Playlist i = list.get(pos);
        h.n.setText(i.name);
        h.t.setText(i.type);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
        h.d.setOnClickListener(v -> listener.onDelete(i));
    }

    @Override public int getItemCount() { return list == null ? 0 : list.size(); }

    class VH extends RecyclerView.ViewHolder {
        TextView n, t; ImageView d;
        VH(View v) {
            super(v);
            n=v.findViewById(R.id.tvPlayName);
            t=v.findViewById(R.id.tvPlayInfo);
            d=v.findViewById(R.id.btnDel);
        }
    }
}
EOF

cat << EOF > "$PKG_DIR/adapter/CategoryAdapter.java"
package com.merdolda.player.adapter;
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

    public CategoryAdapter(List<Category> list, OnClick listener) {
        this.list = list; this.listener = listener;
    }

    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_category, p, false));
    }

    @Override public void onBindViewHolder(@NonNull VH h, int pos) {
        h.t.setText(list.get(pos).name);
        h.itemView.setBackgroundResource(sel == pos ? R.drawable.bg_neon_btn : R.drawable.bg_glass_input);
        h.itemView.setOnClickListener(v -> {
            int old = sel; sel = h.getAdapterPosition();
            notifyItemChanged(old); notifyItemChanged(sel);
            listener.onClick(list.get(pos));
        });
    }

    @Override public int getItemCount() { return list.size(); }

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

    public StreamAdapter(List<StreamItem> list, OnItemClick listener) {
        this.list = list; this.listener = listener;
    }

    public void setItems(List<StreamItem> items) {
        this.list = items;
        notifyDataSetChanged();
    }

    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_channel, p, false));
    }

    @Override public void onBindViewHolder(@NonNull VH h, int pos) {
        StreamItem i = list.get(pos);
        h.t.setText(i.name);
        Glide.with(h.itemView.getContext())
                .load(i.icon)
                .placeholder(R.drawable.ic_play)
                .into(h.i);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
    }

    @Override public int getItemCount() { return list == null ? 0 : list.size(); }

    class VH extends RecyclerView.ViewHolder {
        TextView t; ImageView i;
        VH(View v) {
            super(v);
            t = v.findViewById(R.id.tvName);
            i = v.findViewById(R.id.ivIcon);
        }
    }
}
EOF

cat << EOF > "$PKG_DIR/adapter/EpisodeAdapter.java"
package com.merdolda.player.adapter;
import android.view.*;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.merdolda.player.R;
import com.merdolda.player.model.AppModels.Episode;
import java.util.List;

public class EpisodeAdapter extends RecyclerView.Adapter<EpisodeAdapter.VH> {
    private List<Episode> list; private OnItemClick listener;

    public interface OnItemClick { void onClick(Episode item); }

    public EpisodeAdapter(List<Episode> list, OnItemClick listener) {
        this.list = list; this.listener = listener;
    }

    public void setItems(List<Episode> items) {
        this.list = items;
        notifyDataSetChanged();
    }

    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_episode, p, false));
    }

    @Override public void onBindViewHolder(@NonNull VH h, int pos) {
        Episode e = list.get(pos);
        String title = (e.title != null && !e.title.isEmpty()) ? e.title : ("Episode " + e.id);
        h.t.setText(title);
        h.itemView.setOnClickListener(v -> listener.onClick(e));
    }

    @Override public int getItemCount() { return list == null ? 0 : list.size(); }

    class VH extends RecyclerView.ViewHolder {
        TextView t;
        VH(View v) {
            super(v);
            t = v.findViewById(R.id.tvEpName);
        }
    }
}
EOF

# 8. LAYOUTLAR (yan menü + arama + hafif hover)
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
        android:textSize="30sp"
        android:textStyle="bold"
        android:layout_centerHorizontal="true"
        android:layout_marginTop="40dp"/>

    <EditText
        android:id="@+id/etSearchPlaylists"
        android:layout_width="match_parent" android:layout_height="40dp"
        android:layout_below="@id/header"
        android:layout_marginTop="8dp"
        android:layout_marginLeft="20dp"
        android:layout_marginRight="20dp"
        android:background="@drawable/bg_glass_input"
        android:hint="Search playlists..."
        android:textColor="@color/text_primary"
        android:textColorHint="@color/text_secondary"
        android:paddingLeft="12dp"
        android:paddingRight="12dp"
        android:singleLine="true"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvPlaylists"
        android:layout_width="match_parent" android:layout_height="match_parent"
        android:layout_below="@id/etSearchPlaylists"
        android:layout_above="@+id/btnGroup"
        android:padding="20dp"
        android:clipToPadding="false"/>

    <LinearLayout
        android:id="@+id/btnGroup"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="vertical"
        android:layout_alignParentBottom="true"
        android:padding="20dp">

        <Button
            android:id="@+id/btnXtream"
            android:layout_width="match_parent" android:layout_height="52dp"
            android:text="ADD XTREAM API"
            style="@style/NeonButton"
            android:layout_marginBottom="10dp"/>

        <Button
            android:id="@+id/btnM3u"
            android:layout_width="match_parent" android:layout_height="52dp"
            android:text="ADD M3U LINK"
            style="@style/GlassInput"
            android:textColor="@color/text_primary"/>
    </LinearLayout>
</RelativeLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_playlist.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    style="@style/GlassCard"
    android:layout_marginBottom="12dp"
    android:orientation="horizontal"
    android:gravity="center_vertical"
    android:clickable="true"
    android:focusable="true"
    android:foreground="?android:attr/selectableItemBackground">

    <LinearLayout
        android:layout_width="0dp" android:layout_height="wrap_content"
        android:layout_weight="1"
        android:orientation="vertical">

        <TextView
            android:id="@+id/tvPlayName"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:textColor="@color/text_primary"
            android:textSize="18sp" android:textStyle="bold"/>

        <TextView
            android:id="@+id/tvPlayInfo"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:layout_marginTop="4dp"
            android:textColor="@color/text_secondary"
            android:textSize="14sp"/>
    </LinearLayout>

    <ImageView
        android:id="@+id/btnDel"
        android:layout_width="32dp" android:layout_height="32dp"
        android:src="@drawable/ic_delete"
        android:padding="4dp"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_dashboard.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="@color/bg_dark"
    android:orientation="vertical"
    android:padding="24dp">

    <TextView
        android:id="@+id/tvUser"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:gravity="center"
        android:textSize="18sp"
        android:layout_marginBottom="24dp"
        android:textStyle="bold"/>

    <LinearLayout
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:weightSum="2"
        android:layout_marginBottom="16dp">

        <LinearLayout
            android:id="@+id/btnLive"
            android:layout_width="0dp" android:layout_height="140dp"
            android:layout_weight="1"
            android:layout_marginRight="8dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical"
            android:clickable="true"
            android:focusable="true"
            android:foreground="?android:attr/selectableItemBackground">

            <TextView
                android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="LIVE TV" android:textColor="@color/text_primary"
                android:textSize="20sp" android:textStyle="bold"/>
        </LinearLayout>

        <LinearLayout
            android:id="@+id/btnMovies"
            android:layout_width="0dp" android:layout_height="140dp"
            android:layout_weight="1"
            android:layout_marginLeft="8dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical"
            android:clickable="true"
            android:focusable="true"
            android:foreground="?android:attr/selectableItemBackground">

            <TextView
                android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="VOD" android:textColor="@color/text_primary"
                android:textSize="20sp" android:textStyle="bold"/>
        </LinearLayout>
    </LinearLayout>

    <LinearLayout
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:layout_marginBottom="16dp">

        <LinearLayout
            android:id="@+id/btnSeries"
            android:layout_width="match_parent" android:layout_height="120dp"
            style="@style/GlassCard"
            android:gravity="center"
            android:orientation="vertical"
            android:clickable="true"
            android:focusable="true"
            android:foreground="?android:attr/selectableItemBackground">

            <TextView
                android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="SERIES"
                android:textColor="@color/text_primary"
                android:textSize="18sp"
                android:textStyle="bold"/>
        </LinearLayout>
    </LinearLayout>

    <!-- Giriş ekranı banner alanı -->
    <FrameLayout
        android:id="@+id/bannerContainerDashboard"
        android:layout_width="match_parent" android:layout_height="50dp"
        android:layout_marginTop="8dp"/>
    
    <Button
        android:id="@+id/btnLogout"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="SWITCH PLAYLIST"
        style="@style/NeonButton"
        android:layout_gravity="center_horizontal"
        android:layout_marginTop="20dp"
        android:paddingLeft="40dp" android:paddingRight="40dp"/>
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
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="XTREAM LOGIN"
        android:textColor="@color/text_primary"
        android:textSize="26sp" android:textStyle="bold"
        android:layout_marginBottom="30dp"/>

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Playlist Name" style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etUser"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Username" style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etPass"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Password" android:inputType="textPassword"
        style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etDns"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="http://url:port" style="@style/GlassInput"
        android:layout_marginBottom="30dp"/>

    <Button
        android:id="@+id/btnLogin"
        android:layout_width="match_parent" android:layout_height="56dp"
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
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="M3U LINK"
        android:textColor="@color/text_primary"
        android:textSize="26sp" android:textStyle="bold"
        android:layout_marginBottom="30dp"/>

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="Playlist Name" style="@style/GlassInput"
        android:layout_marginBottom="10dp"/>

    <EditText
        android:id="@+id/etUrl"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:hint="http://example.com/playlist.m3u" style="@style/GlassInput"
        android:layout_marginBottom="30dp"/>

    <Button
        android:id="@+id/btnSave"
        android:layout_width="match_parent" android:layout_height="56dp"
        android:text="DOWNLOAD &amp; SAVE"
        style="@style/NeonButton"/>
</LinearLayout>
EOF

# Yan menü + arama + banner alanı
cat << 'EOF' > "$RES_DIR/layout/activity_list.xml"
<androidx.drawerlayout.widget.DrawerLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/drawer_layout"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="@color/bg_dark">

    <!-- ANA İÇERİK -->
    <LinearLayout
        android:layout_width="match_parent" android:layout_height="match_parent"
        android:orientation="vertical">

        <LinearLayout
            android:layout_width="match_parent" android:layout_height="56dp"
            android:gravity="center_vertical"
            android:padding="10dp">

            <ImageButton
                android:id="@+id/btnMenu"
                android:layout_width="40dp" android:layout_height="40dp"
                android:background="@drawable/bg_glass"
                android:src="@android:drawable/ic_menu_sort_by_size"
                android:contentDescription="Menu"
                android:padding="8dp"/>

            <TextView
                android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:layout_marginLeft="12dp"
                android:text="CHANNELS"
                android:textColor="@color/text_primary"
                android:textSize="18sp"
                android:textStyle="bold"/>
        </LinearLayout>

        <EditText
            android:id="@+id/etSearchStreams"
            android:layout_width="match_parent" android:layout_height="40dp"
            android:layout_marginLeft="10dp"
            android:layout_marginRight="10dp"
            android:layout_marginBottom="4dp"
            android:background="@drawable/bg_glass_input"
            android:hint="Search channels..."
            android:textColor="@color/text_primary"
            android:textColorHint="@color/text_secondary"
            android:singleLine="true"
            android:paddingLeft="12dp"
            android:paddingRight="12dp"/>

        <androidx.recyclerview.widget.RecyclerView
            android:id="@+id/rvStreams"
            android:layout_width="match_parent" android:layout_height="0dp"
            android:layout_weight="1"
            android:padding="8dp"/>

        <!-- Liste altı banner alanı -->
        <FrameLayout
            android:id="@+id/bannerContainerList"
            android:layout_width="match_parent" android:layout_height="50dp"
            android:layout_marginBottom="4dp"/>
    </LinearLayout>

    <!-- SOL ÇEKMECE: KATEGORİLER -->
    <LinearLayout
        android:layout_width="260dp" android:layout_height="match_parent"
        android:layout_gravity="start"
        android:orientation="vertical"
        android:background="@color/bg_dark"
        android:padding="12dp">

        <TextView
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:text="CATEGORIES"
            android:textColor="@color/text_primary"
            android:textSize="18sp"
            android:textStyle="bold"
            android:layout_marginBottom="8dp"/>

        <androidx.recyclerview.widget.RecyclerView
            android:id="@+id/rvCats"
            android:layout_width="match_parent" android:layout_height="match_parent"
            android:paddingTop="4dp"
            android:clipToPadding="false"/>
    </LinearLayout>
</androidx.drawerlayout.widget.DrawerLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_channel.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:padding="14dp"
    style="@style/GlassCard"
    android:layout_marginBottom="8dp"
    android:orientation="horizontal"
    android:gravity="center_vertical"
    android:clickable="true"
    android:focusable="true"
    android:foreground="?android:attr/selectableItemBackground">

    <ImageView
        android:id="@+id/ivIcon"
        android:layout_width="44dp" android:layout_height="44dp"
        android:src="@drawable/ic_play"/>

    <TextView
        android:id="@+id/tvName"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textSize="18sp"
        android:layout_marginLeft="15dp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_category.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:padding="10dp"
    android:layout_marginBottom="6dp"
    android:gravity="center_vertical"
    android:clickable="true"
    android:focusable="true"
    android:background="@drawable/bg_glass_input"
    android:foreground="?android:attr/selectableItemBackground">

    <TextView
        android:id="@+id/tvCatName"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textSize="14sp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

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
        android:src="@drawable/ic_zoom"
        android:background="@drawable/bg_glass"
        android:layout_gravity="top|right"
        android:layout_margin="30dp"
        android:padding="10dp"/>
</FrameLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/activity_series.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@color/bg_dark"
    android:padding="16dp">

    <TextView
        android:id="@+id/tvSeriesTitle"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textSize="20sp"
        android:textStyle="bold"
        android:layout_marginBottom="8dp"/>

    <EditText
        android:id="@+id/etSearchEpisodes"
        android:layout_width="match_parent" android:layout_height="40dp"
        android:background="@drawable/bg_glass_input"
        android:hint="Search episodes..."
        android:textColor="@color/text_primary"
        android:textColorHint="@color/text_secondary"
        android:singleLine="true"
        android:paddingLeft="12dp"
        android:paddingRight="12dp"
        android:layout_marginBottom="8dp"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvEpisodes"
        android:layout_width="match_parent" android:layout_height="match_parent"
        android:paddingTop="4dp"/>
</LinearLayout>
EOF

cat << 'EOF' > "$RES_DIR/layout/item_episode.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    style="@style/GlassCard"
    android:layout_marginBottom="8dp"
    android:orientation="horizontal"
    android:gravity="center_vertical"
    android:padding="14dp"
    android:clickable="true"
    android:focusable="true"
    android:foreground="?android:attr/selectableItemBackground">

    <TextView
        android:id="@+id/tvEpName"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textSize="16sp"
        android:textStyle="bold"/>
</LinearLayout>
EOF

# 9. JAVA EKRANLAR (arama + ilk kategori + EXTVLCOPT + fullscreen player)
cat << EOF > "$PKG_DIR/ui/SelectionActivity.java"
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
    PlaylistAdapter adapter;
    List<Playlist> all = new ArrayList<>();
    List<Playlist> filtered = new ArrayList<>();

    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_selection);

        RecyclerView rv = findViewById(R.id.rvPlaylists);
        rv.setLayoutManager(new LinearLayoutManager(this));

        adapter = new PlaylistAdapter(filtered, new PlaylistAdapter.OnClick() {
            @Override public void onClick(Playlist p) {
                PrefUtils.savePlaylist(SelectionActivity.this, p);
                startActivity(new Intent(SelectionActivity.this, DashboardActivity.class));
            }
            @Override public void onDelete(Playlist p) {
                PrefUtils.deletePlaylist(SelectionActivity.this, p.id);
                all.remove(p);
                applyFilter(((EditText)findViewById(R.id.etSearchPlaylists)).getText().toString());
            }
        });
        rv.setAdapter(adapter);

        EditText search = findViewById(R.id.etSearchPlaylists);
        search.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c,int s,int b,int c2){}
            @Override public void onTextChanged(CharSequence c,int s,int b,int c2){}
            @Override public void afterTextChanged(Editable e){ applyFilter(e.toString()); }
        });

        findViewById(R.id.btnXtream).setOnClickListener(v ->
                startActivity(new Intent(this, LoginXtreamActivity.class)));
        findViewById(R.id.btnM3u).setOnClickListener(v ->
                startActivity(new Intent(this, LoginM3uActivity.class)));
    }

    @Override protected void onResume() {
        super.onResume();
        all = PrefUtils.getPlaylists(this);
        applyFilter(((EditText)findViewById(R.id.etSearchPlaylists)).getText().toString());
    }

    void applyFilter(String q) {
        filtered = new ArrayList<>();
        String s = q == null ? "" : q.toLowerCase();
        for (Playlist p : all) {
            if (s.isEmpty() || (p.name != null && p.name.toLowerCase().contains(s))) {
                filtered.add(p);
            }
        }
        adapter.setItems(filtered);
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/DashboardActivity.java"
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import android.widget.FrameLayout;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.utils.PrefUtils;
import com.merdolda.player.model.AppModels.Playlist;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class DashboardActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_dashboard);

        TextView tv = findViewById(R.id.tvUser);
        Playlist p = PrefUtils.getActive(this);
        if(p != null) {
            String text = p.name;
            if (p.exp != null && !p.exp.isEmpty()) {
                try {
                    long expSec = Long.parseLong(p.exp);
                    if (expSec > 0) {
                        long nowSec = System.currentTimeMillis()/1000L;
                        long diff = expSec - nowSec;
                        String extra;
                        if (diff > 0) {
                            long days = diff / (60*60*24);
                            SimpleDateFormat sdf = new SimpleDateFormat("dd.MM.yyyy", Locale.getDefault());
                            String dateStr = sdf.format(new Date(expSec*1000L));
                            extra = "Expires: " + dateStr + " (" + days + " days left)";
                        } else {
                            extra = "Expired";
                        }
                        text = p.name + "\\n" + extra;
                    }
                } catch (Exception ignored) {}
            }
            tv.setText(text);
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

        // Buraya panelden gelen reklam ayarlarına göre banner çağrısı gelecek (AdManager ile)
        FrameLayout banner = findViewById(R.id.bannerContainerDashboard);
        // Örnek: AdManager.showBanner(this, banner, "dashboard");
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

        EditText name = findViewById(R.id.etName),
                 u = findViewById(R.id.etUser),
                 p = findViewById(R.id.etPass),
                 d = findViewById(R.id.etDns);

        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String url = d.getText().toString();
            if(!url.startsWith("http")) url = "http://"+url;
            Retrofit r = new Retrofit.Builder().baseUrl(url+"/")
                    .addConverterFactory(GsonConverterFactory.create()).build();
            final String fU = url;

            r.create(XtreamApi.class)
                    .login(fU+"/player_api.php",
                           u.getText().toString(),
                           p.getText().toString())
                    .enqueue(new Callback<LoginResponse>() {
                @Override public void onResponse(Call<LoginResponse> c, Response<LoginResponse> res) {
                    if(res.body()!=null && res.body().userInfo != null) {
                        Playlist pl = new Playlist();
                        pl.id = UUID.randomUUID().toString();
                        pl.type="Xtream";
                        pl.url=fU;
                        pl.user=u.getText().toString();
                        pl.pass=p.getText().toString();
                        pl.name=name.getText().toString();
                        if (res.body().userInfo.expDate != null)
                            pl.exp = res.body().userInfo.expDate;
                        PrefUtils.savePlaylist(LoginXtreamActivity.this, pl);
                        startActivity(new Intent(LoginXtreamActivity.this, DashboardActivity.class));
                        finish();
                    } else {
                        Toast.makeText(LoginXtreamActivity.this, "Login Failed", Toast.LENGTH_SHORT).show();
                    }
                }
                @Override public void onFailure(Call<LoginResponse> c, Throwable t) {
                    Toast.makeText(LoginXtreamActivity.this, "Connection Error", Toast.LENGTH_SHORT).show();
                }
            });
        });
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/LoginM3uActivity.java"
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

public class LoginM3uActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_login_m3u);

        EditText n = findViewById(R.id.etName),
                 u = findViewById(R.id.etUrl);

        findViewById(R.id.btnSave).setOnClickListener(v -> {
            String url = u.getText().toString();
            OkHttpClient client = new OkHttpClient();
            Request request = new Request.Builder().url(url).build();

            new Thread(() -> {
                try {
                    Response response = client.newCall(request).execute();
                    if(response.isSuccessful()) {
                        String content = response.body().string();
                        runOnUiThread(() -> {
                            Playlist pl = new Playlist();
                            pl.id = UUID.randomUUID().toString();
                            pl.type="M3U";
                            pl.name=n.getText().toString();
                            pl.url=url;
                            pl.m3uContent = content;
                            PrefUtils.savePlaylist(this, pl);
                            startActivity(new Intent(this, DashboardActivity.class));
                            finish();
                        });
                    } else {
                        runOnUiThread(() ->
                            Toast.makeText(this, "Failed to download M3U", Toast.LENGTH_SHORT).show());
                    }
                } catch(Exception e) {
                    runOnUiThread(() ->
                        Toast.makeText(this, "Failed to download M3U", Toast.LENGTH_SHORT).show());
                }
            }).start();
        });
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/CommonListActivity.java"
package com.merdolda.player.ui;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.EditText;
import androidx.appcompat.app.AppCompatActivity;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.core.view.GravityCompat;
import androidx.recyclerview.widget.*;
import com.merdolda.player.R;
import com.merdolda.player.adapter.*;
import com.merdolda.player.api.XtreamApi;
import com.merdolda.player.model.AppModels.*;
import com.merdolda.player.utils.*;
import java.util.*;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;
import android.content.Intent;
import android.widget.FrameLayout;

public class CommonListActivity extends AppCompatActivity {
    XtreamApi api;
    RecyclerView rvC, rvS;
    StreamAdapter adp;
    String type;
    Playlist p;

    DrawerLayout drawer;
    EditText search;

    Map<String, List<StreamItem>> m3uMap = new LinkedHashMap<>();
    Map<String, List<StreamItem>> xtreamMap = new LinkedHashMap<>();
    List<StreamItem> allM3u = new ArrayList<>();
    List<StreamItem> allXtream = new ArrayList<>();
    String activeCategoryId = null;

    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_list);
        type = getIntent().getStringExtra("type");
        p = PrefUtils.getActive(this);

        drawer = findViewById(R.id.drawer_layout);
        rvC = findViewById(R.id.rvCats);
        rvS = findViewById(R.id.rvStreams);
        search = findViewById(R.id.etSearchStreams);

        rvC.setLayoutManager(new LinearLayoutManager(this, RecyclerView.VERTICAL, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));

        findViewById(R.id.btnMenu).setOnClickListener(v ->
                drawer.openDrawer(GravityCompat.START));

        adp = new StreamAdapter(new ArrayList<>(), item -> {
            Intent in;
            String url;
            if ("Xtream".equals(p.type)) {
                if ("series".equals(type)) {
                    in = new Intent(this, SeriesActivity.class);
                    in.putExtra("series_id", item.streamId);
                    in.putExtra("series_name", item.name);
                } else {
                    in = new Intent(this, PlayerActivity.class);
                    url = p.url + "/" + (type.equals("live") ? "live" : "movie")
                            + "/" + p.user + "/" + p.pass + "/"
                            + item.streamId + "." + (item.ext!=null?item.ext:"ts");
                    in.putExtra("url", url);
                }
            } else {
                in = new Intent(this, PlayerActivity.class);
                url = item.directUrl;
                in.putExtra("url", url);
                if (item.origin != null) in.putExtra("origin", item.origin);
                if (item.referrer != null) in.putExtra("ref", item.referrer);
            }
            startActivity(in);
        });
        rvS.setAdapter(adp);

        search.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c,int s,int c2,int a){}
            @Override public void onTextChanged(CharSequence c,int s,int c2,int a){}
            @Override public void afterTextChanged(Editable e){ updateList(); }
        });

        // Liste altı banner alanı (panelden gelen ayara göre doldurulacak)
        FrameLayout banner = findViewById(R.id.bannerContainerList);
        // Örnek: AdManager.showBanner(this, banner, "list");

        if("Xtream".equals(p.type)) loadXtream();
        else loadM3u();
    }

    void loadM3u() {
        m3uMap = M3UParser.parse(p.m3uContent);
        allM3u.clear();
        List<Category> cats = new ArrayList<>();
        for (String key : m3uMap.keySet()) {
            cats.add(new Category(key, key));
            allM3u.addAll(m3uMap.get(key));
        }
        rvC.setAdapter(new CategoryAdapter(cats, cat -> {
            activeCategoryId = cat.id;
            updateList();
        }));
        if (!cats.isEmpty()) activeCategoryId = cats.get(0).id;
        updateList();
    }

    void loadXtream() {
        api = new Retrofit.Builder()
                .baseUrl(p.url+"/")
                .addConverterFactory(GsonConverterFactory.create())
                .build()
                .create(XtreamApi.class);

        String a;
        if ("live".equals(type)) a = "get_live_categories";
        else if ("vod".equals(type)) a = "get_vod_categories";
        else a = "get_series_categories";

        api.getCategories(p.url+"/player_api.php", p.user, p.pass, a)
                .enqueue(new Callback<List<Category>>() {
            public void onResponse(Call<List<Category>> c, Response<List<Category>> r) {
                if(r.body()!=null) {
                    List<Category> cats = r.body();
                    rvC.setAdapter(new CategoryAdapter(cats, cat -> {
                        activeCategoryId = cat.id;
                        if (!xtreamMap.containsKey(cat.id)) {
                            loadItems(cat.id);
                        } else {
                            updateList();
                        }
                    }));
                    if (!cats.isEmpty()) {
                        activeCategoryId = cats.get(0).id;
                        loadItems(activeCategoryId);
                    }
                }
            }
            public void onFailure(Call<List<Category>> c, Throwable t) {}
        });
    }

    void loadItems(String id) {
        String a;
        if ("live".equals(type)) a = "get_live_streams";
        else if ("vod".equals(type)) a = "get_vod_streams";
        else a = "get_series";

        api.getStreams(p.url+"/player_api.php", p.user, p.pass, a, id)
                .enqueue(new Callback<List<StreamItem>>() {
            public void onResponse(Call<List<StreamItem>> c, Response<List<StreamItem>> r) {
                if(r.body()!=null) {
                    xtreamMap.put(id, r.body());
                    rebuildXtreamAll();
                    updateList();
                }
            }
            public void onFailure(Call<List<StreamItem>> c, Throwable t) {}
        });
    }

    void rebuildXtreamAll() {
        allXtream.clear();
        for (List<StreamItem> list : xtreamMap.values()) {
            allXtream.addAll(list);
        }
    }

    void updateList() {
        String q = search.getText().toString().trim().toLowerCase(Locale.ROOT);
        List<StreamItem> base = new ArrayList<>();
        if ("Xtream".equals(p.type)) {
            if (q.isEmpty()) {
                if (activeCategoryId != null && xtreamMap.containsKey(activeCategoryId))
                    base.addAll(xtreamMap.get(activeCategoryId));
                else
                    base.addAll(allXtream);
            } else {
                for (StreamItem s : allXtream) {
                    if (s.name != null && s.name.toLowerCase(Locale.ROOT).contains(q))
                        base.add(s);
                }
            }
        } else {
            if (q.isEmpty()) {
                if (activeCategoryId != null && m3uMap.containsKey(activeCategoryId))
                    base.addAll(m3uMap.get(activeCategoryId));
                else
                    base.addAll(allM3u);
            } else {
                for (StreamItem s : allM3u) {
                    if (s.name != null && s.name.toLowerCase(Locale.ROOT).contains(q))
                        base.add(s);
                }
            }
        }
        adp.setItems(base);
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/SeriesActivity.java"
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.EditText;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.merdolda.player.R;
import com.merdolda.player.adapter.EpisodeAdapter;
import com.merdolda.player.api.XtreamApi;
import com.merdolda.player.model.AppModels.*;
import com.merdolda.player.utils.PrefUtils;
import java.util.*;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;

public class SeriesActivity extends AppCompatActivity {
    XtreamApi api;
    Playlist p;
    EpisodeAdapter adapter;
    List<Episode> all = new ArrayList<>();
    EditText search;

    @Override protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_series);

        String seriesId = getIntent().getStringExtra("series_id");
        String seriesName = getIntent().getStringExtra("series_name");

        TextView title = findViewById(R.id.tvSeriesTitle);
        if (seriesName != null) title.setText(seriesName);

        RecyclerView rv = findViewById(R.id.rvEpisodes);
        rv.setLayoutManager(new LinearLayoutManager(this));

        search = findViewById(R.id.etSearchEpisodes);
        search.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c,int s,int c2,int a){}
            @Override public void onTextChanged(CharSequence c,int s,int c2,int a){}
            @Override public void afterTextChanged(Editable e){ applyFilter(e.toString()); }
        });

        p = PrefUtils.getActive(this);
        api = new Retrofit.Builder()
                .baseUrl(p.url + "/")
                .addConverterFactory(GsonConverterFactory.create())
                .build()
                .create(XtreamApi.class);

        adapter = new EpisodeAdapter(new ArrayList<>(), e -> {
            String url = p.url + "/series/" + p.user + "/" + p.pass + "/"
                    + e.id + "." + (e.ext != null ? e.ext : "mp4");
            Intent in = new Intent(this, PlayerActivity.class);
            in.putExtra("url", url);
            startActivity(in);
        });
        rv.setAdapter(adapter);

        loadEpisodes(seriesId);
    }

    void loadEpisodes(String seriesId) {
        api.getSeriesInfo(p.url + "/player_api.php", p.user, p.pass, "get_series_info", seriesId)
                .enqueue(new Callback<SeriesInfo>() {
            @Override public void onResponse(Call<SeriesInfo> c, Response<SeriesInfo> r) {
                if (r.body() != null && r.body().episodes != null) {
                    all.clear();
                    for (List<Episode> eps : r.body().episodes.values()) all.addAll(eps);
                    applyFilter(search.getText().toString());
                }
            }
            @Override public void onFailure(Call<SeriesInfo> c, Throwable t) {}
        });
    }

    void applyFilter(String q) {
        List<Episode> filtered = new ArrayList<>();
        String s = q == null ? "" : q.toLowerCase(Locale.ROOT);
        for (Episode e : all) {
            String name = e.title != null ? e.title : e.id;
            if (s.isEmpty() || (name != null && name.toLowerCase(Locale.ROOT).contains(s))) {
                filtered.add(e);
            }
        }
        adapter.setItems(filtered);
    }
}
EOF

cat << EOF > "$PKG_DIR/ui/PlayerActivity.java"
package com.merdolda.player.ui;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.*;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.*;
import com.google.android.exoplayer2.source.DefaultMediaSourceFactory;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.merdolda.player.R;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class PlayerActivity extends AppCompatActivity {
    ExoPlayer p; StyledPlayerView pv;
    int resizeMode = 0; // 0:Fit, 1:Fill, 2:Zoom

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
            getWindow().getAttributes().layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        setContentView(R.layout.activity_player);
        pv = findViewById(R.id.player_view);

        pv.setControllerShowTimeoutMs(3000);
        pv.setControllerHideOnTouch(true);

        hideSystemUI();

        String url = getIntent().getStringExtra("url");
        String origin = getIntent().getStringExtra("origin");
        String ref = getIntent().getStringExtra("ref");

        DefaultHttpDataSource.Factory httpFactory =
                new DefaultHttpDataSource.Factory().setAllowCrossProtocolRedirects(true);

        Map<String, String> headers = new HashMap<>();
        if (origin != null && !origin.isEmpty()) headers.put("Origin", origin);
        if (ref != null && !ref.isEmpty()) headers.put("Referer", ref);
        if (!headers.isEmpty()) httpFactory.setDefaultRequestProperties(headers);

        p = new ExoPlayer.Builder(this)
                .setMediaSourceFactory(new DefaultMediaSourceFactory(httpFactory))
                .build();
        pv.setPlayer(p);

        findViewById(R.id.btnZoom).setOnClickListener(v -> toggleZoom());

        if(url != null) {
            p.setMediaItem(MediaItem.fromUri(Uri.parse(url)));
            p.prepare();
            p.play();
        }
    }

    private void hideSystemUI() {
        View decorView = getWindow().getDecorView();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            getWindow().setDecorFitsSystemWindows(false);
            WindowInsetsController controller = decorView.getWindowInsetsController();
            if (controller != null) {
                controller.hide(WindowInsets.Type.statusBars() | WindowInsets.Type.navigationBars());
                controller.setSystemBarsBehavior(
                        WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            decorView.setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                            | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_FULLSCREEN
            );
        }
    }

    @Override public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) hideSystemUI();
    }

    void toggleZoom() {
        resizeMode++;
        if(resizeMode > 2) resizeMode = 0;

        if(resizeMode == 0) {
            pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT);
            Toast.makeText(this, "MODE: FIT", Toast.LENGTH_SHORT).show();
        } else if(resizeMode == 1) {
            pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FILL);
            Toast.makeText(this, "MODE: STRETCH FILL", Toast.LENGTH_SHORT).show();
        } else {
            pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);
            Toast.makeText(this, "MODE: ZOOM CROP", Toast.LENGTH_SHORT).show();
        }
    }

    @Override protected void onDestroy() {
        super.onDestroy();
        if(p != null) p.release();
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

        <activity android:name=".ui.LoginXtreamActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.LoginM3uActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.DashboardActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.CommonListActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.SeriesActivity" android:screenOrientation="portrait" />
        <activity
            android:name=".ui.PlayerActivity"
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize"
            android:screenOrientation="sensor" />
    </application>
</manifest>
EOF

# 11. WRAPPER GENERATION
echo "Generating Gradle Wrapper..."
cd "$PROJECT_ROOT"
gradle wrapper --gradle-version 8.4
chmod +x gradlew
cd ..

echo "✅ ERDINPLAYER v14.0: SPOR YEŞİL TEMA, ARAMA, SIDE MENU, EXTVLCOPT, SERIES HAZIR."
echo "👉 NOW RUN: cd $PROJECT_NAME && ./gradlew assembleRelease --no-daemon"
