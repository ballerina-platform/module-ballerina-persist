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
 *
 */
public class Constants {

    public static final String PERSIST_SQL_CLIENT = "persist:SQLClient";
    public static final String TRUE = "true";
    public static final String AUTO_INCREMENT = "AUTO_INCREMENT";
    public static final String COLUMN_NAME = "columnName";
    public static final String TYPE = "'type";
    public static final String INSERT_METHOD_NAME = "runInsertQuery";
    public static final String ENTITY = "persist:Entity ";
    public static final String UNNECESSARY_CHARS_REGEX = "\"|\\n";
    public static final String TABLE_NAME = "tableName";
    public static final String PER_AUTO_INCREMENT = "persist:AutoIncrement";
    public static final String INCREMENT = "increment";
    public static final String RELATION = "persist:Relation";
    public static final String KEY = "key";
    public static final String REFERENCE = "reference";

    /**
     * Constants related to Ballerina types.
     */
    public static final class BallerinaTypes {
        public static final String INT = "int";
        public static final String BOOLEAN = "boolean";
        public static final String DECIMAL = "decimal";
        public static final String FLOAT = "float";
    }

    /**
     * Constants related to SQL types.
     */
    public static final class SqlTypes {
        public static final String INT = "INT";
        public static final String BOOLEAN = "BOOLEAN";
        public static final String DECIMAL = "DECIMAL";
        public static final String FLOAT = "FLOAT";
        public static final String VARCHAR = "FLOAT";
    }
}
