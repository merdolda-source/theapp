#!/bin/bash

# --- AYARLAR ---
PROJECT_ROOT="theapp"
MODULE_DIR="$PROJECT_ROOT/app"
PKG_DIR="$MODULE_DIR/src/main/java/com/merdolda/player"
RES_DIR="$MODULE_DIR/src/main/res"

echo "🚀 ERDINPLAYER (ULTRA STABLE) OLUŞTURULUYOR..."

# 1. TEMİZLİK
rm -rf $PROJECT_ROOT
mkdir -p $PKG_DIR/model
mkdir -p $PKG_DIR/adapter
mkdir -p $RES_DIR/layout
mkdir -p $RES_DIR/values
mkdir -p $RES_DIR/drawable
mkdir -p $RES_DIR/mipmap-anydpi-v26
mkdir -p $PROJECT_ROOT/gradle/wrapper

# 2. KEYSTORE (HATA VERMEMESİ İÇİN BASİT ANAHTAR)
keytool -genkey -v -keystore $MODULE_DIR/release.keystore -alias erdinplayer -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=Erdin, OU=Player, O=Merdolda, L=Ist, S=Tr, C=TR" 2>/dev/null

# 3. GRADLE DOSYALARI
cat << 'EOF' > $PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat << 'EOF' > $PROJECT_ROOT/settings.gradle
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS); repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } } }
rootProject.name = "ErdinPlayer"
include ':app'
EOF

cat << 'EOF' > $PROJECT_ROOT/gradle.properties
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
EOF

cat << 'EOF' > $PROJECT_ROOT/build.gradle
plugins { id 'com.android.application' version '8.2.0' apply false }
EOF

# 4. APP BUILD.GRADLE
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
        release { storeFile file("release.keystore"); storePassword "123456"; keyAlias "erdinplayer"; keyPassword "123456" }
    }
    buildTypes {
        release { minifyEnabled false; signingConfig signingConfigs.release; proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro' }
    }
    compileOptions { sourceCompatibility JavaVersion.VERSION_17; targetCompatibility JavaVersion.VERSION_17 }
    lint { checkReleaseBuilds = false; abortOnError = false }
    packaging { resources { excludes += '/META-INF/{AL2.0,LGPL2.1}' } }
}
dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.github.bumptech.glide:glide:4.16.0'
}
EOF

# 5. RESOURCES
cat << 'EOF' > $RES_DIR/values/strings.xml
<resources>
    <string name="app_name">ErdinPlayer</string>
</resources>
EOF

cat << 'EOF' > $RES_DIR/values/colors.xml
<resources>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
    <color name="colorAccent">#E50914</color>
    <color name="card_bg">#222222</color>
</resources>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_launcher_background.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#000000" android:pathData="M0,0h108v108h-108z"/>
</vector>
EOF

cat << 'EOF' > $RES_DIR/drawable/selector_bg.xml
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:state_focused="true" android:drawable="@color/colorAccent" />
    <item android:drawable="@color/card_bg" />
</selector>
EOF

# 6. LAYOUTS (TASARIMLAR)

# Login Ekranı (Basitleştirildi)
cat << 'EOF' > $RES_DIR/layout/activity_login.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:gravity="center" android:padding="30dp" android:background="#101010">
    
    <TextView android:text="ERDIN PLAYER" android:textColor="#E50914" android:textSize="32sp" android:textStyle="bold" android:layout_marginBottom="40dp"/>
    
    <EditText android:id="@+id/etName" android:hint="Liste İsmi (Örn: Ev)" 
        android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFF" android:layout_marginBottom="15dp"/>

    <EditText android:id="@+id/etUser" android:hint="Kullanıcı Adı" 
        android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFF" android:layout_marginBottom="15dp"/>
        
    <EditText android:id="@+id/etPass" android:hint="Şifre" android:inputType="textPassword" 
        android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFF" android:layout_marginBottom="15dp"/>
        
    <EditText android:id="@+id/etDns" android:hint="URL (http://site.com:8080)" 
        android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFF" android:layout_marginBottom="30dp"/>
        
    <Button android:id="@+id/btnLogin" android:text="GİRİŞ YAP" 
        android:backgroundTint="#E50914" android:textColor="#FFF" android:textStyle="bold"
        android:layout_width="match_parent" android:layout_height="60dp"/>
        
    <TextView android:id="@+id/tvStatus" android:text="" android:textColor="#FFFF00" android:layout_marginTop="20dp"/>
</LinearLayout>
EOF

