package com.tekartik.sqflite;


import android.content.Context;
import android.database.DatabaseErrorHandler;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteDatabase.CursorFactory;

/**
 * A helper class to manage database creation and version management.
 */
public abstract class SQLiteOpenHelper extends android.database.sqlite.SQLiteOpenHelper {
    private static final String TAG = SQLiteOpenHelper.class.getSimpleName();

    public SQLiteOpenHelper(Context context, String name, CursorFactory factory, int version) {
        super(context, name, factory, version);
    }

    public void onDowngrade(SQLiteDatabase db, int oldVersion, int newVersion) {
      throw new UnsupportedOperationException("Downgrade not supported");
    }

    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
      throw new UnsupportedOperationException("Upgrade not supported");
    }
}
