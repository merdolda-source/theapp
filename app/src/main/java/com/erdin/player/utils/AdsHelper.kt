package com.erdin.player.utils
import android.app.Activity
import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdLoader
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.appopen.AppOpenAd
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdOptions
import com.google.android.gms.ads.nativead.NativeAdView
import com.erdin.player.R
import java.util.Date

// 3 reklam birimi: Gecis (interstitial), Native, Uygulama Acilis (App Open).
// Banner reklam kullanilmiyor.
object AdsHelper {
    @Volatile private var initialized = false
    private var interstitial: InterstitialAd? = null
    private var clickCount = 0
    var CHANNEL_INTERVAL = 4

    private var appOpenAd: AppOpenAd? = null
    private var appOpenLoadTime: Long = 0L
    @Volatile private var loadingAppOpen = false
    @Volatile private var showingAppOpen = false

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

    // ---- Gecis (Interstitial) ----
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

    // ---- Native ----
    // NativeAdView kullanan resmi Google sablonu: "Reklam" rozeti policy geregi zorunlu.
    fun loadNativeAdInto(context: Context, container: ViewGroup, onResult: (Boolean) -> Unit) {
        try {
            val adUnitId = RemoteConfig.getNativeId(context)
            val loader = AdLoader.Builder(context, adUnitId)
                .forNativeAd { nativeAd: NativeAd ->
                    try {
                        val inflater = LayoutInflater.from(context)
                        val adView = inflater.inflate(R.layout.item_native_ad, container, false) as NativeAdView
                        bindNativeAd(adView, nativeAd)
                        container.removeAllViews(); container.addView(adView)
                        onResult(true)
                    } catch (e: Exception) { onResult(false) }
                }
                .withAdListener(object : AdListener() {
                    override fun onAdFailedToLoad(error: LoadAdError) { onResult(false) }
                })
                .withNativeAdOptions(NativeAdOptions.Builder().build())
                .build()
            loader.loadAd(AdRequest.Builder().build())
        } catch (e: Throwable) {
            onResult(false)
        }
    }
    private fun bindNativeAd(adView: NativeAdView, nativeAd: NativeAd) {
        val headline = adView.findViewById<TextView>(R.id.adHeadline)
        val body = adView.findViewById<TextView>(R.id.adBody)
        val cta = adView.findViewById<Button>(R.id.adCallToAction)
        val icon = adView.findViewById<ImageView>(R.id.adIcon)
        headline.text = nativeAd.headline ?: ""; adView.headlineView = headline
        val bodyText = nativeAd.body
        if (bodyText.isNullOrEmpty()) { body.visibility = View.GONE } else { body.visibility = View.VISIBLE; body.text = bodyText }
        adView.bodyView = body
        val ctaText = nativeAd.callToAction
        if (ctaText.isNullOrEmpty()) { cta.visibility = View.GONE } else { cta.visibility = View.VISIBLE; cta.text = ctaText }
        adView.callToActionView = cta
        val iconObj = nativeAd.icon
        if (iconObj != null) { icon.setImageDrawable(iconObj.drawable); icon.visibility = View.VISIBLE } else { icon.visibility = View.GONE }
        adView.iconView = icon
        adView.setNativeAd(nativeAd)
    }

    // ---- Uygulama Acilis (App Open) ----
    fun loadAppOpenAd(context: Context) {
        if (loadingAppOpen || isAppOpenAdAvailable()) return
        loadingAppOpen = true
        try {
            AppOpenAd.load(context, RemoteConfig.getAppOpenId(context), AdRequest.Builder().build(),
                object : AppOpenAd.AppOpenAdLoadCallback() {
                    override fun onAdLoaded(ad: AppOpenAd) {
                        appOpenAd = ad; appOpenLoadTime = Date().time; loadingAppOpen = false
                    }
                    override fun onAdFailedToLoad(error: LoadAdError) { loadingAppOpen = false }
                })
        } catch (e: Throwable) { loadingAppOpen = false }
    }
    private fun isAppOpenAdAvailable(): Boolean {
        val ad = appOpenAd ?: return false
        val fourHoursMs = 4L * 60L * 60L * 1000L
        return (Date().time - appOpenLoadTime) < fourHoursMs && !showingAppOpen
    }
    fun maybeShowAppOpenAd(activity: Activity) {
        if (showingAppOpen) return
        val ad = appOpenAd
        if (ad == null || !isAppOpenAdAvailable()) { loadAppOpenAd(activity); return }
        try {
            ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                override fun onAdDismissedFullScreenContent() {
                    appOpenAd = null; showingAppOpen = false; loadAppOpenAd(activity)
                }
                override fun onAdFailedToShowFullScreenContent(error: AdError) {
                    appOpenAd = null; showingAppOpen = false; loadAppOpenAd(activity)
                }
                override fun onAdShowedFullScreenContent() { showingAppOpen = true }
            }
            ad.show(activity)
        } catch (e: Throwable) { showingAppOpen = false }
    }

    // Splash ekraninda tek seferlik ("uygulama acilirken") gosterim icin:
    // reklam hazirsa gosterir ve kapandiginda onDone() cagirir; hazir degilse
    // veya bu process'te zaten gosterildiyse akisi bloklamadan direkt onDone() cagirir.
    @Volatile private var shownThisSession = false
    fun showAppOpenOnceThenContinue(activity: Activity, onDone: () -> Unit) {
        if (shownThisSession) { onDone(); return }
        val ad = appOpenAd
        if (ad == null || !isAppOpenAdAvailable()) { onDone(); return }
        try {
            shownThisSession = true
            ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                override fun onAdDismissedFullScreenContent() { appOpenAd = null; showingAppOpen = false; onDone() }
                override fun onAdFailedToShowFullScreenContent(error: AdError) { appOpenAd = null; showingAppOpen = false; onDone() }
                override fun onAdShowedFullScreenContent() { showingAppOpen = true }
            }
            ad.show(activity)
        } catch (e: Throwable) { onDone() }
    }
}