# Dashboard (Menü)
cat << 'EOF' > $RES_DIR/layout/activity_dashboard.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="#050505" android:gravity="center">
    
    <TextView android:id="@+id/tvUserInfo" android:text="Kullanıcı" android:textColor="#FFF" android:textSize="20sp" android:layout_marginBottom="30dp"/>
    
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center">
        <LinearLayout android:id="@+id/btnLive" android:layout_width="160dp" android:layout_height="120dp"
            android:background="#E50914" android:orientation="vertical" android:gravity="center"
            android:focusable="true" android:clickable="true" android:layout_margin="10dp">
            <TextView android:text="CANLI TV" android:textColor="#FFF" android:textStyle="bold" android:textSize="18sp"/>
        </LinearLayout>
    </LinearLayout>
    
    <Button android:id="@+id/btnLogout" android:text="ÇIKIŞ YAP" android:layout_marginTop="50dp" android:layout_width="wrap_content" android:layout_height="wrap_content"/>
</LinearLayout>
EOF

# Liste Elemanı
cat << 'EOF' > $RES_DIR/layout/item_channel.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:orientation="horizontal" android:padding="10dp"
    android:background="@drawable/selector_bg" android:focusable="true" android:clickable="true">
    <ImageView android:id="@+id/ivIcon" android:layout_width="50dp" android:layout_height="50dp" android:src="@drawable/ic_launcher_background"/>
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="vertical" android:layout_marginLeft="10dp" android:gravity="center_vertical">
        <TextView android:id="@+id/tvName" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFF" android:textSize="16sp" android:textStyle="bold"/>
        <TextView android:id="@+id/tvNum" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#AAA" android:textSize="14sp"/>
    </LinearLayout>
</LinearLayout>
EOF

# Liste Ekranı
cat << 'EOF' > $RES_DIR/layout/activity_list.xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent" android:background="#101010">
    <androidx.recyclerview.widget.RecyclerView android:id="@+id/recyclerView" android:layout_width="match_parent" android:layout_height="match_parent"/>
    <ProgressBar android:id="@+id/progressBar" android:layout_width="wrap_content" android:layout_height="wrap_content" android:layout_centerInParent="true"/>
</RelativeLayout>
EOF

# Player
cat << 'EOF' > $RES_DIR/layout/activity_player.xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent" android:layout_height="match_parent" android:background="#000">
    <com.google.android.exoplayer2.ui.StyledPlayerView
        android:id="@+id/video_view" android:layout_width="match_parent" android:layout_height="match_parent"
        app:resize_mode="fit" />
</FrameLayout>
EOF

# 7. JAVA KODLARI

cat << EOF > $PKG_DIR/model/LoginResponse.java
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
public class LoginResponse {
    @SerializedName("user_info") public UserInfo userInfo;
    @SerializedName("server_info") public ServerInfo serverInfo;
    public class UserInfo { @SerializedName("username") public String username; @SerializedName("auth") public int auth; }
    public class ServerInfo { @SerializedName("url") public String url; }
}
EOF

cat << EOF > $PKG_DIR/model/StreamItem.java
package com.merdolda.player.model;
import com.google.gson.annotations.SerializedName;
public class StreamItem {
    @SerializedName("num") public String num;
    @SerializedName("name") public String name;
    @SerializedName("stream_id") public int streamId;
    @SerializedName("stream_icon") public String streamIcon;
}
EOF

cat << EOF > $PKG_DIR/adapter/ChannelAdapter.java
package com.merdolda.player.adapter;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.merdolda.player.R;
import com.merdolda.player.model.StreamItem;
import java.util.List;

public class ChannelAdapter extends RecyclerView.Adapter<ChannelAdapter.ViewHolder> {
    private List<StreamItem> streams;
    private Context context;
    private OnItemClickListener listener;
    public interface OnItemClickListener { void onItemClick(StreamItem item); }
    public ChannelAdapter(Context context, List<StreamItem> streams, OnItemClickListener listener) {
        this.context = context; this.streams = streams; this.listener = listener;
    }
    @NonNull @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_channel, parent, false);
        return new ViewHolder(view);
    }
    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        StreamItem item = streams.get(position);
        holder.name.setText(item.name);
        holder.num.setText(item.num); 
        if (item.streamIcon != null && !item.streamIcon.isEmpty()) {
            Glide.with(context).load(item.streamIcon).placeholder(R.drawable.ic_launcher_background).into(holder.icon);
        } else { holder.icon.setImageResource(R.drawable.ic_launcher_background); }
        holder.itemView.setOnClickListener(v -> listener.onItemClick(item));
        holder.itemView.setOnFocusChangeListener((v, hasFocus) -> {
            if(hasFocus) v.setBackgroundResource(R.color.colorAccent);
            else v.setBackgroundResource(R.color.card_bg);
        });
    }
    @Override
    public int getItemCount() { return streams.size(); }
    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView name, num; ImageView icon;
        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            name = itemView.findViewById(R.id.tvName);
            num = itemView.findViewById(R.id.tvNum);
            icon = itemView.findViewById(R.id.ivIcon);
        }
    }
}
EOF

