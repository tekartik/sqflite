package com.tekartik.sqflite.operation;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Operation for Method call
 */

public class MethodCallOperation extends BaseOperation {
    final MethodCall methodCall;
    final Result result;

    class Result implements OperationResult {

        final MethodChannel.Result result;

        Result(MethodChannel.Result result) {
            this.result = result;
        }

        @Override
        public void success(Object result) {
            this.result.success(result);
        }

        @Override
        public void error(String errorCode, String errorMessage, Object data) {
            result.error(errorCode, errorMessage, data);
        }

    }

    public MethodCallOperation(MethodCall methodCall, MethodChannel.Result result) {
        this.methodCall = methodCall;
        this.result = new Result(result);
    }

    @Override
    public String getMethod() {
        return methodCall.method;
    }

    @Override
    public <T> T getArgument(String key) {
        return methodCall.argument(key);
    }

    @Override
    public OperationResult getOperationResult() {
        return result;
    }


}
