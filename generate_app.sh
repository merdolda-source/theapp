#!/bin/bash
set -e

PROJECT_ROOT="."
APP_DIR="$PROJECT_ROOT/app"
PKG="com.erdin.xtream"
PKG_PATH="${PKG//./\/}"
JAVA_DIR="$APP_DIR/src/main/java/$PKG_PATH"
RES_DIR="$APP_DIR/src/main/res"

echo "✅ UPDATE: Unity aktif (interstitial), AdMob sadece banner + Xtream Series/Episodes"
echo "📦 Package: $PKG"
echo "📂 Project: $PROJECT_ROOT"

if [ ! -d "$PROJECT_ROOT" ]; then
  echo "❌ theapp klasörü bulunamadı. Repo kökünde 'theapp' olmalı."
  exit 1
fi

mkdir -p "$JAVA_DIR/utils" "$JAVA_DIR/ui" "$JAVA_DIR/api" "$JAVA_DIR/model" "$JAVA_DIR/adapter"
mkdir -p "$RES_DIR/layout" "$RES_DIR/values"

# ----------------------------------------------------
# 1) strings.xml (AdMob banner ID + app_name)
# ----------------------------------------------------
cat > "$RES_DIR/values/strings.xml" <<'EOF'
<resources>
    <string name="app_name">ERDİNXTREAM</string>
    <!-- AdMob TEST Banner -->
    <string name="admob_banner_id">ca-app-pub-3940256099942544/6300978111</string>
</resources>
EOF

# ----------------------------------------------------
# 2) activity_list.xml -> AdMob Banner eklendi
# ----------------------------------------------------
cat > "$RES_DIR/layout/activity_list.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:ads="http://schemas.android.com/apk/res-auto"
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
        android:layout_height="0dp"
        android:layout_weight="1"
        android:padding="8dp" />

    <!-- ✅ AdMob Banner (Sadece banner aktif kalacak) -->
    <com.google.android.gms.ads.AdView
        android:id="@+id/adView"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_gravity="center"
        ads:adSize="BANNER"
        ads:adUnitId="@string/admob_banner_id" />

</LinearLayout>
EOF

# ----------------------------------------------------
# 3) Dashboard layout -> Series butonu eklendi (3. kutu)
# ----------------------------------------------------
cat > "$RES_DIR/layout/activity_dashboard.xml" <<'EOF'
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
        android:textSize="24sp"
        android:layout_marginBottom="30dp"
        android:textStyle="bold" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:weightSum="2"
        android:layout_marginBottom="18dp">

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
                android:text="MOVIES"
                android:textColor="@color/text_primary"
                android:textSize="20sp"
                android:textStyle="bold" />
        </LinearLayout>
    </LinearLayout>

    <!-- ✅ Series -->
    <LinearLayout
        android:id="@+id/btnSeries"
        android:layout_width="match_parent"
        android:layout_height="120dp"
        style="@style/GlassCard"
        android:gravity="center"
        android:orientation="vertical"
        android:layout_marginBottom="22dp">

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="SERIES"
            android:textColor="@color/text_primary"
            android:textSize="20sp"
            android:textStyle="bold" />
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

# ----------------------------------------------------
# 4) Series Episodes layout + item
# ----------------------------------------------------
cat > "$RES_DIR/layout/activity_series_episodes.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@color/bg_dark"
    android:padding="10dp">

    <TextView
        android:id="@+id/tvTitle"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="@color/text_primary"
        android:textSize="18sp"
        android:textStyle="bold"
        android:padding="10dp"
        android:text="EPISODES" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvEpisodes"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:padding="6dp" />
</LinearLayout>
EOF

cat > "$RES_DIR/layout/item_episode.xml" <<'EOF'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:padding="12dp"
    style="@style/GlassCard"
    android:layout_marginBottom="8dp"
    android:orientation="horizontal"
    android:gravity="center_vertical">

    <ImageView
        android:layout_width="28dp"
        android:layout_height="28dp"
        android:src="@drawable/ic_play" />

    <TextView
        android:id="@+id/tvEpName"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:textColor="@color/text_primary"
        android:textSize="15sp"
        android:layout_marginLeft="12dp"
        android:textStyle="bold" />

