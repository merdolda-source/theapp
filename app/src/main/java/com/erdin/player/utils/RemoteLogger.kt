package com.erdin.player.utils
import android.content.Context
import android.os.Build
import android.provider.Settings
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
object RemoteLogger {
    private const val EVENT_URL = "https://creatorapp24.com/erdin/api/event.php"
    fun sendEvent(context: Context, type: String, data: Map<String, String>) {
        Thread {
            try {
                val ctx = context.applicationContext
                val did = Settings.Secure.getString(ctx.contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"
                val pkg = ctx.packageName
                val ver = runCatching { ctx.packageManager.getPackageInfo(pkg, 0).versionName }.getOrDefault("1.0")
                val params = HashMap<String, String>()
                params["type"] = type; params["device_id"] = did; params["package"] = pkg
                params["version"] = ver ?: "1.0"
                params["brand"] = Build.BRAND ?: ""; params["model"] = Build.MODEL ?: ""
                params.putAll(data)
                val body = params.entries.joinToString("&") {
                    URLEncoder.encode(it.key,"UTF-8") + "=" + URLEncoder.encode(it.value,"UTF-8")
                }
                val conn = (URL(EVENT_URL).openConnection() as HttpURLConnection).apply {
                    connectTimeout = 8000; readTimeout = 8000; requestMethod = "POST"
                    doOutput = true; setRequestProperty("Content-Type","application/x-www-form-urlencoded")
                }
                conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
                conn.responseCode
            } catch (_: Exception) {}
        }.start()
    }
}

