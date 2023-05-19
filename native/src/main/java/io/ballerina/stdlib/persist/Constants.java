/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.persist;

import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.values.BString;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;
/**
 * Constants for Persist module.
 *
 * @since 0.1.0
 */
public final class Constants {
    private Constants() {
    }

    public static final BString PERSIST_CLIENTS = fromString("persistClients");
    public static final String PERSIST_SQL_STREAM = "PersistSQLStream";
    public static final String PERSIST_GOOGLE_SHEETS_STREAM = "PersistGoogleSheetsStream";
    public static final String PERSIST_IN_MEMORY_STREAM = "PersistInMemoryStream";
    public static final BString KEY_FIELDS = fromString("keyFields");
    public static final String ERROR = "Error";

    public static final String RUN_READ_QUERY_METHOD = "runReadQuery";
    public static final String RUN_READ_TABLE_AS_STREAM_METHOD = "readTableAsStream";
    public static final String RUN_READ_BY_KEY_QUERY_METHOD = "runReadByKeyQuery";
    public static final Module BALLERINA_ANNOTATIONS_MODULE = new Module("ballerina", "lang.annotations", "0.0.0");
    public static final String DEFAULT_STREAM_CONSTRAINT_NAME = "$stream$anon$constraint$";
    public static final String CURRENT_TRANSACTION_CONTEXT = "currentTrxContext";

    /**
     * Constant related to the Ballerina time types.
     *
     * @since 0.1.0
     */
    public static final class TimeTypes {
        public static final String CIVIL = "Civil";
        public static final String DATE_RECORD = "Date";
        public static final String TIME_RECORD = "TimeOfDay";
        public static final String UTC = "Utc";
    }
    
}
