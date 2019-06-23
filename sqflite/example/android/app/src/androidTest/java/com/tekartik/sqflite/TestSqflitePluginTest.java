package com.tekartik.sqflite;

import android.content.Context;
import android.util.Log;

import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CountDownLatch;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

//import androidx.test.runner.AndroidJUnit4; import androidx.test.ext.junit.runners.AndroidJUnit4;

/**
 * Instrumented test, which will execute on an Android device.
 *
 * @see <a href="http://d.android.com/tools/testing">Testing documentation</a>
 */
@RunWith(AndroidJUnit4.class)
public class TestSqflitePluginTest {
    static String TAG = "SQFLTest";

    class Data {
        CountDownLatch signal;
        Integer id;
    }

    @Test
    public void openCloseDatabase() throws InterruptedException {
        final Data data = new Data();
        // Context of the app under test.
        Context appContext = ApplicationProvider.getApplicationContext();
        TestSqflitePlugin plugin = new TestSqflitePlugin(appContext);

        // Open the database
        data.signal = new CountDownLatch(1);
        Map<String, Object> param = new HashMap<>();
        param.put("path", ":memory:");
        MethodCall call = new MethodCall("openDatabase", param);
        MethodChannel.Result result = new MethodChannel.Result() {
            @Override
            public void success(Object o) {
                Log.d(TAG, "openDatabase: " + o);
                data.id = (Integer) o;
                // Should be the database id

                data.signal.countDown();
            }

            @Override
            public void error(String s, String s1, Object o) {

            }

            @Override
            public void notImplemented() {

            }
        };
        plugin.onMethodCall(call, result);
        data.signal.await();

        // Close
        data.signal = new CountDownLatch(1);
        param = new HashMap<>();
        param.put("id", data.id);
        call = new MethodCall("closeDatabase", param);
        result = new MethodChannel.Result() {
            @Override
            public void success(Object o) {
                // should be null
                Log.d(TAG, "closeDatabase: " + o);
                data.signal.countDown();
            }

            @Override
            public void error(String s, String s1, Object o) {

            }

            @Override
            public void notImplemented() {

            }
        };
        plugin.onMethodCall(call, result);
        data.signal.await();


    }
}
