package com.tekartik.sqflite.operation;

import com.tekartik.sqflite.SqlCommand;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

/**
 * Created by alex on 09/01/18.
 */

public class ExecuteOperation extends BaseReadOperation {
    final Map<String, Object> map = new HashMap<>();
    final SqlCommand command;
    final MethodChannel.Result result;

    public ExecuteOperation(MethodChannel.Result result, SqlCommand command) {
        this.result = result;
        this.command = command;
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
