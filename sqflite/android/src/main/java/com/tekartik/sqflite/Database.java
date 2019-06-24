package com.tekartik.sqflite;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import static com.tekartik.sqflite.Constant.TAG;

class Database {
    final boolean singleInstance;
    final String path;
    final int id;
    final int logLevel;
    SQLiteDatabase sqliteDatabase;

    Database(String path, int id, boolean singleInstance, int logLevel) {
        this.path = path;
        this.singleInstance = singleInstance;
        this.id = id;
        this.logLevel = logLevel;
    }

    public void open() {
        sqliteDatabase = SQLiteDatabase.openDatabase(path, null,
                SQLiteDatabase.CREATE_IF_NECESSARY);
    }

    public void openReadOnly() {
        sqliteDatabase = SQLiteDatabase.openDatabase(path, null,
                SQLiteDatabase.OPEN_READONLY);
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
            Log.e(TAG, "enable WAL error: " + e);
            return false;
        }
    }

    String getThreadLogTag() {
        Thread thread = Thread.currentThread();

        return "" + id + "," + thread.getName() + "(" + thread.getId() + ")";
    }
}
