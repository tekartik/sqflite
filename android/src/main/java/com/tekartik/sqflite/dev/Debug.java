package com.tekartik.sqflite.dev;

import android.util.Log;

import static android.content.ContentValues.TAG;

/**
 * Created by alex on 09/01/18.
 */

public class Debug {

    // Deprecated to prevent usage
    @Deprecated
    public static void devLog(String tag, String message) {
        Log.d(TAG, message);
    }
}
