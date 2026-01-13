#!/usr/bin/env bash
# create_xtream_project.sh
# Tek bir .sh ile Android (Kotlin single-Activity) proje iskeleti + build script + panel PHP tetikleyici oluşturur.
# Kullanım:
#   chmod +x create_xtream_project.sh
#   ./create_xtream_project.sh
#
# Oluşturulan dizin yapısı örneği:
#  - settings.gradle
#  - build.gradle
#  - gradle.properties
#  - app/
#    - build.gradle
#    - src/main/AndroidManifest.xml
#    - src/main/res/values/colors.xml
#    - src/main/res/values/themes.xml
#    - src/main/res/layout/activity_main.xml
#    - src/main/java/com/example/xtreamplayer/MainActivity.kt
#  - scripts/build.sh
#  - panel/trigger_build.php
#
# Not: Bu script gradle wrapper veya keystore yaratmaz; CI/keystore ve gerçek derleme ortamı ayrıca konfigüre edilmelidir.

set -euo pipefail

echo "Creating XtreamPlayer project skeleton..."

# Root files
mkdir -p app/src/main/java/com/example/xtreamplayer
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/layout
mkdir -p scripts
mkdir -p panel

cat > settings.gradle <<'EOF'
rootProject.name = "XtreamPlayer"
include ':app'
EOF

