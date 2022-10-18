package com.tekartik.sqflite;

import static com.tekartik.sqflite.Constant.EMPTY_STRING_ARRAY;
import static com.tekartik.sqflite.Constant.PARAM_CANCEL;
import static com.tekartik.sqflite.Constant.PARAM_COLUMNS;
import static com.tekartik.sqflite.Constant.PARAM_CURSOR_ID;
import static com.tekartik.sqflite.Constant.PARAM_CURSOR_PAGE_SIZE;
import static com.tekartik.sqflite.Constant.PARAM_ROWS;
import static com.tekartik.sqflite.Constant.TAG;
import static com.tekartik.sqflite.Utils.cursorRowToList;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.database.DatabaseErrorHandler;
import android.database.SQLException;
import android.database.sqlite.SQLiteCantOpenDatabaseException;
import android.database.sqlite.SQLiteCursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;

import com.tekartik.sqflite.operation.Operation;
import com.tekartik.sqflite.operation.SqlErrorInfo;

import org.jetbrains.annotations.NotNull;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

class Database {
    // To turn on when supported fully
    // 2022-09-14 experiments show several corruption issue.
    final static boolean WAL_ENABLED_BY_DEFAULT = false;

    final boolean singleInstance;
    final String path;
    final int id;
    final int logLevel;
    final Context context;
    SQLiteDatabase sqliteDatabase;
    boolean inTransaction;

    // Cursors
    private int lastCursorId = 0; // incremental cursor id
    final Map<Integer, SqfliteCursor> cursors = new HashMap<>();

    private static final String WAL_ENABLED_META_NAME = "com.tekartik.sqflite.wal_enabled";

    static private Boolean walGloballyEnabled;

    Database(Context context, String path, int id, boolean singleInstance, int logLevel) {
        this.context = context;
        this.path = path;
        this.singleInstance = singleInstance;
        this.id = id;
        this.logLevel = logLevel;
    }

