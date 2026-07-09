package com.erdin.player.utils
import android.app.Activity
import android.content.Context
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback
object AdsHelper {
    @Volatile private var initialized = false
    private var interstitial: InterstitialAd? = null
    private var clickCount = 0
    var CHANNEL_INTERVAL = 4
    fun init(context: Context) {
        // Play Services eksik/eski oldugu ucuz Android TV kutularinda reklam SDK'si
        // baslatilamayabilir; bu durum uygulamayi asla cokertmemeli.
        try {
            if (!initialized) { synchronized(this) { if (!initialized) { MobileAds.initialize(context.applicationContext) {}; initialized = true } } }
        } catch (e: Throwable) { }
        try {
            RemoteConfig.init(context)
            CHANNEL_INTERVAL = RemoteConfig.getChannelInterval(context, CHANNEL_INTERVAL)
        } catch (e: Exception) { }
    }
    fun loadBanner(adView: AdView?) {
        if (adView == null) return
        try {
            val id = RemoteConfig.getBannerId(adView.context)
            try { adView.adUnitId = id } catch (_: Exception) {}
            adView.isFocusable = false; adView.isFocusableInTouchMode = false
            adView.loadAd(AdRequest.Builder().build())
        } catch (e: Throwable) { }
    }
    fun loadInterstitial(context: Context) {
        try {
            InterstitialAd.load(context, RemoteConfig.getInterstitialId(context),
                AdRequest.Builder().build(),
                object : InterstitialAdLoadCallback() {
                    override fun onAdLoaded(ad: InterstitialAd) { interstitial = ad }
                    override fun onAdFailedToLoad(e: LoadAdError) { interstitial = null }
                })
        } catch (e: Throwable) {
            interstitial = null
        }
    }
    fun maybeShowOnChannelClick(activity: Activity, onContinue: () -> Unit) {
        clickCount++
        val ad = interstitial
        if (ad != null && CHANNEL_INTERVAL > 0 && clickCount % CHANNEL_INTERVAL == 0) {
            try {
                ad.show(activity)
            } catch (e: Throwable) { }
            interstitial = null; loadInterstitial(activity); onContinue()
        } else onContinue()
    }
}
