package com.tadbeer.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Home-screen widget: the ayah of the day on frosted glass, and the khatma's
 * progress.
 *
 * The app stores the next 30 days of ayahs, each also drawn as an image in
 * the Quranic font, so the widget shows today's even when the app has not
 * been opened since. Taps open the ayah, its reflection, or the khatma page.
 */
class TadbeerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val title = widgetData.getString("title", null)
        // Arabic-Indic digits when the app is in Arabic.
        val arabic = title?.any { it in '؀'..'ۿ' } ?: true
        val number = { n: Int -> if (arabic) toArabicDigits(n) else n.toString() }
        val ayah = todaysAyah(widgetData.getString("ayahs", null), today)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.tadbeer_widget)
            if (title != null) views.setTextViewText(R.id.widget_title, title)
            widgetData.getString("reflect_label", null)?.let {
                views.setTextViewText(R.id.widget_reflect, it)
            }

            if (ayah != null) {
                // Read leniently: data saved by an older version may lack fields.
                views.setTextViewText(R.id.widget_ayah, ayah.optString("t"))
                views.setTextViewText(R.id.widget_ref, ayah.optString("r"))
                val image = widgetData.getString("img_$today", null)
                    ?.takeIf { File(it).exists() }
                    ?.let { BitmapFactory.decodeFile(it) }
                if (image != null) {
                    views.setImageViewBitmap(R.id.widget_ayah_img, image)
                    views.setViewVisibility(R.id.widget_ayah_img, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_ayah, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_ayah_img, View.GONE)
                    views.setViewVisibility(R.id.widget_ayah, View.VISIBLE)
                }
                if (ayah.has("s") && ayah.has("a")) {
                    val verse = "s=${ayah.optInt("s")}&a=${ayah.optInt("a")}"
                    views.setOnClickPendingIntent(R.id.widget_ayah_area, open(context, "tadbeer://ayah?$verse"))
                    views.setOnClickPendingIntent(R.id.widget_reflect, open(context, "tadbeer://reflect?$verse"))
                }
            }

            val hasKhatma = widgetData.getBoolean("has_khatma", false)
            views.setViewVisibility(R.id.widget_khatma, if (hasKhatma) View.VISIBLE else View.GONE)
            if (hasKhatma) {
                val progress = widgetData.getInt("khatma_progress", 0)
                val portion = widgetData.getInt("portion", 0)
                // Pages read count only for the day they were recorded on.
                val readToday =
                    if (widgetData.getString("read_day", null) == today) widgetData.getInt("read_today", 0) else 0
                val left = (portion - readToday).coerceAtLeast(0)
                views.setProgressBar(R.id.widget_progress, 100, progress, false)
                views.setTextViewText(
                    R.id.widget_khatma_percent,
                    if (arabic) "${number(progress)}٪" else "$progress%",
                )
                views.setTextViewText(R.id.widget_khatma_title, widgetData.getString("khatma_title", ""))
                val portionText = if (left == 0) {
                    widgetData.getString("portion_done", "")
                } else {
                    widgetData.getString("portion_template", "")
                        ?.replace("{left}", number(left))
                        ?.replace("{portion}", number(portion))
                }
                val page = widgetData.getString("khatma_page", "").orEmpty()
                views.setTextViewText(
                    R.id.widget_portion,
                    if (page.isEmpty()) portionText else "$portionText · $page",
                )
                views.setTextViewText(R.id.widget_read, widgetData.getString("read_label", ""))
                views.setOnClickPendingIntent(R.id.widget_read, open(context, "tadbeer://khatma"))
            }

            views.setOnClickPendingIntent(R.id.widget_root, open(context, "tadbeer://home"))
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun open(context: Context, uri: String) =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri))

    private fun todaysAyah(json: String?, today: String): JSONObject? {
        if (json == null) return null
        val list = try {
            JSONArray(json)
        } catch (e: Exception) {
            return null
        }
        var latest: JSONObject? = null
        for (i in 0 until list.length()) {
            val item = list.getJSONObject(i)
            val day = item.optString("d")
            if (day == today) return item
            // Past the stored days, keep showing the last one.
            if (day < today) latest = item
        }
        return latest ?: if (list.length() > 0) list.getJSONObject(0) else null
    }

    private fun toArabicDigits(n: Int): String =
        n.toString().map { if (it in '0'..'9') '٠' + (it - '0') else it }.joinToString("")
}
