package com.erdin.player
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.erdin.player.models.AccountProfile
import com.erdin.player.utils.AdsHelper
import com.erdin.player.utils.Prefs
import com.erdin.player.utils.RemoteLogger
class LoginActivity : AppCompatActivity() {
    private var isXtream = true
    override fun onCreate(s: Bundle?) {
        super.onCreate(s)
        setContentView(R.layout.activity_login)
        val prefs = Prefs(this)
        if (prefs.getActive() != null) { startActivity(Intent(this,ContentActivity::class.java)); finish(); return }
        RemoteLogger.sendEvent(this,"screen_login_open",emptyMap())
        AdsHelper.init(this)
        AdsHelper.loadInterstitial(this)
        val nativeContainer = findViewById<FrameLayout>(R.id.nativeAdContainerLogin)
        nativeContainer.visibility = View.VISIBLE
        AdsHelper.loadNativeAdInto(this, nativeContainer) { }
        val cardX = findViewById<View>(R.id.cardXtream); val cardM = findViewById<View>(R.id.cardM3u)
        val tvX = findViewById<TextView>(R.id.tvXtream); val tvM = findViewById<TextView>(R.id.tvM3u)
        val lX = findViewById<View>(R.id.layoutXtream); val lM = findViewById<View>(R.id.layoutM3u)
        val etName = findViewById<EditText>(R.id.etName)
        val etDns = findViewById<EditText>(R.id.etDns)
        val etUser = findViewById<EditText>(R.id.etUser)
        val etPass = findViewById<EditText>(R.id.etPass)
        val etM3u = findViewById<EditText>(R.id.etM3u)
        val btnAdd = findViewById<Button>(R.id.btnAddAccount)
        val lvAccounts = findViewById<ListView>(R.id.lvAccounts)
        fun updateUI() {
            if (isXtream) {
                lX.visibility=View.VISIBLE; lM.visibility=View.GONE
                cardX.setBackgroundResource(R.drawable.bg_header_card)
                cardM.setBackgroundResource(android.R.color.transparent)
                tvX.setTextColor(Color.WHITE); tvM.setTextColor(Color.parseColor("#78909C"))
            } else {
                lX.visibility=View.GONE; lM.visibility=View.VISIBLE
                cardM.setBackgroundResource(R.drawable.bg_header_card)
                cardX.setBackgroundResource(android.R.color.transparent)
                tvM.setTextColor(Color.WHITE); tvX.setTextColor(Color.parseColor("#78909C"))
            }
        }
        cardX.setOnClickListener { isXtream=true; updateUI() }
        cardM.setOnClickListener { isXtream=false; updateUI() }
        updateUI()
        fun refreshList() {
            val accounts = prefs.getAccounts().toMutableList()
            lvAccounts.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1,
                accounts.map { a -> a.name + "  (" + (if(a.type=="M3U") "M3U" else "Xtream") + ")" })
            lvAccounts.setOnItemClickListener { _,_,pos,_ ->
                prefs.setActive(accounts[pos].id); startActivity(Intent(this,ContentActivity::class.java)); finish()
            }
            lvAccounts.setOnItemLongClickListener { _,_,pos,_ ->
                val acc = accounts[pos]
                AlertDialog.Builder(this).setTitle("Hesabi Sil").setMessage(acc.name + " silinsin mi?")
                    .setPositiveButton("Sil") { _,_ -> prefs.deleteAccount(acc.id); refreshList() }
                    .setNegativeButton("Iptal",null).create().show()
                true
            }
        }
        refreshList()
        btnAdd.setOnClickListener {
            val finalName = etName.text.toString().trim().ifEmpty { "Hesap" }
            if (isXtream) {
                var d = etDns.text.toString().trim()
                val u = etUser.text.toString().trim().split(" ").joinToString("")
                val p = etPass.text.toString().trim()
                if (d.isEmpty()||u.isEmpty()||p.isEmpty()) { Toast.makeText(this,"URL, kullanici adi ve sifre zorunlu.",Toast.LENGTH_SHORT).show(); return@setOnClickListener }
                if (!d.startsWith("http://",true) && !d.startsWith("https://",true)) d = "http://$d"
                val finalDns = d.trimEnd('/')
                prefs.createXtreamAccount(finalName,finalDns,u,p)
                RemoteLogger.sendEvent(this,"account_xtream_created",mapOf("name" to finalName))
                Toast.makeText(this,"Hesap eklendi.",Toast.LENGTH_SHORT).show()
                etName.setText(""); etDns.setText(""); etUser.setText(""); etPass.setText("")
                refreshList()
                prefs.getAccounts().lastOrNull()?.let { prefs.setActive(it.id); startActivity(Intent(this,ContentActivity::class.java)); finish() }
            } else {
                var m = etM3u.text.toString().trim()
                if (m.isEmpty()) { Toast.makeText(this,"M3U URL bos olamaz.",Toast.LENGTH_SHORT).show(); return@setOnClickListener }
                if (!m.startsWith("http://",true) && !m.startsWith("https://",true)) m = "http://$m"
                prefs.createM3uAccount(finalName,m)
                RemoteLogger.sendEvent(this,"account_m3u_created",mapOf("name" to finalName))
                Toast.makeText(this,"Hesap eklendi.",Toast.LENGTH_SHORT).show()
                etName.setText(""); etM3u.setText("")
                refreshList()
                prefs.getAccounts().lastOrNull()?.let { prefs.setActive(it.id); startActivity(Intent(this,ContentActivity::class.java)); finish() }
            }
        }
    }
}

