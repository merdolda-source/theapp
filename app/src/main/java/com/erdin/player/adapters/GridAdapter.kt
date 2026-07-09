package com.erdin.player.adapters
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.erdin.player.R
import com.erdin.player.utils.AdsHelper
class GridAdapter(
    private var titles: List<String>,
    private var subtitles: List<String>,
    private val onClick: (Int) -> Unit
) : RecyclerView.Adapter<GridAdapter.VH>() {
    private var icons: List<String?> = emptyList()
    class VH(v: View) : RecyclerView.ViewHolder(v) {
        val cardLayout: LinearLayout = v.findViewById(R.id.cardLayout)
        val txt: TextView = v.findViewById(R.id.txtName)
        val sub: TextView = v.findViewById(R.id.txtSub)
        val posterLayout: FrameLayout = v.findViewById(R.id.posterLayout)
        val imgPoster: ImageView = v.findViewById(R.id.imgPoster)
        val txtPosterName: TextView = v.findViewById(R.id.txtPosterName)
        val adContainer: FrameLayout = v.findViewById(R.id.adContainer)
    }
    override fun onCreateViewHolder(parent: ViewGroup, vt: Int): VH =
        VH(LayoutInflater.from(parent.context).inflate(R.layout.item_grid_pro, parent, false))
    override fun onBindViewHolder(h: VH, pos: Int) {
        val t = titles[pos]
        if (t == "###AD###") {
            h.cardLayout.visibility = View.GONE; h.posterLayout.visibility = View.GONE
            h.adContainer.visibility = View.VISIBLE
            h.itemView.isFocusable = false; h.itemView.isClickable = false
            AdsHelper.loadNativeAdInto(h.adContainer.context, h.adContainer) { }
            return
        }
        h.adContainer.visibility = View.GONE
        val icon = icons.getOrNull(pos)
        if (!icon.isNullOrEmpty()) {
            h.cardLayout.visibility = View.GONE; h.posterLayout.visibility = View.VISIBLE
            h.txtPosterName.text = t
            try {
                Glide.with(h.imgPoster.context).load(icon)
                    .placeholder(R.drawable.bg_focusable).error(R.drawable.bg_focusable)
                    .into(h.imgPoster)
            } catch (_: Exception) { }
            bindFocusAndClick(h.posterLayout, pos)
        } else {
            h.posterLayout.visibility = View.GONE; h.cardLayout.visibility = View.VISIBLE
            h.txt.text = t
            val s = subtitles.getOrNull(pos) ?: ""
            h.sub.visibility = if (s.isNotEmpty()) View.VISIBLE else View.GONE; h.sub.text = s
            bindFocusAndClick(h.cardLayout, pos)
        }
    }
    private fun bindFocusAndClick(v: View, pos: Int) {
        v.isFocusable = true; v.isClickable = true
        v.setOnFocusChangeListener { view, f ->
            view.animate().scaleX(if(f) 1.05f else 1f).scaleY(if(f) 1.05f else 1f).setDuration(150).start()
            view.elevation = if (f) 10f else 0f
        }
        v.setOnClickListener { onClick(pos) }
        v.setOnKeyListener { _, code, event ->
            if (event.action == KeyEvent.ACTION_DOWN &&
                (code == KeyEvent.KEYCODE_DPAD_CENTER || code == KeyEvent.KEYCODE_ENTER)) {
                onClick(pos); true
            } else false
        }
    }
    override fun getItemCount() = titles.size
    fun update(t: List<String>, s: List<String>, ic: List<String?> = emptyList()) {
        titles = t; subtitles = s; icons = ic; notifyDataSetChanged()
    }
}
