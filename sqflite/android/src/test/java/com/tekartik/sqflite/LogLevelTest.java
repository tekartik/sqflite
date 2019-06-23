package com.tekartik.sqflite;

import org.junit.Test;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

/**
 * Constants between dart & Java world
 */

public class LogLevelTest {


    @Test
    public void hasSqlLogLevel() {
        assertTrue(LogLevel.hasSqlLovel(1));
        assertFalse(LogLevel.hasSqlLovel(0));
    }
}
