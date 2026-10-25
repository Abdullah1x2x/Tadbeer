package com.tadbeer.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Home-screen widget: the ayah of the day and the khatma's progress.
 *
 * The app stores the next 30 days of ayahs, so the widget shows today's
 * even when the app has not been opened since.
 */
class TadbeerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.tadbeer_widget)
            views.setTextViewText(R.id.widget_title, widgetData.getString("title", "آية اليوم"))

            val ayah = todaysAyah(widgetData.getString("ayahs", null), today)
            views.setTextViewText(R.id.widget_ayah, ayah?.first ?: "")
            views.setTextViewText(R.id.widget_ref, ayah?.second ?: "")

            val hasKhatma = widgetData.getBoolean("has_khatma", false)
            views.setViewVisibility(R.id.widget_khatma, if (hasKhatma) View.VISIBLE else View.GONE)
            if (hasKhatma) {
                val progress = widgetData.getInt("khatma_progress", 0)
                val portion = widgetData.getInt("portion", 0)
                // Pages read count only for the day they were recorded on.
                val readToday =
                    if (widgetData.getString("read_day", null) == today) widgetData.getInt("read_today", 0) else 0
                val left = (portion - readToday).coerceAtLeast(0)
                views.setTextViewText(R.id.widget_khatma_title, widgetData.getString("khatma_title", ""))
                // Arabic-Indic digits when the app is in Arabic.
                val arabic = widgetData.getString("title", "")?.any { it in '\u0600'..'\u06FF' } ?: true
                val number = { n: Int -> if (arabic) toArabicDigits(n) else n.toString() }
                views.setTextViewText(
                    R.id.widget_khatma_percent,
                    if (arabic) "${number(progress)}٪" else "$progress%",
                )
                views.setProgressBar(R.id.widget_progress, 100, progress, false)
                views.setTextViewText(
                    R.id.widget_portion,
                    if (left == 0) {
                        widgetData.getString("portion_done", "")
                    } else {
                        widgetData.getString("portion_template", "")
                            ?.replace("{left}", number(left))
                            ?.replace("{portion}", number(portion))
                    },
                )
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun todaysAyah(json: String?, today: String): Pair<String, String>? {
        if (json == null) return null
        val list = JSONArray(json)
        var fallback: Pair<String, String>? = null
        for (i in 0 until list.length()) {
            val item = list.getJSONObject(i)
            val entry = item.getString("t") to item.getString("r")
            if (item.getString("d") == today) return entry
            // Past the stored days, keep showing the last one.
            if (item.getString("d") < today) fallback = entry
        }
        return fallback ?: if (list.length() > 0) {
            list.getJSONObject(0).let { it.getString("t") to it.getString("r") }
        } else {
            null
        }
    }

    private fun toArabicDigits(n: Int): String =
        n.toString().map { if (it in '0'..'9') '٠' + (it - '0') else it }.joinToString("")
}