cat << EOF > $PKG_DIR/ApiService.java
package com.merdolda.player;
import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.POST;
import retrofit2.http.Body;
import retrofit2.http.Query;
import retrofit2.http.Url;
import java.util.List;
import com.merdolda.player.model.LoginResponse;
import com.merdolda.player.model.StreamItem;

public interface ApiService {
    @GET Call<LoginResponse> xtreamLogin(@Url String url, @Query("username") String user, @Query("password") String pass);
    @GET Call<List<StreamItem>> getLiveStreams(@Url String url, @Query("username") String user, @Query("password") String pass, @Query("action") String action);
}
EOF

cat << EOF > $PKG_DIR/SessionManager.java
package com.merdolda.player;
import android.content.Context;
import android.content.SharedPreferences;
public class SessionManager {
    SharedPreferences pref; SharedPreferences.Editor editor; Context _context;
    private static final String PREF_NAME = "ErdinPlayerPref";
    public SessionManager(Context context) {
        this._context = context; pref = _context.getSharedPreferences(PREF_NAME, 0); editor = pref.edit();
    }
    public void createLoginSession(String dns, String username, String password) {
        editor.putString("dns", dns); editor.putString("username", username); editor.putString("password", password); editor.commit();
    }
    public String getDns() { return pref.getString("dns", ""); }
    public String getUser() { return pref.getString("username", ""); }
    public String getPass() { return pref.getString("password", ""); }
    public void logout() { editor.clear(); editor.commit(); }
    public boolean isLoggedIn() { return !getUser().isEmpty(); }
}
EOF

# LOGIN ACTIVITY - FİX: ONCREATE'DE HİÇBİR NETWORK İŞLEMİ YAPILMIYOR
cat << EOF > $PKG_DIR/LoginActivity.java
package com.merdolda.player;
import android.content.Intent;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import com.merdolda.player.model.LoginResponse;

public class LoginActivity extends AppCompatActivity {
    SessionManager session;
    TextView tvStatus;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        session = new SessionManager(this);
        
        // Eğer daha önce giriş yapılmışsa direkt Dashboard'u aç
        // Bu işlem UI'dan bağımsız ve hızlıdır, çökme yapmaz
        if(session.isLoggedIn()){
            startActivity(new Intent(this, DashboardActivity.class));
            finish();
            return;
        }

        setContentView(R.layout.activity_login);
        
        EditText etDns = findViewById(R.id.etDns);
        EditText etUser = findViewById(R.id.etUser);
        EditText etPass = findViewById(R.id.etPass);
        tvStatus = findViewById(R.id.tvStatus);
        
        findViewById(R.id.btnLogin).setOnClickListener(v -> {
            String d = etDns.getText().toString().trim();
            if(!d.startsWith("http")) d = "http://" + d;
            // Sonunda / varsa sil (örn: http://site.com/ -> http://site.com)
            if(d.endsWith("/")) d = d.substring(0, d.length() - 1);
            
            String u = etUser.getText().toString().trim();
            String p = etPass.getText().toString().trim();

            if(d.length() < 5 || u.isEmpty() || p.isEmpty()) { 
                Toast.makeText(this, "Eksik bilgi!", Toast.LENGTH_SHORT).show(); 
                return; 
            }
            
            tvStatus.setText("Bağlanıyor...");
            performXtreamLogin(d, u, p);
        });
    }

    void performXtreamLogin(String d, String u, String p) {
        try {
            // Dummy base URL (Retrofit hatasız başlasın diye)
            Retrofit retrofit = new Retrofit.Builder().baseUrl("http://127.0.0.1/").addConverterFactory(GsonConverterFactory.create()).build();
            
            String apiPath = d + "/player_api.php";
            
            retrofit.create(ApiService.class).xtreamLogin(apiPath, u, p).enqueue(new Callback<LoginResponse>() {
                public void onResponse(Call<LoginResponse> call, Response<LoginResponse> response) {
                    if(response.body() != null && response.body().userInfo != null) {
                        tvStatus.setText("Giriş Başarılı!");
                        session.createLoginSession(d, u, p);
                        startActivity(new Intent(LoginActivity.this, DashboardActivity.class));
                        finish();
                    } else {
                        tvStatus.setText("HATA: Kullanıcı adı veya şifre yanlış.");
                    }
                }
                public void onFailure(Call<LoginResponse> c, Throwable t) { 
                    tvStatus.setText("BAĞLANTI HATASI: " + t.getMessage());
                }
            });
        } catch(Exception e) { 
            tvStatus.setText("KRİTİK HATA: " + e.getMessage());
        }
    }
}
EOF

