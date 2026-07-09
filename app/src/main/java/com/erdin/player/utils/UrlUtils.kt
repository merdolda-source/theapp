package com.erdin.player.utils
import java.net.URLEncoder

object UrlUtils {
    // Path segmentlerinde (ör. /live/USER/PASS/id.ext) boslugu %20 olarak kodlar,
    // URLEncoder'in query-string icin uygun "+" kodlamasini path'e tasimaz.
    fun encPathSegment(s: String): String = URLEncoder.encode(s, "UTF-8").replace("+", "%20")
    fun encQueryParam(s: String): String = URLEncoder.encode(s, "UTF-8")
}
