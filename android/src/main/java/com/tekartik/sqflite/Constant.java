package com.tekartik.sqflite;

/**
 * Created by alex on 22/05/17.
 */

public class Constant {

    static final public String METHOD_GET_PLATFORM_VERSION = "getPlatformVersion";
    static final public String METHOD_DEBUG_MODE = "debugMode";
    static final public String METHOD_OPEN_DATABASE = "openDatabase";
    static final public String METHOD_CLOSE_DATABASE = "closeDatabase";
    static final public String METHOD_INSERT = "insert";
    static final public String METHOD_EXECUTE = "execute";
    static final public String METHOD_QUERY = "query";
    static final public String METHOD_UPDATE = "update";

    static final String PARAM_ID = "id";
    static final String PARAM_PATH = "path";
    static final String PARAM_SQL = "sql";
    static final String PARAM_SQL_ARGUMENTS = "arguments";

    static final String SQLITE_ERROR = "sqlite_error"; // code
    static final String ERROR_OPEN_FAILED = "open_failed"; // msg

}
