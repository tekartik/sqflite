package com.tekartik.sqflite;

import static com.tekartik.sqflite.Constant.TAG;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.database.DatabaseErrorHandler;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import androidx.annotation.VisibleForTesting;

import org.jetbrains.annotations.NotNull;

import java.io.File;

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
}
