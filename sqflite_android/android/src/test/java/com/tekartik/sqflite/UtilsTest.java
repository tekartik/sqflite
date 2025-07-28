package com.tekartik.sqflite;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

import java.util.Locale;

/**
 * Utils test
 */

public class UtilsTest {

    @Test
    public void threadId() {
        Thread thread = Thread.currentThread();
        long threadId = Utils.getThreadId(thread);
        long threadId2 = Utils.getThreadId(thread);
        assertEquals(threadId, threadId2);
    }

    @Test
    public void localOf() {
        // Locale.of is only available on Android 36+
        // For earlier versions, we use the deprecated constructor
        // which is still valid for creating a Locale object.
        String language = "en";
        String country = "US";
        String variant = "variant";
        Locale locale = Utils.localOf(language, country, variant);
        assertEquals(language, locale.getLanguage());
        assertEquals(country, locale.getCountry());
        assertEquals(variant, locale.getVariant());
    }
}
