package com.tekartik.sqflite;

//import android.database.sqlite.SQLiteDatabase;

import android.content.ContentValues;
import android.content.Context;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.util.Log;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static com.tekartik.sqflite.Constant.METHOD_EXECUTE;
import static com.tekartik.sqflite.Constant.METHOD_INSERT;
import static com.tekartik.sqflite.Constant.PARAM_TABLE;
import static com.tekartik.sqflite.Constant.PARAM_VALUES;

/**
 * SqflitePlugin
 */
public class SqflitePlugin implements MethodCallHandler {

    static protected boolean LOGV = true;
    static final String PARAM_ID = "id";
    static final String PARAM_PATH = "path";
    static final String PARAM_VERSION = "version";
    static final String PARAM_SQL = "sql";
    static final String PARAM_SQL_ARGUMENTS = "arguments";

    static class Database extends SQLiteOpenHelper {
        public Database(Context context, String path, int version) {
            super(context, path, null, version);
        }

        @Override
        public void onCreate(SQLiteDatabase db) {

        }

        @Override
        public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {

        }
    }

    static public String TAG = "Sqflite";

    Context context;

    final Object mapLocker = new Object();
    int databaseId = 0; // incremental database id
    Map<Integer, Database> databaseMap = new HashMap<>();

    private SqflitePlugin(Context context) {
        this.context = context;
    }
    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.tekartik.sqflite");
        channel.setMethodCallHandler(new SqflitePlugin(registrar.activity().getApplicationContext()));
    }

    private Database getDatabase(int databaseId) {
        return databaseMap.get(databaseId);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;

            case "closeDatabase": {
                int databaseId = call.argument(PARAM_ID);
                Database database = getDatabase(databaseId);
                if (database != null) {
                    database.close();
                    synchronized (mapLocker) {
                        databaseMap.remove(databaseId);
                    }
                }
                break;
            }
            case METHOD_INSERT: {
                int databaseId = call.argument(PARAM_ID);
                String table = call.argument(PARAM_TABLE);
                Map<String, Object> values = call.argument(PARAM_VALUES);
                ContentValues contentValues = contentValuesFromMap(values);
                Database database = getDatabase(databaseId);
                if (LOGV) {
                    Log.d(TAG, "" + databaseId + " inserting into " + table + " " + contentValues);
                }
                try {
                    if (database != null) {
                        long id = database.getWritableDatabase().insertOrThrow(table, null, contentValues);
                        result.success(id);
                    } else {
                        result.error(METHOD_INSERT, "database " + databaseId + " not found", null);
                    }

                } catch (SQLException exception) {
                    result.error(METHOD_INSERT, table, exception);
                }
                break;
            }
            case METHOD_EXECUTE: {

                int databaseId = call.argument(PARAM_ID);
                String sql = call.argument(PARAM_SQL);
                List<Object> arguments = call.argument(PARAM_SQL_ARGUMENTS);
                if (arguments == null) {
                    arguments = new ArrayList<>();
                }
                if (LOGV) {
                    Log.d(TAG, "" + databaseId + " executing " + sql + " " + arguments);
                }
                Database database = getDatabase(databaseId);
                try {
                    if (database != null) {
                        database.getWritableDatabase().execSQL(sql, arguments.toArray());
                        result.success(null);
                    } else {
                        result.error(METHOD_EXECUTE, "database " + databaseId + " not found", null);
                    }
                } catch (SQLException exception) {
                    result.error(METHOD_EXECUTE, sql, exception);
                }
                if (LOGV) {
                    Log.d(TAG, "executed");
                }
                break;
            }
            case "openDatabase": {
                String path = call.argument(PARAM_PATH);
                int version = call.argument(PARAM_VERSION);
                File file = new File(path);
                File directory = new File(file.getParent());
                if (!directory.exists()) {
                    directory.mkdirs();
                }
                Log.d(TAG, path);
                Database database = new Database(context, path, version);
                // force opening
                database.getReadableDatabase();
                //SQLiteDatabase sqLiteDatabase = SQLiteDatabase.openDatabase(path, null, 0);
                int databaseId;
                synchronized (mapLocker) {
                    databaseId = ++this.databaseId;
                    databaseMap.put(databaseId, database);
                }
                result.success(databaseId);
                break;
            }
            default:
                result.notImplemented();
                break;
        }
    }

    private ContentValues contentValuesFromMap(Map<String, Object> values) {
        ContentValues contentValues = new ContentValues();
        for (Map.Entry<String, Object> entry : values.entrySet()) {
            Object value = entry.getValue();
            String key = entry.getKey();
            if (value instanceof String) {
                contentValues.put(key, (String)value);
            } else if (value instanceof Integer) {
                contentValues.put(key, (Integer) value);
            } else if (value instanceof Long) {
                contentValues.put(key, (Long) value);
            } else if (value == null) {
                contentValues.putNull(key);
            } else {
                throw new IllegalArgumentException("object of type " + value.getClass() + " value " + value + " not supported");
            }
        }
        return contentValues;
    }
}
