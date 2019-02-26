package com.tekartik.sqflite.operation;

import com.tekartik.sqflite.SqlCommand;

import java.util.HashMap;
import java.util.Map;

import static com.tekartik.sqflite.Constant.PARAM_SQL;
import static com.tekartik.sqflite.Constant.PARAM_SQL_ARGUMENTS;

public class SqlErrorInfo {

    static public Map<String, Object> getMap(Operation operation) {
        Map<String, Object> map = null;
        SqlCommand command = operation.getSqlCommand();
        if (command != null) {
            map = new HashMap<>();
            map.put(PARAM_SQL, command.getSql());
            map.put(PARAM_SQL_ARGUMENTS, command.getRawSqlArguments());
        }
        return map;
    }
}
