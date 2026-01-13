#!/bin/bash
# create_project.sh - Kotlin Xtream/M3U Player temel yapı

PACKAGE="com.santra.tv.player"
APP_NAME="Santra TV Player"
MIN_SDK=24
TARGET_SDK=35
COMPILE_SDK=35

mkdir -p app/src/main/kotlin/com/santra/tv/player
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/drawable

# AndroidManifest.xml
cat << EOF > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PACKAGE">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:icon="@drawable/ic_launcher"
        android:label="$APP_NAME"
        android:roundIcon="@drawable/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.SantraTV">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name=".LoginActivity" />
        <activity android:name=".PlayerActivity"
            android:configChanges="orientation|screenSize|keyboardHidden|uiMode" />
    </application>

</manifest>
EOF

# res/values/themes.xml (renkler: koyu gri, spor yeşili, bordo)
cat << EOF > app/src/main/res/values/themes.xml
<resources xmlns:tools="http://schemas.android.com/tools">
    <style name="Theme.SantraTV" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <item name="colorPrimary">#4CAF50</item>         <!-- spor yeşili -->
        <item name="colorPrimaryVariant">#2E7D32</item>
        <item name="colorOnPrimary">#FFFFFF</item>
        <item name="colorSecondary">#B71C1C</item>      <!-- bordo -->
        <item name="colorSecondaryVariant">#7F0000</item>
        <item name="colorOnSecondary">#FFFFFF</item>
        <item name="android:statusBarColor">#2D2D2D</item> <!-- koyu gri -->
        <item name="android:windowBackground">#2D2D2D</item>
    </style>
</resources>
EOF

# res/values/colors.xml
cat << EOF > app/src/main/res/values/colors.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="dark_gray">#2D2D2D</color>
    <color name="sport_green">#4CAF50</color>
    <color name="maroon">#B71C1C</color>
</resources>
EOF

# res/layout/activity_main.xml (basit giriş seçimi)
cat << EOF > app/src/main/res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@color/dark_gray"
    android:padding="16dp">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="@string/app_name"
        android:textColor="@color/sport_green"
        android:textSize="28sp"
        android:layout_gravity="center"
        android:layout_marginBottom="32dp"/>

    <Button
        android:id="@+id/btn_xtream"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Xtream Codes Giriş"
        android:backgroundTint="@color/sport_green"/>

    <Button
        android:id="@+id/btn_m3u"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="M3U Playlist Giriş"
        android:backgroundTint="@color/maroon"
        android:layout_marginTop="16dp"/>

    <!-- Banner reklam alanı -->
    <com.google.android.gms.ads.AdView
        android:id="@+id/ad_banner"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom"
        android:visibility="gone"/>
</LinearLayout>
EOF

# LoginActivity.kt (Xtream giriş + kaydet)
cat << EOF > app/src/main/kotlin/com/santra/tv/player/LoginActivity.kt
package com.santra.tv.player

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class LoginActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)  // ayrı xml oluşturabilirsin

        val etUrl = findViewById<EditText>(R.id.et_url)
        val etUser = findViewById<EditText>(R.id.et_username)
        val etPass = findViewById<EditText>(R.id.et_password)
        val btnLogin = findViewById<Button>(R.id.btn_login)

        val prefs = getSharedPreferences("prefs", Context.MODE_PRIVATE)

        // Kaydedilmiş varsa doldur
        etUrl.setText(prefs.getString("xt_url", ""))
        etUser.setText(prefs.getString("xt_user", ""))
        etPass.setText(prefs.getString("xt_pass", ""))

        btnLogin.setOnClickListener {
            val url = etUrl.text.toString()
            val user = etUser.text.toString()
            val pass = etPass.text.toString()

            if (url.isNotEmpty() && user.isNotEmpty() && pass.isNotEmpty()) {
                prefs.edit()
                    .putString("xt_url", url)
                    .putString("xt_user", user)
                    .putString("xt_pass", pass)
                    .apply()
                Toast.makeText(this, "Kaydedildi", Toast.LENGTH_SHORT).show()
                startActivity(Intent(this, MainActivity::class.java))
                finish()
            } else {
                Toast.makeText(this, "Tüm alanları doldur", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
EOF

# PlayerActivity.kt (ExoPlayer + referrer/origin + modlar)
cat << EOF > app/src/main/kotlin/com/santra/tv/player/PlayerActivity.kt
package com.santra.tv.player

import android.os.Bundle
import android.view.View
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource

class PlayerActivity : AppCompatActivity() {

    private lateinit var player: ExoPlayer
    private lateinit var playerView: PlayerView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_player)

        playerView = findViewById(R.id.player_view)
        player = ExoPlayer.Builder(this).build()
        playerView.player = player

        val url = intent.getStringExtra("STREAM_URL") ?: return
        val referrer = intent.getStringExtra("REFERRER") ?: ""
        val origin = intent.getStringExtra("ORIGIN") ?: ""

        val headers = mutableMapOf<String, String>()
        if (referrer.isNotEmpty()) headers["Referer"] = referrer
        if (origin.isNotEmpty()) headers["Origin"] = origin
        headers["User-Agent"] = "Mozilla/5.0"

        val dataSourceFactory = DefaultHttpDataSource.Factory()
            .setDefaultRequestProperties(headers)

        val mediaSource = HlsMediaSource.Factory(dataSourceFactory)
            .createMediaSource(MediaItem.fromUri(url))

        player.setMediaSource(mediaSource)
        player.prepare()
        player.play()

        // Mod butonları örnek (kare, full, zoom)
        findViewById<View>(R.id.btn_full).setOnClickListener {
            window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FILL
        }
        findViewById<View>(R.id.btn_zoom).setOnClickListener {
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
        }
        findViewById<View>(R.id.btn_kare).setOnClickListener {
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
        }
    }

    override fun onStop() {
        super.onStop()
        player.release()
    }
}
EOF

# Diğer dosyalar (activity_login.xml, activity_player.xml, strings.xml vs.) için benzer heredoc ekleyebilirsin

echo "Temel yapı oluşturuldu. Şimdi update_configs.sh çalıştır."
