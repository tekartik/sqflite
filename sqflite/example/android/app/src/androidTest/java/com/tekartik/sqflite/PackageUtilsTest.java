package com.tekartik.sqflite;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import android.content.Context;

import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;

/**
 * Instrumented test, which will execute on an Android device.
 *
 * @see <a href="http://d.android.com/tools/testing">Testing documentation</a>
 */
@RunWith(AndroidJUnit4.class)
public class PackageUtilsTest {
    Context appContext = ApplicationProvider.getApplicationContext();

    @Test
    public void getAppInfoMetaDataBoolean() {
        // False, uncomment in manifest to check for true
        assertEquals(Database.checkWalEnabled(appContext), PackageUtils.getAppInfoMetaDataBoolean(appContext, "com.tekartik.sqflite.wal_enabled", false));
        assertTrue(PackageUtils.getAppInfoMetaDataBoolean(appContext, "com.tekartik.sqflite.test.meta.example", false));
    }
}
