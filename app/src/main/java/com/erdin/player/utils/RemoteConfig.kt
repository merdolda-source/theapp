package com.erdin.player.utils
import android.content.Context
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import com.erdin.player.R
object RemoteConfig {
    private const val CONFIG_URL = "https://creatorapp24.com/erdin/api/config.php"
    @Volatile private var initialized = false
    @Volatile private var bannerId: String? = null
    @Volatile private var interstitialId: String? = null
    @Volatile private var channelInterval: Int = 4
    @Volatile private var bannerListInterval: Int = 7
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
                    bannerId = ads.optString("admob_banner_id", null)
                    interstitialId = ads.optString("admob_interstitial_id", null)
                    val iv = ads.optInt("channel_interval", 0); if (iv > 0) channelInterval = iv
                    val li = ads.optInt("banner_interval", 7); if (li > 0) bannerListInterval = li
                } catch (_: Exception) {}
            }.start()
        }
    }
    fun getBannerId(context: Context): String = bannerId ?: context.getString(R.string.admob_banner_test)
    fun getInterstitialId(context: Context): String = interstitialId ?: context.getString(R.string.admob_interstitial_test)
    fun getChannelInterval(context: Context, def: Int): Int = if (channelInterval > 0) channelInterval else def
    fun getBannerListInterval(context: Context): Int = bannerListInterval
}

