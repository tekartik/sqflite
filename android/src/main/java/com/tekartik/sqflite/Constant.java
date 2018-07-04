package com.tekartik.sqflite;

/**
 * Constants between dart & Java world
 */

public class Constant {

    static final public String METHOD_GET_PLATFORM_VERSION = "getPlatformVersion";
    static final public String METHOD_GET_DATABASES_PATH = "getDatabasesPath";
    static final public String METHOD_DEBUG_MODE = "debugMode";
    static final public String METHOD_OPTIONS = "options";
    static final public String METHOD_OPEN_DATABASE = "openDatabase";
    static final public String METHOD_CLOSE_DATABASE = "closeDatabase";
    static final public String METHOD_INSERT = "insert";
    static final public String METHOD_EXECUTE = "execute";
    static final public String METHOD_QUERY = "query";
    static final public String METHOD_UPDATE = "update";
    static final public String METHOD_BATCH = "batch";

    static final String PARAM_ID = "id";
    static final String PARAM_PATH = "path";
    // when opening a database
    static final String PARAM_READ_ONLY = "readOnly"; // boolean

    static final String PARAM_QUERY_AS_MAP_LIST = "queryAsMapList"; // boolean

    public static final String PARAM_SQL = "sql";
    public static final String PARAM_SQL_ARGUMENTS = "arguments";
    public static final String PARAM_NO_RESULT = "noResult";

    // in batch
    static final String PARAM_OPERATIONS = "operations";
    // in each operation
    public static final String PARAM_METHOD = "method";

    static final String SQLITE_ERROR = "sqlite_error"; // code
    static final String ERROR_BAD_PARAM = "bad_param"; // internal only
    static final String ERROR_OPEN_FAILED = "open_failed"; // msg
    static final String ERROR_DATABASE_CLOSED = "database_closed"; // msg

    // memory database path
    static final String MEMORY_DATABASE_PATH = ":memory:";

    // android log tag
    static public String TAG = "Sqflite";
}
