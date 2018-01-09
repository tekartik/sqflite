package com.tekartik.sqflite.operation;

import java.util.List;

import io.flutter.plugin.common.MethodChannel;

import static com.tekartik.sqflite.Constant.PARAM_SQL;

/**
 * Created by alex on 09/01/18.
 */

public interface Operation extends OperationResult {

    String getMethod();
    <T> T getArgument(String key);
    String getSql();
    List<Object> getSqlArguments();
}