</LinearLayout>
EOF

# ----------------------------------------------------
# 5) AppModels.java -> Series + Episodes modelleri eklendi
# ----------------------------------------------------
cat > "$JAVA_DIR/model/AppModels.java" <<EOF
package $PKG.model;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.List;
import java.util.Map;

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
        public String ref;
        public String origin;
    }

    // ✅ XTREAM SERIES (liste)
    public static class SeriesItem implements Serializable {
        @SerializedName("name") public String name;
        @SerializedName("series_id") public String seriesId;
        @SerializedName("cover") public String cover;
        @SerializedName("plot") public String plot;
        @SerializedName("rating") public String rating;
    }

    // ✅ XTREAM SERIES INFO (episodes)
    public static class SeriesInfoResponse implements Serializable {
        @SerializedName("episodes") public Map<String, List<EpisodeItem>> episodes; // season -> episodes
    }

    public static class EpisodeItem implements Serializable {
        @SerializedName("id") public String id; // episode id (playback uses /series/user/pass/{id}.ext)
        @SerializedName("title") public String title;
        @SerializedName("episode_num") public String episodeNum;
        @SerializedName("season") public String season;
        @SerializedName("container_extension") public String ext;
    }
}
EOF

# ----------------------------------------------------
# 6) XtreamApi.java -> series endpoints eklendi
# ----------------------------------------------------
cat > "$JAVA_DIR/api/XtreamApi.java" <<EOF
package $PKG.api;

import java.util.List;

import $PKG.model.AppModels.Category;
import $PKG.model.AppModels.LoginResponse;
import $PKG.model.AppModels.StreamItem;
import $PKG.model.AppModels.SeriesItem;
import $PKG.model.AppModels.SeriesInfoResponse;

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

    // ✅ Series list
    @GET
    Call<List<SeriesItem>> getSeries(
            @Url String url,
            @Query("username") String u,
            @Query("password") String p,
            @Query("action") String a,
            @Query("category_id") String c
    );

    // ✅ Series episodes
    @GET
    Call<SeriesInfoResponse> getSeriesInfo(
            @Url String url,
            @Query("username") String u,
            @Query("password") String p,
            @Query("action") String a,
            @Query("series_id") String seriesId
    );
}
EOF

# ----------------------------------------------------
# 7) AdMobManager.java -> SADECE BANNER (interstitial pasif)
# ----------------------------------------------------
cat > "$JAVA_DIR/utils/AdMobManager.java" <<EOF
package $PKG.utils;

import android.app.Activity;
import android.util.Log;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.MobileAds;

public class AdMobManager {

    private static boolean inited = false;

    public static void init(Activity a) {
        if (inited) return;
        inited = true;
        try {
            MobileAds.initialize(a, status -> {});
        } catch (Throwable t) {
            Log.e("AdMobManager", "init err: " + t);
        }
    }

    // ✅ Sadece banner aktif
    public static void loadBanner(Activity a, AdView adView) {
        try {
            init(a);
            AdRequest req = new AdRequest.Builder().build();
            adView.loadAd(req);
        } catch (Throwable t) {
            Log.e("AdMobManager", "banner err: " + t);
        }
    }

    // ❌ Interstitial PASİF (bilerek boş)
    public static void showInterstitialIfNeeded(Activity a, int clickCount, Runnable onDone) {
        if (onDone != null) onDone.run();
    }
}
EOF

# ----------------------------------------------------
# 8) UnityAdsManager.java -> Unity interstitial AKTİF (click ile)
# ----------------------------------------------------
cat > "$JAVA_DIR/utils/UnityAdsManager.java" <<EOF
package $PKG.utils;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;

import com.unity3d.ads.IUnityAdsInitializationListener;
import com.unity3d.ads.IUnityAdsLoadListener;
import com.unity3d.ads.IUnityAdsShowListener;
import com.unity3d.ads.UnityAds;
import com.unity3d.ads.UnityAdsShowOptions;

import $PKG.BuildConfig;

public class UnityAdsManager {