cat > build.gradle <<'EOF'
// Top-level build file
buildscript {
    ext.kotlin_version = "1.8.21"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:7.4.2"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:${kotlin_version}"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOF

cat > gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx2048m
android.useAndroidX=true
kotlin.code.style=official
EOF

cat > app/build.gradle <<'EOF'
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    compileSdk 33

    defaultConfig {
        // Bu değerler build.sh ile güncellenecek
        applicationId "com.example.xtreamplayer"
        minSdk 21
        targetSdk 33
        versionCode 1
        versionName "1.0.0"

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            minifyEnabled false
            // signingConfig signingConfigs.release  // Keystore ile gerekli ise aç
        }
        debug {
            // debug config
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    namespace "com.example.xtreamplayer"
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib:1.8.21"
    implementation 'androidx.core:core-ktx:1.10.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.2.1'

    // ExoPlayer
    implementation 'com.google.android.exoplayer:exoplayer:2.18.5'

    // OkHttp for advanced HTTP handling (optional)
    implementation 'com.squareup.okhttp3:okhttp:4.10.0'

    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
EOF

cat > app/src/main/AndroidManifest.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.xtreamplayer">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:allowBackup="true"
        android:label="XtreamPlayer"
        android:theme="@style/Theme.XtreamPlayer">
        <activity android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

cat > app/src/main/res/values/colors.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="dark_gray">#1F2023</color>
    <color name="sport_green">#00C853</color>
    <color name="maroon">#7B0000</color>
    <color name="white">#FFFFFF</color>
    <color name="black">#000000</color>
</resources>
EOF

cat > app/src/main/res/values/themes.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.XtreamPlayer" parent="Theme.MaterialComponents.DayNight.NoActionBar">
        <item name="colorPrimary">@color/dark_gray</item>
        <item name="colorPrimaryVariant">@color/maroon</item>
        <item name="colorSecondary">@color/sport_green</item>
    </style>
</resources>
EOF

cat > app/src/main/res/layout/activity_main.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.coordinatorlayout.widget.CoordinatorLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/dark_gray">

    <!-- Top banner (girişte Xtream/M3U seçim arasına konacak) -->
    <TextView
        android:id="@+id/topBanner"
        android:layout_width="match_parent"
        android:layout_height="48dp"
        android:gravity="center"
        android:text="REKLAM BANNER"
        android:textColor="@color/white"
        android:background="@color/maroon"/>

    <!-- PlayerView -->
    <com.google.android.exoplayer2.ui.PlayerView
        android:id="@+id/playerView"
        android:layout_width="match_parent"
        android:layout_height="240dp"
        android:layout_marginTop="56dp"
        app:use_controller="true"
        android:background="@color/black"
        app:controller_show_timeout="3000"/>

    <!-- Controls: mode switch, favorite, logout -->
    <LinearLayout
        android:id="@+id/controls"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:layout_marginTop="304dp"
        android:padding="8dp"
        android:gravity="center">

        <Button
            android:id="@+id/btnMode"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Mode"/>

        <Button
            android:id="@+id/btnFav"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Favorite"
            android:layout_marginLeft="8dp"/>

        <Button
            android:id="@+id/btnLogout"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Logout"
            android:layout_marginLeft="8dp"/>
    </LinearLayout>

    <!-- Simple list of streams -->
    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/listStreams"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_marginTop="380dp"
        android:padding="8dp"
        android:clipToPadding="false"/>

    <!-- Bottom banner -->
    <TextView
        android:id="@+id/bottomBanner"
        android:layout_width="match_parent"
        android:layout_height="48dp"
        android:layout_gravity="bottom"
        android:gravity="center"
        android:text="ALT REKLAM"
        android:textColor="@color/white"
        android:background="@color/maroon"/>
</androidx.coordinatorlayout.widget.CoordinatorLayout>
EOF

cat > app/src/main/java/com/example/xtreamplayer/MainActivity.kt <<'EOF'
package com.example.xtreamplayer

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource

// Basit single-Activity örneği: M3U entry listesi, ExoPlayer ile oynatma, favori, 3 mod
class MainActivity : AppCompatActivity() {

    private lateinit var playerView: PlayerView
    private var player: ExoPlayer? = null
    private lateinit var listStreams: RecyclerView
    private lateinit var btnMode: Button
    private lateinit var btnFav: Button
    private lateinit var btnLogout: Button
    private lateinit var topBanner: TextView

    private lateinit var prefs: SharedPreferences

    private var modeIndex = 0 // 0: normal, 1: square, 2: full
    private var currentStream: M3UEntry? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        prefs = getSharedPreferences("xtream_prefs", Context.MODE_PRIVATE)

        playerView = findViewById(R.id.playerView)
        listStreams = findViewById(R.id.listStreams)
        btnMode = findViewById(R.id.btnMode)
        btnFav = findViewById(R.id.btnFav)
        btnLogout = findViewById(R.id.btnLogout)
        topBanner = findViewById(R.id.topBanner)

        listStreams.layoutManager = LinearLayoutManager(this)
        val adapter = StreamsAdapter { entry -> onStreamClicked(entry) }
        listStreams.adapter = adapter

        // Demo: Basit M3U örneği (birkaç satır)
        val sampleM3U = listOf(
            M3UEntry(
                title = "Al Hilal Riyadh - Al Nassr",
                url = "https://ogr.d72577a9dd0ec6.sbs/yayinex1.m3u8",
                group = "20:30",
                tvgName = "Al Hilal Riyadh - Al Nassr",
                headers = mapOf("Referer" to "https://trgoals1491.xyz/", "Origin" to "https://trgoals1491.xyz")
            ),
            M3UEntry(
                title = "Demo Stream (no headers)",
                url = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8",
                group = "Demo",
                tvgName = "Demo",
                headers = emptyMap()
            )
        )

        (listStreams.adapter as StreamsAdapter).submitList(sampleM3U)

        btnMode.setOnClickListener {
            modeIndex = (modeIndex + 1) % 3
            applyMode()
        }

        btnFav.setOnClickListener {
            toggleFavorite()
        }

        btnLogout.setOnClickListener {
            // basit logout: prefs temizle
            prefs.edit().clear().apply()
            // uygulama durumunu sıfırla
            currentStream = null
            player?.stop()
        }
    }

    private fun onStreamClicked(entry: M3UEntry) {
        currentStream = entry
        playStream(entry.url, entry.headers)
    }

    private fun playStream(url: String, headers: Map<String, String>) {
        releasePlayer()
        // ExoPlayer oluştur
        val httpDataSourceFactory = DefaultHttpDataSource.Factory()
        if (headers.isNotEmpty()) {
            httpDataSourceFactory.setDefaultRequestProperties(headers)
        }
        player = ExoPlayer.Builder(this).build()
        playerView.player = player
        val mediaItem = MediaItem.Builder()
            .setUri(Uri.parse(url))
            .build()
        player?.setMediaItem(mediaItem)
        player?.prepare()
        player?.play()
    }

    private fun releasePlayer() {
        player?.release()
        player = null
    }

    private fun applyMode() {
        val params = playerView.layoutParams
        when (modeIndex) {
            0 -> { // normal
                params.height = (240 * resources.displayMetrics.density).toInt()
                playerView.layoutParams = params
            }
            1 -> { // square
                val w = resources.displayMetrics.widthPixels
                params.width = w
                params.height = w
                playerView.layoutParams = params
            }
            2 -> { // full (zoom)
                params.width = ViewGroup.LayoutParams.MATCH_PARENT
                params.height = ViewGroup.LayoutParams.MATCH_PARENT
                playerView.layoutParams = params
                // gizle actionbar vb istersen immersive mod eklenebilir
            }
        }
    }

    private fun toggleFavorite() {
        val url = currentStream?.url ?: return
        val set = prefs.getStringSet("favorites", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        if (set.contains(url)) {
            set.remove(url)
        } else {
            set.add(url)
        }
        prefs.edit().putStringSet("favorites", set).apply()
    }

    override fun onStop() {
        super.onStop()
        releasePlayer()
    }
}

// Basit M3U entry data class
data class M3UEntry(
    val title: String,
    val url: String,
    val group: String = "",
    val tvgName: String = "",
    val headers: Map<String, String> = emptyMap()
)

// Basit RecyclerView adapter
class StreamsAdapter(
    private val onClick: (M3UEntry) -> Unit
) : RecyclerView.Adapter<StreamsAdapter.VH>() {

    private val items = mutableListOf<M3UEntry>()

    fun submitList(list: List<M3UEntry>) {
        items.clear()
        items.addAll(list)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val v = LayoutInflater.from(parent.context).inflate(android.R.layout.simple_list_item_2, parent, false)
        return VH(v)
    }

    override fun onBindViewHolder(holder: VH, position: Int) {
        val item = items[position]
        holder.title.text = item.title
        holder.sub.text = item.group
        holder.itemView.setOnClickListener { onClick(item) }
    }

    override fun getItemCount(): Int = items.size

    class VH(v: View) : RecyclerView.ViewHolder(v) {
        val title: TextView = v.findViewById(android.R.id.text1)
        val sub: TextView = v.findViewById(android.R.id.text2)
    }
}
EOF

cat > scripts/build.sh <<'EOF'
#!/usr/bin/env bash
# scripts/build.sh
# Tek parametreli basit build runner. Paket adı, versiyon, icon, build variant parametrelerini sed ile uygular.
# Kullanım:
#   ./scripts/build.sh <PACKAGE_NAME> <VERSION_NAME> <VERSION_CODE> <ICON_URL> <BUILD_VARIANT>
set -euo pipefail

PACKAGE_NAME="${1:-com.example.xtreamplayer}"
VERSION_NAME="${2:-1.0.0}"
VERSION_CODE="${3:-1}"
ICON_URL="${4:-}"
BUILD_VARIANT="${5:-release}"

echo "Running build.sh with:"
echo "  PACKAGE_NAME=${PACKAGE_NAME}"
echo "  VERSION_NAME=${VERSION_NAME}"
echo "  VERSION_CODE=${VERSION_CODE}"
echo "  ICON_URL=${ICON_URL}"
echo "  BUILD_VARIANT=${BUILD_VARIANT}"

# Update applicationId, versionName, versionCode in app/build.gradle (simple sed replacement)
if [ -f app/build.gradle ]; then
  cp app/build.gradle app/build.gradle.bak
  sed -E "s/applicationId \"[^\"]+\"/applicationId \"${PACKAGE_NAME}\"/" app/build.gradle.bak > app/build.gradle.tmp || true
  sed -E "s/versionName [^\n]*/versionName \"${VERSION_NAME}\"/" app/build.gradle.tmp > app/build.gradle.tmp2 || true
  sed -E "s/versionCode [0-9]+/versionCode ${VERSION_CODE}/" app/build.gradle.tmp2 > app/build.gradle || true
  rm -f app/build.gradle.tmp app/build.gradle.tmp2 || true
fi

# Icon download (kopyala mipmap ic_launcher*.png üzerine yaz if exists)
if [ -n "${ICON_URL}" ]; then
  echo "Downloading icon from ${ICON_URL}"
  tmpdir="$(mktemp -d)"
  curl -fsSL "${ICON_URL}" -o "${tmpdir}/icon.png" || echo "Icon download failed, skipping."
  if [ -f "${tmpdir}/icon.png" ]; then
    echo "Replacing ic_launcher images if present..."
    find app/src/main/res -type f -name "ic_launcher*.png" -exec cp "${tmpdir}/icon.png" {} \; || true
  fi
  rm -rf "${tmpdir}"
fi

# Run gradle build (systemde gradle yüklü olmalı veya wrapper olmalı)
if [ -f ./gradlew ]; then
  ./gradlew clean assemble${BUILD_VARIANT^} --no-daemon
else
  echo "Gradle wrapper bulunamadı. Sistemde gradle varsa çalıştırılacak."
  gradle clean assemble${BUILD_VARIANT^} --no-daemon
fi

echo "Build script finished. Check app/build/outputs for artifacts."
EOF

chmod +x scripts/build.sh

cat > panel/trigger_build.php <<'EOF'
<?php
// panel/trigger_build.php
// Panel tarafından çağrılacak örnek: GitHub Actions workflow_dispatch tetikleyicisi.
// POST JSON örneği:
// {
//   "repo_owner": "owner",
//   "repo_name": "repo",
//   "workflow_id": "android-build.yml",
//   "ref": "main",
//   "inputs": { "app_id":"1", "package_name":"com.example.xtream", ... }
// }
// Gereksinim: GITHUB_TOKEN panelde environment veya server config olarak tanımlanmalı

header('Content-Type: application/json');

$raw = file_get_contents('php://input');
if (!$raw) {
    http_response_code(400);
    echo json_encode(['error'=>'No payload']);
    exit;
}
$payload = json_decode($raw, true); 
if (!$payload) {
    http_response_code(400);
    echo json_encode(['error'=>'Invalid JSON']);
    exit;
}

$owner = $payload['repo_owner'] ?? '';
$repo = $payload['repo_name'] ?? '';
$workflow_id = $payload['workflow_id'] ?? 'android-build.yml';
$ref = $payload['ref'] ?? 'main';
$inputs = $payload['inputs'] ?? [];

if (!$owner || !$repo) {
    http_response_code(400);
    echo json_encode(['error'=>'repo_owner and repo_name required']);
    exit;
}

$token = getenv('GITHUB_TOKEN');
if (!$token) {
    http_response_code(500);
    echo json_encode(['error'=>'Server misconfiguration: GITHUB_TOKEN not set']);
    exit;
}

$url = "https://api.github.com/repos/{$owner}/{$repo}/actions/workflows/{$workflow_id}/dispatches";
$data = [
    'ref' => $ref,
    'inputs' => $inputs
];

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_USERAGENT, 'panel-trigger');
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Authorization: token {$token}",
    "Accept: application/vnd.github.v3+json",
    "Content-Type: application/json"
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));

$response = curl_exec($ch);
$httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$err = curl_error($ch);
curl_close($ch);

if ($err) {
    http_response_code(500);
    echo json_encode(['error' => $err]);
    exit;
}

if ($httpcode >= 200 && $httpcode < 300) {
    echo json_encode(['status'=>'dispatched','http_code'=>$httpcode]);
} else {
    http_response_code($httpcode);
    echo json_encode(['status'=>'error','http_code'=>$httpcode,'response'=>$response]);
}
EOFv

# Make created files readable/executable where appropriate
chmod -R u+rw .

echo "All files created."
echo ""
echo "Next steps:"
echo "  1) Open the created project in Android Studio or run the build script:"
echo "       ./scripts/build.sh com.example.xtreamplayer 1.0.0 1 '' debug"
echo "  2) Configure keystore/signing if you want release builds."
echo "  3) For CI: commit this repo and configure GitHub Actions workflow to call scripts/build.sh (example workflow provided previously)."
echo ""
echo "Script finished."
