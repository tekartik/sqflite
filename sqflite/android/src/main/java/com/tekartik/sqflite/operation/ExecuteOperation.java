package com.tekartik.sqflite.operation;

import com.tekartik.sqflite.SqlCommand;

import io.flutter.plugin.common.MethodChannel;

/**
 * Created by alex on 09/01/18.
 */

public class ExecuteOperation extends BaseReadOperation {
    final private SqlCommand command;
    final private MethodChannel.Result result;
    final private Boolean inTransaction;

    public ExecuteOperation(MethodChannel.Result result, SqlCommand command, Boolean inTransaction) {
        this.result = result;
        this.command = command;
        this.inTransaction = inTransaction;
    }

    @Override
    public SqlCommand getSqlCommand() {
        return command;
    }

    @Override
    protected OperationResult getOperationResult() {
        return null;
    }

    @Override
    public String getMethod() {
        return null;
    }

    @Override
    public <T> T getArgument(String key) {
        return null;
    }

    @Override
    public void error(String errorCode, String errorMessage, Object data) {
        result.error(errorCode, errorMessage, data);
    }

    @Override
    public Boolean getInTransaction() {
        return inTransaction;
    }

    @Override
    public void success(Object result) {
        this.result.success(result);
    }
}
