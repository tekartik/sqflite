// Method to use
const String methodInsert = "insert";
const String methodBatch = "batch";
const String methodDebug = "debug";
const String methodOptions = "options";
const String methodCloseDatabase = "closeDatabase";
const String methodOpenDatabase = "openDatabase";
const String methodExecute = "execute";
const String methodUpdate = "update";
const String methodQuery = "query";
const String methodGetPlatformVersion = "getPlatformVersion";
const String methodGetDatabasesPath = "getDatabasesPath";
const String methodDatabaseExists = "databaseExists";
const String methodDeleteDatabase = "deleteDatabase";

// For batch
const String paramOperations = "operations";
// if true the result of each batch operation is not filled
const String paramNoResult = "noResult";
// if true all the operation in the batch are executed even if on failed
const String paramContinueOnError = "continueOnError";

// For each operation
const String paramMethod = "method";
// For each operation reponse
const String paramResult = "result";
const String paramError = "error";
const String paramErrorCode = "code";
const String paramErrorMessage = "message";
const String paramErrorData = "data";

// Result for open if a single instance was recovered from the native world
const String paramRecovered = "recovered";
// Result for open if a single instance was recovered from the native world while in a transaction
const String paramRecoveredInTransaction = "recoveredInTransaction";
// The database path (string)
const String paramPath = "path";
// The database instance name (string)
const String paramName = "name";
// The database version (int)
const String paramVersion = "version";
// The database id (int)
const String paramId = "id";
// True if the database is in a transaction
const String paramInTransaction = "inTransaction";
// When opening the database (bool)
const String paramReadOnly = "readOnly";
// When opening the database (bool)
const String paramSingleInstance = "singleInstance";

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

/// No logs
final int sqfliteLogLevelNone = 0;

/// Log native sql commands
final int sqfliteLogLevelSql = 1;

/// Log native verbose
final int sqfliteLogLevelVerbose = 2;

// deprecated since 1.1.6
// @deprecated
const String methodSetDebugModeOn = "debugMode";
