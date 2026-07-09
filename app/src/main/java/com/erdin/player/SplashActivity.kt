package com.erdin.player
import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.animation.AnimationUtils
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
@SuppressLint("CustomSplashScreen")
class SplashActivity : AppCompatActivity() {
    override fun onCreate(s: Bundle?) {
        super.onCreate(s)
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        setContentView(R.layout.activity_splash)
        val logo = findViewById<ImageView>(R.id.ivSplashLogo)
        val name = findViewById<TextView>(R.id.tvSplashName)
        val tag  = findViewById<TextView>(R.id.tvSplashTagline)
        val ver  = findViewById<TextView>(R.id.tvSplashVersion)
        runCatching { ver.text = "v" + packageManager.getPackageInfo(packageName,0).versionName }
        runCatching { logo.startAnimation(AnimationUtils.loadAnimation(this, R.anim.anim_scale)) }
        runCatching { name.startAnimation(AnimationUtils.loadAnimation(this, R.anim.anim_fade)) }
        runCatching { tag.startAnimation(AnimationUtils.loadAnimation(this, R.anim.anim_slide)) }
        Handler(Looper.getMainLooper()).postDelayed({
            val prefs = getSharedPreferences("EP_Prefs",0)
            val target = if (prefs.getInt("active_id",-1) > 0) ContentActivity::class.java else LoginActivity::class.java
            startActivity(Intent(this, target))
            overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
            finish()
        }, 2000)
    }
}

