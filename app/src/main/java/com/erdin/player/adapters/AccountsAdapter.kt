package com.erdin.player.adapters
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.erdin.player.R
import com.erdin.player.models.AccountProfile
class AccountsAdapter(
    private var items: MutableList<AccountProfile>,
    private val onOpen: (AccountProfile) -> Unit,
    private val onDelete: (AccountProfile) -> Unit
) : RecyclerView.Adapter<AccountsAdapter.VH>() {
    class VH(v: View) : RecyclerView.ViewHolder(v) {
        val txtName: TextView = v.findViewById(R.id.tvAccountName)
        val txtType: TextView = v.findViewById(R.id.tvAccountType)
        val btnDelete: ImageButton = v.findViewById(R.id.btnDeleteAccount)
        val container: View = v.findViewById(R.id.accountContainer)
    }
    override fun onCreateViewHolder(parent: ViewGroup, vt: Int): VH =
        VH(LayoutInflater.from(parent.context).inflate(R.layout.item_account, parent, false))
    override fun onBindViewHolder(h: VH, pos: Int) {
        val item = items[pos]
        h.txtName.text = item.name
        h.txtType.text = if (item.type == "M3U") "M3U" else "Xtream"
        h.container.isFocusable = true; h.container.isClickable = true
        h.container.setOnFocusChangeListener { v, f ->
            v.animate().scaleX(if(f) 1.05f else 1f).scaleY(if(f) 1.05f else 1f).setDuration(150).start()
        }
        h.container.setOnClickListener { onOpen(item) }
        h.btnDelete.setOnClickListener { onDelete(item) }
        h.container.setOnKeyListener { _, code, event ->
            if (event.action == KeyEvent.ACTION_DOWN &&
                (code == KeyEvent.KEYCODE_DPAD_CENTER || code == KeyEvent.KEYCODE_ENTER)) {
                onOpen(item); true
            } else false
        }
    }
    override fun getItemCount() = items.size
    fun update(newItems: List<AccountProfile>) { items.clear(); items.addAll(newItems); notifyDataSetChanged() }
}

