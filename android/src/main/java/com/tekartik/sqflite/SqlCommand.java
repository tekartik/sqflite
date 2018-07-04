package com.tekartik.sqflite;

import android.util.Log;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static com.tekartik.sqflite.Constant.TAG;
import static com.tekartik.sqflite.dev.Debug.EXTRA_LOGV;

public class SqlCommand {
    public String getSql() {
        return sql;
    }

    final private String sql;
    final private List<Object> rawArguments;


    // Handle list of int as byte[]
    static private Object toValue(Object value) {
        if (value == null) {
            return null;
        } else {
            if (EXTRA_LOGV) {
                Log.d(TAG, "arg " + value.getClass().getCanonicalName() + " " + toString(value));
            }
            // Assume a list is a blog
            if (value instanceof List) {
                @SuppressWarnings("unchecked")
                List<Integer> list = (List<Integer>) value;
                byte[] blob = new byte[list.size()];
                for (int i = 0; i < list.size(); i++) {
                    blob[i] = (byte) (int) list.get(i);
                }
                value = blob;

            }
            if (EXTRA_LOGV) {
                Log.d(TAG, "arg " + value.getClass().getCanonicalName() + " " + toString(value));
            }
            return value;
        }
    }

    public SqlCommand(String sql, List<Object> rawArguments) {
        this.sql = sql;
        if (rawArguments == null) {
            rawArguments = new ArrayList<>();
        }
        this.rawArguments = rawArguments;

    }

    // Only sanitize if the parameter count matches the argument count
    // For integer value replace ? with the actual value directly
    // to workaround an issue with references
    public SqlCommand sanitizeForQuery() {
        if (rawArguments.size() == 0) {
            return this;
        }
        StringBuilder sanitizeSqlSb = new StringBuilder();
        List<Object> sanitizeArguments = new ArrayList<>();
        int count = 0;
        int argumentIndex = 0;
        int sqlLength = sql.length();
        for (int i = 0; i < sqlLength; i++) {
            char ch = sql.charAt(i);
            if (ch == '?') {
                count++;
                // no match, return the same
                if (argumentIndex >= rawArguments.size()) {
                    return this;
                }
                Object argument = rawArguments.get(argumentIndex++);
                if (argument instanceof Integer || argument instanceof Long) {
                    sanitizeSqlSb.append(argument.toString());
                    continue;
                } else {
                    // Let the other args as is
                    sanitizeArguments.add(argument);
                }
            }
            // Simply append the existing
            sanitizeSqlSb.append(ch);
        }
        // no match (there might be an extra ? somwhere), return the same
        if (count != rawArguments.size()) {
            return this;
        }
        return new SqlCommand(sanitizeSqlSb.toString(), sanitizeArguments);
    }


    // Query only accept string arguments
    // so should not have byte[]
    private String[] getQuerySqlArguments(List<Object> rawArguments) {
        return getStringQuerySqlArguments(rawArguments).toArray(new String[0]);
    }

    private Object[] getSqlArguments(List<Object> rawArguments) {
        List<Object> fixedArguments = new ArrayList<>();
        if (rawArguments != null) {
            for (Object rawArgument : rawArguments) {
                fixedArguments.add(toValue(rawArgument));
            }
        }
        return fixedArguments.toArray(new Object[0]);
    }


    // Query only accept string arguments
    private List<String> getStringQuerySqlArguments(List<Object> rawArguments) {
        List<String> stringArguments = new ArrayList<>();
        if (rawArguments != null) {
            for (Object rawArgument : rawArguments) {
                stringArguments.add(toString(rawArgument));
            }
        }
        return stringArguments;
    }


    // Convert a value to a string
    // especially byte[]
    static private String toString(Object value) {
        if (value == null) {
            return null;
        } else if (value instanceof byte[]) {
            List<Integer> list = new ArrayList<>();
            for (byte _byte : (byte[]) value) {
                list.add((int) _byte);
            }
            return list.toString();
        } else if (value instanceof Map) {
            @SuppressWarnings("unchecked")
            Map<Object, Object> mapValue = (Map<Object, Object>) value;
            return fixMap(mapValue).toString();
        } else {
            return value.toString();
        }
    }


    static private Map<String, Object> fixMap(Map<Object, Object> map) {
        Map<String, Object> newMap = new HashMap<>();
        for (Map.Entry<Object, Object> entry : map.entrySet()) {
            Object value = entry.getValue();
            if (value instanceof Map) {
                @SuppressWarnings("unchecked")
                Map<Object, Object> mapValue = (Map<Object, Object>) value;
                value = fixMap(mapValue);
            } else {
                value = toString(value);
            }
            newMap.put(toString(entry.getKey()), value);
        }
        return newMap;
    }

    @Override
    public String toString() {
        return sql + ((rawArguments == null || rawArguments.isEmpty()) ? "" : (" " + getStringQuerySqlArguments(rawArguments)));
    }

    // As expected by execSQL
    public Object[] getSqlArguments() {
        return getSqlArguments(rawArguments);
    }

    public String[] getQuerySqlArguments() {
        return getQuerySqlArguments(rawArguments);
    }

    public List<Object> getRawSqlArguments() {
        return rawArguments;
    }

    @Override
    public int hashCode() {
        return sql != null ? sql.hashCode() : 0;
    }

    @Override
    public boolean equals(Object obj) {
        if (obj instanceof SqlCommand) {
            SqlCommand o = (SqlCommand) obj;
            if (sql != null) {
                if (!sql.equals(o.sql)) {
                    return false;
                }
            } else {
                if (o.sql != null) {
                    return false;
                }
            }

            if (rawArguments.size() != o.rawArguments.size()) {
                return false;
            }
            for (int i = 0; i < rawArguments.size(); i++) {
                // special blob handling
                if (rawArguments.get(i) instanceof byte[] && o.rawArguments.get(i) instanceof byte[]) {
                    if (!Arrays.equals((byte[]) rawArguments.get(i), (byte[]) o.rawArguments.get(i))) {
                        return false;
                    }
                } else {
                    if (!rawArguments.get(i).equals(o.rawArguments.get(i))) {
                        return false;
                    }
                }
            }
            return true;
        }
        return false;
    }
}
