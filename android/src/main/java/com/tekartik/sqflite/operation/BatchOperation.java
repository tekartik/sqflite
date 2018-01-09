package com.tekartik.sqflite.operation;

import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

import static com.tekartik.sqflite.Constant.PARAM_METHOD;

/**
 * Created by alex on 09/01/18.
 */

public class BatchOperation extends BaseOperation {
    final Map<String, Object> map;
    final BatchOperationResult result = new BatchOperationResult();

    class BatchOperationResult implements OperationResult {
        // success
        Object results;

        // error
        String errorCode;
        String errorMessage;
        Object data;

        @Override
        public void success(Object results) {
            this.results = results;
        }

        @Override
        public void error(String errorCode, String errorMessage, Object data) {
            this.errorCode = errorCode;
            this.errorMessage = errorMessage;
            this.data = data;
        }
    }

    public BatchOperation(Map<String, Object> map) {
        this.map = map;
    }

    @Override
    public String getMethod() {
        return (String) map.get(PARAM_METHOD);
    }

    @Override
    public <T> T getArgument(String key) {
        return (T) map.get(key);
    }

    @Override
    public OperationResult getResult() {
        return result;
    }

    public Object getBatchResults() {
        return result.results;
    }

    public void handleError(MethodChannel.Result result) {
        result.error(this.result.errorCode, this.result.errorMessage, this.result.data);
    }

    public void handleSuccess(List<Object> results) {
        results.add(getBatchResults());
    }


}
