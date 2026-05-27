package com.idaradz.idara_dz_android

import android.graphics.Color
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "idara_dz/pdf"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "htmlToPdf") {
                val html = call.argument<String>("html")
                val outputPath = call.argument<String>("outputPath")
                if (html.isNullOrBlank() || outputPath.isNullOrBlank()) {
                    result.error("INVALID_ARGS", "html أو outputPath غير صالح.", null)
                    return@setMethodCallHandler
                }
                renderHtmlToPdf(html, outputPath, result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun renderHtmlToPdf(html: String, outputPath: String, result: MethodChannel.Result) {
        runOnUiThread {
            val webView = WebView(this)
            webView.setBackgroundColor(Color.WHITE)
            webView.settings.javaScriptEnabled = false
            webView.settings.loadWithOverviewMode = false
            webView.settings.useWideViewPort = false

            var finished = false
            fun finishSuccess() {
                if (!finished) {
                    finished = true
                    webView.destroy()
                    result.success(outputPath)
                }
            }
            fun finishError(code: String, message: String, error: Throwable? = null) {
                if (!finished) {
                    finished = true
                    webView.destroy()
                    result.error(code, message, error?.message)
                }
            }

            webView.webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    webView.postDelayed({
                        try {
                            val outputFile = File(outputPath)
                            outputFile.parentFile?.mkdirs()
                            if (outputFile.exists()) outputFile.delete()

                            val printAdapter = webView.createPrintDocumentAdapter("IDARA_DZ_Document")
                            val attributes = PrintAttributes.Builder()
                                .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
                                .setResolution(PrintAttributes.Resolution("pdf", "pdf", 300, 300))
                                .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
                                .setColorMode(PrintAttributes.COLOR_MODE_COLOR)
                                .build()

                            printAdapter.onLayout(
                                null,
                                attributes,
                                null,
                                object : PrintDocumentAdapter.LayoutResultCallback() {
                                    override fun onLayoutFinished(info: android.print.PrintDocumentInfo?, changed: Boolean) {
                                        try {
                                            val descriptor = ParcelFileDescriptor.open(
                                                outputFile,
                                                ParcelFileDescriptor.MODE_CREATE or
                                                    ParcelFileDescriptor.MODE_TRUNCATE or
                                                    ParcelFileDescriptor.MODE_READ_WRITE
                                            )

                                            printAdapter.onWrite(
                                                arrayOf(PageRange.ALL_PAGES),
                                                descriptor,
                                                CancellationSignal(),
                                                object : PrintDocumentAdapter.WriteResultCallback() {
                                                    override fun onWriteFinished(pages: Array<PageRange>?) {
                                                        try {
                                                            descriptor.close()
                                                        } catch (_: Exception) {
                                                        }
                                                        finishSuccess()
                                                    }

                                                    override fun onWriteFailed(error: CharSequence?) {
                                                        try {
                                                            descriptor.close()
                                                        } catch (_: Exception) {
                                                        }
                                                        finishError("WRITE_FAILED", error?.toString() ?: "فشل إنشاء PDF.")
                                                    }
                                                }
                                            )
                                        } catch (error: Throwable) {
                                            finishError("WRITE_EXCEPTION", "فشل حفظ PDF.", error)
                                        }
                                    }

                                    override fun onLayoutFailed(error: CharSequence?) {
                                        finishError("LAYOUT_FAILED", error?.toString() ?: "فشل إعداد صفحة PDF.")
                                    }
                                },
                                Bundle()
                            )
                        } catch (error: Throwable) {
                            finishError("PDF_EXCEPTION", "فشل إنشاء PDF من HTML.", error)
                        }
                    }, 500)
                }
            }

            webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
        }
    }
}
