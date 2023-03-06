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
import static io.ballerina.tools.diagnostics.DiagnosticSeverity.INTERNAL;

/**
 * Persist related diagnostic codes.
 */
public enum DiagnosticsCodes {

    PERSIST_001("PERSIST_001", "{0}", INTERNAL),

    PERSIST_101("PERSIST_101", "persist model definition only supports record definitions", ERROR),
    PERSIST_102("PERSIST_102", "persist model definition does not support import prefix", ERROR),

    PERSIST_201("PERSIST_201", "an entity should be a closed record", ERROR),
    PERSIST_202("PERSIST_202", "redeclared entity ''{0}''", ERROR),

    PERSIST_301("PERSIST_301", "an entity does not support rest descriptor field", ERROR),
    PERSIST_302("PERSIST_302", "an entity does not support defaultable field", ERROR),
    PERSIST_303("PERSIST_303", "an entity does not support inherited field", ERROR),
    PERSIST_304("PERSIST_304", "an entity does not support optional field", ERROR),
    PERSIST_305("PERSIST_305", "an entity does not support {0}-typed field", ERROR),
    PERSIST_306("PERSIST_306", "an entity does not support {0} array field type", ERROR),
    PERSIST_307("PERSIST_307", "redeclared field ''{0}''", ERROR),

    PERSIST_401("PERSIST_401", "an entity cannot reference itself in a relation field", ERROR),
    PERSIST_402("PERSIST_402",
            "the related entity ''{0}'' does not have the {1}-typed relation field", ERROR),
    PERSIST_403("PERSIST_403", "the entity does not support duplicated relations to ''{0}'' entity", ERROR),
    PERSIST_420("PERSIST_420", "many-to-many relation is not supported yet", ERROR),
    PERSIST_421("PERSIST_421", "an entity does not support nillable relations", ERROR),
    PERSIST_422("PERSIST_422", "the entity should not contain foreign key field ''{0}'' for relation ''{1}''", ERROR),

    PERSIST_501("PERSIST_501", "''{0}'' entity must have at least one identity readonly field", ERROR),
    PERSIST_502("PERSIST_502", "an identity field cannot be nillable", ERROR),
    PERSIST_503("PERSIST_503", "only ''int'', ''string'', ''float'', ''boolean'', ''decimal'' " +
            "types are supported as identity fields, found ''{0}''", ERROR);

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
