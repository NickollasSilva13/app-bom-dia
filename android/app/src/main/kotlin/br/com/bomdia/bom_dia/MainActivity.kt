package br.com.bomdia.bom_dia

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Geocoder
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

/**
 * Native helpers exposed on the "bom_dia/native" channel:
 * - shareToWhatsApp(path): sends the PNG straight to WhatsApp (or WhatsApp Business).
 *   Returns false when neither is installed, so Dart falls back to share_plus.
 * - reverseGeocode(latitude, longitude): city name from the platform geocoder.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "bom_dia/native"
    private val whatsappPackages = listOf("com.whatsapp", "com.whatsapp.w4b")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareToWhatsApp" -> {
                        val path = call.argument<String>("path")
                        result.success(path != null && shareToWhatsApp(path))
                    }
                    "reverseGeocode" -> {
                        val lat = call.argument<Double>("latitude")
                        val lon = call.argument<Double>("longitude")
                        if (lat == null || lon == null) {
                            result.success(null)
                        } else {
                            // Geocoder blocks on the network; keep it off the UI thread.
                            Thread {
                                val city = reverseGeocode(lat, lon)
                                runOnUiThread { result.success(city) }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isInstalled(pkg: String): Boolean = try {
        packageManager.getPackageInfo(pkg, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    private fun shareToWhatsApp(path: String): Boolean {
        val pkg = whatsappPackages.firstOrNull { isInstalled(it) } ?: return false
        val file = File(path)
        if (!file.exists()) return false
        val uri = FileProvider.getUriForFile(this, "$packageName.bomdia.fileprovider", file)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            setPackage(pkg)
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun reverseGeocode(lat: Double, lon: Double): String? = try {
        if (!Geocoder.isPresent()) {
            null
        } else {
            val address = Geocoder(this, Locale("pt", "BR")).getFromLocation(lat, lon, 1)?.firstOrNull()
            address?.locality ?: address?.subAdminArea
        }
    } catch (e: Exception) {
        null
    }
}
