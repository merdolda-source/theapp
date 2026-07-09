package com.erdin.player.utils
import android.content.Context
import com.erdin.player.models.AccountProfile
import org.json.JSONArray
import org.json.JSONObject
class Prefs(ctx: Context) {
    private val appContext = ctx.applicationContext
    private val p = appContext.getSharedPreferences("EP_Prefs", 0)
    private fun loadArray(): JSONArray = try { JSONArray(p.getString("accounts_json","[]")?:"[]") } catch(e:Exception) { JSONArray() }
    private fun saveArray(arr: JSONArray) { p.edit().putString("accounts_json", arr.toString()).apply() }
    fun createXtreamAccount(name:String,dns:String,u:String,ps:String): Int {
        val id = p.getInt("next_id",1)
        val obj = JSONObject()
        obj.put("id",id); obj.put("name",name); obj.put("type","XTREAM")
        obj.put("dns",dns); obj.put("user",u); obj.put("pass",ps); obj.put("m3u","")
        val arr = loadArray(); arr.put(obj); saveArray(arr)
        p.edit().putInt("next_id",id+1).putInt("active_id",id).apply(); return id
    }
    fun createM3uAccount(name:String,m3u:String): Int {
        val id = p.getInt("next_id",1)
        val obj = JSONObject()
        obj.put("id",id); obj.put("name",name); obj.put("type","M3U")
        obj.put("dns",""); obj.put("user",""); obj.put("pass",""); obj.put("m3u",m3u)
        val arr = loadArray(); arr.put(obj); saveArray(arr)
        p.edit().putInt("next_id",id+1).putInt("active_id",id).apply(); return id
    }
    fun getAccounts(): List<AccountProfile> {
        val arr = loadArray(); val list = ArrayList<AccountProfile>(); var i = 0
        while (i < arr.length()) {
            val o = arr.optJSONObject(i)
            if (o != null) list.add(AccountProfile(o.optInt("id",0),o.optString("name",""),
                o.optString("type","XTREAM"),o.optString("dns",null),o.optString("user",null),
                o.optString("pass",null),o.optString("m3u",null)))
            i++
        }
        return list
    }
    fun deleteAccount(id: Int) {
        val arr = loadArray(); val newArr = JSONArray(); var i = 0
        while (i < arr.length()) {
            val o = arr.optJSONObject(i)
            if (o != null && o.optInt("id",0) != id) newArr.put(o); i++
        }
        saveArray(newArr)
        if (p.getInt("active_id",-1) == id) p.edit().putInt("active_id",-1).apply()
    }
    fun setActive(id:Int) { p.edit().putInt("active_id",id).apply() }
    fun clearActive() { p.edit().putInt("active_id",-1).apply() }
    fun getActive(): AccountProfile? {
        val id = p.getInt("active_id",-1); if (id <= 0) return null
        return getAccounts().find { it.id == id }
    }
    fun getLang(): String = p.getString("lang","tr") ?: "tr"
    fun getDns(): String = getActive()?.dns ?: ""
    fun getUser(): String = getActive()?.user ?: ""
    fun getPass(): String = getActive()?.pass ?: ""
    fun getSeekSec(): Int = p.getInt("seek_sec",10)
    fun setSeekSec(v:Int) { p.edit().putInt("seek_sec",v).apply() }
    fun saveResume(itemKey:String, posSec:Long, durSec:Long) {
        p.edit().putLong("resume_pos_$itemKey",posSec)
               .putLong("resume_dur_$itemKey",durSec)
               .putLong("resume_ts_$itemKey",System.currentTimeMillis())
               .apply()
    }
    fun getResumePosMs(itemKey:String): Long {
        val pos = p.getLong("resume_pos_$itemKey",-1L)
        val ts  = p.getLong("resume_ts_$itemKey",0L)
        if (ts > 0 && System.currentTimeMillis() - ts > 30L*24*3600*1000) { clearResume(itemKey); return -1L }
        return if (pos > 5) pos * 1000L else -1L
    }
    fun getResumePct(itemKey:String): Int {
        val pos = p.getLong("resume_pos_$itemKey",-1L)
        val dur = p.getLong("resume_dur_$itemKey",0L)
        return if (pos > 0 && dur > 0) ((pos * 100) / dur).toInt() else 0
    }
    fun clearResume(itemKey:String) {
        p.edit().remove("resume_pos_$itemKey").remove("resume_dur_$itemKey").remove("resume_ts_$itemKey").apply()
    }
}

