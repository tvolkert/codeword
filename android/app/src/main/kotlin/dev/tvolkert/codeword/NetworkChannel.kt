package dev.tvolkert.codeword

import android.content.Context

class NetworkChannel internal constructor(
    @NonNull flutterEngine: FlutterEngine,
    @NonNull applicationContext: Context
) {
    @NonNull
    private val flutterEngine: FlutterEngine = flutterEngine

    @NonNull
    private val connectivityManager: ConnectivityManager =
        applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    @Nullable
    private var channel: MethodChannel? = null

    fun register() {
        if (channel != null) {
            // Already registered.
            return
        }

        channel = MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME)
        channel.setMethodCallHandler { methodCall: MethodCall, result: MethodChannel.Result ->
            when (methodCall.method) {
                METHOD_NAME_GET_ADDRESSES -> getAddresses(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun getAddresses(result: MethodChannel.Result) {
        val data: List<String> = ArrayList<String>()
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            @Nullable val network: Network = connectivityManager.getActiveNetwork()
            if (network == null) {
                result.error(ERROR_CODE_NO_NETWORK, null, null)
            }

            @Nullable val linkProperties: LinkProperties =
                connectivityManager.getLinkProperties(network)
            if (linkProperties == null) {
                result.error(ERROR_CODE_NO_NETWORK, null, null)
            }

            checkNotNull(linkProperties)
            val linkAddresses: List<LinkAddress> = linkProperties.getLinkAddresses()
            for (linkAddress in linkAddresses) {
                if (linkAddress.getAddress().getAddress().length === 4) {
                    // IPv4 address.
                    val address: String = linkAddress.getAddress().getHostAddress()
                    val prefixLength: Int = linkAddress.getPrefixLength()
                    data.add("$address/$prefixLength")
                }
            }
        } else {
            result.error(ERROR_CODE_INCOMPATIBLE_DEVICE, null, null)
        }
        result.success(data)
    }

    companion object {
        private const val TAG = "flutter"
        private const val CHANNEL_NAME = "codeword.tvolkert.dev/network"
        private const val METHOD_NAME_GET_ADDRESSES = "getAddresses"
        const val ERROR_CODE_NO_NETWORK: String = "no_network"
        const val ERROR_CODE_INCOMPATIBLE_DEVICE: String = "incompatible_device"
    }
}
