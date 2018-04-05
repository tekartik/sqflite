package com.tekartik.sqflite.operation;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

import static com.tekartik.sqflite.Constant.PARAM_METHOD;
import static com.tekartik.sqflite.Constant.PARAM_SQL;
import static com.tekartik.sqflite.Constant.PARAM_SQL_ARGUMENTS;

/**
 * Created by alex on 09/01/18.
 */

public class ExecuteOperation extends BaseReadOperation {
    final Map<String, Object> map = new HashMap<>();
    final MethodChannel.Result result;

    public ExecuteOperation(MethodChannel.Result result, String sql, List<Object> arguments) {
        this.result = result;
        map.put(PARAM_SQL, sql);
        map.put(PARAM_SQL_ARGUMENTS, arguments);
    }

    @Override
    protected OperationResult getResult() {
        return null;
    }

    @Override
    public String getMethod() {
        return null;
    }

    @SuppressWarnings("unchecked")
    @Override
    public <T> T getArgument(String key) {
        return (T) map.get(key);
    }

    @Override
    public void error(String errorCode, String errorMessage, Object data) {
        result.error(errorCode, errorMessage, data);
    }

    @Override
    public void success(Object results) {
        result.success(results);
    }
}
