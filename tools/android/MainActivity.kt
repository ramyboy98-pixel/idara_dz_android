package com.idaradz.idara_dz_android

import android.annotation.SuppressLint
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfDocument
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "idara_dz/pdf"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "createPdfFromHtml", "htmlToPdf", "exportHtmlToPdf" -> {
                    val html = call.argument<String>("html") ?: ""
                    val filePath = call.argument<String>("outputPath")
                        ?: call.argument<String>("filePath")
                        ?: call.argument<String>("path")
                        ?: ""

                    if (html.isBlank()) {
                        result.error("EMPTY_HTML", "HTML content is empty", null)
                        return@setMethodCallHandler
                    }
                    if (filePath.isBlank()) {
                        result.error("EMPTY_PATH", "PDF file path is empty", null)
                        return@setMethodCallHandler
                    }

                    createPdfFromHtml(html, filePath, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun createPdfFromHtml(html: String, filePath: String, result: MethodChannel.Result) {
        Handler(Looper.getMainLooper()).post {
            try {
                val webView = WebView(this)
                webView.setBackgroundColor(Color.WHITE)
                webView.settings.javaScriptEnabled = false
                webView.settings.loadWithOverviewMode = false
                webView.settings.useWideViewPort = false

                // A4 at 150 DPI. This keeps the page ratio stable and avoids Android Print callbacks.
                val pageWidthPx = 1240
                val pageHeightPx = 1754

                webView.layoutParams = android.view.ViewGroup.LayoutParams(pageWidthPx, pageHeightPx)
                webView.visibility = View.INVISIBLE

                webView.webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView, url: String?) {
                        Handler(Looper.getMainLooper()).postDelayed({
                            try {
                                view.measure(
                                    View.MeasureSpec.makeMeasureSpec(pageWidthPx, View.MeasureSpec.EXACTLY),
                                    View.MeasureSpec.makeMeasureSpec(pageHeightPx, View.MeasureSpec.EXACTLY)
                                )
                                view.layout(0, 0, pageWidthPx, pageHeightPx)

                                val document = PdfDocument()
                                val pageInfo = PdfDocument.PageInfo.Builder(pageWidthPx, pageHeightPx, 1).create()
                                val page = document.startPage(pageInfo)
                                val canvas: Canvas = page.canvas
                                canvas.drawColor(Color.WHITE)
                                view.draw(canvas)
                                document.finishPage(page)

                                val outputFile = File(filePath)
                                outputFile.parentFile?.mkdirs()
                                FileOutputStream(outputFile).use { stream ->
                                    document.writeTo(stream)
                                }
                                document.close()
                                view.destroy()

                                result.success(filePath)
                            } catch (e: Exception) {
                                result.error("PDF_RENDER_ERROR", e.message, null)
                            }
                        }, 500)
                    }
                }

                webView.loadDataWithBaseURL(
                    null,
                    html,
                    "text/html",
                    "UTF-8",
                    null
                )
            } catch (e: Exception) {
                result.error("PDF_CREATE_ERROR", e.message, null)
            }
        }
    }
}