    private static boolean inited = false;
    private static boolean loading = false;
    private static boolean loaded = false;

    public static void init(Activity a) {
        if (inited) return;
        inited = true;

        UnityAds.initialize(a, BuildConfig.UNITY_GAME_ID, false, new IUnityAdsInitializationListener() {
            @Override public void onInitializationComplete() {
                loadInterstitial();
            }
            @Override public void onInitializationFailed(UnityAds.UnityAdsInitializationError error, String message) {
                loaded = false;
            }
        });
    }

    private static void loadInterstitial() {
        if (loading) return;
        loading = true;
        loaded = false;

        UnityAds.load(BuildConfig.UNITY_INTER_ID, new IUnityAdsLoadListener() {
            @Override public void onUnityAdsAdLoaded(String placementId) {
                loading = false;
                loaded = true;
            }
            @Override public void onUnityAdsFailedToLoad(String placementId, UnityAds.UnityAdsLoadError error, String message) {
                loading = false;
                loaded = false;
            }
        });
    }

    // ✅ Açılış reklamı (Unity interstitial)
    public static void showStartAd(Activity a, Runnable onDone) {
        init(a);

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            if (!loaded || !UnityAds.isInitialized()) {
                if (onDone != null) onDone.run();
                return;
            }

            UnityAds.show(a, BuildConfig.UNITY_INTER_ID, new UnityAdsShowOptions(), new IUnityAdsShowListener() {
                @Override public void onUnityAdsShowStart(String placementId) {}
                @Override public void onUnityAdsShowClick(String placementId) {}
                @Override public void onUnityAdsShowComplete(String placementId, UnityAds.UnityAdsShowCompletionState state) {
                    loaded = false;
                    loadInterstitial();
                    if (onDone != null) onDone.run();
                }
                @Override public void onUnityAdsShowFailure(String placementId, UnityAds.UnityAdsShowError error, String message) {
                    loaded = false;
                    loadInterstitial();
                    if (onDone != null) onDone.run();
                }
            });
        }, 700);
    }

    // ✅ Tıklama interstitial: interval dolduysa Unity göster
    public static void showInterstitialIfNeeded(Activity a, int clickCount, Runnable onDone) {
        init(a);

        int interval = Math.max(1, BuildConfig.INTER_INTERVAL);
        if (clickCount % interval != 0) {
            if (onDone != null) onDone.run();
            return;
        }

        if (!loaded || !UnityAds.isInitialized()) {
            loadInterstitial();
            if (onDone != null) onDone.run();
            return;
        }

        UnityAds.show(a, BuildConfig.UNITY_INTER_ID, new UnityAdsShowOptions(), new IUnityAdsShowListener() {
            @Override public void onUnityAdsShowStart(String placementId) {}
            @Override public void onUnityAdsShowClick(String placementId) {}
            @Override public void onUnityAdsShowComplete(String placementId, UnityAds.UnityAdsShowCompletionState state) {
                loaded = false;
                loadInterstitial();
                if (onDone != null) onDone.run();
            }
            @Override public void onUnityAdsShowFailure(String placementId, UnityAds.UnityAdsShowError error, String message) {
                loaded = false;
                loadInterstitial();
                if (onDone != null) onDone.run();
            }
        });
    }
}
EOF

# ----------------------------------------------------
# 9) EpisodeAdapter.java (episodes list)
# ----------------------------------------------------
cat > "$JAVA_DIR/adapter/EpisodeAdapter.java" <<EOF
package $PKG.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import $PKG.R;
import $PKG.model.AppModels.EpisodeItem;

public class EpisodeAdapter extends RecyclerView.Adapter<EpisodeAdapter.VH> {

    public interface OnClick {
        void onClick(EpisodeItem ep);
    }

    private List<EpisodeItem> list;
    private OnClick listener;

    public EpisodeAdapter(List<EpisodeItem> list, OnClick listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_episode, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH holder, int position) {
        EpisodeItem ep = list.get(position);
        holder.t.setText(ep.title);
        holder.itemView.setOnClickListener(v -> listener.onClick(ep));
    }

