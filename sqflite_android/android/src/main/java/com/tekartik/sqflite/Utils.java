package com.tekartik.sqflite;

import static com.tekartik.sqflite.Constant.TAG;

import android.database.Cursor;
import android.os.Build;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import com.tekartik.sqflite.dev.Debug;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

public class Utils {

    static public List<Object> cursorRowToList(Cursor cursor, int length) {
        List<Object> list = new ArrayList<>(length);

        for (int i = 0; i < length; i++) {
            Object value = cursorValue(cursor, i);
            if (Debug.EXTRA_LOGV) {
                String type = getString(value);
                Log.d(TAG, "column " + i + " " + cursor.getType(i) + ": " + value + (type == null ? "" : " (" + type + ")"));
            }
            list.add(value);
        }
        return list;
    }

    @Nullable
    private static String getString(Object value) {
        String type = null;
        if (value != null) {
            if (value.getClass().isArray()) {
                try {
                    type = "array(" + Objects.requireNonNull(value.getClass().getComponentType()).getName() + ")";
                } catch (Exception e) {
                    type = "array";
                }
            } else {
                type = value.getClass().getName();
            }
        }
        return type;
    }

    static public Object cursorValue(Cursor cursor, int index) {
        switch (cursor.getType(index)) {
            case Cursor.FIELD_TYPE_NULL:
                return null;
            case Cursor.FIELD_TYPE_INTEGER:
                return cursor.getLong(index);
            case Cursor.FIELD_TYPE_FLOAT:
                return cursor.getDouble(index);
            case Cursor.FIELD_TYPE_STRING:
                return cursor.getString(index);
            case Cursor.FIELD_TYPE_BLOB:
                return cursor.getBlob(index);
        }
        return null;
    }

    static Locale localeForLanguageTag(String localeString) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            return localeForLanguageTag21(localeString);
        } else {
            return localeForLanguageTagPre21(localeString);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    static Locale localeForLanguageTag21(String localeString) {
        return Locale.forLanguageTag(localeString);
    }

    /**
     * Really basic implementation, hopefully not so many dev/apps with such requirements
     * should be impacted.
     *
     * @param localeString text such as fr-FR or fr
     * @return a Locale object
     */
    static Locale localeForLanguageTagPre21(String localeString) {
        //Locale.Builder builder = new Locale().Builder();
        String[] parts = localeString.split("-");
        String language = "";
        String country = "";
        String variant = "";
        if (parts.length > 0) {
            language = parts[0];
            if (parts.length > 1) {
                country = parts[1];

                if (parts.length > 2) {
                    variant = parts[parts.length - 1];
                }
            }
        }
        return localOf(language, country, variant);
    }

    static Locale localOf(String language, String country, String variant) {
        // SDK 36 is the minimum supported version
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            // For Android versions before 36, we can use the standard Locale constructor
            return Locale.of(language, country, variant);
        } else {
            // For Android versions before 36, we can use the standard Locale constructor
            @SuppressWarnings("deprecation")
            Locale locale = new Locale(language, country, variant);
            return locale;
        }
    }

    public static long getThreadId(Thread thread) {
        // SDK 36 is the minimum supported version
        // Build.VERSION_CODES.BAKLAVA is Android 36
        // for when Thread.threadId() is definitely available and getId() is deprecated.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) { // Android 13 (API 33) and above
            // Use the new, recommended method
            return thread.threadId();
        } else {
            // For older Android versions where threadId() might not be available
            // and getId() is still the primary way to get a thread ID.
            // Suppress the deprecation warning for this specific line.
            @SuppressWarnings("deprecation")
            long id = thread.getId();
            return id;
        }
    }

}
