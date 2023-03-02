/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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
 * Constants class.
 */
public final class Constants {
    public static final String PERSIST_DIRECTORY = "persist";
    public static final String TIME_MODULE = "time";
    public static final String EMPTY_STRING = "";
    public static final String ARRAY = "[]";
    public static final String LS = System.lineSeparator();

    private Constants() {
    }

    /**
     * Constants related to Ballerina types.
     */
    public static final class BallerinaTypes {

        public static final String INT = "int";
        public static final String STRING = "string";
        public static final String BOOLEAN = "boolean";
        public static final String DECIMAL = "decimal";
        public static final String FLOAT = "float";
        public static final String BYTE = "byte";

        private BallerinaTypes() {
        }
    }

    /**
     * Constants related to Ballerina time type.
     */
    public static final class BallerinaTimeTypes {

        public static final String DATE = "Date";
        public static final String TIME_OF_DAY = "TimeOfDay";
        public static final String UTC = "Utc";
        public static final String CIVIL = "Civil";

        private BallerinaTimeTypes() {
        }
    }

}
