package com.erdin.player.models
data class AccountProfile(val id:Int,val name:String,val type:String,
    val dns:String?,val user:String?,val pass:String?,val m3u:String?)
data class Category(val category_id:String,val category_name:String,val is_adult:Boolean=false)
data class StreamItem(val name:String,val stream_id:String?,val series_id:String?,
    val container_extension:String?,val category_id:String?,
    val full_url:String?,val referer:String?,val origin:String?)
data class EpisodeItem(val id:String,val title:String,
    val seasonNumber:Int,val episodeNumber:Int,val container_extension:String?)

