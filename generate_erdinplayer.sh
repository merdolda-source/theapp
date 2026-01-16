#!/bin/bash
set -e

echo "======================================="
echo "     ERDINPLAYER PRO ULTRA GENERATE    "
echo "======================================="

APP_NAME="EerdinPlayer"
PACKAGE_NAME="com.erdin.player"
PATH_NAME="com/erdin/player"

PASS="erdin123"
STORE_PASS="${ANDROID_KEYSTORE_PASSWORD:-$PASS}"
KEY_PASS="${ANDROID_KEY_PASSWORD:-$PASS}"
KEY_ALIAS="${ANDROID_KEY_ALIAS:-key0}"

echo "🚀 EMİN XTREAM Player Projesi Üretiliyor..."

rm -rf "$APP_NAME"
mkdir -p "$APP_NAME/app/src/main/java/$PATH_NAME"
mkdir -p "$APP_NAME/app/src/main/java/$PATH_NAME/models"
mkdir -p "$APP_NAME/app/src/main/java/$PATH_NAME/utils"
mkdir -p "$APP_NAME/app/src/main/java/$PATH_NAME/adapters"
mkdir -p "$APP_NAME/app/src/main/res/layout"
mkdir -p "$APP_NAME/app/src/main/res/values"
mkdir -p "$APP_NAME/app/src/main/res/values-tr"
mkdir -p "$APP_NAME/app/src/main/res/drawable"
mkdir -p "$APP_NAME/app/src/main/res/mipmap-hdpi"
mkdir -p "$APP_NAME/app/src/main/res/color"
mkdir -p "$APP_NAME/app"

cd "$APP_NAME"

# ICON
wget -U "Mozilla/5.0" -O app/src/main/res/mipmap-hdpi/ic_launcher.png "https://i.ibb.co/LDdzzhsk/f564b0ed-277d-489c-9a1a-c59f0fe471fc.png" || true

# KEYSTORE
if [ -n "${ANDROID_KEYSTORE_BASE64}" ]; then
  echo "🔐 Keystore secrets'ten yazılıyor..."
  echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > app/keystore.jks
else
  echo "⚠️ ANDROID_KEYSTORE_BASE64 yok, local keystore üretilecek."
  keytool -genkey -v \
    -keystore app/keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASS" \
    -keypass "$KEY_PASS" \
    -dname "CN=Erdin, O=ErdinMedia, C=TR"
fi

# Gradle config
echo "include ':app'" > settings.gradle

cat <<EOF > gradle.properties
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx2048m
EOF

cat <<EOF > build.gradle
buildscript {
    repositories { google(); mavenCentral() }
    dependencies {
        classpath "com.android.tools.build:gradle:8.0.0"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0"
    }
}
allprojects { repositories { google(); mavenCentral() } }
EOF

# app/build.gradle
cat <<EOF > app/build.gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
}

