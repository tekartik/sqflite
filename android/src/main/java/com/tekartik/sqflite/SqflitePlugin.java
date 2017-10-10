package com.tekartik.sqflite;

import android.annotation.SuppressLint;
import android.content.Context;
import android.database.Cursor;
import android.database.SQLException;
import android.database.sqlite.SQLiteCantOpenDatabaseException;
import android.database.sqlite.SQLiteDatabase;
import android.os.Handler;
import android.os.HandlerThread;
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
import static com.tekartik.sqflite.Constant.METHOD_GET_PLATFORM_VERSION;
import static com.tekartik.sqflite.Constant.METHOD_INSERT;
import static com.tekartik.sqflite.Constant.METHOD_OPEN_DATABASE;
import static com.tekartik.sqflite.Constant.METHOD_QUERY;
import static com.tekartik.sqflite.Constant.METHOD_UPDATE;
import static com.tekartik.sqflite.Constant.PARAM_ID;
import static com.tekartik.sqflite.Constant.PARAM_PATH;
import static com.tekartik.sqflite.Constant.PARAM_SQL;
import static com.tekartik.sqflite.Constant.PARAM_SQL_ARGUMENTS;

/**
 * SqflitePlugin Android implementation
 */
public class SqflitePlugin implements MethodCallHandler {

    //private MethodChannel channel;

    static private boolean LOGV = false;
    static private boolean _EXTRA_LOGV = false; // to set to true for type debugging
    static private boolean EXTRA_LOGV = false; // to set to true for type debugging
    static private String TAG = "Sqflite";
    private final Object databaseMapLocker = new Object();
    private Context context;
    private int databaseOpenCount = 0;
    private int databaseId = 0; // incremental database id

    // Database thread execution
    private HandlerThread handlerThread;
    private Handler handler;

    private class BgResult implements MethodChannel.Result {
        // Caller handler
        final Handler handler = new Handler();
        private final Result result;

        private BgResult(Result result) {
            this.result = result;
        }

        // make sure to respond in the caller thread
        public void success(final Object results) {

            handler.post(new Runnable() {
                @Override
                public void run() {
                    result.success(results);
                }
            });
        }

