package com.erdin.player
import android.app.PictureInPictureParams
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.util.Rational
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.erdin.player.utils.Prefs
import com.erdin.player.utils.RemoteLogger
import kotlin.math.abs
class PlayerActivity : AppCompatActivity() {
    private lateinit var prefs: Prefs
    private var player: ExoPlayer? = null
    private var aspectMode = 0
    private var currentSpeed = 1f
    private lateinit var pvMain: PlayerView
    private lateinit var pbBuffering: ProgressBar
    private lateinit var tvInfoCenter: TextView
    private lateinit var tvSeekLeft: TextView
    private lateinit var tvSeekRight: TextView
    private lateinit var tvBrightness: TextView
    private lateinit var tvVolume: TextView
    private lateinit var tvPosition: TextView
    private lateinit var tvDuration: TextView
    private lateinit var tvPlaybackSpeed: TextView
    private lateinit var tvSleepCountdown: TextView
    private lateinit var seekBar: SeekBar
    private lateinit var ivPlayPauseIcon: ImageView
    private lateinit var controlsOverlay: View
    private lateinit var overlayLeft: View
    private lateinit var overlayRight: View
    private lateinit var liveBadge: View
    private lateinit var panelSpeed: View
    private lateinit var panelSleep: View
    private lateinit var layoutLocked: View
    private lateinit var btnLock: ImageButton
    private lateinit var tvPlayerTitle: TextView
    private var playUrl = ""; private var playType = "LIVE"; private var playTitle = ""; private var itemKey = ""
    private var isLocked = false; private var sbDragging = false; private var ctrlVisible = true
    private var candidates = listOf<String>(); private var attempt = 0
    private var errorRetryCount = 0
    private val MAX_ERROR_RETRIES = 2
    private var audioManager: AudioManager? = null; private var maxVolume = 15
    private var gestureVolStart = 0; private var gestureBrightStart = 0.5f
    private var gestureStartY = 0f; private var isGesture = false
    private var tapLeftLast = 0L; private var tapLeftCount = 0
    private var tapRightLast = 0L; private var tapRightCount = 0
    private var sleepTimer: CountDownTimer? = null
    private val UA = "Mozilla/5.0 (Linux; Android 12; SM-G998B) AppleWebKit/537.36"
    private val handler = Handler(Looper.getMainLooper())
    private val hideOverlayR = Runnable {
        tvBrightness.visibility = View.GONE; tvVolume.visibility = View.GONE
        tvInfoCenter.visibility = View.GONE
        tvSeekLeft.visibility = View.GONE; tvSeekRight.visibility = View.GONE
    }
    private val hideCtrlR = Runnable { hideCtrl() }
    private val progressR = object : Runnable {
        override fun run() { tickProgress(); handler.postDelayed(this, 500) }
    }
    override fun onCreate(s: Bundle?) {
        super.onCreate(s)
        prefs = Prefs(this)
        window.run {
            addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN)
            decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        }
        setContentView(R.layout.activity_player_pro)
        playUrl   = intent.getStringExtra("URL") ?: ""
        playType  = intent.getStringExtra("TYPE") ?: "LIVE"
        playTitle = intent.getStringExtra("TITLE") ?: ""
        itemKey   = intent.getStringExtra("ITEM_KEY") ?: ""
        val ref   = intent.getStringExtra("REF") ?: ""
        val org   = intent.getStringExtra("ORG") ?: ""
        if (playUrl.isEmpty()) { Toast.makeText(this,"Gecersiz URL",Toast.LENGTH_SHORT).show(); finish(); return }
        candidates = buildCandidates(playUrl, playType)
        bindViews()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        maxVolume = audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: 15
        gestureBrightStart = window.attributes.screenBrightness.let { if (it in 0f..1f) it else 0.5f }
        pvMain.useController = false; applyAspect()
        setupButtons(); setupSeekBar(); setupGestures()
        val resumeMs = if (playType != "LIVE" && itemKey.isNotEmpty()) prefs.getResumePosMs(itemKey) else -1L
        if (resumeMs > 30_000L) {
            val pct = prefs.getResumePct(itemKey)
            AlertDialog.Builder(this)
                .setTitle("Kaldigi yerden devam et?")
                .setMessage("%$pct izlemistin. Devam et?")
                .setPositiveButton("Devam Et") { _, _ -> buildPlayer(candidates[attempt], ref, org, resumeMs) }
                .setNegativeButton("Bastan Basla") { _, _ -> prefs.clearResume(itemKey); buildPlayer(candidates[attempt], ref, org, 0L) }
                .setCancelable(false).show()
        } else {
            buildPlayer(candidates[attempt], ref, org, 0L)
        }
        handler.post(progressR); schedHide()
    }
    private fun buildCandidates(url: String, kind: String): List<String> {
        val set = linkedSetOf(url)
        if (kind == "LIVE") {
            val base = url.replace(Regex("""\.(m3u8|ts|mp4)(\?.*)?$""", RegexOption.IGNORE_CASE), "")
            set.add("$base.ts"); set.add("$base.m3u8"); set.add(base)
        }
        return set.filter { it.isNotEmpty() }
    }
    private fun buildPlayer(url: String, ref: String, org: String, startMs: Long) {
        findViewById<View>(R.id.layoutPlayerError).visibility = View.GONE
        player?.release()
        val headers = mutableMapOf("User-Agent" to UA)
        if (ref.isNotEmpty()) headers["Referer"] = ref
        if (org.isNotEmpty()) headers["Origin"]  = org
        val factory = DefaultHttpDataSource.Factory()
            .setConnectTimeoutMs(20_000).setReadTimeoutMs(40_000)
            .setDefaultRequestProperties(headers)
        val exo = ExoPlayer.Builder(this).setMediaSourceFactory(DefaultMediaSourceFactory(factory)).build()
        player = exo; pvMain.player = exo
        exo.setMediaItem(MediaItem.fromUri(url))
        exo.prepare(); exo.playWhenReady = true
        if (startMs > 0L) exo.seekTo(startMs)
        exo.setPlaybackParameters(PlaybackParameters(currentSpeed))
        exo.addListener(object : Player.Listener {
            override fun onIsPlayingChanged(playing: Boolean) {
                ivPlayPauseIcon.setImageResource(if (playing) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play)
                pbBuffering.visibility = View.GONE
            }
            override fun onPlaybackStateChanged(state: Int) {
                pbBuffering.visibility = if (state == Player.STATE_BUFFERING) View.VISIBLE else View.GONE
                if (state == Player.STATE_READY) {
                    errorRetryCount = 0
                    if (playType != "LIVE") {
                        seekBar.visibility = View.VISIBLE
                        tvPosition.visibility = View.VISIBLE; tvDuration.visibility = View.VISIBLE
                    }
                }
                if (state == Player.STATE_ENDED && playType != "LIVE") {
                    itemKey.takeIf { it.isNotEmpty() }?.let { prefs.clearResume(it) }
                }
            }
            override fun onPlayerError(err: PlaybackException) {
                if (attempt + 1 < candidates.size) {
                    attempt++; center("Format ${attempt+1}/${candidates.size} deneniyor...")
                    buildPlayer(candidates[attempt], ref, org, 0L)
                } else if (errorRetryCount < MAX_ERROR_RETRIES) {
                    // Seek sirasinda ya da agdaki gecici bir kesintide oynatici hemen
                    // pes etmesin; kaldigi konumdan birkac kez daha baglanmayi dener.
                    errorRetryCount++
                    val resumeAt = (player?.currentPosition ?: 0L).coerceAtLeast(0L)
                    center("Baglanti sorunu, tekrar deneniyor ($errorRetryCount/$MAX_ERROR_RETRIES)...")
                    handler.postDelayed({ buildPlayer(url, ref, org, resumeAt) }, 1200)
                } else {
                    showPlayerError(err)
                    RemoteLogger.sendEvent(this@PlayerActivity,"player_error",mapOf("url" to url,"err" to (err.message?:"")))
                }
            }
        })
    }
    private fun showPlayerError(err: PlaybackException) {
        pbBuffering.visibility = View.GONE
        val code = err.errorCodeName
        val msg = err.cause?.message ?: err.message ?: "Bilinmeyen hata"
        findViewById<TextView>(R.id.tvPlayerError).text = "Yayin acilamadi.\n$code\n$msg"
        findViewById<View>(R.id.layoutPlayerError).visibility = View.VISIBLE
        findViewById<View>(R.id.btnPlayerRetry).setOnClickListener {
            attempt = 0; errorRetryCount = 0
            buildPlayer(candidates[attempt], intent.getStringExtra("REF") ?: "", intent.getStringExtra("ORG") ?: "", 0L)
        }
    }
    private fun bindViews() {
        pvMain=findViewById(R.id.pvMain); pbBuffering=findViewById(R.id.pbBuffering)
        tvInfoCenter=findViewById(R.id.tvInfoCenter); tvSeekLeft=findViewById(R.id.tvSeekLeft)
        tvSeekRight=findViewById(R.id.tvSeekRight); tvBrightness=findViewById(R.id.tvBrightness)
        tvVolume=findViewById(R.id.tvVolume); tvPosition=findViewById(R.id.tvPosition)
        tvDuration=findViewById(R.id.tvDuration); tvPlaybackSpeed=findViewById(R.id.tvPlaybackSpeed)
        tvSleepCountdown=findViewById(R.id.tvSleepCountdown); seekBar=findViewById(R.id.seekBar)
        ivPlayPauseIcon=findViewById(R.id.ivPlayPauseIcon); controlsOverlay=findViewById(R.id.controlsOverlay)
        overlayLeft=findViewById(R.id.overlayLeft); overlayRight=findViewById(R.id.overlayRight)
        liveBadge=findViewById(R.id.liveBadge); panelSpeed=findViewById(R.id.panelSpeed)
        panelSleep=findViewById(R.id.panelSleep); layoutLocked=findViewById(R.id.layoutLocked)
        btnLock=findViewById(R.id.btnLock); tvPlayerTitle=findViewById(R.id.tvPlayerTitle)
        tvPlayerTitle.text = playTitle
        if (playType == "LIVE") {
            liveBadge.visibility = View.VISIBLE
            seekBar.visibility = View.GONE; tvPosition.visibility = View.GONE; tvDuration.visibility = View.GONE
        }
        tvPlaybackSpeed.text = "1x"
        updateSeekLabels()
    }
    private fun setupButtons() {
        findViewById<View>(R.id.btnBack).setOnClickListener { finish() }
        findViewById<View>(R.id.btnPlayPause).setOnClickListener { togglePlay(); reHide() }
        findViewById<View>(R.id.btnSeekBack).setOnClickListener {
            if (playType == "LIVE") return@setOnClickListener
            val ms = prefs.getSeekSec() * 1000L; seekBy(-ms); showSeekAnim(false, "${ms/1000} sn"); reHide()
        }
        findViewById<View>(R.id.btnSeekFwd).setOnClickListener {
            if (playType == "LIVE") return@setOnClickListener
            val ms = prefs.getSeekSec() * 1000L; seekBy(ms); showSeekAnim(true, "${ms/1000} sn"); reHide()
        }
        findViewById<View>(R.id.btnMode).setOnClickListener {
            aspectMode = (aspectMode + 1) % 3; applyAspect()
            center(listOf("Sigdir","Doldur","Zoom")[aspectMode]); reHide()
        }
        findViewById<View>(R.id.btnPip).setOnClickListener {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try { enterPictureInPictureMode(PictureInPictureParams.Builder().setAspectRatio(Rational(16,9)).build()) }
                catch (e: Exception) { Toast.makeText(this,"PiP desteklenmiyor",Toast.LENGTH_SHORT).show() }
            } else Toast.makeText(this,"Android 8+ gerekli",Toast.LENGTH_SHORT).show()
        }
        findViewById<View>(R.id.btnAudioTrack).setOnClickListener { showAudioDialog() }
        findViewById<View>(R.id.btnSubtitle).setOnClickListener { showSubtitleDialog() }
        findViewById<View>(R.id.btnSleep).setOnClickListener {
            panelSpeed.visibility = View.GONE
            panelSleep.visibility = if (panelSleep.visibility == View.VISIBLE) View.GONE else View.VISIBLE
        }
        btnLock.setOnClickListener {
            isLocked = !isLocked
            controlsOverlay.visibility = if (isLocked) View.GONE else View.VISIBLE
            layoutLocked.visibility = if (isLocked) View.VISIBLE else View.GONE
            btnLock.isSelected = isLocked
            if (!isLocked) reHide()
        }
        tvPlaybackSpeed.setOnClickListener {
            panelSleep.visibility = View.GONE
            panelSpeed.visibility = if (panelSpeed.visibility == View.VISIBLE) View.GONE else View.VISIBLE
        }
        controlsOverlay.setOnClickListener { if (ctrlVisible) hideCtrl() else showCtrl() }
        pvMain.setOnClickListener { if (!ctrlVisible) showCtrl() }
        setupSpeedBtn(R.id.panelSpeed05, 0.5f); setupSpeedBtn(R.id.panelSpeed1, 1.0f)
        setupSpeedBtn(R.id.panelSpeed15, 1.5f); setupSpeedBtn(R.id.panelSpeed2, 2.0f)
        findViewById<View>(R.id.sleepOff).setOnClickListener {
            sleepTimer?.cancel(); sleepTimer=null
            tvSleepCountdown.visibility=View.GONE; panelSleep.visibility=View.GONE
            Toast.makeText(this,"Uyku iptal edildi",Toast.LENGTH_SHORT).show()
        }
        setupSleepBtn(R.id.sleep15, 15*60*1000L)
        setupSleepBtn(R.id.sleep30, 30*60*1000L)
        setupSleepBtn(R.id.sleep60, 60*60*1000L)
    }
    private fun setupSpeedBtn(id: Int, speed: Float) {
        findViewById<TextView>(id).setOnClickListener { setSpeed(speed); panelSpeed.visibility=View.GONE; reHide() }
    }
    private fun setSpeed(speed: Float) {
        currentSpeed = speed
        player?.setPlaybackParameters(PlaybackParameters(speed))
        val label = when(speed) { 0.5f->"0.5x"; 1.5f->"1.5x"; 2.0f->"2x"; else->"1x" }
        tvPlaybackSpeed.text = label; center("Hiz: $label")
        listOf(R.id.panelSpeed05 to 0.5f, R.id.panelSpeed1 to 1f, R.id.panelSpeed15 to 1.5f, R.id.panelSpeed2 to 2f).forEach { (bid, s) ->
            try { findViewById<TextView>(bid)?.isSelected = (s == speed) } catch(_:Exception) {}
        }
    }
    private fun setupSleepBtn(id: Int, ms: Long) {
        findViewById<View>(id).setOnClickListener {
            sleepTimer?.cancel(); sleepRemainMs = ms; panelSleep.visibility = View.GONE
            tvSleepCountdown.visibility = View.VISIBLE
            val label = when(ms) { 15*60*1000L->"15dk"; 30*60*1000L->"30dk"; else->"60dk" }
            Toast.makeText(this,"Uyku: $label sonra",Toast.LENGTH_SHORT).show()
            sleepTimer = object : CountDownTimer(ms, 60_000L) {
                override fun onTick(remain: Long) { tvSleepCountdown.text="${remain/60_000L}dk" }
                override fun onFinish() { player?.pause(); tvSleepCountdown.visibility=View.GONE }
            }.start()
        }
    }
    private var sleepRemainMs = 0L
    private fun showAudioDialog() {
        val p = player ?: return; val tracks = p.currentTracks
        val groups = mutableListOf<Pair<String,Int>>()
        for (gi in 0 until tracks.groups.size) {
            val g = tracks.groups[gi]
            if (g.type == C.TRACK_TYPE_AUDIO) {
                for (ti in 0 until g.length) { val f = g.getTrackFormat(ti); groups.add(Pair(f.language ?: "Ses ${gi+1}", gi)) }
            }
        }
        if (groups.isEmpty()) { Toast.makeText(this,"Baska ses izi yok",Toast.LENGTH_SHORT).show(); return }
        val items = groups.map { it.first }.toTypedArray()
        AlertDialog.Builder(this).setTitle("Ses Izi Sec")
            .setItems(items) { _, which ->
                val g = tracks.groups[groups[which].second]
                p.trackSelectionParameters = p.trackSelectionParameters.buildUpon()
                    .setOverrideForType(TrackSelectionOverride(g.mediaTrackGroup, 0)).build()
                Toast.makeText(this,"Ses: ${items[which]}",Toast.LENGTH_SHORT).show()
            }.setNegativeButton("Iptal",null).show()
    }
    private fun showSubtitleDialog() {
        val p = player ?: return; val tracks = p.currentTracks
        val groups = mutableListOf<Pair<String,Int>>()
        for (gi in 0 until tracks.groups.size) {
            val g = tracks.groups[gi]
            if (g.type == C.TRACK_TYPE_TEXT) {
                for (ti in 0 until g.length) { val f = g.getTrackFormat(ti); groups.add(Pair(f.language ?: "Altyazi ${gi+1}", gi)) }
            }
        }
        if (groups.isEmpty()) { Toast.makeText(this,"Altyazi yok",Toast.LENGTH_SHORT).show(); return }
        val items = (listOf("Kapat") + groups.map { it.first }).toTypedArray()
        AlertDialog.Builder(this).setTitle("Altyazi Sec")
            .setItems(items) { _, which ->
                if (which == 0) {
                    p.trackSelectionParameters = p.trackSelectionParameters.buildUpon().setDisabledTrackTypes(setOf(C.TRACK_TYPE_TEXT)).build()
                    Toast.makeText(this,"Altyazi kapatildi",Toast.LENGTH_SHORT).show()
                } else {
                    val g = tracks.groups[groups[which-1].second]
                    p.trackSelectionParameters = p.trackSelectionParameters.buildUpon()
                        .setDisabledTrackTypes(emptySet())
                        .setOverrideForType(TrackSelectionOverride(g.mediaTrackGroup, 0)).build()
                    Toast.makeText(this,"Altyazi: ${items[which]}",Toast.LENGTH_SHORT).show()
                }
            }.setNegativeButton("Iptal",null).show()
    }
    private fun setupSeekBar() {
        if (playType == "LIVE") { seekBar.visibility = View.GONE; return }
        // Ilerleme 0-1000 olceginde hesaplaniyor (tickProgress/onStopTrackingTouch),
        // SeekBar'in varsayilan max'i (100) ile eslesmezse cubuk suenin ilk %10'unda
        // gorsel olarak tavan yapar - ileri sarma calismiyormus gibi gorunur.
        seekBar.max = 1000
        seekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(sb: SeekBar, p: Int, fromUser: Boolean) {
                if (fromUser) { val dur=player?.duration?:0L; if(dur>0) { val t=p.toLong()*dur/1000L; center("%02d:%02d".format(t/60000,(t/1000)%60)) } }
            }
            override fun onStartTrackingTouch(sb: SeekBar) { sbDragging=true; handler.removeCallbacks(hideCtrlR) }
            override fun onStopTrackingTouch(sb: SeekBar) {
                sbDragging=false
                val p=player
                if (p!=null && p.isCurrentMediaItemSeekable) {
                    val dur=p.duration; if(dur>0) p.seekTo(sb.progress.toLong()*dur/1000L)
                } else if (p!=null) {
                    Toast.makeText(this@PlayerActivity,"Bu yayin sarma (seek) desteklemiyor.",Toast.LENGTH_SHORT).show()
                }
                schedHide()
            }
        })
    }
    private fun setupGestures() {
        fun setup(v: View, isLeft: Boolean) {
            v.setOnTouchListener { _, event ->
                if (isLocked) return@setOnTouchListener false
                val am = audioManager
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        gestureStartY=event.y; isGesture=false
                        gestureVolStart=am?.getStreamVolume(AudioManager.STREAM_MUSIC)?:(maxVolume/2)
                        gestureBrightStart=window.attributes.screenBrightness.let{if(it in 0f..1f) it else 0.5f}
                        handler.removeCallbacks(hideOverlayR); showCtrl(); true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dy=event.y-gestureStartY
                        if(abs(dy)>40) { isGesture=true; val pct=-dy/v.height.toFloat(); if(isLeft) adjBright(pct) else adjVol(pct) }; true
                    }
                    MotionEvent.ACTION_UP -> {
                        if(!isGesture) {
                            val now=System.currentTimeMillis()
                            if(isLeft) {
                                tapLeftCount=if(now-tapLeftLast<350) tapLeftCount+1 else 1; tapLeftLast=now
                                if(tapLeftCount>=2&&playType!="LIVE") { tapLeftCount=0; val ms=prefs.getSeekSec()*1000L; seekBy(-ms); showSeekAnim(false,"${ms/1000} sn") }
                            } else {
                                tapRightCount=if(now-tapRightLast<350) tapRightCount+1 else 1; tapRightLast=now
                                if(tapRightCount>=2&&playType!="LIVE") { tapRightCount=0; val ms=prefs.getSeekSec()*1000L; seekBy(ms); showSeekAnim(true,"${ms/1000} sn") }
                            }
                        }
                        handler.removeCallbacks(hideOverlayR); handler.postDelayed(hideOverlayR,1500); schedHide(); true
                    }
                    else -> false
                }
            }
        }
        setup(overlayLeft, true); setup(overlayRight, false)
    }
    private fun tickProgress() {
        val p=player?:return; val dur=p.duration; val pos=p.currentPosition
        if(dur<=0||playType=="LIVE"||sbDragging) return
        seekBar.progress=if(dur>0) (pos*1000/dur).toInt() else 0
        tvPosition.text="%02d:%02d".format(pos/60000,(pos/1000)%60)
        tvDuration.text="%02d:%02d".format(dur/60000,(dur/1000)%60)
        if(itemKey.isNotEmpty()&&pos>5000&&dur>10000&&(pos/1000)%10==0L) {
            prefs.saveResume(itemKey,pos/1000,dur/1000)
        }
    }
    private fun togglePlay() { player?.let { if(it.isPlaying) it.pause() else it.play() } }
    private fun seekBy(ms: Long) {
        val p=player?:return
        if (!p.isCurrentMediaItemSeekable) {
            Toast.makeText(this,"Bu yayin sarma (seek) desteklemiyor.",Toast.LENGTH_SHORT).show()
            return
        }
        p.seekTo((p.currentPosition+ms).coerceIn(0L,if(p.duration>0) p.duration else Long.MAX_VALUE))
    }
    private fun applyAspect() {
        pvMain.resizeMode=when(aspectMode) { 0->AspectRatioFrameLayout.RESIZE_MODE_FIT; 1->AspectRatioFrameLayout.RESIZE_MODE_FILL; else->AspectRatioFrameLayout.RESIZE_MODE_ZOOM }
    }
    private fun adjVol(pct: Float) {
        val am=audioManager?:return; val nv=(gestureVolStart+(pct*maxVolume).toInt()).coerceIn(0,maxVolume)
        am.setStreamVolume(AudioManager.STREAM_MUSIC,nv,0)
        tvVolume.text="Ses: ${nv*100/maxVolume}%"; tvVolume.visibility=View.VISIBLE
    }
    private fun adjBright(pct: Float) {
        val nb=(gestureBrightStart+pct).coerceIn(0.01f,1f)
        window.attributes=window.attributes.also{it.screenBrightness=nb}; gestureBrightStart=nb
        tvBrightness.text="Prlk: ${(nb*100).toInt()}%"; tvBrightness.visibility=View.VISIBLE
    }
    private fun center(msg: String) {
        tvInfoCenter.text=msg; tvInfoCenter.visibility=View.VISIBLE
        handler.removeCallbacks(hideOverlayR); handler.postDelayed(hideOverlayR,1500)
    }
    private fun showSeekAnim(isForward: Boolean, label: String) {
        if(isForward) { tvSeekRight.text="+$label"; tvSeekRight.visibility=View.VISIBLE }
        else { tvSeekLeft.text="-$label"; tvSeekLeft.visibility=View.VISIBLE }
        handler.removeCallbacks(hideOverlayR); handler.postDelayed(hideOverlayR,1500)
    }
    private fun showCtrl() { ctrlVisible=true; if(!isLocked) controlsOverlay.visibility=View.VISIBLE; schedHide() }
    private fun hideCtrl() { ctrlVisible=false; controlsOverlay.visibility=View.GONE; panelSpeed.visibility=View.GONE; panelSleep.visibility=View.GONE }
    private fun schedHide() { handler.removeCallbacks(hideCtrlR); handler.postDelayed(hideCtrlR,4000) }
    private fun reHide() { showCtrl() }
    private fun updateSeekLabels() {
        val sec=prefs.getSeekSec()
        try { findViewById<TextView>(R.id.tvSeekBackLabel).text="$sec sn"; findViewById<TextView>(R.id.tvSeekFwdLabel).text="$sec sn" } catch(_:Exception) {}
    }
    override fun dispatchKeyEvent(ev: KeyEvent): Boolean {
        if(isLocked) {
            if(ev.keyCode==KeyEvent.KEYCODE_BACK&&ev.action==KeyEvent.ACTION_DOWN) {
                isLocked=false; controlsOverlay.visibility=View.VISIBLE; layoutLocked.visibility=View.GONE; btnLock.isSelected=false; reHide()
            }
            return true
        }
        if(ev.action!=KeyEvent.ACTION_DOWN) return super.dispatchKeyEvent(ev)
        showCtrl()
        val seekMs=prefs.getSeekSec()*1000L
        return when(ev.keyCode) {
            KeyEvent.KEYCODE_DPAD_CENTER,KeyEvent.KEYCODE_ENTER,KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> { togglePlay(); true }
            KeyEvent.KEYCODE_DPAD_LEFT,KeyEvent.KEYCODE_MEDIA_REWIND ->
                if(playType!="LIVE") { seekBy(-seekMs); showSeekAnim(false,"${seekMs/1000} sn"); true } else false
            KeyEvent.KEYCODE_DPAD_RIGHT,KeyEvent.KEYCODE_MEDIA_FAST_FORWARD ->
                if(playType!="LIVE") { seekBy(seekMs); showSeekAnim(true,"${seekMs/1000} sn"); true } else false
            KeyEvent.KEYCODE_DPAD_UP -> {
                val am=audioManager?:return true
                val nv=(am.getStreamVolume(AudioManager.STREAM_MUSIC)+1).coerceAtMost(maxVolume)
                am.setStreamVolume(AudioManager.STREAM_MUSIC,nv,0); center("Ses: ${nv*100/maxVolume}%"); true
            }
            KeyEvent.KEYCODE_DPAD_DOWN -> {
                val am=audioManager?:return true
                val nv=(am.getStreamVolume(AudioManager.STREAM_MUSIC)-1).coerceAtLeast(0)
                am.setStreamVolume(AudioManager.STREAM_MUSIC,nv,0); center("Ses: ${nv*100/maxVolume}%"); true
            }
            KeyEvent.KEYCODE_BACK -> { finish(); true }
            else -> super.dispatchKeyEvent(ev)
        }
    }
    override fun onUserLeaveHint() {
        if(Build.VERSION.SDK_INT>=Build.VERSION_CODES.O&&player?.isPlaying==true) {
            try { enterPictureInPictureMode(PictureInPictureParams.Builder().setAspectRatio(Rational(16,9)).build()) } catch(_:Exception) {}
        }
    }
    override fun onPause() {
        super.onPause()
        if(Build.VERSION.SDK_INT<Build.VERSION_CODES.O||!isInPictureInPictureMode) player?.pause()
    }
    override fun onStop() { super.onStop(); player?.pause() }
    override fun onDestroy() {
        super.onDestroy(); sleepTimer?.cancel()
        handler.removeCallbacksAndMessages(null); player?.release(); player=null
    }
}

