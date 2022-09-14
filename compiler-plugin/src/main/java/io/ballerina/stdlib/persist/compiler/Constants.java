/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.persist.compiler;

/**
 * Constants for Persist compiler plugin.
 */
public class Constants {

    public static final String TRUE = "true";
    public static final String INSERT_METHOD_NAME = "runInsertQuery";
    public static final String ENTITY = "persist:Entity ";
    public static final String UNNECESSARY_CHARS_REGEX = "\"|\\n";
    public static final String TABLE_NAME = "tableName";
    public static final String AUTO_INCREMENT = "persist:AutoIncrement";
    public static final String INCREMENT = "increment";
    public static final String RELATION = "persist:Relation";
    public static final String KEY_COLUMNS = "keyColumns";
    public static final String REFERENCE = "reference";
    public static final String START_VALUE = "startValue";
    public static final String ONE = "1";
    public static final String CASCADE_DELETE = "cascadeDelete";
    public static final String ON_DELETE_CASCADE = " ON DELETE CASCADE";
    public static final String ON_UPDATE_CASCADE = " ON UPDATE CASCADE";
    public static final String NOT_NULL = " NOT NULL";
    public static final String AUTO_INCREMENT_WITH_SPACE = " AUTO_INCREMENT";
    public static final String AUTO_INCREMENT_WITH_TAB = "\tAUTO_INCREMENT";
    public static final String CONSTRAINT_STRING = "constraint:String";
    public static final String LENGTH = "length";
    public static final String MAX_LENGTH = "maxLength";

    /**
     * Constants related to Ballerina types.
     */
    public static final class BallerinaTypes {
        public static final String INT = "int";
        public static final String STRING = "string";
        public static final String BOOLEAN = "boolean";
        public static final String DECIMAL = "decimal";
        public static final String FLOAT = "float";
        public static final String DATE = "time:Date";
        public static final String TIME_OF_DAY = "time:TimeOfDay";
        public static final String UTC = "time:Utc";
        public static final String CIVIL = "time:Civil";
    }

    /**
     * Constants related to SQL types.
     */
    public static final class SqlTypes {
        public static final String INT = "INT";
        public static final String BOOLEAN = "BOOLEAN";
        public static final String DECIMAL = "DECIMAL";
        public static final String FLOAT = "FLOAT";
        public static final String VARCHAR = "VARCHAR";
        public static final String DATE = "DATE";
        public static final String TIME = "TIME";
        public static final String TIME_STAMP = "TIMESTAMP";
        public static final String DATE_TIME = "DATETIME";
    }
}
