package dev.tvolkert.codeword

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network

import java.util.ArrayList
import kotlin.collections.MutableList

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NetworkChannel internal constructor(
    private val flutterEngine: FlutterEngine,
    applicationContext: Context
) {
    private val connectivityManager: ConnectivityManager =
        applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private var channel: MethodChannel? = null

    fun register() {
        if (channel != null) {
            // Already registered.
            return
        }

        val localChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel = localChannel
        localChannel.setMethodCallHandler { methodCall: MethodCall, result: MethodChannel.Result ->
            when (methodCall.method) {
                METHOD_NAME_GET_ADDRESSES -> getAddresses(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun getAddresses(result: MethodChannel.Result) {
        val data: MutableList<String> = ArrayList<String>()
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            val network: Network? = connectivityManager.activeNetwork
            if (network == null) {
                result.error(ERROR_CODE_NO_NETWORK, null, null)
            }

            val linkProperties: LinkProperties? = connectivityManager.getLinkProperties(network)
            if (linkProperties == null) {
                result.error(ERROR_CODE_NO_NETWORK, null, null)
            }

            checkNotNull(linkProperties)
            for (linkAddress in linkProperties.linkAddresses) {
                if (linkAddress.address.address.size == 4) {
                    // IPv4 address.
                    val address: String = linkAddress.address.hostAddress!!
                    val prefixLength: Int = linkAddress.prefixLength
                    data.add("$address/$prefixLength")
                }
            }
        } else {
            result.error(ERROR_CODE_INCOMPATIBLE_DEVICE, null, null)
        }
        result.success(data)
    }

    companion object {
        private const val CHANNEL_NAME = "codeword.tvolkert.dev/network"
        private const val METHOD_NAME_GET_ADDRESSES = "getAddresses"
        const val ERROR_CODE_NO_NETWORK: String = "no_network"
        const val ERROR_CODE_INCOMPATIBLE_DEVICE: String = "incompatible_device"
    }
}
