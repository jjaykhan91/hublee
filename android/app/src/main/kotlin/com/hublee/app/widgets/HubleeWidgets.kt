package com.hublee.app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import com.hublee.app.MainActivity
import com.hublee.app.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

internal object HubleeWidgetBinder {
    fun update(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
        kind: String,
        layoutId: Int,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, layoutId)
            val theme = widgetData.getString("${kind}_theme", "accent") ?: "accent"
            val size = widgetData.getString("${kind}_size", "comfortable")
                ?: "comfortable"
            val showTr = widgetData.getBoolean("${kind}_show_tr", true)
            val kicker = widgetData.getString("${kind}_kicker", null)
                ?.takeIf { it.isNotBlank() }
                ?: fallbackKicker(kind)
            val arabic = widgetData.getString("${kind}_arabic", null)
                ?.takeIf { it.isNotBlank() }
                ?: "Open Hublee to load today\u2019s text."
            val english = widgetData.getString("${kind}_english", "") ?: ""
            val ref = widgetData.getString("${kind}_ref", "") ?: ""
            val uri = widgetData.getString("${kind}_uri", "hublee://home")
                ?.takeIf { it.isNotBlank() }
                ?: "hublee://home"

            views.setInt(
                R.id.widget_root,
                "setBackgroundResource",
                backgroundRes(kind, theme),
            )
            val colors = textColors(kind, theme)
            views.setTextViewText(R.id.widget_kicker, kicker.uppercase())
            views.setTextColor(R.id.widget_kicker, colors.kicker)
            views.setTextViewText(R.id.widget_arabic, arabic)
            views.setTextColor(R.id.widget_arabic, colors.body)
            views.setTextViewText(R.id.widget_english, english)
            views.setTextColor(R.id.widget_english, colors.muted)
            views.setTextViewText(R.id.widget_ref, ref)
            views.setTextColor(R.id.widget_ref, colors.kicker)

            val arabicSp = when (size) {
                "compact" -> 16f
                "large" -> 24f
                else -> 20f
            }
            val englishSp = when (size) {
                "compact" -> 12f
                "large" -> 15f
                else -> 13f
            }
            views.setTextViewTextSize(
                R.id.widget_arabic,
                TypedValue.COMPLEX_UNIT_SP,
                arabicSp,
            )
            views.setTextViewTextSize(
                R.id.widget_english,
                TypedValue.COMPLEX_UNIT_SP,
                englishSp,
            )
            views.setViewVisibility(
                R.id.widget_english,
                if (showTr && english.isNotBlank()) View.VISIBLE else View.GONE,
            )
            views.setViewVisibility(
                R.id.widget_ref,
                if (ref.isNotBlank()) View.VISIBLE else View.GONE,
            )

            val parsed = try {
                Uri.parse(uri)
            } catch (_: Exception) {
                Uri.parse("hublee://home")
            }
            val tap = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                parsed,
            )
            views.setOnClickPendingIntent(R.id.widget_root, tap)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun fallbackKicker(kind: String): String = when (kind) {
        "hadith" -> "Hadith of the day"
        "qword" -> "Quran word"
        "aword" -> "Arabic word"
        else -> "Ayah of the day"
    }

    private fun backgroundRes(kind: String, theme: String): Int = when (theme) {
        "dark" -> R.drawable.widget_bg_dark
        "paper" -> R.drawable.widget_bg_paper
        "light" -> R.drawable.widget_bg_light
        else -> when (kind) {
            "hadith" -> R.drawable.widget_bg_hadith
            "aword" -> R.drawable.widget_bg_teal
            else -> R.drawable.widget_bg_ayah
        }
    }

    private data class TextPalette(val body: Int, val kicker: Int, val muted: Int)

    private fun textColors(kind: String, theme: String): TextPalette = when (theme) {
        "dark" -> TextPalette(
            Color.parseColor("#E7ECF2"),
            Color.parseColor("#8AB4FF"),
            Color.parseColor("#B8C2CF"),
        )
        "paper" -> TextPalette(
            Color.parseColor("#3F2F1F"),
            Color.parseColor("#8B5E34"),
            Color.parseColor("#6B5344"),
        )
        "light" -> TextPalette(
            Color.parseColor("#0F172A"),
            Color.parseColor("#2563EB"),
            Color.parseColor("#475569"),
        )
        else -> when (kind) {
            "hadith" -> TextPalette(
                Color.WHITE,
                Color.parseColor("#A7F3D0"),
                Color.parseColor("#D1FAE5"),
            )
            "aword" -> TextPalette(
                Color.WHITE,
                Color.parseColor("#7DD3FC"),
                Color.parseColor("#D6EEF5"),
            )
            else -> TextPalette(
                Color.WHITE,
                Color.parseColor("#C7D2FE"),
                Color.parseColor("#E0E7FF"),
            )
        }
    }
}

abstract class HubleeWidgetProvider : HomeWidgetProvider() {
    abstract val kind: String

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        HubleeWidgetBinder.update(
            context,
            appWidgetManager,
            appWidgetIds,
            widgetData,
            kind,
            R.layout.hublee_widget,
        )
    }
}

class AyahWidgetProvider : HubleeWidgetProvider() {
    override val kind = "ayah"
}

class HadithWidgetProvider : HubleeWidgetProvider() {
    override val kind = "hadith"
}

class QuranWordWidgetProvider : HubleeWidgetProvider() {
    override val kind = "qword"
}

class ArabicWordWidgetProvider : HubleeWidgetProvider() {
    override val kind = "aword"
}
