package com.erdin.player.adapters
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.google.android.gms.ads.AdView
import com.erdin.player.R
import com.erdin.player.utils.AdsHelper
class GridAdapter(
    private var titles: List<String>,
    private var subtitles: List<String>,
    private val onClick: (Int) -> Unit
) : RecyclerView.Adapter<GridAdapter.VH>() {
    class VH(v: View) : RecyclerView.ViewHolder(v) {
        val cardLayout: LinearLayout = v.findViewById(R.id.cardLayout)
        val txt: TextView = v.findViewById(R.id.txtName)
        val sub: TextView = v.findViewById(R.id.txtSub)
        val adContainer: LinearLayout = v.findViewById(R.id.adContainer)
        val adView: AdView = v.findViewById(R.id.adViewItem)
    }
    override fun onCreateViewHolder(parent: ViewGroup, vt: Int): VH =
        VH(LayoutInflater.from(parent.context).inflate(R.layout.item_grid_pro, parent, false))
    override fun onBindViewHolder(h: VH, pos: Int) {
        val t = titles[pos]
        if (t == "###AD###") {
            h.cardLayout.visibility = View.GONE; h.adContainer.visibility = View.VISIBLE
            AdsHelper.loadBanner(h.adView); h.itemView.isFocusable = false; h.itemView.isClickable = false
        } else {
            h.adContainer.visibility = View.GONE; h.cardLayout.visibility = View.VISIBLE
            h.txt.text = t
            val s = subtitles[pos]; h.sub.visibility = if (s.isNotEmpty()) View.VISIBLE else View.GONE; h.sub.text = s
            h.cardLayout.isFocusable = true; h.cardLayout.isClickable = true
            h.cardLayout.setOnFocusChangeListener { v, f ->
                v.animate().scaleX(if(f) 1.05f else 1f).scaleY(if(f) 1.05f else 1f).setDuration(150).start()
                v.elevation = if (f) 10f else 0f
            }
            h.cardLayout.setOnClickListener { onClick(pos) }
            h.cardLayout.setOnKeyListener { _, code, event ->
                if (event.action == KeyEvent.ACTION_DOWN &&
                    (code == KeyEvent.KEYCODE_DPAD_CENTER || code == KeyEvent.KEYCODE_ENTER)) {
                    onClick(pos); true
                } else false
            }
        }
    }
    override fun getItemCount() = titles.size
    fun update(t: List<String>, s: List<String>) { titles = t; subtitles = s; notifyDataSetChanged() }
}

