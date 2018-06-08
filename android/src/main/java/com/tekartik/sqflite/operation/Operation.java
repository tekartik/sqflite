package com.tekartik.sqflite.operation;

import com.tekartik.sqflite.SqlCommand;

/**
 * Created by alex on 09/01/18.
 */

public interface Operation extends OperationResult {

    String getMethod();

    <T> T getArgument(String key);

    SqlCommand getSqlCommand();

    boolean getNoResult();
}
