package com.erdin.player

import android.widget.Button
import android.widget.EditText
import androidx.test.core.app.ApplicationProvider
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class LoginFlowCrashTest {

    @Test
    fun `filling xtream form and clicking login does not crash`() {
        val controller = Robolectric.buildActivity(LoginActivity::class.java)
        val activity = controller.create().start().resume().get()

        activity.findViewById<EditText>(R.id.etName).setText("Test Hesap")
        activity.findViewById<EditText>(R.id.etDns).setText("http://example.com:8080")
        activity.findViewById<EditText>(R.id.etUser).setText("testuser")
        activity.findViewById<EditText>(R.id.etPass).setText("testpass")

        val btn = activity.findViewById<Button>(R.id.btnAddAccount)
        btn.performClick()

        val shadowActivity = Shadows.shadowOf(activity)
        val nextIntent = shadowActivity.nextStartedActivity
        println("Next intent: " + nextIntent)

        if (nextIntent != null) {
            val nextController = Robolectric.buildActivity(ContentActivity::class.java, nextIntent)
            nextController.create().start().resume()
        }
    }

    @Test
    fun `filling m3u form and clicking login does not crash`() {
        val controller = Robolectric.buildActivity(LoginActivity::class.java)
        val activity = controller.create().start().resume().get()

        activity.findViewById<android.view.View>(R.id.cardM3u).performClick()
        activity.findViewById<EditText>(R.id.etName).setText("M3U Hesap")
        activity.findViewById<EditText>(R.id.etM3u).setText("http://example.com/playlist.m3u")

        val btn = activity.findViewById<Button>(R.id.btnAddAccount)
        btn.performClick()

        val shadowActivity = Shadows.shadowOf(activity)
        val nextIntent = shadowActivity.nextStartedActivity
        println("Next intent: " + nextIntent)

        if (nextIntent != null) {
            val nextController = Robolectric.buildActivity(ContentActivity::class.java, nextIntent)
            nextController.create().start().resume()
        }
    }
}
