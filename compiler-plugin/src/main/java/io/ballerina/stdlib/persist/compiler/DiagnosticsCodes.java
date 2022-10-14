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
import static io.ballerina.tools.diagnostics.DiagnosticSeverity.WARNING;

/**
 * Enum class to hold persis module diagnostic codes.
 */
public enum DiagnosticsCodes {

    PERSIST_101("PERSIST_101",
            "invalid field type: the persist client does not support the union type", ERROR),
    PERSIST_102("PERSIST_102",
            "invalid key: the given key is not in the record definition", ERROR),
    PERSIST_103("PERSIST_103",
            "invalid value: the value only supports positive integer", ERROR),
    PERSIST_104("PERSIST_104",
            "invalid value: the value does not support negative integer", ERROR),
    PERSIST_105("PERSIST_105",
            "invalid type: the field type should be in integer", ERROR),
    PERSIST_106("PERSIST_106",
            "invalid initialization: the field is not specified as read-only", ERROR),
    PERSIST_107("PERSIST_107", "duplicate annotation: the entity does not allow " +
            "multiple field with auto increment annotation", ERROR),
    PERSIST_108("PERSIST_108", "invalid initialization: auto increment field" +
            " must be defined as a key", ERROR),
    PERSIST_109("PERSIST_109", "mismatch reference: the given key count is mismatched " +
            "with reference key count", ERROR),
    PERSIST_110("PERSIST_110", "", WARNING),
    PERSIST_111("PERSIST_111", "invalid initialization: the entity should be public", ERROR),
    PERSIST_112("PERSIST_112", "mysql db only allow increment value by one in auto generated field",
            WARNING),
    PERSIST_113("PERSIST_113", "duplicate table name: the table name is already used in another entity",
            ERROR),
    PERSIST_114("PERSIST_114", "unsupported features: many-to-many association is not supported yet",
            ERROR),
    PERSIST_115("PERSIST_115", "invalid entity initialisation: the associated entity of this[{0}] " +
            "does not have the field with the relationship type", ERROR),
    PERSIST_116("PERSIST_116", "invalid entity initialisation: the relation annotation should " +
            "only be added to the relationship owner for one-to-one and one-to-many associations", ERROR),
    PERSIST_117("PERSIST_117", "invalid annotation attachment: The relation annotation can only be " +
            "attached to the field whose type is defined by another entity", ERROR),
    PERSIST_118("PERSIST_118", "duplicate entity names are not allowed: the specified name is already " +
            "used in another entity", ERROR),

    PERSIST_201("PERSIST_201",
            "Unsupported expression: read() function of persist client does not support this expression", ERROR),
    PERSIST_202("PERSIST_202",
            "Unsupported expression: read() function of persist client only supports int value in limit clause",
            ERROR),
    PERSIST_203("PERSIST_203",
            "Unsupported expression: read() function of persist client only supports selected variables "
                    + "from the 'from clause' in order by clause",
            ERROR);

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
