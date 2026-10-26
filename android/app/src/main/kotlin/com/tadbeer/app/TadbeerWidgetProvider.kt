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
import es.antonborri.home_widget.HomeWidgetScheduler
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Home-screen widget: an ayah on frosted glass that changes every quarter
 * hour, and the khatma's progress.
 *
 * The app stores an ayah for each quarter hour of the next two days, each
 * also drawn as an image in the Quranic font; the widget picks the current
 * one from the clock and wakes itself at the next quarter hour. The glass
 * follows the app's colour theme. Taps open the ayah, its reflection, or
 * the khatma page.
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
        val glass = glassFor(widgetData.getString("theme", null))
        // Arabic-Indic digits when the app is in Arabic.
        val arabic = title?.any { it in '؀'..'ۿ' } ?: true
        val number = { n: Int -> if (arabic) toArabicDigits(n) else n.toString() }
        val ayah = currentAyah(widgetData.getString("ayahs", null), quarterOf(Calendar.getInstance()))

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.tadbeer_widget)
            views.setImageViewResource(R.id.widget_glass, glass)
            if (title != null) views.setTextViewText(R.id.widget_title, title)
            widgetData.getString("reflect_label", null)?.let {
                views.setTextViewText(R.id.widget_reflect, it)
            }

            if (ayah != null) {
                // Read leniently: data saved by an older version may lack fields.
                views.setTextViewText(R.id.widget_ayah, ayah.optString("t"))
                views.setTextViewText(R.id.widget_ref, ayah.optString("r"))
                val image = widgetData.getString("img_${ayah.optInt("s")}_${ayah.optInt("a")}", null)
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
        scheduleNextQuarter(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        HomeWidgetScheduler.cancel(context, TadbeerWidgetProvider::class.java.name)
    }

    /** Wakes the widget just after the next quarter hour begins. */
    private fun scheduleNextQuarter(context: Context) {
        val next = Calendar.getInstance().apply {
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            set(Calendar.MINUTE, (get(Calendar.MINUTE) / 15) * 15)
            add(Calendar.MINUTE, 15)
        }
        HomeWidgetScheduler.schedule(
            context,
            TadbeerWidgetProvider::class.java.name,
            listOf(next.timeInMillis + 2_000),
        )
    }

    /**
     * Number of the quarter hour [time] falls in, counted from 2020-01-01 in
     * local time, as the app counts it (HomeWidgetSync.quarterOf).
     */
    private fun quarterOf(time: Calendar): Long {
        val day = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            clear()
            set(time.get(Calendar.YEAR), time.get(Calendar.MONTH), time.get(Calendar.DAY_OF_MONTH))
        }
        val days = day.timeInMillis / 86_400_000L - EPOCH_2020_DAYS
        return days * 96 + time.get(Calendar.HOUR_OF_DAY) * 4 + time.get(Calendar.MINUTE) / 15
    }

    private fun glassFor(theme: String?): Int = when (theme) {
        "emerald" -> R.drawable.widget_glass_emerald
        "burgundy" -> R.drawable.widget_glass_burgundy
        "brown" -> R.drawable.widget_glass_brown
        "teal" -> R.drawable.widget_glass_teal
        else -> R.drawable.widget_glass_navy
    }

    private fun open(context: Context, uri: String) =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri))

    /**
     * The stored ayah for [quarter], or past the stored quarters one of them
     * in turn, so the widget keeps changing until the app refreshes it.
     */
    private fun currentAyah(json: String?, quarter: Long): JSONObject? {
        if (json == null) return null
        val list = try {
            JSONArray(json)
        } catch (e: Exception) {
            return null
        }
        if (list.length() == 0) return null
        for (i in 0 until list.length()) {
            val item = list.getJSONObject(i)
            if (item.optLong("q", -1) == quarter) return item
        }
        val first = list.getJSONObject(0).optLong("q", quarter)
        val index = (quarter - first).mod(list.length().toLong()).toInt()
        return list.getJSONObject(index)
    }

    private fun toArabicDigits(n: Int): String =
        n.toString().map { if (it in '0'..'9') '٠' + (it - '0') else it }.joinToString("")

    private companion object {
        /** Days from 1970-01-01 to 2020-01-01. */
        const val EPOCH_2020_DAYS = 18262L
    }
}
