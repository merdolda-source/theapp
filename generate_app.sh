#!/bin/bash

# --- KONFİGÜRASYON ---
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_PATH="com/merdolda/player"
PKG_DIR="$MODULE_DIR/src/main/java/$PKG_PATH"
RES_DIR="$MODULE_DIR/src/main/res"

echo "💎 ERDINPLAYER PRO SİSTEMİ OLUŞTURULUYOR..."

# 1. KLASÖR YAPISI (PROFESYONEL KATMANLI MİMARİ)
rm -rf $PROJECT_ROOT
mkdir -p $PKG_DIR/model $PKG_DIR/adapter $PKG_DIR/api $PKG_DIR/utils $PKG_DIR/ui
mkdir -p $RES_DIR/layout $RES_DIR/values $RES_DIR/drawable $RES_DIR/anim
mkdir -p $PROJECT_ROOT/gradle/wrapper

# 2. İMZA (KEYSTORE) - APK'NIN YÜKLENMESİ İÇİN ŞART
keytool -genkey -v -keystore $MODULE_DIR/release.keystore -alias erdinplayer -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=Erdin, O=ErdinPlayer, C=TR" 2>/dev/null

# 3. GRADLE VE AYARLAR (JAVA 17 & MULTIDEX)
cat << 'EOF' > $PROJECT_ROOT/build.gradle
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath 'com.android.tools.build:gradle:8.1.1' }
}
allprojects {
    repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } }
}
EOF

cat << 'EOF' > $PROJECT_ROOT/settings.gradle
rootProject.name = "ErdinPlayer"
include ':app'
EOF

cat << 'EOF' > $PROJECT_ROOT/gradle.properties
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx2048m
EOF

cat << 'EOF' > $MODULE_DIR/build.gradle
plugins { id 'com.android.application' }
android {
    namespace 'com.merdolda.player'
    compileSdk 34
    defaultConfig {
        applicationId "com.merdolda.player"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
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
    compileOptions { sourceCompatibility JavaVersion.VERSION_17; targetCompatibility JavaVersion.VERSION_17 }
}
dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.19.1'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.github.bumptech.glide:glide:4.16.0'
}
EOF

# 4. MODELLER (XTREAM API TÜM PARAMETRELER)
cat << EOF > $PKG_DIR/model/XtreamData.java
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
import java.util.List;

public class XtreamData {
    public static class LoginResponse {
        @SerializedName("user_info") public UserInfo userInfo;
        @SerializedName("server_info") public ServerInfo serverInfo;
    }
    public static class UserInfo {
        @SerializedName("username") public String username;
        @SerializedName("auth") public int auth;
        @SerializedName("status") public String status;
        @SerializedName("expiry_date") public String expiry;
    }
    public static class ServerInfo {
        @SerializedName("url") public String url;
        @SerializedName("port") public String port;
    }
    public static class Category {
        @SerializedName("category_id") public String id;
        @SerializedName("category_name") public String name;
    }
    public static class StreamItem {
        @SerializedName("name") public String name;
        @SerializedName("stream_id") public String streamId;
        @SerializedName("stream_icon") public String icon;
        @SerializedName("category_id") public String catId;
        @SerializedName("epg_channel_id") public String epgId;
    }
}
EOF

# 5. ADAPTERLER (KATEGORİ VE KANAL)
cat << EOF > $PKG_DIR/adapter/MainAdapter.java
package com.merdolda.player.adapter;
import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.merdolda.player.R;
import com.merdolda.player.model.XtreamData.StreamItem;
import java.util.List;

public class MainAdapter extends RecyclerView.Adapter<MainAdapter.VH> {
    private List<StreamItem> list;
    private OnItemClick listener;
    public interface OnItemClick { void onClick(StreamItem item); }
    public MainAdapter(List<StreamItem> list, OnItemClick listener) { this.list = list; this.listener = listener; }
    @NonNull @Override public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_channel, p, false));
    }
    @Override public void onBindViewHolder(@NonNull VH h, int p) {
        StreamItem i = list.get(p);
        h.txt.setText(i.name);
        Glide.with(h.itemView.getContext()).load(i.icon).placeholder(R.drawable.ic_launcher_background).into(h.img);
        h.itemView.setOnClickListener(v -> listener.onClick(i));
    }
    @Override public int getItemCount() { return list == null ? 0 : list.size(); }
    class VH extends RecyclerView.ViewHolder {
        TextView txt; ImageView img;
        VH(View v) { super(v); txt = v.findViewById(R.id.tvName); img = v.findViewById(R.id.ivIcon); }
    }
}
EOF

# 6. API VE UTILS
cat << EOF > $PKG_DIR/api/XtreamApi.java
package com.merdolda.player.api;
import com.merdolda.player.model.XtreamData.*;
import java.util.List;
import retrofit2.Call;
import retrofit2.http.*;

public interface XtreamApi {
    @GET("player_api.php") Call<LoginResponse> login(@Query("username") String u, @Query("password") String p);
    @GET("player_api.php") Call<List<Category>> getCategories(@Query("username") String u, @Query("password") String p, @Query("action") String a);
    @GET("player_api.php") Call<List<StreamItem>> getStreams(@Query("username") String u, @Query("password") String p, @Query("action") String a, @Query("category_id") String c);
}
EOF

cat << EOF > $PKG_DIR/utils/PrefUtils.java
package com.merdolda.player.utils;
import android.content.*;