android {
    namespace "$PACKAGE_NAME"
    compileSdk 34

    defaultConfig {
        applicationId "$PACKAGE_NAME"
        minSdk 24
        targetSdk 35
        versionCode 4
        versionName "1.7.0"
    }

    signingConfigs {
        release {
            storeFile file("keystore.jks")
            storePassword "$STORE_PASS"
            keyAlias "$KEY_ALIAS"
            keyPassword "$KEY_PASS"
        }
    }

    buildTypes {
        release {
            minifyEnabled false
            signingConfig signingConfigs.release
            proguardFiles getDefaultProguardFile("proguard-android-optimize.txt")
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
    implementation "androidx.core:core-ktx:1.9.0"
    implementation "androidx.appcompat:appcompat:1.6.1"
    implementation "com.google.android.material:material:1.9.0"
    implementation "androidx.recyclerview:recyclerview:1.3.0"
    implementation "androidx.constraintlayout:constraintlayout:2.1.4"

    implementation "androidx.media3:media3-exoplayer:1.1.0"
    implementation "androidx.media3:media3-ui:1.1.0"
    implementation "androidx.media3:media3-exoplayer-hls:1.1.0"

    implementation "com.google.android.gms:play-services-ads:23.4.0"
}
EOF

########################################
# RESOURCES
########################################

cat <<EOF > app/src/main/res/values/colors.xml
<resources>
    <color name="bg_dark">#050608</color>
    <color name="accent_green">#00C853</color>
    <color name="bordo">#801336</color>
    <color name="white">#FFFFFF</color>
    <color name="black">#000000</color>
    <color name="gray_800">#1C1C1E</color>
    <color name="error_red">#FF5252</color>
    <color name="hint_yellow">#FFD600</color>
</resources>
EOF

cat <<EOF > app/src/main/res/values/styles.xml
<resources>
    <style name="Theme.ErdinPlayer" parent="Theme.AppCompat.DayNight.NoActionBar">
        <item name="android:windowBackground">@color/bg_dark</item>
        <item name="android:textColor">@color/white</item>
        <item name="colorAccent">@color/accent_green</item>
        <item name="android:windowFullscreen">true</item>
    </style>
</resources>
EOF

cat <<EOF > app/src/main/res/values/strings.xml
<resources>
    <string name="app_name">EMIN XTREAM PLAYER</string>
    <string name="admob_app_id">ca-app-pub-3940256099942544~3347511713</string>
    <string name="admob_banner_test">ca-app-pub-3940256099942544/6300978111</string>
    <string name="admob_interstitial_test">ca-app-pub-3940256099942544/1033173712</string>
</resources>
EOF

cat <<EOF > app/src/main/res/values-tr/strings.xml
<resources>
    <string name="app_name">EMIN XTREAM PLAYER</string>
    <string name="admob_app_id">ca-app-pub-3940256099942544~3347511713</string>
    <string name="admob_banner_test">ca-app-pub-3940256099942544/6300978111</string>
    <string name="admob_interstitial_test">ca-app-pub-3940256099942544/1033173712</string>
</resources>
EOF

# Input background
cat <<EOF > app/src/main/res/drawable/bg_input_dark.xml
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="@color/gray_800"/>
    <corners android:radius="10dp"/>
    <stroke android:width="1dp" android:color="@color/bordo"/>
</shape>
EOF

# Kategori / kanal focus için
cat <<EOF > app/src/main/res/drawable/bg_item_focus.xml
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:state_focused="true">
        <shape>
            <solid android:color="@color/gray_800"/>
            <stroke android:width="2dp" android:color="@color/accent_green"/>
            <corners android:radius="12dp"/>
        </shape>
    </item>
    <item android:state_pressed="true">
        <shape>
            <solid android:color="@color/bordo"/>
            <corners android:radius="12dp"/>
        </shape>
    </item>
    <item>
        <shape>
            <solid android:color="@color/gray_800"/>
            <corners android:radius="12dp"/>
        </shape>
    </item>
</selector>
EOF

########################################
# MODELS
########################################

cat <<EOF > app/src/main/java/$PATH_NAME/models/Models.kt
package $PACKAGE_NAME.models

data class AccountProfile(
    val id: Int,
    val name: String,
    val type: String,   // XTREAM or M3U
    val dns: String?,
    val user: String?,
    val pass: String?,
    val m3u: String?
)

data class Category(
    val category_id: String,
    val category_name: String
)

data class StreamItem(
    val name: String,
    val stream_id: String?,
    val series_id: String?,
    val container_extension: String?,
    val category_id: String?,
    val full_url: String?,
    val referer: String?,
    val origin: String?
)
EOF

########################################
# UTILS: Prefs + AdsHelper
########################################

cat <<EOF > app/src/main/java/$PATH_NAME/utils/Prefs.kt
package $PACKAGE_NAME.utils

import android.content.Context
import $PACKAGE_NAME.models.AccountProfile
import org.json.JSONArray
import org.json.JSONObject

class Prefs(ctx: Context) {
    private val appContext = ctx.applicationContext
    private val p = appContext.getSharedPreferences("EP_Prefs", 0)

    private fun loadArray(): JSONArray {
        val s = p.getString("accounts_json", "[]") ?: "[]"
        return JSONArray(s)
    }

    private fun saveArray(arr: JSONArray) {
        p.edit().putString("accounts_json", arr.toString()).apply()
    }

    fun createXtreamAccount(name: String, dns: String, u: String, ps: String): Int {
        val id = p.getInt("next_id", 1)
        val obj = JSONObject()
        obj.put("id", id)
        obj.put("name", name)
        obj.put("type", "XTREAM")
        obj.put("dns", dns)
        obj.put("user", u)
        obj.put("pass", ps)
        obj.put("m3u", "")

        val arr = loadArray()
        arr.put(obj)
        saveArray(arr)

        p.edit().putInt("next_id", id + 1).putInt("active_id", id).apply()
        return id
    }

    fun createM3uAccount(name: String, m3u: String): Int {
        val id = p.getInt("next_id", 1)
        val obj = JSONObject()
        obj.put("id", id)
        obj.put("name", name)
        obj.put("type", "M3U")
        obj.put("dns", "")
        obj.put("user", "")
        obj.put("pass", "")
        obj.put("m3u", m3u)

        val arr = loadArray()
        arr.put(obj)
        saveArray(arr)

        p.edit().putInt("next_id", id + 1).putInt("active_id", id).apply()
        return id
    }

    fun getAccounts(): List<AccountProfile> {
        val arr = loadArray()
        val list = ArrayList<AccountProfile>()
        var i = 0
        while (i < arr.length()) {
            val o = arr.optJSONObject(i)
            if (o != null) {
                val id = o.optInt("id", 0)
                val name = o.optString("name", "Hesap " + i)
                val type = o.optString("type", "XTREAM")
                val dns = o.optString("dns", null)
                val user = o.optString("user", null)
                val pass = o.optString("pass", null)
                val m3u = o.optString("m3u", null)
                list.add(AccountProfile(id, name, type, dns, user, pass, m3u))
            }
            i++
        }
        return list
    }

    fun deleteAccount(id: Int) {
        val arr = loadArray()
        val newArr = JSONArray()
        var i = 0
        while (i < arr.length()) {
            val o = arr.optJSONObject(i)
            if (o != null && o.optInt("id", 0) != id) {
                newArr.put(o)
            }
            i++
        }
        saveArray(newArr)

        val activeId = p.getInt("active_id", -1)
        if (activeId == id) {
            val remaining = getAccounts()
            val newActive = if (remaining.isNotEmpty()) remaining[0].id else -1
            p.edit().putInt("active_id", newActive).apply()
        }
    }

    fun setActive(id: Int) {
        p.edit().putInt("active_id", id).apply()
    }

    fun getActive(): AccountProfile? {
        val all = getAccounts()
        if (all.isEmpty()) return null
        val activeId = p.getInt("active_id", -1)
        if (activeId <= 0) return all[0]
        return all.find { it.id == activeId } ?: all[0]
    }

    fun getDns(): String = getActive()?.dns ?: ""
    fun getUser(): String = getActive()?.user ?: ""
    fun getPass(): String = getActive()?.pass ?: ""

    fun setLastMode(mode: String) {
        p.edit().putString("last_mode", mode).apply()
    }

    fun getLastMode(): String {
        return p.getString("last_mode", "LIVE") ?: "LIVE"
    }
}
EOF

cat <<EOF > app/src/main/java/$PATH_NAME/utils/AdsHelper.kt
package $PACKAGE_NAME.utils

import android.app.Activity
import android.content.Context
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback
import com.google.android.gms.ads.LoadAdError

object AdsHelper {
    @Volatile
    private var initialized = false

    private var interstitial: InterstitialAd? = null
    private var clickCount = 0
    var CHANNEL_INTERVAL = 4

    fun init(context: Context) {
        if (!initialized) {
            synchronized(this) {
                if (!initialized) {
                    MobileAds.initialize(context.applicationContext) {}
                    initialized = true
                }
            }
        }
    }

    fun loadBanner(adView: AdView?) {
        if (adView == null) return
        val request = AdRequest.Builder().build()
        adView.loadAd(request)
    }

    fun loadInterstitial(context: Context) {
        val request = AdRequest.Builder().build()
        InterstitialAd.load(
            context,
            "ca-app-pub-3940256099942544/1033173712",
            request,
            object : InterstitialAdLoadCallback() {
                override fun onAdLoaded(ad: InterstitialAd) {
                    interstitial = ad
                }
                override fun onAdFailedToLoad(error: LoadAdError) {
                    interstitial = null
                }
            }
        )
    }

    fun maybeShowOnChannelClick(activity: Activity, onContinue: () -> Unit) {
        clickCount++
        val ad = interstitial
        if (ad != null && CHANNEL_INTERVAL > 0 && (clickCount % CHANNEL_INTERVAL == 0)) {
            ad.show(activity)
            interstitial = null
            loadInterstitial(activity)
            onContinue()
        } else {
            onContinue()
        }
    }
}
EOF

########################################
# ADAPTERS
########################################

cat <<EOF > app/src/main/java/$PATH_NAME/adapters/CategoryAdapter.kt
package $PACKAGE_NAME.adapters

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import $PACKAGE_NAME.R
import $PACKAGE_NAME.models.Category

class CategoryAdapter(
    private val list: List<Category>,
    private val onClick: (Category) -> Unit
) : RecyclerView.Adapter<CategoryAdapter.VH>() {

    private var selectedId: String? = null

    fun setSelected(id: String?) {
        selectedId = id
        notifyDataSetChanged()
    }

    class VH(v: View) : RecyclerView.ViewHolder(v) {
        val txt: TextView = v.findViewById(R.id.txtCategory)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val v = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_category, parent, false)
        return VH(v)
    }

    override fun onBindViewHolder(holder: VH, position: Int) {
        val item = list[position]
        holder.txt.text = item.category_name

        holder.itemView.isSelected = item.category_id == selectedId

        holder.itemView.setOnClickListener {
            onClick(item)
        }
    }

    override fun getItemCount(): Int = list.size
}
EOF

cat <<EOF > app/src/main/java/$PATH_NAME/adapters/StreamAdapter.kt
package $PACKAGE_NAME.adapters

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import $PACKAGE_NAME.R
import $PACKAGE_NAME.models.StreamItem

class StreamAdapter(
    private var list: List<StreamItem>,
    private val onClick: (StreamItem) -> Unit
) : RecyclerView.Adapter<StreamAdapter.VH>() {

    class VH(v: View) : RecyclerView.ViewHolder(v) {
        val txt: TextView = v.findViewById(R.id.txtStreamName)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val v = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_stream, parent, false)
        return VH(v)
    }

    override fun onBindViewHolder(holder: VH, position: Int) {
        val item = list[position]
        holder.txt.text = item.name
        holder.itemView.setOnClickListener {
            onClick(item)
        }
    }

    override fun getItemCount(): Int = list.size

    fun update(newList: List<StreamItem>) {
        list = newList
        notifyDataSetChanged()
    }
}
EOF

