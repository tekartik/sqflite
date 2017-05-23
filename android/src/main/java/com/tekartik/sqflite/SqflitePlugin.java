package com.tekartik.sqflite;

//import android.database.sqlite.SQLiteDatabase;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.DatabaseUtils;
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

import static com.tekartik.sqflite.Constant.METHOD_CLOSE_DATABASE;
import static com.tekartik.sqflite.Constant.METHOD_DEBUG_MODE;
import static com.tekartik.sqflite.Constant.METHOD_EXECUTE;
import static com.tekartik.sqflite.Constant.METHOD_INSERT;
import static com.tekartik.sqflite.Constant.METHOD_OPEN_DATABASE;
import static com.tekartik.sqflite.Constant.METHOD_QUERY;
import static com.tekartik.sqflite.Constant.METHOD_UPDATE;
import static com.tekartik.sqflite.Constant.PARAM_TABLE;
import static com.tekartik.sqflite.Constant.PARAM_VALUES;

/**
 * SqflitePlugin
 */
public class SqflitePlugin implements MethodCallHandler {

    static protected boolean LOGV = false;
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

    private Database getDatabaseOrError(MethodCall call, Result result) {
        int databaseId = call.argument(PARAM_ID);
        Database database = getDatabase(databaseId);

            if (database != null) {
                return database;
            } else {
                result.error(call.method, "database " + databaseId + " not found", null);
                return null;
            }
    }

    private void errorException(MethodCall call, Result result, Exception exception) {
        result.error(call.method, "Native exception", exception);
    }

    String[] getSqlArguments(List<Object> rawArguments) {
        List<String> stringArguments = new ArrayList<>();
        if (rawArguments != null) {
            for (Object rawArgument : rawArguments) {
                if (rawArgument == null) {
                    stringArguments.add(null);
                } else {
                    stringArguments.add(rawArgument.toString());
                }
            }
        }
        return stringArguments.toArray(new String[0]);
    }
    private void onQueryCall(MethodCall call, Result result) {
        Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        String sql = call.argument(PARAM_SQL);
        List<Object> arguments = call.argument(PARAM_SQL_ARGUMENTS);

        List<Map<String, Object>> results = new ArrayList<>();

        Cursor cursor = database.getReadableDatabase().rawQuery(sql, getSqlArguments(arguments));
        try {
            while (cursor.moveToNext()) {
                ContentValues cv = new ContentValues();
                DatabaseUtils.cursorRowToContentValues(cursor, cv);
                Map<String, Object> map = contentValuesToMap(cv);
                results.add(map);
            }
            result.success(results);
        } catch (Exception e) {
            errorException(call, result, e);
        } finally {
            cursor.close();
        }
    }


    @Deprecated
    void handleInsertSmartCall(MethodCall call, Result result) {
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
    }

    void onInsertCall(MethodCall call, Result result) {
        Database database = executeOrError(call, result);
        if (database == null) {
            return;
        }
        String sql = "SELECT last_insert_rowid()";
        if (LOGV) {
            Log.d(TAG, "Sqflite: " + sql);
        }


        Cursor cursor = database.getWritableDatabase().rawQuery(sql, null);
        try {
            if (cursor.moveToFirst()) {
                long id = cursor.getLong(0);
                if (LOGV) {
                    Log.d(TAG, "Sqflite: inserted " + id);
                }
                result.success(id);
                return;
            } else {
                if (LOGV) {
                    Log.d(TAG, "Sqfilte: has no next");
                }
            }
            result.success(null);
        } catch (Exception e) {
            errorException(call, result, e);
        } finally {
            cursor.close();
        }
    }

    void onInsertCallOld(MethodCall call, Result result) {
        Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        String sql = call.argument(PARAM_SQL);
        List<Object> arguments = call.argument(PARAM_SQL_ARGUMENTS);
        List<Map<String, Object>> results = new ArrayList<>();

        if (!sql.endsWith(";")) {
            sql += ";";
        }
        sql += " SELECT last_insert_rowid()";

        if (LOGV) {
            Log.d(TAG, "Sqflite: " + sql + " " + arguments);
        }


        Cursor cursor = database.getWritableDatabase().rawQuery(sql, getSqlArguments(arguments));
        try {
            if (cursor.moveToFirst()) {
                long id = cursor.getLong(0);
                if (LOGV) {
                    Log.d(TAG, "Sqflite: inserted " + id);
                }
                result.success(id);
                return;
            } else {
                if (LOGV) {
                    Log.d(TAG, "Sqfilte: has no next");
                }
            }
            result.success(null);
        } catch (Exception e) {
            errorException(call, result, e);
        } finally {
            cursor.close();
        }
    }

    Database executeOrError(MethodCall call, Result result) {
        Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return null;
        }
        String sql = call.argument(PARAM_SQL);
        List<Object> arguments = call.argument(PARAM_SQL_ARGUMENTS);
        if (LOGV) {
            Log.d(TAG, "Sqflite: " + sql + " " + arguments);
        }
        try {
            database.getWritableDatabase().execSQL(sql, getSqlArguments(arguments));
        } catch (SQLException exception) {
            result.error(call.method, sql, exception);
        }
        return database;

    }
    void onUpdateCall(MethodCall call, Result result) {
        Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        String sql = call.argument(PARAM_SQL);
        List<Object> arguments = call.argument(PARAM_SQL_ARGUMENTS);
        List<Map<String, Object>> results = new ArrayList<>();
        if (LOGV) {
            Log.d(TAG, "Sqflite: " + sql + " " + arguments);
        }
        Cursor cursor = database.getWritableDatabase().rawQuery(sql, getSqlArguments(arguments));
        try {
            if (cursor.moveToNext()) {
                int changed = cursor.getInt(0);
                if (LOGV) {
                    Log.d(TAG, "Sqflite: changed " + changed);
                }
                result.success(changed);
                return;
            }
            result.success(null);
        } catch (Exception e) {
            errorException(call, result, e);
        } finally {
            cursor.close();
        }
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;

            case METHOD_DEBUG_MODE: {
                LOGV = true;
                result.success(null);
                break;
            }
            case METHOD_CLOSE_DATABASE: {
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
            case METHOD_QUERY: {
                onQueryCall(call, result);
                break;
            }
            case METHOD_INSERT: {
                onInsertCall(call, result);
                break;
            }
            case METHOD_UPDATE: {
                onUpdateCall(call, result);
                break;
            }
            case METHOD_EXECUTE: {

                int databaseId = call.argument(PARAM_ID);
                String sql = call.argument(PARAM_SQL);
                List<Object> arguments = call.argument(PARAM_SQL_ARGUMENTS);
                if (LOGV) {
                    Log.d(TAG, "Sqflite: " + databaseId + " executing " + sql + " " + arguments);
                }
                Database database = getDatabase(databaseId);
                try {
                    if (database != null) {
                        database.getWritableDatabase().execSQL(sql, getSqlArguments(arguments));
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
            case METHOD_OPEN_DATABASE: {
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

    private Map<String, Object> contentValuesToMap(ContentValues cv) {
        Map<String, Object> map = new HashMap();
        for (Map.Entry<String, Object> entry : cv.valueSet()) {
            map.put(entry.getKey(), entry.getValue());
        }
        return map;
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