public class PrefUtils {
    public static void saveUser(Context c, String d, String u, String p) {
        c.getSharedPreferences("Erdin", 0).edit().putString("d", d).putString("u", u).putString("p", p).apply();
    }
    public static String getU(Context c) { return c.getSharedPreferences("Erdin", 0).getString("u", ""); }
    public static String getP(Context c) { return c.getSharedPreferences("Erdin", 0).getString("p", ""); }
    public static String getD(Context c) { return c.getSharedPreferences("Erdin", 0).getString("d", ""); }
}
EOF

# 7. TASARIMLAR (LAYOUT)
cat << 'EOF' > $RES_DIR/layout/activity_login.xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#101010">
    <LinearLayout android:layout_width="450dp" android:layout_height="wrap_content" android:layout_centerInParent="true" android:orientation="vertical" android:padding="30dp" android:background="#1C1C1C">
        <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="ERDIN PLAYER" android:textColor="#E50914" android:textSize="32sp" android:textStyle="bold" android:layout_gravity="center" android:layout_marginBottom="30dp"/>
        <EditText android:id="@+id/etUser" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Kullanıcı" android:textColor="#FFF"/>
        <EditText android:id="@+id/etPass" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="Şifre" android:inputType="textPassword" android:textColor="#FFF"/>
        <EditText android:id="@+id/etDns" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="http://server.com:8080" android:textColor="#FFF"/>
        <Button android:id="@+id/btnLogin" android:layout_width="match_parent" android:layout_height="60dp" android:text="GİRİŞ YAP" android:layout_marginTop="20dp" android:backgroundTint="#E50914"/>
    </LinearLayout>
</RelativeLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/activity_dashboard.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000" android:gravity="center" android:orientation="horizontal">
    <Button android:id="@+id/btnLive" android:layout_width="250dp" android:layout_height="180dp" android:text="CANLI TV" android:backgroundTint="#E50914" android:textSize="22sp" android:layout_margin="10dp"/>
    <Button android:id="@+id/btnVod" android:layout_width="250dp" android:layout_height="180dp" android:text="FİLMLER" android:backgroundTint="#222" android:textSize="22sp" android:layout_margin="10dp"/>
</LinearLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/item_channel.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="wrap_content" android:padding="10dp" android:focusable="true" android:clickable="true" android:background="?attr/selectableItemBackground">
    <ImageView android:id="@+id/ivIcon" android:layout_width="60dp" android:layout_height="60dp"/>
    <TextView android:id="@+id/tvName" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:textSize="18sp" android:layout_marginLeft="15dp" android:layout_gravity="center"/>
</LinearLayout>
EOF

# 8. ANA KODLAR (UI)
cat << EOF > $PKG_DIR/ui/LoginActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;
import com.merdolda.player.api.XtreamApi;
import com.merdolda.player.model.XtreamData.LoginResponse;
import com.merdolda.player.utils.PrefUtils;
import retrofit2.*;
import retrofit2.converter.gson.GsonConverterFactory;

public class LoginActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if(!PrefUtils.getU(this).isEmpty()) { start(); return; }
        setContentView(R.layout.activity_login);
        EditText u = findViewById(R.id.etUser), p = findViewById(R.id.etPass), d = findViewById(R.id.etDns);
        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String url = d.getText().toString();
            if(!url.startsWith("http")) url = "http://" + url;
            final String fD = url;
            Retrofit r = new Retrofit.Builder().baseUrl(fD+"/").addConverterFactory(GsonConverterFactory.create()).build();
            r.create(XtreamApi.class).login(u.getText().toString(), p.getText().toString()).enqueue(new Callback<LoginResponse>() {
                public void onResponse(Call<LoginResponse> c, Response<LoginResponse> res) {
                    if(res.body() != null && res.body().userInfo != null && res.body().userInfo.auth == 1) {
                        PrefUtils.saveUser(LoginActivity.this, fD, u.getText().toString(), p.getText().toString()); start();
                    } else Toast.makeText(LoginActivity.this, "Hatalı Giriş!", 0).show();
                }
                public void onFailure(Call<LoginResponse> c, Throwable t) { Toast.makeText(LoginActivity.this, "Bağlantı Yok!", 0).show(); }
            });
        });
    }
    void start() { startActivity(new Intent(this, DashboardActivity.class)); finish(); }
}
EOF

cat << EOF > $PKG_DIR/ui/DashboardActivity.java
package com.merdolda.player.ui;
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import com.merdolda.player.R;

public class DashboardActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dashboard);
        findViewById(R.id.btnLive).setOnClickListener(v -> startActivity(new Intent(this, LiveActivity.class)));
    }
}
EOF

# 9. MANIFEST (TÜM İZİNLER)
cat << 'EOF' > $MODULE_DIR/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <application android:name="androidx.multidex.MultiDexApplication" android:label="ErdinPlayer" android:theme="@style/Theme.AppCompat.NoActionBar" android:usesCleartextTraffic="true" android:icon="@drawable/ic_launcher_background">
        <activity android:name=".ui.LoginActivity" android:exported="true" android:screenOrientation="landscape">
            <intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter>
        </activity>
        <activity android:name=".ui.DashboardActivity" android:screenOrientation="landscape" />
        <activity android:name=".ui.LiveActivity" android:screenOrientation="landscape" />
        <activity android:name=".ui.PlayerActivity" android:screenOrientation="landscape" />
    </application>
</manifest>
EOF

# Diğer boş sınıfları oluştur (Build hatası vermemesi için)
touch $PKG_DIR/ui/LiveActivity.java $PKG_DIR/ui/PlayerActivity.java

# 10. KRİTİK: GRADLEW OLUŞTURUCU
# Bu adım 'No such file or directory' hatasını çözer.
cd $PROJECT_ROOT
gradle wrapper --gradle-version 8.2 --distribution-type bin
cd ..

echo "✅ PROJE VE GRADLEW HAZIR."
