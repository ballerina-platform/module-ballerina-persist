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

import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import static io.ballerina.tools.diagnostics.DiagnosticSeverity.ERROR;

/**
 * Enum class to hold persis module diagnostic codes.
 */
public enum DiagnosticsCodes {

    PERSIST_101("PERSIST_101",
            "invalid field type: the record field does not support the optional value type", ERROR),
    PERSIST_102("PERSIST_102",
            "missing annotation: the record does not have `persist:Entity` annotation", ERROR),
    PERSIST_103("PERSIST_103",
            "invalid column name: the given column name is not in the record definition", ERROR),
    PERSIST_104("PERSIST_104",
            "empty value: At least one key is expected", ERROR),
    PERSIST_105("PERSIST_105",
            "invalid value: the value only supports positive integer", ERROR),
    PERSIST_106("PERSIST_106",
            "invalid value: the value does not support negative integer", ERROR);

    private final String code;
    private final String message;
    private final DiagnosticSeverity severity;

    DiagnosticsCodes(String code, String message, DiagnosticSeverity severity) {
        this.code = code;
        this.message = message;
        this.severity = severity;
    }

    public String getCode() {
        return code;
    }

    public String getMessage() {
        return message;
    }

    public DiagnosticSeverity getSeverity() {
        return severity;
    }
}