########################################
# LOGIN ACTIVITY (TV + Mobil uyumlu)
########################################

cat <<EOF > app/src/main/java/$PATH_NAME/LoginActivity.kt
package $PACKAGE_NAME

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.ads.AdView
import $PACKAGE_NAME.models.AccountProfile
import $PACKAGE_NAME.utils.AdsHelper
import $PACKAGE_NAME.utils.Prefs

class LoginActivity : AppCompatActivity() {

    private var isXtream = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)

        val prefs = Prefs(this)
        val active = prefs.getActive()
        if (active != null) {
            val i = Intent(this, ContentActivity::class.java)
            startActivity(i)
            finish()
            return
        }

        AdsHelper.init(this)
        val adTop = findViewById<AdView>(R.id.adViewTopLogin)
        AdsHelper.loadBanner(adTop)
        AdsHelper.loadInterstitial(this)

        val tvTitle = findViewById<TextView>(R.id.tvTitle)
        val tvLoginType = findViewById<TextView>(R.id.tvLoginType)

        val etName = findViewById<EditText>(R.id.etName)
        val etDns = findViewById<EditText>(R.id.etDns)
        val etUser = findViewById<EditText>(R.id.etUser)
        val etPass = findViewById<EditText>(R.id.etPass)
        val etM3u = findViewById<EditText>(R.id.etM3u)

        val layoutXtream = findViewById<View>(R.id.layoutXtream)
        val layoutM3u = findViewById<View>(R.id.layoutM3u)
        val btnAdd = findViewById<Button>(R.id.btnAddAccount)
        val lvAccounts = findViewById<ListView>(R.id.lvAccounts)

        val cardXtream = findViewById<View>(R.id.cardXtream)
        val cardM3u = findViewById<View>(R.id.cardM3u)
        val tvXtream = findViewById<TextView>(R.id.tvXtream)
        val tvM3u = findViewById<TextView>(R.id.tvM3u)

        tvTitle.text = "EMIN XTREAM PLAYER"
        tvLoginType.text = "Giriş Tipi"
        tvXtream.text = "Xtream"
        tvM3u.text = "M3U"

        fun updateTypeUI() {
            if (isXtream) {
                layoutXtream.visibility = View.VISIBLE
                layoutM3u.visibility = View.GONE
                cardXtream.isSelected = true
                cardM3u.isSelected = false
            } else {
                layoutXtream.visibility = View.GONE
                layoutM3u.visibility = View.VISIBLE
                cardXtream.isSelected = false
                cardM3u.isSelected = true
            }
        }

        cardXtream.setOnClickListener {
            isXtream = true
            updateTypeUI()
        }

        cardM3u.setOnClickListener {
            isXtream = false
            updateTypeUI()
        }

        updateTypeUI()

        fun refreshAccounts() {
            val list = prefs.getAccounts()
            val adapter = object : BaseAdapter() {
                override fun getCount(): Int = list.size
                override fun getItem(position: Int): Any = list[position]
                override fun getItemId(position: Int): Long = list[position].id.toLong()
                override fun getView(position: Int, convertView: View?, parent: android.view.ViewGroup?): View {
                    val v = convertView ?: layoutInflater.inflate(R.layout.item_account, parent, false)
                    val name = v.findViewById<TextView>(R.id.tvAccountName)
                    val type = v.findViewById<TextView>(R.id.tvAccountType)
                    val btnDelete = v.findViewById<ImageButton>(R.id.btnDeleteAccount)

                    val item: AccountProfile = list[position]
                    name.text = item.name
                    type.text = if (item.type == "M3U") "M3U" else "Xtream"

                    v.setOnClickListener {
                        prefs.setActive(item.id)
                        val i = Intent(this@LoginActivity, ContentActivity::class.java)
                        startActivity(i)
                        finish()
                    }

                    btnDelete.setOnClickListener {
                        AlertDialog.Builder(this@LoginActivity)
                            .setTitle("Hesabı Sil")
                            .setMessage("Bu hesabı silmek istiyor musun?\n" + item.name)
                            .setPositiveButton("Evet") { _, _ ->
                                prefs.deleteAccount(item.id)
                                refreshAccounts()
                            }
                            .setNegativeButton("Hayır", null)
                            .show()
                    }

                    return v
                }
            }
            lvAccounts.adapter = adapter
        }

        refreshAccounts()

        btnAdd.setOnClickListener {
            val baseName = etName.text.toString().trim()
            val name = if (baseName.isEmpty()) "Hesap" else baseName

            if (isXtream) {
                val d = etDns.text.toString().trim()
                val u = etUser.text.toString().trim()
                val p = etPass.text.toString().trim()
                if (d.isEmpty() || u.isEmpty()) {
                    Toast.makeText(this, "Xtream URL ve kullanıcı adı zorunludur.", Toast.LENGTH_SHORT).show()
                    return@setOnClickListener
                }
                prefs.createXtreamAccount(name, d, u, p)
            } else {
                val m = etM3u.text.toString().trim()
                if (m.isEmpty()) {
                    Toast.makeText(this, "M3U adresi boş olamaz.", Toast.LENGTH_SHORT).show()
                    return@setOnClickListener
                }
                prefs.createM3uAccount(name, m)
            }

            etName.setText("")
            etDns.setText("")
            etUser.setText("")
            etPass.setText("")
            etM3u.setText("")

            refreshAccounts()
        }
    }
}
EOF