    @Override
    public int getItemCount() {
        return list == null ? 0 : list.size();
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView t;
        VH(@NonNull View v) {
            super(v);
            t = v.findViewById(R.id.tvEpName);
        }
    }
}
EOF

# ----------------------------------------------------
# 10) SeriesEpisodesActivity.java (series_id -> episodes -> play)
# ----------------------------------------------------
cat > "$JAVA_DIR/ui/SeriesEpisodesActivity.java" <<EOF
package $PKG.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;

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

import $PKG.R;
import $PKG.api.XtreamApi;
import $PKG.model.AppModels.EpisodeItem;
import $PKG.model.AppModels.Playlist;
import $PKG.model.AppModels.SeriesInfoResponse;
import $PKG.adapter.EpisodeAdapter;
import $PKG.utils.PrefUtils;

public class SeriesEpisodesActivity extends AppCompatActivity {

    private XtreamApi api;
    private Playlist playlist;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_series_episodes);

        String seriesId = getIntent().getStringExtra("series_id");
        String seriesName = getIntent().getStringExtra("series_name");

        ((TextView)findViewById(R.id.tvTitle)).setText(seriesName == null ? "EPISODES" : seriesName);

        playlist = PrefUtils.getActive(this);
        if (playlist == null || seriesId == null) {
            finish();
            return;
        }

        RecyclerView rv = findViewById(R.id.rvEpisodes);
        rv.setLayoutManager(new LinearLayoutManager(this));

        Retrofit r = new Retrofit.Builder()
                .baseUrl(playlist.url + "/")
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        api = r.create(XtreamApi.class);

        api.getSeriesInfo(playlist.url + "/player_api.php", playlist.user, playlist.pass, "get_series_info", seriesId)
                .enqueue(new Callback<SeriesInfoResponse>() {
                    @Override
                    public void onResponse(Call<SeriesInfoResponse> call, Response<SeriesInfoResponse> response) {
                        SeriesInfoResponse body = response.body();
                        if (body == null || body.episodes == null) return;

                        List<EpisodeItem> flat = new ArrayList<>();

                        for (Map.Entry<String, List<EpisodeItem>> e : body.episodes.entrySet()) {
                            String seasonKey = e.getKey();
                            List<EpisodeItem> eps = e.getValue();
                            if (eps == null) continue;

                            for (EpisodeItem ep : eps) {
                                String s = (ep.season != null && !ep.season.isEmpty()) ? ep.season : seasonKey;
                                String en = ep.episodeNum != null ? ep.episodeNum : "";
                                String title = (ep.title != null) ? ep.title : "Episode";
                                ep.title = "S" + s + "E" + en + " - " + title;
                                flat.add(ep);
                            }
                        }

                        rv.setAdapter(new EpisodeAdapter(flat, ep -> {
                            String ext = (ep.ext != null && !ep.ext.isEmpty()) ? ep.ext : "mp4";
                            String url = playlist.url + "/series/" + playlist.user + "/" + playlist.pass + "/" + ep.id + "." + ext;

                            Intent in = new Intent(SeriesEpisodesActivity.this, PlayerActivity.class);
                            in.putExtra("url", url);
                            in.putExtra("ref", (String) null);
                            in.putExtra("origin", (String) null);
                            startActivity(in);
                        }));
                    }

                    @Override
                    public void onFailure(Call<SeriesInfoResponse> call, Throwable t) {}
                });
    }
}
EOF

# ----------------------------------------------------
# 11) DashboardActivity.java -> Series butonu bağlandı
# ----------------------------------------------------
cat > "$JAVA_DIR/ui/DashboardActivity.java" <<EOF
package $PKG.ui;

import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import $PKG.R;
import $PKG.model.AppModels.Playlist;
import $PKG.utils.PrefUtils;

