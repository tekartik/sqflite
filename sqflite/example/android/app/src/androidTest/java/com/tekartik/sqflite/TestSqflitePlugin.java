package com.tekartik.sqflite;

import android.content.Context;

import com.tekartik.sqflite.dev.Debug;

/**
 * Allow creating the object directly
 */
public class TestSqflitePlugin extends SqflitePlugin {
    public TestSqflitePlugin(Context context) {
        super(context);
    }

    // Change log level (and return previous)
    public int setLogLevel(int logLevel) {
        int previous = SqflitePlugin.logLevel;
        SqflitePlugin.logLevel = logLevel;
        if (logLevel >= LogLevel.extra) {
            Debug.EXTRA_LOGV = true;
        }
        return previous;
    }

    // "For test only"
    @Deprecated()
    public void setExtraLogLevel() {
        setLogLevel(LogLevel.extra);
    }
}
