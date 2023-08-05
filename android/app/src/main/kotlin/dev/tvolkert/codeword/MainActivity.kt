package dev.tvolkert.codeword

import android.os.Bundle
import android.view.WindowManager

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        val networkChannel = NetworkChannel(flutterEngine!!, applicationContext)
        networkChannel.register()
    }
}
