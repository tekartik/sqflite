// Method to use
const String methodInsert = "insert";
const String methodBatch = "batch";
const String methodSetDebugModeOn = "debugMode";
const String methodOptions = "options";
const String methodCloseDatabase = "closeDatabase";
const String methodOpenDatabase = "openDatabase";
const String methodExecute = "execute";
const String methodUpdate = "update";
const String methodQuery = "query";
const String methodGetPlatformVersion = "getPlatformVersion";
const String methodGetDatabasesPath = "getDatabasesPath";

// For batch
const String paramOperations = "operations";
// if true the result of each batch operation is not filled
const String paramNoResult = "noResult";
// For each operation
const String paramMethod = "method";

// The database path (string)
const String paramPath = "path";
// The database version (int)
const String paramVersion = "version";
// The database id (int)
const String paramId = "id";
// When opening the database (bool)
const String paramReadOnly = "readOnly";

const String paramTable = "table";
const String paramValues = "values";

// for SQL query
const String paramSql = "sql";
const String paramSqlArguments = "arguments";

// Error
const String sqliteErrorCode = "sqlite_error";

const String inMemoryDatabasePath = ":memory:";

// Non final for changing it during testing
// If a database called is delayed by this duration, a print will happen
const Duration lockWarningDuration = Duration(seconds: 10);
