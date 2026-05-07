package com.spark.mkulimaproo

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Switch from LaunchTheme (red background) to NormalTheme
        // before Flutter draws its first frame — eliminates white flash
        setTheme(R.style.NormalTheme)
        super.onCreate(savedInstanceState)
    }
}