    @VisibleForTesting
    @NotNull
    static protected boolean checkWalEnabled(Context context) {
        try {
            final String packageName = context.getPackageName();
            final ApplicationInfo applicationInfo = context.getPackageManager().getApplicationInfo(packageName, PackageManager.GET_META_DATA);
            final boolean walEnabled = applicationInfo.metaData.getBoolean(WAL_ENABLED_META_NAME, WAL_ENABLED_BY_DEFAULT);
            if (walEnabled) {
                return true;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public void open() {
        int flags = SQLiteDatabase.CREATE_IF_NECESSARY;

        // Check meta data only once
        if (walGloballyEnabled == null) {
            walGloballyEnabled = checkWalEnabled(context);
            if (walGloballyEnabled) {
                if (LogLevel.hasVerboseLevel(logLevel)) {
                    Log.d(TAG, getThreadLogPrefix() + "[sqflite] WAL enabled");
                }
            }
        }
        if (walGloballyEnabled) {
            // Turned on since 2.1.0-dev.1
            flags |= SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING;
        }

        sqliteDatabase = SQLiteDatabase.openDatabase(path, null, flags);
    }

    // Change default error handler to avoid erasing the existing file.
    public void openReadOnly() {
        sqliteDatabase = SQLiteDatabase.openDatabase(path, null,
                SQLiteDatabase.OPEN_READONLY, new DatabaseErrorHandler() {
                    @Override
                    public void onCorruption(SQLiteDatabase dbObj) {
                        // ignored
                        // default implementation delete the file
                        //
                        // This happens asynchronously so cannot be tracked. However a simple
                        // access should fail
                    }
                });
    }

    public void close() {
        sqliteDatabase.close();
    }

    public SQLiteDatabase getWritableDatabase() {
        return sqliteDatabase;
    }

    public SQLiteDatabase getReadableDatabase() {
        return sqliteDatabase;
    }

    public boolean enableWriteAheadLogging() {
        try {
            return sqliteDatabase.enableWriteAheadLogging();
        } catch (Exception e) {
            Log.e(TAG, getThreadLogPrefix() + "enable WAL error: " + e);
            return false;
        }
    }

    String getThreadLogTag() {
        Thread thread = Thread.currentThread();

        return "" + id + "," + thread.getName() + "(" + thread.getId() + ")";
    }

    String getThreadLogPrefix() {
        return "[" + getThreadLogTag() + "] ";
    }


    static void deleteDatabase(String path) {
        SQLiteDatabase.deleteDatabase(new File(path));
    }

    private Map<String, Object> cursorToResults(Cursor cursor, @Nullable Integer cursorPageSize) {
        Map<String, Object> results = null;
        List<List<Object>> rows = null;
        int columnCount = 0;
        while (cursor.moveToNext()) {

            if (results == null) {
                rows = new ArrayList<>();
                results = new HashMap<>();
                columnCount = cursor.getColumnCount();
                results.put(PARAM_COLUMNS, Arrays.asList(cursor.getColumnNames()));
                results.put(PARAM_ROWS, rows);
            }
            rows.add(cursorRowToList(cursor, columnCount));

            // Paging support
            if (cursorPageSize != null) {
                if (rows.size() >= cursorPageSize) {
                    break;
                }
            }
        }
        // Handle empty
        if (results == null) {
            results = new HashMap<>();
        }

        return results;
    }

    public boolean query(final @NonNull Operation operation) {
        // Non null means dealing with saved cursor.
        Integer cursorPageSize = operation.getArgument(PARAM_CURSOR_PAGE_SIZE);
        boolean cursorHasMoreData = false;

        final SqlCommand command = operation.getSqlCommand();


        // Might be created if reading by page and result don't fit
        SqfliteCursor sqfliteCursor = null;
        if (LogLevel.hasSqlLevel(logLevel)) {
            Log.d(TAG, getThreadLogPrefix() + command);
        }
        Cursor cursor = null;

        try {
            cursor = getReadableDatabase().rawQueryWithFactory(
                    (sqLiteDatabase, sqLiteCursorDriver, editTable, sqLiteQuery) -> {
                        command.bindTo(sqLiteQuery);
                        return new SQLiteCursor(sqLiteCursorDriver, editTable, sqLiteQuery);
                    }, command.getSql(), EMPTY_STRING_ARRAY, null);

            Map<String, Object> results = cursorToResults(cursor, cursorPageSize);
            if (cursorPageSize != null) {
                // We'll have potentially more data to fetch
                cursorHasMoreData = !(cursor.isLast() || cursor.isAfterLast());

            }

            if (cursorHasMoreData) {
                int cursorId = ++lastCursorId;
                results.put(PARAM_CURSOR_ID, cursorId);
                sqfliteCursor = new SqfliteCursor(cursorId, cursorPageSize, cursor);
                cursors.put(cursorId, sqfliteCursor);
            }
            operation.success(results);

            return true;

        } catch (Exception exception) {
            handleException(exception, operation);
            // Cleanup
            if (sqfliteCursor != null) {
                closeCursor(sqfliteCursor);
            }
            return false;
        } finally {
            // Close the cursor for non-paged query
            if (sqfliteCursor == null) {
                if (cursor != null) {
                    cursor.close();
                }
            }
        }
    }

    public boolean queryCursorNext(final @NonNull Operation operation) {
        // Non null means dealing with saved cursor.
        int cursorId = operation.getArgument(PARAM_CURSOR_ID);
        boolean cancel = Boolean.TRUE.equals(operation.getArgument(PARAM_CANCEL));
        if (LogLevel.hasSqlLevel(logLevel)) {
            Log.d(TAG, getThreadLogPrefix() + "cursor " + cursorId + (cancel ? " cancel" : " next"));
        }

        SqfliteCursor sqfliteCursor = cursors.get(cursorId);
        boolean cursorHasMoreData = false;
        try {
            if (sqfliteCursor == null) {
                throw new IllegalStateException("Cursor " + cursorId + " not found");
            } else if (cancel) {
                closeCursor(sqfliteCursor);
                operation.success(null);
                return true;
            }
            Cursor cursor = sqfliteCursor.cursor;

            Map<String, Object> results = cursorToResults(cursor, sqfliteCursor.pageSize);

            // We'll have potentially more data to fetch
            cursorHasMoreData = !(cursor.isLast() || cursor.isAfterLast());

            if (cursorHasMoreData) {
                // Keep the cursor Id in the response to specify that we have more data
                results.put(PARAM_CURSOR_ID, cursorId);
            }
            operation.success(results);

            return true;

        } catch (Exception exception) {
            handleException(exception, operation);
            // Cleanup
            if (sqfliteCursor != null) {
                closeCursor(sqfliteCursor);
                sqfliteCursor = null;
            }
            return false;
        } finally {
            // Close the cursor if we don't have any more data
            if (!cursorHasMoreData) {
                if (sqfliteCursor != null) {
                    closeCursor(sqfliteCursor);
                }
            }
        }
    }

    private void closeCursor(@NonNull SqfliteCursor sqfliteCursor) {
        try {
            cursors.remove(sqfliteCursor.cursorId);
            sqfliteCursor.cursor.close();
        } catch (Exception ignore) {
        }
    }

    private void closeCursor(int cursorId) {
        SqfliteCursor sqfliteCursor = cursors.get(cursorId);
        if (sqfliteCursor != null) {
            closeCursor(sqfliteCursor);
        }
    }

    private void handleException(Exception exception, Operation operation) {
        if (exception instanceof SQLiteCantOpenDatabaseException) {
            operation.error(Constant.SQLITE_ERROR, Constant.ERROR_OPEN_FAILED + " " + path, null);
            return;
        } else if (exception instanceof SQLException) {
            operation.error(Constant.SQLITE_ERROR, exception.getMessage(), SqlErrorInfo.getMap(operation));
            return;
        }
        operation.error(Constant.SQLITE_ERROR, exception.getMessage(), SqlErrorInfo.getMap(operation));
    }

}
