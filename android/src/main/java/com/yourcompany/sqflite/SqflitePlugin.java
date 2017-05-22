package com.yourcompany.sqflite;

//import android.database.sqlite.SQLiteDatabase;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.provider.ContactsContract;
import android.util.Log;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static android.content.ContentValues.TAG;

/**
 * SqflitePlugin
 */
public class SqflitePlugin implements MethodCallHandler {

    static final String PARAM_ID = "id";
    static final String PARAM_PATH = "path";
    static final String PARAM_VERSION = "version";

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
                int databaseId = call.argument("path");
                Database database = getDatabase(databaseId);
                if (database != null) {
                    database.close();
                    synchronized (mapLocker) {
                        databaseMap.remove(databaseId);
                    }
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
}
