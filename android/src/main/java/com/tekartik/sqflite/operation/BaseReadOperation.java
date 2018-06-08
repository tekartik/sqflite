package com.tekartik.sqflite.operation;

import com.tekartik.sqflite.SqlCommand;

import java.util.List;

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

    @Override
    public boolean getNoResult() {
        return Boolean.TRUE.equals(getArgument(PARAM_NO_RESULT));
    }

    // We actually have an inner object that does the implementation
    protected abstract OperationResult getResult();

}
