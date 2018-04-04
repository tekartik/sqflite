package com.tekartik.sqflite.operation;

import java.util.List;

import static com.tekartik.sqflite.Constant.PARAM_NO_RESULT;
import static com.tekartik.sqflite.Constant.PARAM_SQL;
import static com.tekartik.sqflite.Constant.PARAM_SQL_ARGUMENTS;

/**
 * Created by alex on 09/01/18.
 */

public abstract class BaseOperation extends BaseReadOperation {
    public String getSql() {
        return getArgument(PARAM_SQL);
    }

    public List<Object> getSqlArguments() {
        return getArgument(PARAM_SQL_ARGUMENTS);
    }

    @Override
    public boolean getNoResult() {
        return Boolean.TRUE.equals(getArgument(PARAM_NO_RESULT));
    }

    // We actually have an inner object that does the implementation
    protected abstract OperationResult getResult();

    @Override
    public void success(Object results) {
        getResult().success(results);
    }

    @Override
    public void error(String errorCode, String errorMessage, Object data) {
        getResult().error(errorCode, errorMessage, data);
    }

}
