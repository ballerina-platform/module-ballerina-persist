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
            "attached to the entity record field", ERROR),
    PERSIST_118("PERSIST_118", "invalid annotation attachment: the `one-to-many` relation annotation " +
            "can not be attached to the array entity record field", ERROR),
    PERSIST_119("PERSIST_119", "duplicate entity names are not allowed: the specified name is already " +
            "used in another entity", ERROR),
    PERSIST_120("PERSIST_120", "unsupported features: array type is not supported",
            ERROR),
    PERSIST_121("PERSIST_121", "unsupported features: {0} type is not supported",
            ERROR),

    // todo: Add expression type in the diagnostic message
    PERSIST_201("PERSIST_201",
            "persist client read() function not supported for expression", ERROR),
    PERSIST_202("PERSIST_202",
            "persist client read() function limit not supported for variables, " +
                    "limit expression should be an integer", ERROR),
    PERSIST_203("PERSIST_203",
            "persist client read() function order by key should be ''variables'' in the ''from clause''",
            ERROR),

    PERSIST_210("PERSIST_210", "persist client execute() function is an internal function and cannot be invoked",
                ERROR),
    PERSIST_211("PERSIST_211", "this persist client read() function invocation is not optimised, " +
            "use the function within the query syntax to run optimised fetch", WARNING);

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
