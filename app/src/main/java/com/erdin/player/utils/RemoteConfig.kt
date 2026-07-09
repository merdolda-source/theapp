package com.erdin.player.utils
import android.content.Context
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import com.erdin.player.R
object RemoteConfig {
    private const val CONFIG_URL = "https://creatorapp24.com/erdin/api/config.php"
    @Volatile private var initialized = false
    @Volatile private var nativeId: String? = null
    @Volatile private var interstitialId: String? = null
    @Volatile private var appOpenId: String? = null
    @Volatile private var channelInterval: Int = 4
    @Volatile private var nativeGridInterval: Int = 7
    fun init(context: Context) {
        if (initialized) return
        synchronized(this) {
            if (initialized) return
            initialized = true
            Thread {
                try {
                    val conn = (URL(CONFIG_URL).openConnection() as HttpURLConnection).apply {
                        connectTimeout = 8000; readTimeout = 8000; requestMethod = "GET"
                    }
                    if (conn.responseCode != HttpURLConnection.HTTP_OK) return@Thread
                    val body = conn.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                    val obj = JSONObject(body)
                    val ads = obj.optJSONObject("ads") ?: obj
                    nativeId = ads.optString("admob_native_id", null)
                    interstitialId = ads.optString("admob_interstitial_id", null)
                    appOpenId = ads.optString("admob_app_open_id", null)
                    val iv = ads.optInt("channel_interval", 0); if (iv > 0) channelInterval = iv
                    val gi = ads.optInt("native_grid_interval", 0); if (gi > 0) nativeGridInterval = gi
                } catch (_: Exception) {}
            }.start()
        }
    }
    fun getNativeId(context: Context): String = nativeId ?: context.getString(R.string.admob_native_test)
    fun getInterstitialId(context: Context): String = interstitialId ?: context.getString(R.string.admob_interstitial_test)
    fun getAppOpenId(context: Context): String = appOpenId ?: context.getString(R.string.admob_app_open_test)
    fun getChannelInterval(context: Context, def: Int): Int = if (channelInterval > 0) channelInterval else def
    fun getNativeGridInterval(context: Context): Int = nativeGridInterval
}