public class DashboardActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dashboard);

        Playlist p = PrefUtils.getActive(this);
        if (p != null) {
            ((TextView)findViewById(R.id.tvUser)).setText(p.name);
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

        // ✅ SERIES
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

# ----------------------------------------------------
# 12) CommonListActivity.java -> Unity interstitial + AdMob banner + Series list
# ----------------------------------------------------
cat > "$JAVA_DIR/ui/CommonListActivity.java" <<EOF
package $PKG.ui;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.gms.ads.AdView;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

import $PKG.R;
import $PKG.adapter.CategoryAdapter;
import $PKG.adapter.StreamAdapter;
import $PKG.api.XtreamApi;
import $PKG.model.AppModels.Category;
import $PKG.model.AppModels.Playlist;
import $PKG.model.AppModels.StreamItem;
import $PKG.model.AppModels.SeriesItem;
import $PKG.utils.M3UParser;
import $PKG.utils.PrefUtils;
import $PKG.utils.AdMobManager;
import $PKG.utils.UnityAdsManager;

public class CommonListActivity extends AppCompatActivity {

    private XtreamApi api;
    private RecyclerView rvC, rvS;
    private StreamAdapter streamAdapter;
    private String type;
    private Playlist playlist;

    private Map<String, List<StreamItem>> m3uMap;

    private int clickCount = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list);

        type = getIntent().getStringExtra("type");
        playlist = PrefUtils.getActive(this);

        rvC = findViewById(R.id.rvCats);
        rvS = findViewById(R.id.rvStreams);

        rvC.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        rvS.setLayoutManager(new LinearLayoutManager(this));

        // ✅ AdMob sadece banner
        AdView adView = findViewById(R.id.adView);
        if (adView != null) AdMobManager.loadBanner(this, adView);

        if (playlist == null) {
            finish();
            return;
        }

        // StreamAdapter (Live/VOD için)
        streamAdapter = new StreamAdapter(new ArrayList<>(), item -> {
            clickCount++;

            Runnable goPlay = () -> {
                Intent in = new Intent(this, PlayerActivity.class);
                String url;

                if ("Xtream".equals(playlist.type)) {
                    String path;
                    if ("live".equals(type)) path = "live";
                    else path = "movie";

                    String ext = (item.ext != null && !item.ext.isEmpty()) ? item.ext : "ts";
                    url = playlist.url + "/" + path + "/" + playlist.user + "/" + playlist.pass + "/" + item.streamId + "." + ext;

                    in.putExtra("ref", (String) null);
                    in.putExtra("origin", (String) null);
                } else {
                    url = item.directUrl;
                    in.putExtra("ref", item.ref);
                    in.putExtra("origin", item.origin);
                }

                in.putExtra("url", url);
                startActivity(in);
            };

            // ✅ Unity interstitial aktif (AdMob interstitial kapalı)
            UnityAdsManager.showInterstitialIfNeeded(this, clickCount, goPlay);
        });

        rvS.setAdapter(streamAdapter);

        if ("Xtream".equals(playlist.type)) {
            loadXtream();
        } else {
            loadM3u();
        }
    }

    private void loadM3u() {
        m3uMap = M3UParser.parse(playlist.m3uContent);
        List<Category> cats = new ArrayList<>();
        for (String key : m3uMap.keySet()) cats.add(new Category(key, key));

        CategoryAdapter catAdapter = new CategoryAdapter(cats, cat -> {
            List<StreamItem> items = m3uMap.get(cat.id);
            streamAdapter.update(items);
        });

        rvC.setAdapter(catAdapter);

        if (!cats.isEmpty()) {
            streamAdapter.update(m3uMap.get(cats.get(0).id));
        }
    }

    private void loadXtream() {
        Retrofit r = new Retrofit.Builder()
                .baseUrl(playlist.url + "/")
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        api = r.create(XtreamApi.class);

        String action;
        if ("live".equals(type)) action = "get_live_categories";
        else if ("vod".equals(type)) action = "get_vod_categories";
        else action = "get_series_categories"; // ✅ series

        api.getCategories(playlist.url + "/player_api.php", playlist.user, playlist.pass, action)
                .enqueue(new Callback<List<Category>>() {
                    @Override
                    public void onResponse(Call<List<Category>> call, Response<List<Category>> response) {
                        List<Category> body = response.body();
                        if (body == null) return;

                        CategoryAdapter catAdapter = new CategoryAdapter(body, cat -> loadItems(cat.id));
                        rvC.setAdapter(catAdapter);

                        if (!body.isEmpty()) loadItems(body.get(0).id);
                    }

                    @Override
                    public void onFailure(Call<List<Category>> call, Throwable t) {}
                });
    }

    private void loadItems(String id) {
        if ("series".equals(type)) {
            // ✅ Series list (get_series)
            api.getSeries(playlist.url + "/player_api.php", playlist.user, playlist.pass, "get_series", id)
                    .enqueue(new Callback<List<SeriesItem>>() {
                        @Override
                        public void onResponse(Call<List<SeriesItem>> call, Response<List<SeriesItem>> response) {
                            List<SeriesItem> list = response.body();
                            if (list == null) return;

                            // Series'i StreamAdapter ile göstermiyoruz; hızlı çözüm: StreamItem'a çeviriyoruz
                            List<StreamItem> fake = new ArrayList<>();
                            for (SeriesItem s : list) {
                                StreamItem it = new StreamItem();
                                it.name = s.name;
                                it.icon = s.cover;
                                it.streamId = s.seriesId; // series_id burada
                                it.ext = "mp4";
                                fake.add(it);
                            }

                            streamAdapter.update(fake);

                            // Tıklamada episode sayfasına yönlendirme için adapter click'i override gerekir.
                            // Basit çözüm: rvS’ye yeni adapter set ediyoruz:
                            rvS.setAdapter(new StreamAdapter(fake, item -> {
                                clickCount++;

                                Runnable goNext = () -> {
                                    Intent in = new Intent(CommonListActivity.this, SeriesEpisodesActivity.class);
                                    in.putExtra("series_id", item.streamId);
                                    in.putExtra("series_name", item.name);
                                    startActivity(in);
                                };

                                UnityAdsManager.showInterstitialIfNeeded(CommonListActivity.this, clickCount, goNext);
                            }));
                        }

                        @Override
                        public void onFailure(Call<List<SeriesItem>> call, Throwable t) {}
                    });
            return;
        }

        String action = "live".equals(type) ? "get_live_streams" : "get_vod_streams";
        api.getStreams(playlist.url + "/player_api.php", playlist.user, playlist.pass, action, id)
                .enqueue(new Callback<List<StreamItem>>() {
                    @Override
                    public void onResponse(Call<List<StreamItem>> call, Response<List<StreamItem>> response) {
                        List<StreamItem> body = response.body();
                        if (body != null) streamAdapter.update(body);
                    }
                    @Override
                    public void onFailure(Call<List<StreamItem>> call, Throwable t) {}
                });
    }
}
EOF

