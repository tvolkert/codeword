package dev.tvolkert.codeword;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.LinkAddress;
import android.net.LinkProperties;
import android.net.Network;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.List;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class NetworkChannel {
    private static final String TAG = "flutter";
    private static final String CHANNEL_NAME = "codeword.tvolkert.dev/network";
    private static final String METHOD_NAME_GET_ADDRESSES = "getAddresses";
    public static final String ERROR_CODE_NO_NETWORK = "no_network";
    public static final String ERROR_CODE_INCOMPATIBLE_DEVICE = "incompatible_device";

    @NonNull private final FlutterEngine flutterEngine;
    @NonNull private final ConnectivityManager connectivityManager;

    @Nullable private MethodChannel channel;

    NetworkChannel(@NonNull FlutterEngine flutterEngine, @NonNull Context applicationContext) {
        this.flutterEngine = flutterEngine;
        this.connectivityManager = (ConnectivityManager) applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE);
    }

    public void register() {
        if (channel != null) {
            // Already registered.
            return;
        }

        channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler((MethodCall methodCall, MethodChannel.Result result) -> {
            switch (methodCall.method) {
                case METHOD_NAME_GET_ADDRESSES:
                    getAddresses(result);
                    break;
                default:
                    result.notImplemented();
            }
        });
    }

    private void getAddresses(MethodChannel.Result result) {
        List<String> data = new ArrayList<String>();
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            @Nullable final Network network = connectivityManager.getActiveNetwork();
            if (network == null) {
                result.error(ERROR_CODE_NO_NETWORK, null, null);
            }

            @Nullable final LinkProperties linkProperties = connectivityManager.getLinkProperties(network);
            if (linkProperties == null) {
                result.error(ERROR_CODE_NO_NETWORK, null, null);
            }

            assert linkProperties != null;
            final List<LinkAddress> linkAddresses = linkProperties.getLinkAddresses();
            for (LinkAddress linkAddress : linkAddresses) {
                if (linkAddress.getAddress().getAddress().length == 4) {
                    // IPv4 address.
                    final String address = linkAddress.getAddress().getHostAddress();
                    final int prefixLength = linkAddress.getPrefixLength();
                    data.add(address + "/" + prefixLength);
                }
            }
        } else {
            result.error(ERROR_CODE_INCOMPATIBLE_DEVICE, null, null);
        }
        result.success(data);
    }
}
