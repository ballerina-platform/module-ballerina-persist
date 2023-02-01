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

import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import static io.ballerina.tools.diagnostics.DiagnosticSeverity.ERROR;

/**
 * Persist related diagnostic codes.
 */
public enum DiagnosticsCodes {
    PERSIST_101("PERSIST_101", "persist model definition only supports record definitions", ERROR),
    PERSIST_102("PERSIST_102", "an entity should be a closed record", ERROR),
    PERSIST_103("PERSIST_103", "entity ''{0}'' must have at least one identifier readonly field", ERROR),
    PERSIST_104("PERSIST_104", "persist model definition does not support import prefix", ERROR),

    PERSIST_201("PERSIST_201", "an entity does not support rest descriptor field", ERROR),
    PERSIST_202("PERSIST_202", "an entity does not support defaultable field", ERROR),
    PERSIST_203("PERSIST_203", "an entity does not support inherited field", ERROR),
    PERSIST_204("PERSIST_204", "an entity does not support optional field", ERROR),
    PERSIST_205("PERSIST_205", "{0}-typed field is not supported in an entity", ERROR),
    PERSIST_206("PERSIST_206", "array of {0}-typed field is not supported in an entity", ERROR),

    PERSIST_301("PERSIST_301", "an entity cannot reference itself in association", ERROR),
    PERSIST_302("PERSIST_302",
            "the associated entity ''{0}'' does not have the associated {1}-typed field", ERROR),
    PERSIST_303("PERSIST_303", "entity does not support duplicated relations to an associated entity", ERROR),
    PERSIST_304("PERSIST_304", "entity should not contain foreign key field ''{0}'' for relation ''{1}''", ERROR),
    PERSIST_305("PERSIST_305", "n:m association is not supported yet", ERROR),
    PERSIST_306("PERSIST_306", "entity does not support nillable associations", ERROR),

    PERSIST_401("PERSIST_401", "identifier field cannot be nillable", ERROR),
    PERSIST_402("PERSIST_402", "fields indicating associations cannot be an identifier field", ERROR);

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
