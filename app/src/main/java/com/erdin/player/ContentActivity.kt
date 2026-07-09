package com.erdin.player
import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.bottomnavigation.BottomNavigationView
import org.json.JSONArray
import org.json.JSONObject
import com.erdin.player.utils.UrlUtils
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*
import com.erdin.player.adapters.AccountsAdapter
import com.erdin.player.adapters.GridAdapter
import com.erdin.player.models.AccountProfile
import com.erdin.player.models.Category
import com.erdin.player.models.StreamItem
import com.erdin.player.utils.AdsHelper
import com.erdin.player.utils.Prefs
import com.erdin.player.utils.RemoteConfig
import com.erdin.player.utils.RemoteLogger
class ContentActivity : AppCompatActivity() {
    private lateinit var prefs:Prefs
    private lateinit var rv:RecyclerView
    private lateinit var pb:ProgressBar
    private lateinit var tvStatus:TextView
    private lateinit var tvTitle:TextView
    private lateinit var etSearch:EditText
    private lateinit var rvAccounts:RecyclerView
    private lateinit var tvDrawerUser:TextView
    private lateinit var tvDrawerExpire:TextView
    private lateinit var tvLogout:TextView
    private lateinit var tvAddAccount:TextView
    private lateinit var layoutSettings:View
    private lateinit var bottomNav:BottomNavigationView
    private var currentMode="LIVE"
    private var activeAcc:AccountProfile?=null
    private enum class Screen { CATEGORIES, ITEMS }
    private var screen=Screen.CATEGORIES
    private var selectedCategory:Category?=null
    private var categoriesAll:List<Category> = emptyList()
    private var streamsAll:List<StreamItem> = emptyList()
    private var displayTitles:List<String> = emptyList()
    private var displaySubtitles:List<String> = emptyList()
    private var displayMapIndex:List<Int> = emptyList()
    private var filteredCategoryIds:List<String> = emptyList()
    private var filteredStreamIdx:List<Int> = emptyList()
    private var gridAdapter:GridAdapter?=null
    private lateinit var layoutManager:LinearLayoutManager
    private var categoriesScrollPos=0
    private val UA="Mozilla/5.0 (Linux; Android 12; SM-G998B) AppleWebKit/537.36"
    override fun onCreate(s:Bundle?) {
        super.onCreate(s); setContentView(R.layout.activity_content)
        prefs=Prefs(this)
        AdsHelper.init(this); AdsHelper.loadInterstitial(this)
        rv=findViewById(R.id.rvContent)
        pb=findViewById(R.id.pbLoading); tvStatus=findViewById(R.id.tvStatus)
        tvTitle=findViewById(R.id.tvTitleBar); etSearch=findViewById(R.id.etSearch)
        layoutSettings=findViewById(R.id.layoutSettings)
        bottomNav=findViewById(R.id.bottomNav)
        layoutManager=LinearLayoutManager(this); rv.layoutManager=layoutManager
        gridAdapter=GridAdapter(emptyList(),emptyList()) { pos -> onGridClick(pos) }
        rv.adapter=gridAdapter
        rvAccounts=findViewById(R.id.rvAccounts); rvAccounts.layoutManager=LinearLayoutManager(this)
        tvDrawerUser=findViewById(R.id.tvDrawerUser); tvDrawerExpire=findViewById(R.id.tvDrawerExpire)
        tvLogout=findViewById(R.id.tvLogout); tvAddAccount=findViewById(R.id.tvAddAccount)
        tvLogout.setOnClickListener {
            prefs.clearActive()
            startActivity(Intent(this,LoginActivity::class.java).apply { addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK) })
            finish()
        }
        tvAddAccount.setOnClickListener { startActivity(Intent(this,LoginActivity::class.java)) }
        findViewById<View>(R.id.tvSettings).setOnClickListener {
            val sp=getSharedPreferences("EP_Prefs",0); val cur=sp.getInt("seek_sec",10)
            val opts=arrayOf("5 sn","10 sn","15 sn","30 sn","60 sn"); val vals=intArrayOf(5,10,15,30,60)
            AlertDialog.Builder(this).setTitle("Seek Suresi (simdi: ${cur}sn)")
                .setSingleChoiceItems(opts,vals.indexOfFirst{it==cur}.coerceAtLeast(0)) { dlg,w ->
                    sp.edit().putInt("seek_sec",vals[w]).apply()
                    Toast.makeText(this,"Seek: ${vals[w]}sn",Toast.LENGTH_SHORT).show(); dlg.dismiss()
                }.setNegativeButton("Iptal",null).show()
        }
        etSearch.addTextChangedListener(object:TextWatcher {
            override fun beforeTextChanged(s:CharSequence?,a:Int,b:Int,c:Int){}
            override fun afterTextChanged(s:Editable?){}
            override fun onTextChanged(s:CharSequence?,a:Int,b:Int,c:Int) {
                val q=s?.toString()?:""; if (q.length>2) applyGlobalSearch(q) else applySearchFilter(q)
            }
        })
        activeAcc=prefs.getActive()
        if (activeAcc==null) { tvStatus.text="Kayitli hesap yok."; tvStatus.visibility=View.VISIBLE; rv.visibility=View.GONE; return }
        setupAccountsList()
        bottomNav.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.nav_live -> { openMode("LIVE"); true }
                R.id.nav_vod -> { openMode("VOD"); true }
                R.id.nav_series -> { openMode("SERIES"); true }
                R.id.nav_settings -> { openSettings(); true }
                else -> false
            }
        }
        openMode("LIVE")
    }
    private fun setupAccountsList() {
        val acc=activeAcc?:return
        tvDrawerUser.text="Hesap: "+acc.name; tvDrawerExpire.text="Sure: -"
        rvAccounts.adapter=AccountsAdapter(prefs.getAccounts().toMutableList(),
            onOpen={a -> prefs.setActive(a.id); activeAcc=a; tvDrawerUser.text="Hesap: "+a.name
                openMode(currentMode) },
            onDelete={a -> AlertDialog.Builder(this).setTitle("Hesabi Sil").setMessage("Silinsin mi? "+a.name)
                .setPositiveButton("Evet") { _,_ -> prefs.deleteAccount(a.id)
                    val act=prefs.getActive()
                    if (act==null) { startActivity(Intent(this,LoginActivity::class.java)); finish() }
                    else { activeAcc=act; tvDrawerUser.text="Hesap: "+act.name; setupAccountsList() } }
                .setNegativeButton("Hayir",null).show() })
    }
    private fun openSettings() {
        setupAccountsList()
        tvTitle.text="Ayarlar"; etSearch.visibility=View.GONE
        rv.visibility=View.GONE; layoutSettings.visibility=View.VISIBLE
        pb.visibility=View.GONE; tvStatus.visibility=View.GONE
        val nativeContainer=findViewById<FrameLayout>(R.id.nativeAdContainer)
        nativeContainer.visibility=View.VISIBLE
        AdsHelper.loadNativeAdInto(this, nativeContainer) { }
    }
    private fun openMode(mode:String) {
        val acc=activeAcc; if (acc==null) { Toast.makeText(this,"Once hesap ekleyin.",Toast.LENGTH_SHORT).show(); return }
        if (acc.type=="M3U" && mode!="LIVE") {
            Toast.makeText(this,"M3U: sadece Canli TV.",Toast.LENGTH_SHORT).show()
            bottomNav.selectedItemId = R.id.nav_live
            return
        }
        currentMode=mode
        tvTitle.text=when(mode) { "VOD"->"Filmler"; "SERIES"->"Diziler"; else->"Canli TV" }
        etSearch.visibility=View.VISIBLE; layoutSettings.visibility=View.GONE; rv.visibility=View.VISIBLE
        etSearch.setText(""); screen=Screen.CATEGORIES; selectedCategory=null
        categoriesAll=emptyList(); streamsAll=emptyList()
        val nativeContainer=findViewById<FrameLayout>(R.id.nativeAdContainer)
        nativeContainer.visibility=View.VISIBLE
        AdsHelper.loadNativeAdInto(this, nativeContainer) { }
        fetchCategoriesAndStreams()
    }
    override fun onBackPressed() {
        if (layoutSettings.visibility==View.VISIBLE) { bottomNav.selectedItemId = R.id.nav_live; return }
        if (screen==Screen.ITEMS && rv.visibility==View.VISIBLE) {
            if (etSearch.text.isNotEmpty()) { etSearch.setText(""); return }
            showCategories(); return
        }
        super.onBackPressed()
    }
    private fun showCategories() {
        screen=Screen.CATEGORIES; selectedCategory=null
        tvTitle.text=when(currentMode) { "VOD"->"Filmler"; "SERIES"->"Diziler"; else->"Canli TV" }
        applySearchFilter(etSearch.text?.toString()?:"")
        layoutManager.scrollToPositionWithOffset(categoriesScrollPos,0)
    }
    private fun applyGlobalSearch(qRaw:String) {
        val q=qRaw.trim().lowercase(Locale.getDefault()); if (rv.visibility!=View.VISIBLE) return
        screen=Screen.ITEMS; useGridLayout()
        val filtered=streamsAll.filter { it.name.lowercase(Locale.getDefault()).contains(q) }
        filteredStreamIdx=filtered.map { streamsAll.indexOf(it) }
        val tt=ArrayList<String>(); val ts=ArrayList<String>(); val ti=ArrayList<Int>(); val ic=ArrayList<String?>()
        for (i in filtered.indices) {
            tt.add(filtered[i].name)
            ts.add("Kat: "+(categoriesAll.find{it.category_id==filtered[i].category_id}?.category_name?:"-"))
            ti.add(i); ic.add(filtered[i].icon_url)
        }
        displayTitles=tt; displaySubtitles=ts; displayMapIndex=ti; gridAdapter?.update(tt,ts,ic)
    }
    private fun applySearchFilter(qRaw:String) {
        val q=qRaw.trim().lowercase(Locale.getDefault()); if (rv.visibility!=View.VISIBLE) return
        val adInterval=RemoteConfig.getNativeGridInterval(this)
        val tt=ArrayList<String>(); val ts=ArrayList<String>(); val ti=ArrayList<Int>(); val ic=ArrayList<String?>()
        if (screen==Screen.CATEGORIES) {
            useListLayout()
            val cats=if(q.isEmpty()) categoriesAll else categoriesAll.filter{it.category_name.lowercase(Locale.getDefault()).contains(q)}
            filteredCategoryIds=cats.map{it.category_id}
            var count=0
            for (i in cats.indices) {
                tt.add(cats[i].category_name); ts.add(""); ti.add(i); ic.add(null); count++
                if (adInterval>0 && count%adInterval==0) { tt.add("###AD###"); ts.add(""); ti.add(-1); ic.add(null) }
            }
        } else {
            useGridLayout()
            val catId=selectedCategory?.category_id
            val items=if(catId.isNullOrEmpty()) streamsAll else streamsAll.filter{it.category_id==catId}
            val filtered=if(q.isEmpty()) items else items.filter{it.name.lowercase(Locale.getDefault()).contains(q)}
            filteredStreamIdx=filtered.map{streamsAll.indexOf(it)}
            var count=0
            for (i in filtered.indices) {
                tt.add(filtered[i].name); ts.add(""); ti.add(i); ic.add(filtered[i].icon_url); count++
                if (adInterval>0 && count%adInterval==0) { tt.add("###AD###"); ts.add(""); ti.add(-1); ic.add(null) }
            }
        }
        displayTitles=tt; displaySubtitles=ts; displayMapIndex=ti; gridAdapter?.update(tt,ts,ic)
    }
    private fun useGridLayout() {
        if (layoutManager !is androidx.recyclerview.widget.GridLayoutManager) {
            val spanCount = if (resources.configuration.screenWidthDp >= 600) 5 else 3
            layoutManager = androidx.recyclerview.widget.GridLayoutManager(this, spanCount)
            rv.layoutManager = layoutManager
        }
    }
    private fun useListLayout() {
        if (layoutManager is androidx.recyclerview.widget.GridLayoutManager) {
            layoutManager = LinearLayoutManager(this)
            rv.layoutManager = layoutManager
        }
    }
    private fun onGridClick(pos:Int) {
        if (pos<0 || pos>=displayMapIndex.size) return
        val realIndex=displayMapIndex[pos]; if (realIndex==-1) return
        val acc=activeAcc?:return
        if (screen==Screen.CATEGORIES) {
            if (realIndex<filteredCategoryIds.size) {
                val catId=filteredCategoryIds[realIndex]
                val cat=categoriesAll.find{it.category_id==catId}?:return
                categoriesScrollPos=layoutManager.findFirstVisibleItemPosition()
                selectedCategory=cat; screen=Screen.ITEMS
                tvTitle.text=when(currentMode) { "VOD"->"Filmler - "+cat.category_name; "SERIES"->"Diziler - "+cat.category_name; else->"Canli - "+cat.category_name }
                applySearchFilter(etSearch.text?.toString()?:"")
                layoutManager.scrollToPositionWithOffset(0,0)
            }
            return
        }
        if (realIndex<filteredStreamIdx.size) {
            val globalIdx=filteredStreamIdx[realIndex]; if (globalIdx !in streamsAll.indices) return
            val item=streamsAll[globalIdx]
            if (acc.type=="M3U") {
                val url=item.full_url; if (url.isNullOrEmpty()) { Toast.makeText(this,"Gecersiz M3U.",Toast.LENGTH_SHORT).show(); return }
                val itn=Intent(this,PlayerActivity::class.java)
                itn.putExtra("URL",url); itn.putExtra("REF",item.referer?:""); itn.putExtra("ORG",item.origin?:"")
                itn.putExtra("TYPE","LIVE"); itn.putExtra("TITLE",item.name); itn.putExtra("ITEM_KEY","m3u_${item.name.hashCode()}")
                AdsHelper.maybeShowOnChannelClick(this) { RemoteLogger.sendEvent(this,"play_m3u",mapOf("name" to item.name)); startActivity(itn) }
                return
            }
            if (currentMode=="SERIES" && item.series_id!=null) {
                startActivity(Intent(this,SeriesDetailActivity::class.java).apply {
                    putExtra("SERIES_ID",item.series_id?:""); putExtra("SERIES_NAME",item.name) })
                return
            }
            val dnsRaw=acc.dns?.trim()?:""; val user=(acc.user?:"").trim().split(" ").joinToString(""); val pass=acc.pass?.trim()?:""
            if (dnsRaw.isEmpty()||user.isEmpty()||pass.isEmpty()) { Toast.makeText(this,"DNS/kullanici/sifre bos.",Toast.LENGTH_SHORT).show(); return }
            val dns=if(dnsRaw.endsWith("/")) dnsRaw.dropLast(1) else dnsRaw
            val path=if(currentMode=="LIVE") "live" else "movie"
            val ext=if(currentMode=="LIVE") ".ts" else (if(!item.container_extension.isNullOrEmpty()) "."+item.container_extension else ".mp4")
            val id=item.stream_id?:""
            val playUrl="$dns/$path/${UrlUtils.encPathSegment(user)}/${UrlUtils.encPathSegment(pass)}/$id$ext"
            val itn=Intent(this,PlayerActivity::class.java)
            itn.putExtra("URL",playUrl); itn.putExtra("REF",""); itn.putExtra("ORG","")
            itn.putExtra("TYPE",if(currentMode=="LIVE") "LIVE" else if(currentMode=="SERIES") "SERIES" else "VOD")
            itn.putExtra("TITLE",item.name); itn.putExtra("ITEM_KEY","${currentMode}_$id")
            AdsHelper.maybeShowOnChannelClick(this) { RemoteLogger.sendEvent(this,"play_xtream",mapOf("name" to item.name,"mode" to currentMode)); startActivity(itn) }
        }
    }
    private fun fetchCategoriesAndStreams() {
        val acc=activeAcc?:return; pb.visibility=View.VISIBLE; tvStatus.visibility=View.GONE
        if (acc.type=="M3U") {
            val m3uUrl=acc.m3u?.trim()?:""; if (m3uUrl.isEmpty()) { pb.visibility=View.GONE; tvStatus.text="M3U link yok."; tvStatus.visibility=View.VISIBLE; return }
            Thread {
                try {
                    val result=fetchM3u(m3uUrl)
                    runOnUiThread { pb.visibility=View.GONE; categoriesAll=result.first; streamsAll=result.second; tvDrawerExpire.text="Sure: M3U"; showCategories() }
                } catch (e:Exception) { runOnUiThread { pb.visibility=View.GONE; tvStatus.text="M3U hatasi: "+(e.message?:""); tvStatus.visibility=View.VISIBLE } }
            }.start(); return
        }
        val dnsRaw=(acc.dns?:"").trim(); val user=(acc.user?:"").trim().split(" ").joinToString(""); val pass=(acc.pass?:"").trim()
        if (dnsRaw.isEmpty()||user.isEmpty()||pass.isEmpty()) { pb.visibility=View.GONE; tvStatus.text="DNS/kullanici/sifre bos."; tvStatus.visibility=View.VISIBLE; return }
        val dns=if(dnsRaw.endsWith("/")) dnsRaw.dropLast(1) else dnsRaw
        val base="$dns/player_api.php?username=${UrlUtils.encQueryParam(user)}&password=${UrlUtils.encQueryParam(pass)}"
        val catAction=when(currentMode) { "VOD"->"get_vod_categories"; "SERIES"->"get_series_categories"; else->"get_live_categories" }
        val streamsAction=when(currentMode) { "VOD"->"get_vod_streams"; "SERIES"->"get_series"; else->"get_live_streams" }
        Thread {
            try {
                val accInfo=fetchAccountInfo(base)
                val cats=fetchCategories("$base&action=$catAction")
                val streams=fetchStreams("$base&action=$streamsAction")
                runOnUiThread {
                    pb.visibility=View.GONE; categoriesAll=cats; streamsAll=streams
                    tvDrawerExpire.text="Sure: "+formatExp(accInfo.second); showCategories()
                }
            } catch(e:Exception) { runOnUiThread { pb.visibility=View.GONE; tvStatus.text="Hata: "+(e.message?:""); tvStatus.visibility=View.VISIBLE } }
        }.start()
    }
    private fun fetchM3u(urlStr:String):Pair<List<Category>,List<StreamItem>> {
        val catsMap=LinkedHashMap<String,Category>(); val list=ArrayList<StreamItem>()
        val body=httpGet(urlStr)
        var name=""; var group="Genel"; var ref:String?=null; var org:String?=null
        for (raw in body.split("\n")) {
            val line=raw.trim(); if (line.isEmpty()) continue
            when {
                line.startsWith("#EXTM3U",ignoreCase=true) -> {}
                line.startsWith("#EXTINF",ignoreCase=true) -> {
                    val gi=line.indexOf("group-title=\""); if(gi>=0) { val st=gi+"group-title=\"".length; val en=line.indexOf("\"",startIndex=st); if(en>st) group=line.substring(st,en) }
                    val ci=line.lastIndexOf(','); if(ci>=0 && ci<line.length-1) name=line.substring(ci+1).trim()
                    if(name.isEmpty()) name="Kanal"; ref=null; org=null
                }
                line.startsWith("#EXTVLCOPT:http-referrer=",ignoreCase=true) -> ref=line.substringAfter('=').trim()
                line.startsWith("#EXTVLCOPT:http-origin=",ignoreCase=true) -> org=line.substringAfter('=').trim()
                !line.startsWith("#") -> {
                    val gid=if(group.isNotEmpty()) group else "Genel"
                    catsMap.getOrPut(gid) { Category(gid,gid,false) }
                    list.add(StreamItem(name,null,null,null,gid,line,ref,org))
                    ref=null; org=null
                }
            }
        }
        return Pair(catsMap.values.toList(),list)
    }
    private fun fetchAccountInfo(baseUrl:String):Pair<String?,String?> {
        return try {
            val obj=JSONObject(httpGet(baseUrl)); val ui=obj.optJSONObject("user_info")
            if(ui!=null) Pair(ui.optString("username",null),ui.optString("exp_date",null)) else Pair(null,null)
        } catch(_:Exception) { Pair(null,null) }
    }
    private fun formatExp(exp:String?):String {
        if(exp.isNullOrEmpty()||exp=="0"||exp=="null") return "Sinirsiz"
        return try { SimpleDateFormat("dd.MM.yyyy HH:mm",Locale.getDefault()).format(Date(exp.toLong()*1000L)) } catch(_:Exception) { exp }
    }
    private fun fetchCategories(urlStr:String):List<Category> {
        val arr=JSONArray(httpGet(urlStr)); val list=ArrayList<Category>(); var i=0
        while(i<arr.length()) {
            val o=arr.getJSONObject(i); val id=o.optString("category_id",""); val name=o.optString("category_name","Kategori")
            val isAdult=o.optString("is_adult","0")=="1"||name.contains("18",ignoreCase=true)||name.contains("adult",ignoreCase=true)
            list.add(Category(id,name,isAdult)); i++
        }
        return list
    }
    private fun fetchStreams(urlStr:String):List<StreamItem> {
        val arr=JSONArray(httpGet(urlStr)); val list=ArrayList<StreamItem>(); var i=0
        while(i<arr.length()) {
            val o=arr.getJSONObject(i)
            val icon=o.optString("stream_icon",o.optString("cover",""))
            list.add(StreamItem(o.optString("name","?"),o.optString("stream_id",null),o.optString("series_id",null),o.optString("container_extension",null),o.optString("category_id",""),null,null,null,if(icon.isNotEmpty()) icon else null)); i++
        }
        return list
    }
    private fun httpGet(urlStr:String):String {
        val conn=(URL(urlStr).openConnection() as HttpURLConnection).apply {
            connectTimeout=25000; readTimeout=35000; requestMethod="GET"
            setRequestProperty("User-Agent",UA); setRequestProperty("Accept","*/*")
        }
        if(conn.responseCode!=HttpURLConnection.HTTP_OK) throw Exception("HTTP "+conn.responseCode)
        return conn.inputStream.bufferedReader(Charsets.UTF_8).use{it.readText()}
    }
}
