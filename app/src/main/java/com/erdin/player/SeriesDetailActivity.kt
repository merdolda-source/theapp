package com.erdin.player
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import com.erdin.player.adapters.GridAdapter
import com.erdin.player.models.EpisodeItem
import com.erdin.player.utils.Prefs
import com.erdin.player.utils.RemoteConfig
class SeriesDetailActivity : AppCompatActivity() {
    private lateinit var prefs:Prefs
    private lateinit var tvTitle:TextView; private lateinit var tvStatus:TextView
    private lateinit var pb:ProgressBar; private lateinit var rv:RecyclerView
    private lateinit var gridAdapter:GridAdapter; private lateinit var layoutManager:LinearLayoutManager
    private var seriesName=""; private var seriesId=""
    private enum class Screen { SEASONS, EPISODES }
    private var screen=Screen.SEASONS
    private val seasons=mutableListOf<Int>(); private val allEpisodes=mutableListOf<EpisodeItem>()
    private var seasonsScrollPos=0
    private var displayMapIndex:List<Int> = emptyList(); private var displayEpisodes:List<EpisodeItem> = emptyList()
    private val UA="Mozilla/5.0 (Linux; Android 12; SM-G998B) AppleWebKit/537.36"
    override fun onCreate(s:Bundle?) {
        super.onCreate(s); setContentView(R.layout.activity_series_detail)
        prefs=Prefs(this); RemoteConfig.init(this)
        tvTitle=findViewById(R.id.tvSeriesTitle); tvStatus=findViewById(R.id.tvSeriesStatus)
        pb=findViewById(R.id.pbSeries); rv=findViewById(R.id.rvEpisodes)
        layoutManager=LinearLayoutManager(this); rv.layoutManager=layoutManager
        gridAdapter=GridAdapter(emptyList(),emptyList()) { pos -> onItemClick(pos) }
        rv.adapter=gridAdapter
        seriesName=intent.getStringExtra("SERIES_NAME")?:"Dizi"
        seriesId=intent.getStringExtra("SERIES_ID")?:""
        tvTitle.text=seriesName
        tvTitle.setOnClickListener { if(screen==Screen.EPISODES) showSeasons() else finish() }
        if(seriesId.isEmpty()) { tvStatus.text="Gecersiz seri."; tvStatus.visibility=View.VISIBLE; return }
        loadSeriesInfo(seriesId)
    }
    override fun onBackPressed() { if(screen==Screen.EPISODES) { showSeasons(); return }; super.onBackPressed() }
    private fun onItemClick(pos:Int) {
        if(pos<0||pos>=displayMapIndex.size) return
        val ri=displayMapIndex[pos]; if(ri==-1) return
        if(screen==Screen.SEASONS) { if(ri<seasons.size) { seasonsScrollPos=layoutManager.findFirstVisibleItemPosition(); showEpisodes(seasons[ri]) } }
        else { if(ri<displayEpisodes.size) playEpisode(displayEpisodes[ri]) }
    }
    private fun showSeasons() {
        screen=Screen.SEASONS; tvTitle.text=seriesName
        val adInterval=RemoteConfig.getBannerListInterval(this)
        val titles=ArrayList<String>(); val subs=ArrayList<String>(); val mapIndex=ArrayList<Int>(); var count=0
        for(i in seasons.indices) {
            titles.add("Sezon "+seasons[i]); subs.add(""); mapIndex.add(i); count++
            if(adInterval>0&&count%adInterval==0) { titles.add("###AD###"); subs.add(""); mapIndex.add(-1) }
        }
        displayMapIndex=mapIndex; gridAdapter.update(titles,subs)
        layoutManager.scrollToPositionWithOffset(seasonsScrollPos,0)
    }
    private fun showEpisodes(season:Int) {
        screen=Screen.EPISODES; displayEpisodes=allEpisodes.filter{it.seasonNumber==season}.sortedBy{it.episodeNumber}
        val adInterval=RemoteConfig.getBannerListInterval(this)
        val titles=ArrayList<String>(); val subs=ArrayList<String>(); val mapIndex=ArrayList<Int>(); var count=0
        for(i in displayEpisodes.indices) {
            val ep=displayEpisodes[i]
            titles.add(ep.episodeNumber.toString().padStart(2,'0')+". Bolum - "+ep.title)
            subs.add(""); mapIndex.add(i); count++
            if(adInterval>0&&count%adInterval==0) { titles.add("###AD###"); subs.add(""); mapIndex.add(-1) }
        }
        displayMapIndex=mapIndex; gridAdapter.update(titles,subs)
        tvTitle.text="$seriesName - Sezon $season"
        layoutManager.scrollToPositionWithOffset(0,0)
    }
    private fun playEpisode(ep:EpisodeItem) {
        val dns=prefs.getDns().trim().trimEnd('/')
        val user=prefs.getUser().trim().split(" ").joinToString("")
        val pass=prefs.getPass().trim()
        val ext=ep.container_extension?:"mp4"
        val url="$dns/series/$user/$pass/${ep.id}.$ext"
        startActivity(Intent(this,PlayerActivity::class.java).apply {
            putExtra("URL",url); putExtra("TYPE","VOD"); putExtra("REF",""); putExtra("ORG","")
            putExtra("TITLE",ep.title); putExtra("ITEM_KEY","series_${ep.id}")
        })
    }
    private fun loadSeriesInfo(seriesId:String) {
        val dns=prefs.getDns().trim().trimEnd('/')
        val user=prefs.getUser().trim().split(" ").joinToString("")
        val pass=prefs.getPass().trim()
        if(dns.isEmpty()||user.isEmpty()||pass.isEmpty()) { tvStatus.text="DNS/kullanici/sifre eksik."; tvStatus.visibility=View.VISIBLE; return }
        val urlStr="$dns/player_api.php?username=$user&password=$pass&action=get_series_info&series_id=$seriesId"
        pb.visibility=View.VISIBLE; tvStatus.visibility=View.GONE
        Thread {
            try {
                val conn=(URL(urlStr).openConnection() as HttpURLConnection).apply {
                    connectTimeout=15000; readTimeout=25000; requestMethod="GET"
                    setRequestProperty("User-Agent",UA)
                }
                if(conn.responseCode!=HttpURLConnection.HTTP_OK) { runOnUiThread{tvStatus.text="HTTP "+conn.responseCode; tvStatus.visibility=View.VISIBLE; pb.visibility=View.GONE}; return@Thread }
                val obj=JSONObject(conn.inputStream.bufferedReader(Charsets.UTF_8).use{it.readText()})
                val epsObj=obj.optJSONObject("episodes")?:JSONObject()
                allEpisodes.clear(); seasons.clear()
                val keys=epsObj.keys()
                while(keys.hasNext()) {
                    val key=keys.next(); val sNum=key.toIntOrNull()?:continue
                    if(!seasons.contains(sNum)) seasons.add(sNum)
                    val arr=epsObj.optJSONArray(key)?:continue
                    for(i in 0 until arr.length()) {
                        val ep=arr.getJSONObject(i)
                        allEpisodes.add(EpisodeItem(ep.optString("id",""),ep.optString("title","Bolum"),sNum,ep.optInt("episode_num",1),ep.optString("container_extension","mp4")))
                    }
                }
                seasons.sort()
                runOnUiThread {
                    pb.visibility=View.GONE
                    if(seasons.isEmpty()) { tvStatus.text="Bolum bulunamadi."; tvStatus.visibility=View.VISIBLE }
                    else showSeasons()
                }
            } catch(e:Exception) { runOnUiThread{pb.visibility=View.GONE; tvStatus.text="Hata: "+(e.message?:""); tvStatus.visibility=View.VISIBLE} }
        }.start()
    }
}