        public void error(final String errorCode, final String errorMessage, final Object data) {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    result.error(errorCode, errorMessage, data);
                }
            });
        }

        @Override
        public void notImplemented() {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    result.notImplemented();
                }
            });
        }
    }

    @SuppressLint("UseSparseArrays")
    private Map<Integer, Database> databaseMap = new HashMap<>();

    private SqflitePlugin(Context context) {
        this.context = context;
    }

    //
    // Plugin registration.
    //
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.tekartik.sqflite");
        channel.setMethodCallHandler(new SqflitePlugin(registrar.activity().getApplicationContext()));
    }

    private static Map<String, Object> cursorRowToMap(Cursor cursor) {
        Map<String, Object> map = new HashMap<>();
        String[] columns = cursor.getColumnNames();
        int length = columns.length;
        for (int i = 0; i < length; i++) {
            if (EXTRA_LOGV) {
                Log.d(TAG, "column " + i + " " + cursor.getType(i));
            }
            switch (cursor.getType(i)) {
                case Cursor.FIELD_TYPE_NULL:
                    map.put(columns[i], null);
                    break;
                case Cursor.FIELD_TYPE_INTEGER:
                    map.put(columns[i], cursor.getLong(i));
                    break;
                case Cursor.FIELD_TYPE_FLOAT:
                    map.put(columns[i], cursor.getDouble(i));
                    break;
                case Cursor.FIELD_TYPE_STRING:
                    map.put(columns[i], cursor.getString(i));
                    break;
                case Cursor.FIELD_TYPE_BLOB:
                    map.put(columns[i], cursor.getBlob(i));
                    break;
            }
        }
        return map;
    }

    /*
    private Long getLong(Object value) {
        if (value instanceof Long) {
            return (Long) value;
        } else if (value instanceof Integer) {
            return ((Integer) value).longValue();
        }
        return null;
    }
    */

    private Database getDatabase(int databaseId) {
        return databaseMap.get(databaseId);
    }

    private Database getDatabaseOrError(MethodCall call, Result result) {
        int databaseId = call.argument(PARAM_ID);
        Database database = getDatabase(databaseId);

        if (database != null) {
            return database;
        } else {
            result.error(Constant.SQLITE_ERROR, Constant.ERROR_DATABASE_CLOSED + " " + databaseId, null);
            return null;
        }
    }

    static private Map<String, Object> fixMap(Map<Object, Object> map) {
        Map<String, Object> newMap = new HashMap<>();
        for (Map.Entry<Object, Object> entry : map.entrySet()) {
            Object value = entry.getValue();
            if (value instanceof Map) {
                @SuppressWarnings("unchecked")
                Map<Object, Object> mapValue = (Map<Object, Object>) value;
                value = fixMap(mapValue);
            } else {
                value = toString(value);
            }
            newMap.put(toString(entry.getKey()), value);
        }
        return newMap;
    }

    // Convert a value to a string
    // especially byte[]
    static private String toString(Object value) {
        if (value == null) {
            return null;
        } else if (value instanceof byte[]) {
            List<Integer> list = new ArrayList<>();
            for (byte _byte : (byte[]) value) {
                list.add((int) _byte);
            }
            return list.toString();
        } else if (value instanceof Map) {
            @SuppressWarnings("unchecked")
            Map<Object, Object> mapValue = (Map<Object, Object>) value;
            return fixMap(mapValue).toString();
        } else {
            return value.toString();
        }
    }

    // Handle list of int as byte[]
    static private Object toValue(Object value) {
        if (value == null) {
            return null;
        } else {
            if (EXTRA_LOGV) {
                Log.d(TAG, "arg " + value.getClass().getCanonicalName() + " " + toString(value));
            }
            // Assume a list is a blog
            if (value instanceof List) {
                @SuppressWarnings("unchecked")
                List<Integer> list = (List<Integer>) value;
                byte[] blob = new byte[list.size()];
                for (int i = 0; i < list.size(); i++) {
                    blob[i] = (byte) (int) list.get(i);
                }
                value = blob;

            }
            if (EXTRA_LOGV) {
                Log.d(TAG, "arg " + value.getClass().getCanonicalName() + " " + toString(value));
            }
            return value;
        }
    }

    // Query only accept string arguments
    private List<String> getStringQuerySqlArguments(List<Object> rawArguments) {
        List<String> stringArguments = new ArrayList<>();
        if (rawArguments != null) {
            for (Object rawArgument : rawArguments) {
                stringArguments.add(toString(rawArgument));
            }
        }
        return stringArguments;
    }

    // Query only accept string arguments
    // so should not have byte[]
    private String[] getQuerySqlArguments(List<Object> rawArguments) {
        return getStringQuerySqlArguments(rawArguments).toArray(new String[0]);
    }

    private Object[] getSqlArguments(List<Object> rawArguments) {
        List<Object> fixedArguments = new ArrayList<>();
        if (rawArguments != null) {
            for (Object rawArgument : rawArguments) {
                fixedArguments.add(toValue(rawArgument));
            }
        }
        return fixedArguments.toArray(new Object[0]);
    }

    private Database executeOrError(Database database, MethodCall call, Result result) {
        String sql = call.argument(PARAM_SQL);
        List<Object> arguments = call.argument(PARAM_SQL_ARGUMENTS);
        Object[] sqlArguments = getSqlArguments(arguments);
        if (LOGV) {
            Log.d(TAG, "[" + Thread.currentThread() + "] " + sql + ((arguments == null || arguments.isEmpty()) ? "" : (" " + getStringQuerySqlArguments(arguments))));
        }
        try {
            database.getWritableDatabase().execSQL(sql, sqlArguments);
        } catch (SQLException exception) {
            handleException(exception, result, database);
            return null;
        }
        return database;
    }

    //
    // query
    //
    private void onQueryCall(final MethodCall call, Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        final BgResult bgResult = new BgResult(result);
        handler.post(new Runnable() {
            @Override
            public void run() {
                String sql = call.argument(PARAM_SQL);
                List<Object> arguments = call.argument(PARAM_SQL_ARGUMENTS);

                List<Map<String, Object>> results = new ArrayList<>();
                if (LOGV) {
                    Log.d(TAG, "[" + Thread.currentThread() + "] " + sql + ((arguments == null || arguments.isEmpty()) ? "" : (" " + arguments)));
                }
                Cursor cursor = null;
                try {
                    cursor = database.getReadableDatabase().rawQuery(sql, getQuerySqlArguments(arguments));
                    while (cursor.moveToNext()) {
                        //ContentValues cv = new ContentValues();
                        //DatabaseUtils.cursorRowToContentValues(cursor, cv);
                        Map<String, Object> map = cursorRowToMap(cursor);
                        if (LOGV) {
                            Log.d(TAG, SqflitePlugin.toString(map));
                        }
                        results.add(map);
                    }
                    bgResult.success(results);
                } catch (SQLException exception) {
                    handleException(exception, bgResult, database);
                } finally {
                    if (cursor != null) {
                        cursor.close();
                    }
                }
            }
        });
    }

    //
    // Insert
    //
    private void onInsertCall(final MethodCall call, Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        final BgResult bgResult = new BgResult(result);
        handler.post(new Runnable() {
            @Override
            public void run() {

                if (executeOrError(database, call, bgResult) == null) {
                    return;
                }

                String sql = "SELECT last_insert_rowid()";
                //if (LOGV) {
                //    Log.d(TAG, sql);
                //}
                Cursor cursor = null;
                try

                {
                    cursor = database.getWritableDatabase().rawQuery(sql, null);
                    if (cursor.moveToFirst()) {
                        long id = cursor.getLong(0);
                        if (LOGV) {
                            Log.d(TAG, "inserted " + id);
                        }
                        bgResult.success(id);
                        return;
                    } else {
                        Log.e(TAG, "Fail to read inserted it");
                    }
                    bgResult.success(null);
                } catch (
                        SQLException exception) {
                    handleException(exception, bgResult, database);
                } finally {
                    if (cursor != null) {
                        cursor.close();
                    }
                }
            }

        });
    }


    //
    // Sqflite.execute
    //
    private void onExecuteCall(final MethodCall call, Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        final BgResult bgResult = new BgResult(result);
        handler.post(new Runnable() {
            @Override
            public void run() {

                if (executeOrError(database, call, bgResult) == null) {
                    return;
                }
                bgResult.success(null);
            }
        });
    }

    //
    // Sqflite.update
    //
    private void onUpdateCall(final MethodCall call, Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        final BgResult bgResult = new BgResult(result);
        handler.post(new Runnable() {
            @Override
            public void run() {

                if (executeOrError(database, call, bgResult) == null) {
                    return;
                }
                Cursor cursor = null;
                try {
                    SQLiteDatabase db = database.getWritableDatabase();

                    cursor = db.rawQuery("SELECT changes()", null);
                    if (cursor != null && cursor.getCount() > 0 && cursor.moveToFirst()) {
                        final int changed = cursor.getInt(0);
                        if (LOGV) {
                            Log.d(TAG, "changed " + changed);
                        }
                        bgResult.success(changed);
                        return;
                    } else {
                        Log.e(TAG, "fail to read changes for Update/Delete");
                    }
                    bgResult.success(null);
                } catch (SQLException e) {
                    handleException(e, bgResult, database);
                } finally {
                    if (cursor != null) {
                        cursor.close();
                    }
                }
            }
        });
    }

    private boolean handleException(SQLException exception, Result result, String path) {
        if (exception instanceof SQLiteCantOpenDatabaseException) {
            result.error(Constant.SQLITE_ERROR, Constant.ERROR_OPEN_FAILED + " " + path, null);
            return true;
        }
        result.error(Constant.SQLITE_ERROR, exception.getMessage(), null);
        return true;
    }

    private boolean handleException(SQLException exception, Result result, Database database) {
        return handleException(exception, result, database.path);
    }

    //
    // Sqflite.open
    //
    private void onOpenDatabaseCall(MethodCall call, Result result) {
        String path = call.argument(PARAM_PATH);
        //int version = call.argument(PARAM_VERSION);
        File file = new File(path);
        File directory = new File(file.getParent());
        if (!directory.exists()) {
            if (!directory.mkdirs()) {
                if (!directory.exists()) {
                    result.error(Constant.SQLITE_ERROR, Constant.ERROR_OPEN_FAILED + " " + path, null);
                    return;
                }
            }
        }

        int databaseId;
        synchronized (databaseMapLocker) {
            databaseId = ++this.databaseId;
        }
        Database database = new Database(context, path);
        // force opening
        try {

            database.open();
        } catch (SQLException e) {
            if (handleException(e, result, path)) {
                return;
            }
            throw e;
        }

        //SQLiteDatabase sqLiteDatabase = SQLiteDatabase.openDatabase(path, null, 0);
        synchronized (databaseMapLocker) {
            if (databaseOpenCount++ == 0) {
                handlerThread = new HandlerThread("Sqflite");
                handlerThread.start();
                //TEST UI  Handler
                //handler = new Handler();
                handler = new Handler(handlerThread.getLooper());
                if (LOGV) {
                    Log.d(TAG, "starting thread" + handlerThread);
                }
            }
            databaseMap.put(databaseId, database);
            if (LOGV) {
                Log.d(TAG, "[" + Thread.currentThread() + "] opened " + databaseId + " " + path + " total open count (" + databaseOpenCount + ")");
            }
        }

        result.success(databaseId);
    }

    //
    // Sqflite.close
    //
    private void onCloseDatabaseCall(MethodCall call, Result result) {
        int databaseId = call.argument(PARAM_ID);
        Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        if (LOGV) {
            Log.d(TAG, "[" + Thread.currentThread() + "] closing " + databaseId + " " + database.path + " total open count (" + databaseOpenCount + ")");
        }
        database.close();

        synchronized (databaseMapLocker) {
            databaseMap.remove(databaseId);
            if (--databaseOpenCount == 0) {
                if (LOGV) {
                    Log.d(TAG, "stopping thread" + handlerThread);
                }
                handlerThread.quit();
                handlerThread = null;
                handler = null;
            }
        }


        result.success(null);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            // quick testing
            case METHOD_GET_PLATFORM_VERSION:
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;

            case METHOD_DEBUG_MODE: {
                Object on = call.arguments();
                LOGV = Boolean.TRUE.equals(on);
                EXTRA_LOGV = _EXTRA_LOGV && LOGV;
                result.success(null);
                break;
            }
            case METHOD_CLOSE_DATABASE: {
                onCloseDatabaseCall(call, result);
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
                onExecuteCall(call, result);
                break;
            }
            case METHOD_OPEN_DATABASE: {
                onOpenDatabaseCall(call, result);
                break;
            }
            default:
                result.notImplemented();
                break;
        }
    }

    private static class Database extends SQLiteOpenHelper {
        String path;

        private Database(Context context, String path) {
            super(context, path, null);
            this.path = path;
        }

        private void open() {
            getReadableDatabase();
        }
    }
}
