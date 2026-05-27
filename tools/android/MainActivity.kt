package com.idaradz.idara_dz_android

import android.annotation.SuppressLint
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfDocument
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
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
            var webView: WebView? = null
            try {
                // HTML is laid out as a fixed A4 page in CSS pixels.
                // The PDF page itself is real A4 points: 595 x 842.
                // We render the WebView to a scaled canvas so the whole page fits,
                // instead of capturing a zoomed or cropped portion of the document.
                val contentWidthPx = 794
                val contentHeightPx = 1123
                val pdfWidthPt = 595
                val pdfHeightPt = 842
                val scaleX = pdfWidthPt.toFloat() / contentWidthPx.toFloat()
                val scaleY = pdfHeightPt.toFloat() / contentHeightPx.toFloat()

                webView = WebView(this)
                val view = webView!!
                view.setBackgroundColor(Color.WHITE)
                view.setLayerType(View.LAYER_TYPE_SOFTWARE, null)
                view.settings.javaScriptEnabled = false
                view.settings.defaultTextEncodingName = "utf-8"
                view.settings.loadWithOverviewMode = false
                view.settings.useWideViewPort = false
                view.settings.loadsImagesAutomatically = true
                view.isVerticalScrollBarEnabled = false
                view.isHorizontalScrollBarEnabled = false
                view.visibility = View.VISIBLE

                val params = FrameLayout.LayoutParams(contentWidthPx, contentHeightPx)
                params.leftMargin = -contentWidthPx - 200
                params.topMargin = 0
                addContentView(view, params)

                fun cleanup() {
                    try {
                        (view.parent as? ViewGroup)?.removeView(view)
                    } catch (_: Exception) {
                    }
                    try {
                        view.destroy()
                    } catch (_: Exception) {
                    }
                }

                fun fail(code: String, message: String?) {
                    cleanup()
                    result.error(code, message ?: "Unknown PDF error", null)
                }

                fun renderToPdf() {
                    try {
                        view.measure(
                            View.MeasureSpec.makeMeasureSpec(contentWidthPx, View.MeasureSpec.EXACTLY),
                            View.MeasureSpec.makeMeasureSpec(contentHeightPx, View.MeasureSpec.EXACTLY)
                        )
                        view.layout(0, 0, contentWidthPx, contentHeightPx)

                        val document = PdfDocument()
                        try {
                            val pageInfo = PdfDocument.PageInfo.Builder(pdfWidthPt, pdfHeightPt, 1).create()
                            val page = document.startPage(pageInfo)
                            val canvas: Canvas = page.canvas
                            canvas.drawColor(Color.WHITE)
                            canvas.save()
                            canvas.scale(scaleX, scaleY)
                            view.draw(canvas)
                            canvas.restore()
                            document.finishPage(page)

                            val outputFile = File(filePath)
                            outputFile.parentFile?.mkdirs()
                            FileOutputStream(outputFile).use { stream ->
                                document.writeTo(stream)
                            }
                        } finally {
                            document.close()
                        }

                        cleanup()
                        result.success(filePath)
                    } catch (e: Exception) {
                        fail("PDF_RENDER_ERROR", e.message)
                    }
                }

                view.webViewClient = object : WebViewClient() {
                    override fun onPageFinished(finishedView: WebView, url: String?) {
                        finishedView.postDelayed({
                            try {
                                finishedView.measure(
                                    View.MeasureSpec.makeMeasureSpec(contentWidthPx, View.MeasureSpec.EXACTLY),
                                    View.MeasureSpec.makeMeasureSpec(contentHeightPx, View.MeasureSpec.EXACTLY)
                                )
                                finishedView.layout(0, 0, contentWidthPx, contentHeightPx)
                                finishedView.invalidate()

                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                    finishedView.postVisualStateCallback(
                                        System.currentTimeMillis(),
                                        object : WebView.VisualStateCallback() {
                                            override fun onComplete(requestId: Long) {
                                                finishedView.postDelayed({ renderToPdf() }, 250)
                                            }
                                        }
                                    )
                                } else {
                                    finishedView.postDelayed({ renderToPdf() }, 500)
                                }
                            } catch (e: Exception) {
                                fail("PDF_PREPARE_ERROR", e.message)
                            }
                        }, 800)
                    }
                }

                view.loadDataWithBaseURL(
                    "https://idara.dz/",
                    html,
                    "text/html",
                    "UTF-8",
                    null
                )
            } catch (e: Exception) {
                try {
                    webView?.destroy()
                } catch (_: Exception) {
                }
                result.error("PDF_CREATE_ERROR", e.message, null)
            }
        }
    }
}
