package com.tekartik.sqflite.operation;

import java.util.HashMap;
import java.util.Map;

import static com.tekartik.sqflite.Constant.PARAM_SQL;
import static com.tekartik.sqflite.Constant.PARAM_SQL_ARGUMENTS;

public class SqlErrorInfo {

    static public Map<String, Object> getMap(Operation operation) {
        Map<String, Object> map = null;
        if (operation.getSql() != null) {
            map = new HashMap<>();
            map.put(PARAM_SQL, operation.getSql());
            map.put(PARAM_SQL_ARGUMENTS, operation.getSqlArguments());
        }
        return map;
    }
}