cat << EOF > $PKG_DIR/DashboardActivity.java
package com.merdolda.player;
import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class DashboardActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dashboard);
        
        SessionManager session = new SessionManager(this);
        TextView tvUser = findViewById(R.id.tvUserInfo);
        tvUser.setText("Hesap: " + session.getUser());
        
        findViewById(R.id.btnLive).setOnClickListener(v -> startActivity(new Intent(this, LiveListActivity.class)));
        
        findViewById(R.id.btnLogout).setOnClickListener(v -> {
            session.logout();
            startActivity(new Intent(this, LoginActivity.class));
            finish();
        });
    }
}
EOF

cat << EOF > $PKG_DIR/LiveListActivity.java
package com.merdolda.player;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import java.util.List;
import com.merdolda.player.model.StreamItem;
import com.merdolda.player.adapter.ChannelAdapter;

public class LiveListActivity extends AppCompatActivity {
    RecyclerView recyclerView; ProgressBar progressBar;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list);
        recyclerView = findViewById(R.id.recyclerView);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        progressBar = findViewById(R.id.progressBar);
        SessionManager session = new SessionManager(this);
        fetchChannels(session.getDns(), session.getUser(), session.getPass());
    }
    void fetchChannels(String d, String u, String p) {
        try {
            Retrofit retrofit = new Retrofit.Builder().baseUrl("http://127.0.0.1/").addConverterFactory(GsonConverterFactory.create()).build();
            String apiPath = d + "/player_api.php";
            retrofit.create(ApiService.class).getLiveStreams(apiPath, u, p, "get_live_streams").enqueue(new Callback<List<StreamItem>>() {
                public void onResponse(Call<List<StreamItem>> call, Response<List<StreamItem>> response) {
                    progressBar.setVisibility(View.GONE);
                    if(response.body() != null) {
                        ChannelAdapter adapter = new ChannelAdapter(LiveListActivity.this, response.body(), item -> {
                            Intent intent = new Intent(LiveListActivity.this, PlayerActivity.class);
                            String streamUrl = d + "/live/" + u + "/" + p + "/" + item.streamId + ".ts";
                            intent.putExtra("url", streamUrl);
                            startActivity(intent);
                        });
                        recyclerView.setAdapter(adapter);
                    }
                }
                public void onFailure(Call<List<StreamItem>> c, Throwable t) { progressBar.setVisibility(View.GONE); Toast.makeText(LiveListActivity.this, "Liste alınamadı", Toast.LENGTH_SHORT).show(); }
            });
        } catch(Exception e){ e.printStackTrace(); }
    }
}
EOF

cat << 'EOF' > $PKG_DIR/PlayerActivity.java
package com.merdolda.player;
import android.net.Uri;
import android.os.Bundle;
import android.view.KeyEvent;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.StyledPlayerView;

public class PlayerActivity extends AppCompatActivity {
    ExoPlayer player; StyledPlayerView view;
    int[] modes = {0, 3, 4, 1}; int modeIdx = 0;
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(R.layout.activity_player);
        view = findViewById(R.id.video_view);
        player = new ExoPlayer.Builder(this).build();
        view.setPlayer(player);
        String url = getIntent().getStringExtra("url");
        if(url!=null) { player.setMediaItem(MediaItem.fromUri(Uri.parse(url))); player.prepare(); player.play(); }
    }
    public boolean onKeyDown(int k, KeyEvent e) {
        if(k==KeyEvent.KEYCODE_PROG_BLUE || k==KeyEvent.KEYCODE_DPAD_CENTER || k==KeyEvent.KEYCODE_ENTER) {
             if(!view.isControllerFullyVisible()){ modeIdx=(modeIdx+1)%4; view.setResizeMode(modes[modeIdx]); return true; }
        }
        return super.onKeyDown(k, e);
    }
    protected void onStop(){ super.onStop(); if(player!=null) player.release(); }
}
EOF

# 8. MANIFEST
cat << 'EOF' > $MODULE_DIR/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-feature android:name="android.software.leanback" android:required="false" />
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    <application android:name="androidx.multidex.MultiDexApplication" android:allowBackup="true" android:label="@string/app_name" 
        android:theme="@style/Theme.AppCompat.NoActionBar" 
        android:icon="@drawable/ic_launcher_background" android:usesCleartextTraffic="true">
        
        <activity android:name=".LoginActivity" android:exported="true">
            <intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /><category android:name="android.intent.category.LEANBACK_LAUNCHER" /></intent-filter>
        </activity>
        
        <activity android:name=".DashboardActivity" />
        <activity android:name=".LiveListActivity" />
        <activity android:name=".PlayerActivity" android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize" />
    </application>
</manifest>
EOF

# --- WRAPPER OLUŞTURMA ---
cd $PROJECT_ROOT
gradle wrapper --gradle-version 8.2 --distribution-type bin
cd ..

echo "✅ ERDINPLAYER TAMAMLANDI."