########################################
# CONTENT ACTIVITY (Önce Canlı, kategori→kanal, arama, TV uyumlu)
########################################

cat <<EOF > app/src/main/java/$PATH_NAME/ContentActivity.kt
package $PACKAGE_NAME

import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.gms.ads.AdView
import $PACKAGE_NAME.adapters.CategoryAdapter
import $PACKAGE_NAME.adapters.StreamAdapter
import $PACKAGE_NAME.models.AccountProfile
import $PACKAGE_NAME.models.Category
import $PACKAGE_NAME.models.StreamItem
import $PACKAGE_NAME.utils.AdsHelper
import $PACKAGE_NAME.utils.Prefs
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.Date

class ContentActivity : AppCompatActivity() {

    private lateinit var prefs: Prefs
    private var active: AccountProfile? = null

    private lateinit var tvHeader: TextView
    private lateinit var tvAccountInfo: TextView
    private lateinit var tvExit: TextView
    private lateinit var etSearch: EditText
    private lateinit var pb: ProgressBar

    private lateinit var rvCategories: RecyclerView
    private lateinit var rvStreams: RecyclerView

    private var categories: List<Category> = emptyList()
    private var streams: List<StreamItem> = emptyList()
    private var filteredStreams: List<StreamItem> = emptyList()

    private var currentMode: String = "LIVE"  // LIVE / VOD / SERIES
    private var selectedCategoryId: String? = null

