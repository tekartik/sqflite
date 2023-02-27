package com.tekartik.sqflite;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;

import androidx.annotation.VisibleForTesting;

import org.jetbrains.annotations.NotNull;

public class PackageUtils {
    @VisibleForTesting
    static public boolean getAppInfoMetaDataBoolean(Context context, String key, boolean defaultValue) {
        try {
            final Bundle metaData = getAppInfoMetaData(context);
            return metaData.getBoolean(key, defaultValue);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    @VisibleForTesting
    @NotNull
    static protected Bundle getAppInfoMetaData(Context context) throws PackageManager.NameNotFoundException {

        final String packageName = context.getPackageName();
        ApplicationInfo applicationInfo;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            applicationInfo = context.getPackageManager().getApplicationInfo(packageName,
                    PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA));
        } else {
            applicationInfo = context.getPackageManager().getApplicationInfo(packageName, PackageManager.GET_META_DATA);
        }
        return applicationInfo.metaData;

    }


}
