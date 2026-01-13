#!/usr/bin/env bash
# create_erdinxplayer.sh
# Tek betikle ERDINXPLAYER Android proje iskeleti oluşturur.
# Uygulama: ERDİNXPLAYER
# Paket: com.erdin.xplay
# Versiyon: 1.0 (versionCode 1)
#
# Kullanım:
#   chmod +x create_erdinxplayer.sh
#   ./create_erdinxplayer.sh
set -euo pipefail

APP_NAME="ERDINXPLAYER"
PKG="com.erdin.xplay"
PKG_DIR=${PKG//./\/}
ROOT_DIR="$(pwd)/${APP_NAME}"
APP_MODULE_DIR="${ROOT_DIR}/app"

echo "Projeyi oluşturuyorum: ${ROOT_DIR}"

# Dizin yapısını oluştur
mkdir -p "${APP_MODULE_DIR}/src/main/java/${PKG_DIR}"
mkdir -p "${APP_MODULE_DIR}/src/main/res/layout"
mkdir -p "${APP_MODULE_DIR}/src/main/res/values"
mkdir -p "${APP_MODULE_DIR}/src/main/assets"
mkdir -p "${APP_MODULE_DIR}/src/main"

# settings.gradle
cat > "${ROOT_DIR}/settings.gradle" <<'EOF'
rootProject.name = "ERDINXPLAYER"
include(":app")
EOF

# gradle.properties
cat > "${ROOT_DIR}/gradle.properties" <<'EOF'
org.gradle.jvmargs=-Xmx1536m
android.useAndroidX=true
android.enableJetifier=true
EOF

# build.gradle (project)
cat > "${ROOT_DIR}/build.gradle" <<'EOF'
buildscript {
    ext.kotlin_version = "1.9.0"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.1.0"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:\$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOF

# app module build.gradle
cat > "${APP_MODULE_DIR}/build.gradle" <<EOF
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace "${PKG}"
    compileSdk 33

    defaultConfig {
        applicationId "${PKG}"
        minSdk 21
        targetSdk 33
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib:1.9.0"
    implementation 'androidx.core:core-ktx:1.10.1'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.0'

    // ExoPlayer
    implementation 'com.google.android.exoplayer:exoplayer:2.18.7'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.18.7'

    // Networking
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'

    // Coroutines
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
}
EOF

# AndroidManifest.xml
cat > "${APP_MODULE_DIR}/src/main/AndroidManifest.xml" <<EOF
<manifest package="${PKG}" xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:allowBackup="true"
        android:label="ERDİNXPLAYER"
        android:supportsRtl="true"
        android:theme="@style/Theme.App">
        <activity android:name=".PlayerActivity" />
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# MainActivity.kt
cat > "${APP_MODULE_DIR}/src/main/java/${PKG_DIR}/MainActivity.kt" <<EOF
package ${PKG}

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.*
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.BufferedReader
import java.io.StringReader

class MainActivity : AppCompatActivity() {
    private val client = OkHttpClient()
    private val scope = CoroutineScope(Dispatchers.Main + Job())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val urlInput = findViewById<EditText>(R.id.editTextUrl)
        val fetchBtn = findViewById<Button>(R.id.buttonFetch)
        val progress = findViewById<ProgressBar>(R.id.progressBar)
        val recycler = findViewById<RecyclerView>(R.id.recyclerView)
        recycler.layoutManager = LinearLayoutManager(this)

        val adapter = ChannelAdapter { channelUrl ->
            val intent = Intent(this, PlayerActivity::class.java)
            intent.putExtra("url", channelUrl)
            startActivity(intent)
        }
        recycler.adapter = adapter

        fetchBtn.setOnClickListener {
            val url = urlInput.text.toString().trim()
            if (url.isEmpty()) {
                Toast.makeText(this, "M3U veya Xtream URL girin", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            progress.visibility = View.VISIBLE
            scope.launch {
                val list = withContext(Dispatchers.IO) { fetchM3U(url) }
                progress.visibility = View.GONE
                if (list.isEmpty()) {
                    Toast.makeText(this@MainActivity, "Hiç kanal bulunamadı veya hata", Toast.LENGTH_SHORT).show()
                } else {
                    adapter.submitList(list)
                }
            }
        }

        // Örnek bir test M3U (kullanıcı değiştirebilir)
        urlInput.setText("https://example.com/playlist.m3u")
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    private fun fetchM3U(url: String): List<Channel> {
        try {
            val req = Request.Builder().url(url).build()
            client.newCall(req).execute().use { res ->
                if (!res.isSuccessful) return emptyList()
                val body = res.body?.string() ?: return emptyList()
                return parseM3U(body)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            return emptyList()
        }
    }

    private fun parseM3U(content: String): List<Channel> {
        val reader = BufferedReader(StringReader(content))
        val channels = mutableListOf<Channel>()
        var line: String?
        var lastTitle: String? = null
        while (true) {
            line = reader.readLine() ?: break
            val trimmed = line.trim()
            if (trimmed.startsWith("#EXTINF:", true)) {
                val comma = trimmed.indexOf(',')
                lastTitle = if (comma >= 0 && comma + 1 < trimmed.length) trimmed.substring(comma + 1).trim() else "Untitled"
            } else if (trimmed.startsWith("http", true) || trimmed.startsWith("udp", true)) {
                val urlLine = trimmed
                val title = lastTitle ?: urlLine
                channels.add(Channel(title, urlLine))
                lastTitle = null
            }
        }
        return channels
    }
}

data class Channel(val name: String, val url: String)
EOF

# ChannelAdapter.kt
cat > "${APP_MODULE_DIR}/src/main/java/${PKG_DIR}/ChannelAdapter.kt" <<EOF
package ${PKG}

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView

class ChannelAdapter(private val click: (String) -> Unit) :
    ListAdapter<Channel, ChannelAdapter.VH>(DIFF) {

    companion object {
        val DIFF = object : DiffUtil.ItemCallback<Channel>() {
            override fun areItemsTheSame(oldItem: Channel, newItem: Channel) = oldItem.url == newItem.url
            override fun areContentsTheSame(oldItem: Channel, newItem: Channel) = oldItem == newItem
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val v = LayoutInflater.from(parent.context).inflate(R.layout.item_channel, parent, false)
        return VH(v)
    }

    override fun onBindViewHolder(holder: VH, position: Int) {
        holder.bind(getItem(position))
    }

    inner class VH(view: View) : RecyclerView.ViewHolder(view) {
        private val title = view.findViewById<TextView>(R.id.channelTitle)
        init {
            view.setOnClickListener {
                val ch = getItem(bindingAdapterPosition)
                click(ch.url)
            }
        }
        fun bind(c: Channel) {
            title.text = c.name
        }
    }
}
EOF

# PlayerActivity.kt
cat > "${APP_MODULE_DIR}/src/main/java/${PKG_DIR}/PlayerActivity.kt" <<EOF
package ${PKG}

import android.net.Uri
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.ui.PlayerView

class PlayerActivity : AppCompatActivity() {
    private var player: ExoPlayer? = null
    private var playerView: PlayerView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_player)
        playerView = findViewById(R.id.playerView)

        val url = intent.getStringExtra("url") ?: return
        player = ExoPlayer.Builder(this).build()
        playerView?.player = player
        val mediaItem = MediaItem.fromUri(Uri.parse(url))
        player?.setMediaItem(mediaItem)
        player?.prepare()
        player?.playWhenReady = true
    }

    override fun onStop() {
        super.onStop()
        player?.release()
        player = null
    }
}
EOF

# Layouts
cat > "${APP_MODULE_DIR}/src/main/res/layout/activity_main.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent" >

    <EditText
        android:id="@+id/editTextUrl"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:hint="M3U URL veya Xtream M3U URL"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toStartOf="@+id/buttonFetch"
        android:padding="12dp"
        android:layout_margin="12dp"/>

    <Button
        android:id="@+id/buttonFetch"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Getir"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_margin="12dp"/>

    <ProgressBar
        android:id="@+id/progressBar"
        android:layout_width="40dp"
        android:layout_height="40dp"
        android:visibility="gone"
        app:layout_constraintTop_toBottomOf="@+id/editTextUrl"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_margin="12dp"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/recyclerView"
        android:layout_width="0dp"
        android:layout_height="0dp"
        app:layout_constraintTop_toBottomOf="@+id/editTextUrl"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_margin="8dp"/>
</androidx.constraintlayout.widget.ConstraintLayout>
EOF

cat > "${APP_MODULE_DIR}/src/main/res/layout/item_channel.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="56dp"
    android:padding="8dp">

    <TextView
        android:id="@+id/channelTitle"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:text="Channel name"
        android:textSize="16sp"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"/>
</androidx.constraintlayout.widget.ConstraintLayout>
EOF

cat > "${APP_MODULE_DIR}/src/main/res/layout/activity_player.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <com.google.android.exoplayer2.ui.PlayerView
        android:id="@+id/playerView"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:use_controller="true"/>
</FrameLayout>
EOF

# values
cat > "${APP_MODULE_DIR}/src/main/res/values/strings.xml" <<EOF
<resources>
    <string name="app_name">${APP_NAME}</string>
</resources>
EOF

cat > "${APP_MODULE_DIR}/src/main/res/values/styles.xml" <<'EOF'
<resources>
    <style name="Theme.App" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <!-- Customize your theme here. -->
    </style>
</resources>
EOF

# proguard
cat > "${APP_MODULE_DIR}/proguard-rules.pro" <<EOF
# Add proguard rules if needed
EOF

# README
cat > "${ROOT_DIR}/README.md" <<EOF
# ERDİNXPLAYER (scaffold)
- Paket: ${PKG}
- Uygulama: ${APP_NAME}
- Basit M3U / Xtream destekli demo player
- ExoPlayer ile oynatma
- Oluşturmak için: chmod +x create_erdinxplayer.sh && ./create_erdinxplayer.sh
- Lokal geliştirme: projeye girdikten sonra 'gradle wrapper' ile wrapper oluşturup commit etmek en iyisidir.
EOF

# Eğer yerelde gradle varsa wrapper oluşturmaya çalış
if command -v gradle >/dev/null 2>&1; then
  echo "Gradle bulundu; ERDINXPLAYER dizininde gradle wrapper oluşturuluyor..."
  (cd "${ROOT_DIR}" && gradle wrapper) || true
  if [ -f "${ROOT_DIR}/gradlew" ]; then
    chmod +x "${ROOT_DIR}/gradlew" || true
    echo "gradlew oluşturuldu ve executable yapıldı."
  fi
else
  echo "Sistemde 'gradle' komutu yok. İstersen kendin 'cd ${ROOT_DIR} && gradle wrapper' ile wrapper oluştur."
fi

echo "İşlem tamamlandı. Proje konumu: ${ROOT_DIR}"
echo "Projeyi derlemek için (yerel):"
echo "  cd \"${ROOT_DIR}\""
echo "  ./gradlew assembleDebug   # (eğer gradlew varsa) veya gradle assembleDebug"