    private var categoryAdapter: CategoryAdapter? = null
    private var streamAdapter: StreamAdapter? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_content)

        prefs = Prefs(this)
        active = prefs.getActive()
        if (active == null) {
            val i = Intent(this, LoginActivity::class.java)
            startActivity(i)
            finish()
            return
        }

        currentMode = "LIVE" // ilk açılışta hep canlı

        AdsHelper.init(this)
        val adTop = findViewById<AdView>(R.id.adViewTopContent)
        val adBottom = findViewById<AdView>(R.id.adViewBottomContent)
        AdsHelper.loadBanner(adTop)
        AdsHelper.loadBanner(adBottom)
        AdsHelper.loadInterstitial(this)

        tvHeader = findViewById(R.id.tvHeader)
        tvAccountInfo = findViewById(R.id.tvAccountInfo)
        tvExit = findViewById(R.id.tvExit)
        etSearch = findViewById(R.id.etSearch)
        pb = findViewById(R.id.pbLoading)
        rvCategories = findViewById(R.id.rvCategories)
        rvStreams = findViewById(R.id.rvStreams)

        tvHeader.text = "CANLI TV"
        tvExit.text = "Çıkış"

        rvCategories.layoutManager =
            LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false)
        rvStreams.layoutManager =
            LinearLayoutManager(this, LinearLayoutManager.VERTICAL, false)

        tvExit.setOnClickListener {
            val p = Prefs(this)
            p.setLastMode("LIVE")
            val i = Intent(this, LoginActivity::class.java)
            i.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(i)
            finish()
        }

        // Üst header tıklanınca mod değiştir: LIVE -> VOD -> SERIES
        tvHeader.setOnClickListener {
            if (active?.type == "M3U") {
                Toast.makeText(this, "M3U hesabı: sadece CANLI listesi.", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            currentMode = when (currentMode) {
                "LIVE" -> "VOD"
                "VOD" -> "SERIES"
                else -> "LIVE"
            }
            prefs.setLastMode(currentMode)
            updateHeaderTitle()
            loadAll()
        }

        etSearch.addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) {
                applyFilter()
            }
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        })

        loadAll()
    }

    private fun updateHeaderTitle() {
        tvHeader.text = when (currentMode) {
            "VOD" -> "FİLMLER"
            "SERIES" -> "DİZİLER"
            else -> "CANLI TV"
        }
    }

    private fun loadAll() {
        val acc = active ?: return
        if (acc.type == "M3U") {
            // Sadece M3U canlı listesi
            loadM3u(acc)
        } else {
            loadXtream(acc)
        }
    }

    private fun loadM3u(acc: AccountProfile) {
        val m3uUrl = acc.m3u?.trim() ?: ""
        if (m3uUrl.isEmpty()) {
            Toast.makeText(this, "Bu M3U hesabında link yok.", Toast.LENGTH_SHORT).show()
            return
        }

        pb.visibility = View.VISIBLE

        Thread {
            try {
                val conn = URL(m3uUrl).openConnection() as HttpURLConnection
                conn.connectTimeout = 10000
                conn.readTimeout = 20000
                conn.requestMethod = "GET"
                if (conn.responseCode != HttpURLConnection.HTTP_OK) {
                    runOnUiThread {
                        pb.visibility = View.GONE
                        Toast.makeText(this, "M3U okunamadı.", Toast.LENGTH_SHORT).show()
                    }
                    return@Thread
                }
                val body = conn.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                val lines = body.split("\n")

                val catsMap = LinkedHashMap<String, Category>()
                val streamsList = ArrayList<StreamItem>()

                var currentName = ""
                var currentGroup = "Genel"
                var currentRef: String? = null
                var currentOrg: String? = null

                for (rawLine in lines) {
                    val line = rawLine.trim()
                    if (line.isEmpty()) continue
                    if (line.startsWith("#EXTM3U")) continue

                    if (line.startsWith("#EXTINF", true)) {
                        var name = ""
                        var group = "Genel"

                        val groupIndex = line.indexOf("group-title=\"")
                        if (groupIndex >= 0) {
                            val start = groupIndex + "group-title=\"".length
                            val end = line.indexOf("\"", start)
                            if (end > start) {
                                group = line.substring(start, end)
                            }
                        }
                        val commaIndex = line.lastIndexOf(',')
                        if (commaIndex >= 0 && commaIndex < line.length - 1) {
                            name = line.substring(commaIndex + 1).trim()
                        }
                        currentName = if (name.isNotEmpty()) name else "Kanal"
                        currentGroup = if (group.isNotEmpty()) group else "Genel"
                        currentRef = null
                        currentOrg = null
                    } else if (line.startsWith("#EXTVLCOPT:http-referrer=")) {
                        val idx = line.indexOf("=")
                        if (idx >= 0 && idx < line.length - 1) {
                            currentRef = line.substring(idx + 1).trim()
                        }
                    } else if (line.startsWith("#EXTVLCOPT:http-origin=")) {
                        val idx = line.indexOf("=")
                        if (idx >= 0 && idx < line.length - 1) {
                            currentOrg = line.substring(idx + 1).trim()
                        }
                    } else if (!line.startsWith("#")) {
                        val playUrl = line
                        val groupId = if (currentGroup.isNotEmpty()) currentGroup else "Genel"
                        val cat = catsMap.getOrPut(groupId) {
                            Category(groupId, groupId)
                        }
                        streamsList.add(
                            StreamItem(
                                name = currentName,
                                stream_id = null,
                                series_id = null,
                                container_extension = null,
                                category_id = cat.category_id,
                                full_url = playUrl,
                                referer = currentRef,
                                origin = currentOrg
                            )
                        )
                        currentRef = null
                        currentOrg = null
                    }
                }

                val catList = catsMap.values.toList()

                runOnUiThread {
                    pb.visibility = View.GONE
                    categories = catList
                    streams = streamsList
                    initAdapters()
                    tvAccountInfo.text = "Hesap: " + acc.name + " • M3U Playlist"
                }
            } catch (e: Exception) {
                e.printStackTrace()
                runOnUiThread {
                    pb.visibility = View.GONE
                    Toast.makeText(this, "M3U hata: " + e.message, Toast.LENGTH_SHORT).show()
                }
            }
        }.start()
    }

    private fun loadXtream(acc: AccountProfile) {
        val dnsRaw = acc.dns?.trim() ?: ""
        val user = acc.user?.trim() ?: ""
        val pass = acc.pass?.trim() ?: ""
        if (dnsRaw.isEmpty() || user.isEmpty() || pass.isEmpty()) {
            Toast.makeText(this, "DNS / kullanıcı / şifre eksik.", Toast.LENGTH_SHORT).show()
            return
        }
        val dns = if (dnsRaw.endsWith("/")) dnsRaw.substring(0, dnsRaw.length - 1) else dnsRaw
        val base = dns + "/player_api.php?username=" + user + "&password=" + pass

        val catAction = when (currentMode) {
            "VOD" -> "get_vod_categories"
            "SERIES" -> "get_series_categories"
            else -> "get_live_categories"
        }
        val streamsAction = when (currentMode) {
            "VOD" -> "get_vod_streams"
            "SERIES" -> "get_series"
            else -> "get_live_streams"
        }

        val infoUrl = base
        val catUrl = base + "&action=" + catAction
        val streamsUrl = base + "&action=" + streamsAction

        pb.visibility = View.VISIBLE

        Thread {
            try {
                // User info
                var userName: String? = null
                var expDate: String? = null
                try {
                    val cInfo = URL(infoUrl).openConnection() as HttpURLConnection
                    cInfo.connectTimeout = 8000
                    cInfo.readTimeout = 8000
                    cInfo.requestMethod = "GET"
                    if (cInfo.responseCode == HttpURLConnection.HTTP_OK) {
                        val body = cInfo.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                        val obj = JSONObject(body)
                        val uInfo = obj.optJSONObject("user_info")
                        if (uInfo != null) {
                            userName = uInfo.optString("username", null)
                            expDate = uInfo.optString("exp_date", null)
                        }
                    }
                } catch (e: Exception) {
                }

                // Categories
                val cCat = URL(catUrl).openConnection() as HttpURLConnection
                cCat.connectTimeout = 10000
                cCat.readTimeout = 15000
                cCat.requestMethod = "GET"
                if (cCat.responseCode != HttpURLConnection.HTTP_OK) {
                    runOnUiThread {
                        pb.visibility = View.GONE
                        Toast.makeText(this, "Kategori alınamadı.", Toast.LENGTH_SHORT).show()
                    }
                    return@Thread
                }
                val catBody = cCat.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                val catArr = JSONArray(catBody)
                val catList = ArrayList<Category>()
                var i = 0
                while (i < catArr.length()) {
                    val o = catArr.getJSONObject(i)
                    val id = o.optString("category_id", "")
                    val name = o.optString("category_name", "Kategori " + i)
                    catList.add(Category(id, name))
                    i++
                }

                // Streams
                val cStr = URL(streamsUrl).openConnection() as HttpURLConnection
                cStr.connectTimeout = 10000
                cStr.readTimeout = 20000
                cStr.requestMethod = "GET"
                if (cStr.responseCode != HttpURLConnection.HTTP_OK) {
                    runOnUiThread {
                        pb.visibility = View.GONE
                        Toast.makeText(this, "Liste alınamadı.", Toast.LENGTH_SHORT).show()
                    }
                    return@Thread
                }
                val strBody = cStr.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                val strArr = JSONArray(strBody)
                val streamList = ArrayList<StreamItem>()
                var j = 0
                while (j < strArr.length()) {
                    val o = strArr.getJSONObject(j)
                    val name = o.optString("name", "Bilinmeyen")
                    val catId = o.optString("category_id", "")
                    val sId = o.optString("stream_id", null)
                    val seriesId = o.optString("series_id", null)
                    val ext = o.optString("container_extension", null)
                    streamList.add(
                        StreamItem(
                            name = name,
                            stream_id = sId,
                            series_id = seriesId,
                            container_extension = ext,
                            category_id = catId,
                            full_url = null,
                            referer = null,
                            origin = null
                        )
                    )
                    j++
                }

                val expText = if (expDate == null || expDate == "" || expDate == "0") {
                    "Sınırsız"
                } else {
                    try {
                        val sec = expDate.toLong()
                        val ms = sec * 1000L
                        val sdf = SimpleDateFormat("dd.MM.yyyy HH:mm", Locale.getDefault())
                        sdf.format(Date(ms))
                    } catch (e: Exception) {
                        expDate
                    }
                }

                runOnUiThread {
                    pb.visibility = View.GONE
                    categories = catList
                    streams = streamList
                    initAdapters()

                    val nm = if (acc.name.isNotEmpty()) acc.name else (userName ?: "Xtream")
                    tvAccountInfo.text = "Hesap: " + nm + " • Bitiş: " + expText
                }
            } catch (e: Exception) {
                e.printStackTrace()
                runOnUiThread {
                    pb.visibility = View.GONE
                    Toast.makeText(this, "Hata: " + e.message, Toast.LENGTH_SHORT).show()
                }
            }
        }.start()
    }

    private fun initAdapters() {
        if (categories.isNotEmpty()) {
            selectedCategoryId = categories[0].category_id
        } else {
            selectedCategoryId = null
        }

        categoryAdapter = CategoryAdapter(categories) { cat ->
            selectedCategoryId = cat.category_id
            categoryAdapter?.setSelected(cat.category_id)
            applyFilter()
        }
        rvCategories.adapter = categoryAdapter
        categoryAdapter?.setSelected(selectedCategoryId)

        streamAdapter = StreamAdapter(emptyList()) { item ->
            openItem(item)
        }
        rvStreams.adapter = streamAdapter

        applyFilter()
    }

    private fun applyFilter() {
        val q = etSearch.text.toString().trim().lowercase(Locale.getDefault())

        val baseList = if (selectedCategoryId == null || selectedCategoryId == "") {
            streams
        } else {
            streams.filter { it.category_id == selectedCategoryId }
        }

        filteredStreams = if (q.isEmpty()) {
            baseList
        } else {
            baseList.filter { it.name.lowercase(Locale.getDefault()).contains(q) }
        }

        streamAdapter?.update(filteredStreams)
    }

    private fun openItem(item: StreamItem) {
        val acc = active ?: return

        if (acc.type == "M3U") {
            val url = item.full_url
            if (url == null || url.isEmpty()) {
                Toast.makeText(this, "Geçersiz M3U kanalı.", Toast.LENGTH_SHORT).show()
                return
            }
            val itn = Intent(this, PlayerActivity::class.java)
            itn.putExtra("URL", url)
            itn.putExtra("REF", item.referer ?: "")
            itn.putExtra("ORG", item.origin ?: "")
            AdsHelper.maybeShowOnChannelClick(this) {
                startActivity(itn)
            }
        } else {
            val dnsRaw = acc.dns?.trim() ?: ""
            val user = acc.user?.trim() ?: ""
            val pass = acc.pass?.trim() ?: ""
            val dns = if (dnsRaw.endsWith("/")) dnsRaw.substring(0, dnsRaw.length - 1) else dnsRaw

            val path: String
            if (currentMode == "VOD") {
                path = "movie"
            } else if (currentMode == "SERIES") {
                // Basit: series'de de movie gibi oynatalım (daha sonra detay sayfası eklenebilir)
                path = "series"
            } else {
                path = "live"
            }

            val ext: String
            if (currentMode == "LIVE") {
                ext = ".ts"
            } else {
                val e = item.container_extension
                ext = if (e != null && e.isNotEmpty()) "." + e else ".mp4"
            }

            val id = item.stream_id ?: ""
            val playUrl = dns + "/" + path + "/" + user + "/" + pass + "/" + id + ext

            val itn = Intent(this, PlayerActivity::class.java)
            itn.putExtra("URL", playUrl)
            itn.putExtra("REF", "")
            itn.putExtra("ORG", "")

            AdsHelper.maybeShowOnChannelClick(this) {
                startActivity(itn)
            }
        }
    }
}
EOF

