#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="xtream-player"
echo "Creating project in ./${ROOT_DIR}"
rm -rf "${ROOT_DIR}"
mkdir -p "${ROOT_DIR}"

# Create backend
mkdir -p "${ROOT_DIR}/backend"

cat > "${ROOT_DIR}/backend/get_channels.php" <<'EOF'
<?php
// Basit prototype: POST { server, username, password }
// Döndürülen format Xtream-style player_api.php?action=get_live_streams ise JSON'ı direkt dönebilir.
// Bu örnek, CORS ve basit hata kontrolü içerir.

header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
if (!$input) {
    echo json_encode(['success' => false, 'message' => 'Invalid JSON']);
    exit;
}
$server = rtrim($input['server'] ?? '', '/');
$username = $input['username'] ?? '';
$password = $input['password'] ?? '';

if (!$server || !$username || !$password) {
    echo json_encode(['success' => false, 'message' => 'Missing parameters']);
    exit;
}

// Xtream-style API: /player_api.php?username=..&password=..&action=get_live_streams
$apiUrl = "http://{$server}/player_api.php?username=" . urlencode($username) . "&password=" . urlencode($password) . "&action=get_live_streams";

$ch = curl_init($apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
$response = curl_exec($ch);
$err = curl_error($ch);
$httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($err) {
    echo json_encode(['success' => false, 'message' => 'Curl error: ' . $err]);
    exit;
}
if ($httpcode !== 200) {
    echo json_encode(['success' => false, 'message' => 'Upstream returned HTTP ' . $httpcode]);
    exit;
}

// Xtream returns JSON for many servers; try to decode and forward
$decoded = json_decode($response, true);
if ($decoded !== null) {
    echo json_encode(['success' => true, 'data' => $decoded]);
} else {
    // Eğer düz text (ör. m3u) döndüyse ham veriyi gönder
    echo json_encode(['success' => true, 'data_raw' => $response]);
}
EOF

cat > "${ROOT_DIR}/backend/get_stream.php" <<'EOF'
<?php
// POST { server, username, password, stream_id }
// Basit prototype: bazı Xtream sağlayıcılarında stream URL şablonu:
// http://{server}/live/{username}/{password}/{stream_id}.m3u8
// Alternatif olarak player_api.php ile bilgi alınabilir.
// Bu endpoint stream URL'sini döner.

header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
$server = rtrim($input['server'] ?? '', '/');
$username = $input['username'] ?? '';
$password = $input['password'] ?? '';
$stream_id = $input['stream_id'] ?? '';

if (!$server || !$username || !$password || !$stream_id) {
    echo json_encode(['success' => false, 'message' => 'Missing parameters']);
    exit;
}

// Bu örnekte önce tipik şablonu deniyoruz:
$possible = [];

// 1) Typical Xtream m3u8 pattern:
$possible[] = "http://{$server}/live/{$username}/{$password}/{$stream_id}.m3u8";
// 2) Another common: /live/{username}/{password}/{stream_id}.ts
$possible[] = "http://{$server}/live/{$username}/{$password}/{$stream_id}.ts";

// Basit test ile ilk çalışan URL'yi döndür
$found = null;
foreach ($possible as $url) {
    $headers = @get_headers($url);
    if ($headers && strpos($headers[0], '200') !== false) {
        $found = $url;
        break;
    }
}

if ($found) {
    echo json_encode(['success' => true, 'stream_url' => $found]);
    exit;
}

// Eğer bulamadıysak, denemek için player_api dan daha fazla bilgi isteyebiliriz:
$apiUrl = "http://{$server}/player_api.php?username=" . urlencode($username) . "&password=" . urlencode($password) . "&action=get_live_streams";
$ch = curl_init($apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
$response = curl_exec($ch);
curl_close($ch);
$decoded = json_decode($response, true);
if ($decoded && isset($decoded['channels']) && is_array($decoded['channels'])) {
    foreach ($decoded['channels'] as $c) {
        if (isset($c['stream_id']) && (string)$c['stream_id'] === (string)$stream_id) {
            // Eğer doğrudan bir stream_url varsa dönebilir
            if (!empty($c['stream_url'])) {
                echo json_encode(['success' => true, 'stream_url' => $c['stream_url']]);
                exit;
            }
        }
    }
}

echo json_encode(['success' => false, 'message' => 'Stream URL not found. You may need to adapt backend for your provider.']);
EOF

# Create Android skeleton
mkdir -p "${ROOT_DIR}/android/app/src/main/java/com/example/xtreamplayer/network"
mkdir -p "${ROOT_DIR}/android/app/src/main/java/com/example/xtreamplayer"
mkdir -p "${ROOT_DIR}/android/app/src/main/res"
mkdir -p "${ROOT_DIR}/android/app/src/main"

cat > "${ROOT_DIR}/android/app/src/main/AndroidManifest.xml" <<'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.xtreamplayer">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:label="XtreamPlayer"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">
        <activity android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

cat > "${ROOT_DIR}/android/app/build.gradle" <<'EOF'
plugins {
    id 'com.android.application'
    id 'kotlin-android'
}

android {
    compileSdk 34
    defaultConfig {
        applicationId "com.example.xtreamplayer"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "0.1"
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib:1.8.0"
    implementation 'com.google.android.exoplayer:exoplayer:2.20.2'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.squareup.okhttp3:logging-interceptor:4.9.3'
    implementation 'androidx.recyclerview:recyclerview:1.3.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.8.0'
}
EOF

cat > "${ROOT_DIR}/android/app/src/main/java/com/example/xtreamplayer/network/ApiService.kt" <<'EOF'
package com.example.xtreamplayer.network

import retrofit2.Call
import retrofit2.http.Body
import retrofit2.http.Headers
import retrofit2.http.POST

data class Credentials(val server: String, val username: String, val password: String)
data class ChannelsResponse(val success: Boolean, val data: Any?)
data class StreamResponse(val success: Boolean, val stream_url: String?)

interface ApiService {
    @Headers("Content-Type: application/json")
    @POST("api/get_channels.php")
    fun getChannels(@Body creds: Credentials): Call<ChannelsResponse>

    @Headers("Content-Type: application/json")
    @POST("api/get_stream.php")
    fun getStream(@Body body: Map<String, String>): Call<StreamResponse>
}
EOF

cat > "${ROOT_DIR}/android/app/src/main/java/com/example/xtreamplayer/MainActivity.kt" <<'EOF'
package com.example.xtreamplayer

import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import com.example.xtreamplayer.network.ApiService
import com.example.xtreamplayer.network.Credentials
import com.example.xtreamplayer.network.StreamResponse
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import retrofit2.*
import retrofit2.converter.gson.GsonConverterFactory

class MainActivity : AppCompatActivity() {

    private lateinit var player: ExoPlayer
    private val BASE_URL = "https://YOUR_BACKEND_DOMAIN/" // <- burayı değiştir

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Basit UI programatik (hızlı prototip)
        val layout = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(16,16,16,16) }
        val etServer = EditText(this); etServer.hint = "server (host veya ip)"
        val etUser = EditText(this); etUser.hint = "username"
        val etPass = EditText(this); etPass.hint = "password"
        val btnFetch = Button(this); btnFetch.text = "Kanal Listesini Getir"
        val listView = ListView(this)
        val playerView = com.google.android.exoplayer2.ui.PlayerView(this)
        layout.addView(etServer); layout.addView(etUser); layout.addView(etPass); layout.addView(btnFetch)
        layout.addView(listView, LinearLayout.LayoutParams.MATCH_PARENT, 500)
        layout.addView(playerView, LinearLayout.LayoutParams.MATCH_PARENT, 600)
        setContentView(layout)

        // Retrofit
        val retrofit = retrofit2.Retrofit.Builder()
            .baseUrl(BASE_URL)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
        val api = retrofit.create(ApiService::class.java)

        btnFetch.setOnClickListener {
            val server = etServer.text.toString().trim()
            val user = etUser.text.toString().trim()
            val pass = etPass.text.toString().trim()
            if (server.isEmpty() || user.isEmpty() || pass.isEmpty()) {
                Toast.makeText(this, "Lütfen tüm alanları doldurun", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val call = api.getChannels(Credentials(server, user, pass))
            call.enqueue(object: Callback<com.example.xtreamplayer.network.ChannelsResponse> {
                override fun onResponse(call: Call<com.example.xtreamplayer.network.ChannelsResponse>, response: Response<com.example.xtreamplayer.network.ChannelsResponse>) {
                    val body = response.body()
                    if (body?.success == true) {
                        // Basit: eğer data.channels varsa listele; değilse ham veriyi göster
                        val items = mutableListOf<String>()
                        items.add("Kanal listesi alındı. (Uygulamayı özelleştir)")
                        val adapter = ArrayAdapter(this@MainActivity, android.R.layout.simple_list_item_1, items)
                        listView.adapter = adapter
                        listView.setOnItemClickListener { _, _, position, _ ->
                            // Örnek stream request
                            // Bu prototipte stream_id bilinmediği için sabit bir ID kullanmıyoruz.
                            Toast.makeText(this@MainActivity, "Kanal seçildi: $position", Toast.LENGTH_SHORT).show()
                        }
                    } else {
                        Toast.makeText(this@MainActivity, "Kanal alınamadı: ${body?.toString()}", Toast.LENGTH_LONG).show()
                    }
                }
                override fun onFailure(call: Call<com.example.xtreamplayer.network.ChannelsResponse>, t: Throwable) {
                    Toast.makeText(this@MainActivity, "Hata: ${t.message}", Toast.LENGTH_LONG).show()
                }
            })
        }

        player = ExoPlayer.Builder(this).build()
        playerView.player = player
    }

    override fun onDestroy() {
        super.onDestroy()
        player.release()
    }
}
EOF

# README
cat > "${ROOT_DIR}/README.md" <<'EOF'
# Xtream Android Player — Minimal MVP

Bu repo iki parçalıdır:
- backend/: Basit PHP API (get_channels.php, get_stream.php) — Xtream-style sağlayıcılarla konuşur.
- android/: Android Kotlin uygulaması — Retrofit ile backend'e istek atar ve ExoPlayer ile oynatır.

Hızlı kurulum (backend)
1. Bir VPS/hosting hazırla (PHP 7.4+).
2. `backend/` içeriğini sunucunun public dizinine kopyala.
3. Sunucu üzerinde HTTPS (Let'sEncrypt) kur.
4. Tarayıcıdan `https://your-server/api/get_channels.php` gibi çağrı yapabilirsin.

Hızlı kurulum (android)
1. Android Studio aç, `android/` dizinini projeyi aç olarak seç.
2. `MainActivity` içindeki `BASE_URL` değişkenini backend sunucuna göre güncelle.
3. Gradle sync / build.

Güvenlik uyarısı: Bu örnek prototip için basitçe sağlayıcı kimlik bilgileri backend'e gönderilmektedir. Production için:
- Kimlik bilgilerini şifreleyin, backend'de saklayın, kısa ömürlü token verin veya streaming'i proxyleyin.
- Tüm istekler HTTPS üzerinden olsun.
EOF

# Initialize git and commit
cd "${ROOT_DIR}"
git init -q
git add -A
git commit -m "Initial MVP skeleton: backend PHP + Android skeleton" -q

echo "Project created at ./${ROOT_DIR} and initial commit made."
echo
echo "Next steps:"
echo "1) Edit android/app/src/main/java/com/example/xtreamplayer/MainActivity.kt -> set BASE_URL to your backend domain (must end with /)."
echo "2) Deploy backend/*.php to your PHP hosting (use HTTPS)."
echo "3) Open android/ in Android Studio, run Gradle sync and build."
echo
echo "If you want, I can help create a GitHub repo and push this. Provide the remote git URL or repo name (and whether to create it), and I will give you the exact git push commands or guide you through adding the remote."
EOF