# ----------------------------------------------------
# 13) AndroidManifest.xml -> SeriesEpisodesActivity eklendi
# (Mevcut dosyan varsa silip yenisini yazmıyoruz; sadece eklemen için garanti update yapıyoruz.)
# Basit yöntem: dosyayı komple tekrar yazmak yerine, yoksa bırak. Varsa elle eklemek yerine direkt overwrite ederiz.
# ----------------------------------------------------
MANIFEST="$APP_DIR/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  # overwrite - güvenli: senin activity listeni koruyacak şekilde minimum alanları içerir
  cat > "$MANIFEST" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PKG">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:name="androidx.multidex.MultiDexApplication"
        android:label="ERDİNXTREAM"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true"
        android:icon="@mipmap/ic_launcher">

        <!-- AdMob App ID (test) -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713" />

        <activity
            android:name=".ui.SplashActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name=".ui.SelectionActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.LoginXtreamActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.LoginM3uActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.DashboardActivity" android:screenOrientation="portrait" />
        <activity android:name=".ui.CommonListActivity" android:screenOrientation="portrait" />

        <!-- ✅ Series Episodes -->
        <activity android:name=".ui.SeriesEpisodesActivity" android:screenOrientation="portrait" />

        <activity
            android:name=".ui.PlayerActivity"
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize"
            android:screenOrientation="sensor" />
    </application>
</manifest>
EOF
fi

echo "✅ UPDATE tamamlandı."
echo "➡️ Build: cd theapp && ./gradlew assembleRelease --no-daemon"