########################################
# PLAYER ACTIVITY (Play/Pause aktif, TV uyumlu)
########################################

cat <<EOF > app/src/main/java/$PATH_NAME/PlayerActivity.kt
package $PACKAGE_NAME

import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.ImageButton
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.media3.common.MediaItem
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.PlayerView

class PlayerActivity : AppCompatActivity() {

    private var player: ExoPlayer? = null
    private lateinit var playerView: PlayerView
    private lateinit var btnPlayPause: ImageButton

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )

        setContentView(R.layout.activity_player_pro)

        val url = intent.getStringExtra("URL") ?: ""
        val ref = intent.getStringExtra("REF") ?: ""
        val org = intent.getStringExtra("ORG") ?: ""

        if (url.isEmpty()) {
            Toast.makeText(this, "Geçersiz yayın URL'si.", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        playerView = findViewById(R.id.pvMain)
        btnPlayPause = findViewById(R.id.btnPlayPause)

        try {
            val headers = mutableMapOf<String, String>()
            headers["User-Agent"] = "Mozilla/5.0 (Android) ExoPlayer"
            if (ref.isNotEmpty()) headers["Referer"] = ref
            if (org.isNotEmpty()) headers["Origin"] = org

            val httpFactory = DefaultHttpDataSource.Factory()
                .setConnectTimeoutMs(15000)
                .setReadTimeoutMs(30000)
                .setDefaultRequestProperties(headers)

            val mediaSourceFactory = DefaultMediaSourceFactory(httpFactory)

            val exo = ExoPlayer.Builder(this)
                .setMediaSourceFactory(mediaSourceFactory)
                .build()

            player = exo
            playerView.player = exo
            playerView.controllerShowTimeoutMs = 4000
            playerView.controllerHideOnTouch = true

            val item = MediaItem.fromUri(url)
            exo.setMediaItem(item)
            exo.prepare()
            exo.playWhenReady = true

            btnPlayPause.setOnClickListener {
                if (exo.isPlaying) {
                    exo.pause()
                    btnPlayPause.setImageResource(android.R.drawable.ic_media_play)
                } else {
                    exo.play()
                    btnPlayPause.setImageResource(android.R.drawable.ic_media_pause)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            Toast.makeText(this, "Oynatıcı hatası: " + e.message, Toast.LENGTH_LONG).show()
            finish()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        player?.release()
        player = null
    }
}
EOF

########################################
# LAYOUTLAR
########################################

# LOGIN
cat <<EOF > app/src/main/res/layout/activity_login.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:ads="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@color/bg_dark"
    android:padding="16dp">

    <com.google.android.gms.ads.AdView
        android:id="@+id/adViewTopLogin"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        ads:adSize="BANNER"
        ads:adUnitId="@string/admob_banner_test"
        android:layout_marginBottom="8dp" />

    <TextView
        android:id="@+id/tvTitle"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="EMIN XTREAM PLAYER"
        android:textColor="@color/accent_green"
        android:textSize="22sp"
        android:textStyle="bold"
        android:layout_marginBottom="8dp" />

    <TextView
        android:id="@+id/tvLoginType"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Giriş Tipi"
        android:textColor="@color/white"
        android:textSize="16sp"
        android:layout_marginBottom="4dp" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:layout_marginBottom="10dp">

        <LinearLayout
            android:id="@+id/cardXtream"
            android:layout_width="0dp"
            android:layout_height="72dp"
            android:layout_weight="1"
            android:background="@drawable/bg_item_focus"
            android:gravity="center"
            android:focusable="true"
            android:focusableInTouchMode="true"
            android:padding="8dp"
            android:layout_marginRight="6dp">

            <TextView
                android:id="@+id/tvXtream"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Xtream"
                android:textColor="@color/white"
                android:textSize="16sp"
                android:textStyle="bold" />
        </LinearLayout>

        <LinearLayout
            android:id="@+id/cardM3u"
            android:layout_width="0dp"
            android:layout_height="72dp"
            android:layout_weight="1"
            android:background="@drawable/bg_input_dark"
            android:gravity="center"
            android:focusable="true"
            android:focusableInTouchMode="true"
            android:padding="8dp"
            android:layout_marginLeft="6dp">

            <TextView
                android:id="@+id/tvM3u"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="M3U"
                android:textColor="@color/white"
                android:textSize="16sp"
                android:textStyle="bold" />
        </LinearLayout>
    </LinearLayout>

    <EditText
        android:id="@+id/etName"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:background="@drawable/bg_input_dark"
        android:hint="Hesap adı"
        android:textColor="@color/white"
        android:textColorHint="@color/hint_yellow"
        android:padding="12dp"
        android:layout_marginBottom="8dp" />

    <LinearLayout
        android:id="@+id/layoutXtream"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical">

        <EditText
            android:id="@+id/etDns"
            android:layout_width="match_parent"
            android:layout_height="56dp"
            android:background="@drawable/bg_input_dark"
            android:hint="Xtream URL"
            android:textColor="@color/white"
            android:textColorHint="@color/hint_yellow"
            android:padding="12dp"
            android:layout_marginBottom="6dp" />

        <EditText
            android:id="@+id/etUser"
            android:layout_width="match_parent"
            android:layout_height="56dp"
            android:background="@drawable/bg_input_dark"
            android:hint="Username"
            android:textColor="@color/white"
            android:textColorHint="@color/hint_yellow"
            android:padding="12dp"
            android:layout_marginBottom="6dp" />

        <EditText
            android:id="@+id/etPass"
            android:layout_width="match_parent"
            android:layout_height="56dp"
            android:background="@drawable/bg_input_dark"
            android:hint="Password"
            android:inputType="textVisiblePassword"
            android:textColor="@color/white"
            android:textColorHint="@color/hint_yellow"
            android:padding="12dp"
            android:layout_marginBottom="6dp" />
    </LinearLayout>

    <LinearLayout
        android:id="@+id/layoutM3u"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:visibility="gone">

        <EditText
            android:id="@+id/etM3u"
            android:layout_width="match_parent"
            android:layout_height="56dp"
            android:background="@drawable/bg_input_dark"
            android:hint="M3U URL"
            android:textColor="@color/white"
            android:textColorHint="@color/hint_yellow"
            android:padding="12dp"
            android:layout_marginBottom="6dp" />
    </LinearLayout>

    <Button
        android:id="@+id/btnAddAccount"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:text="Hesap Ekle"
        android:textAllCaps="false"
        android:textColor="@color/black"
        android:background="@color/accent_green"
        android:layout_marginBottom="12dp" />

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Kayıtlı Hesaplar"
        android:textColor="@color/white"
        android:textSize="16sp"
        android:textStyle="bold"
        android:layout_marginBottom="4dp" />

    <ListView
        android:id="@+id/lvAccounts"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:divider="@android:color/transparent"
        android:dividerHeight="8dp" />
</LinearLayout>
EOF

# CONTENT (kategori→kanal, arama, üstte hesap + çıkış)
cat <<EOF > app/src/main/res/layout/activity_content.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:ads="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@color/bg_dark">

    <com.google.android.gms.ads.AdView
        android:id="@+id/adViewTopContent"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        ads:adSize="BANNER"
        ads:adUnitId="@string/admob_banner_test" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:padding="10dp">

        <TextView
            android:id="@+id/tvHeader"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="CANLI TV"
            android:textColor="@color/white"
            android:textSize="18sp"
            android:textStyle="bold" />

        <TextView
            android:id="@+id/tvExit"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Çıkış"
            android:textColor="@color/error_red"
            android:textSize="14sp" />
    </LinearLayout>

    <TextView
        android:id="@+id/tvAccountInfo"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="@color/hint_yellow"
        android:textSize="13sp"
        android:paddingLeft="12dp"
        android:paddingRight="12dp"
        android:paddingBottom="4dp" />

    <EditText
        android:id="@+id/etSearch"
        android:layout_width="match_parent"
        android:layout_height="48dp"
        android:background="@drawable/bg_input_dark"
        android:hint="Ara (tüm liste)"
        android:textColor="@color/white"
        android:textColorHint="@color/hint_yellow"
        android:padding="10dp"
        android:layout_marginLeft="10dp"
        android:layout_marginRight="10dp"
        android:layout_marginBottom="8dp" />

    <ProgressBar
        android:id="@+id/pbLoading"
        style="?android:attr/progressBarStyleLarge"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="center_horizontal"
        android:layout_marginBottom="6dp"
        android:visibility="gone" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvCategories"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:paddingLeft="8dp"
        android:paddingRight="8dp" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rvStreams"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:padding="8dp" />

    <com.google.android.gms.ads.AdView
        android:id="@+id/adViewBottomContent"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        ads:adSize="BANNER"
        ads:adUnitId="@string/admob_banner_test" />
</LinearLayout>
EOF

# CATEGORY ITEM
cat <<EOF > app/src/main/res/layout/item_category.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="wrap_content"
    android:layout_height="match_parent"
    android:padding="4dp">

    <TextView
        android:id="@+id/txtCategory"
        android:layout_width="wrap_content"
        android:layout_height="match_parent"
        android:minWidth="80dp"
        android:gravity="center"
        android:paddingLeft="12dp"
        android:paddingRight="12dp"
        android:textColor="@color/white"
        android:textSize="14sp"
        android:background="@drawable/bg_item_focus"
        android:focusable="true"
        android:focusableInTouchMode="true" />
</LinearLayout>
EOF

# STREAM ITEM
cat <<EOF > app/src/main/res/layout/item_stream.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:paddingLeft="4dp"
    android:paddingRight="4dp"
    android:paddingTop="4dp"
    android:paddingBottom="4dp">

    <TextView
        android:id="@+id/txtStreamName"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:gravity="center_vertical"
        android:paddingLeft="12dp"
        android:paddingRight="12dp"
        android:textColor="@color/white"
        android:textSize="16sp"
        android:maxLines="2"
        android:ellipsize="end"
        android:background="@drawable/bg_item_focus"
        android:focusable="true"
        android:focusableInTouchMode="true" />
</LinearLayout>
EOF

# ACCOUNT ITEM
cat <<EOF > app/src/main/res/layout/item_account.xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="64dp"
    android:background="@drawable/bg_input_dark"
    android:paddingLeft="10dp"
    android:paddingRight="10dp"
    android:gravity="center_vertical">

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:layout_weight="1">

        <TextView
            android:id="@+id/tvAccountName"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Hesap"
            android:textColor="@color/white"
            android:textSize="15sp"
            android:textStyle="bold" />

        <TextView
            android:id="@+id/tvAccountType"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Xtream"
            android:textColor="@color/accent_green"
            android:textSize="13sp" />
    </LinearLayout>

    <ImageButton
        android:id="@+id/btnDeleteAccount"
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:background="@android:color/transparent"
        android:src="@android:drawable/ic_menu_delete"
        android:tint="@color/error_red" />
</LinearLayout>
EOF

# PLAYER LAYOUT
cat <<EOF > app/src/main/res/layout/activity_player_pro.xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/black">

    <androidx.media3.ui.PlayerView
        android:id="@+id/pvMain"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:keepScreenOn="true" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="72dp"
        android:layout_gravity="bottom"
        android:gravity="right|center_vertical"
        android:paddingRight="16dp"
        android:paddingBottom="8dp">

        <ImageButton
            android:id="@+id/btnPlayPause"
            android:layout_width="56dp"
            android:layout_height="56dp"
            android:background="@android:color/transparent"
            android:src="@android:drawable/ic_media_pause"
            android:tint="@android:color/white" />
    </LinearLayout>
</FrameLayout>
EOF

########################################
# ANDROIDMANIFEST
########################################

cat <<EOF > app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:theme="@style/Theme.ErdinPlayer"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:usesCleartextTraffic="true">

        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="@string/admob_app_id" />

        <activity
            android:name=".LoginActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name=".ContentActivity" />
        <activity android:name=".PlayerActivity" />
    </application>
</manifest>
EOF

echo "✅ Proje dosyaları hazır. Şimdi Gradle ile build alabilirsin."
