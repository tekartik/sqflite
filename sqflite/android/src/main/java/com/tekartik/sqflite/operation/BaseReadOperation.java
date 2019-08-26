package com.tekartik.sqflite.operation;


import com.tekartik.sqflite.SqlCommand;

import java.util.List;

import static com.tekartik.sqflite.Constant.PARAM_CONTINUE_OR_ERROR;
import static com.tekartik.sqflite.Constant.PARAM_IN_TRANSACTION;
import static com.tekartik.sqflite.Constant.PARAM_NO_RESULT;
import static com.tekartik.sqflite.Constant.PARAM_SQL;
import static com.tekartik.sqflite.Constant.PARAM_SQL_ARGUMENTS;

/**
 * Created by alex on 09/01/18.
 */

public abstract class BaseReadOperation implements Operation {
    private String getSql() {
        return getArgument(PARAM_SQL);
    }

    private List<Object> getSqlArguments() {
        return getArgument(PARAM_SQL_ARGUMENTS);
    }

    public SqlCommand getSqlCommand() {
        return new SqlCommand(getSql(), getSqlArguments());
    }

    public Boolean getInTransaction() {
        return getBoolean(PARAM_IN_TRANSACTION);
    }

    @Override
    public boolean getNoResult() {
        return Boolean.TRUE.equals(getArgument(PARAM_NO_RESULT));
    }

    @Override
    public boolean getContinueOnError() {
        return Boolean.TRUE.equals(getArgument(PARAM_CONTINUE_OR_ERROR));
    }

    private Boolean getBoolean(String key) {
        Object value = getArgument(key);
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        return null;
    }

    // We actually have an inner object that does the implementation
    protected abstract OperationResult getOperationResult();

}
