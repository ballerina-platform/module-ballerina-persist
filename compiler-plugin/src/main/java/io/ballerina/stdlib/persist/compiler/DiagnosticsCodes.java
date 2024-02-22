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
import static io.ballerina.tools.diagnostics.DiagnosticSeverity.WARNING;

/**
 * Persist related diagnostic codes.
 */
public enum DiagnosticsCodes {

    // Internal diagnostics used to hold details of the entity fields for entities w/o identity fields PERSIST_501
    PERSIST_001("PERSIST_001", "", INTERNAL),
    // Internal diagnostics used to hold details of the entity fields for PERSIST_404
    PERSIST_002("PERSIST_002", "", INTERNAL),
    // Internal diagnostics used to hold details of the entity fields for PERSIST_405
    PERSIST_003("PERSIST_003", "", INTERNAL),
    // Internal diagnostics used to hold details of the entity fields for PERSIST_403
    PERSIST_004("PERSIST_004", "", INTERNAL),
    // Internal diagnostics used to hold details of the associated entity fields for PERSIST_402
    PERSIST_005("PERSIST_005", "", INTERNAL),

    PERSIST_101("PERSIST_101", "persist model definition only supports record and enum definitions",
            ERROR),
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
    PERSIST_308("PERSIST_308", "an entity does not support nillable field", ERROR),


    PERSIST_401("PERSIST_401", "an entity cannot reference itself in a relation field", ERROR),
    PERSIST_402("PERSIST_402",
            "the related entity ''{0}'' does not have the corresponding relation field", ERROR),
    PERSIST_403("PERSIST_403", "All relation between two entities should have a single owner", ERROR),
    PERSIST_404("PERSIST_404", "1-1 relationship should have at least one relation field nillable " +
            "to indicate non-owner of the relationship", ERROR),
    PERSIST_405("PERSIST_405", "1-1 relationship should have only one nillable relation field", ERROR),
    PERSIST_406("PERSIST_406", "1-n relationship does not support nillable relation field", ERROR),

    PERSIST_420("PERSIST_420", "many-to-many relation is not supported yet", ERROR),
    PERSIST_422("PERSIST_422",
            "the entity should not contain foreign key field ''{0}'' for relation ''{1}''",
            ERROR),
    PERSIST_423("PERSIST_423", "invalid use of Relation annotation. " +
            "mismatched number of reference keys for entity ''{0}'' for relation ''{1}''." +
            " expected {2} but found {3}.",
            ERROR),
    PERSIST_424("PERSIST_424", "invalid use of Relation annotation. " +
            "mismatched key types for entity ''{0}'' for its relationship.",
            ERROR),
    PERSIST_426("PERSIST_426", "invalid use of Relation annotation. " +
            "the field ''{0}'' is an array type in a 1-n relationship. " +
            "therefore, it cannot have foreign keys.",
            ERROR),
    PERSIST_427("PERSIST_427", "invalid use of Relation annotation. " +
            "the field ''{0}'' is an optional type in a 1-1 relationship. " +
            "therefore, it cannot have foreign keys.",
            ERROR),
    PERSIST_428("PERSIST_428", "invalid use of Relation annotation. " +
            "the field ''{0}'' is not found in the entity ''{1}''.",
            ERROR),
    PERSIST_429("PERSIST_429", "invalid use of Relation annotation. " +
            "refs cannot contain duplicates.",
            ERROR),
    PERSIST_430("PERSIST_430", "invalid use of Relation annotation. " +
            "duplicated reference field.",
            ERROR),

    PERSIST_501("PERSIST_501", "''{0}'' entity must have at least one identity readonly field", ERROR),
    PERSIST_502("PERSIST_502", "an identity field cannot be nillable", ERROR),
    PERSIST_503("PERSIST_503", "only ''int'', ''string'', ''float'', ''boolean'', ''decimal'' " +
            "types are supported as identity fields, found ''{0}''", ERROR),
    PERSIST_600("PERSIST_600", "invalid use of Mapping annotation. mapping name cannot be empty.", ERROR),
    PERSIST_601("PERSIST_601", "mapping name is same as model definition.", WARNING),
    PERSIST_602("PERSIST_602", "invalid use of Mapping annotation. " +
            "Mapping annotation cannot be used for relation fields.", ERROR),
    PERSIST_604("PERSIST_604", "invalid use of ''{0}'' annotation. " +
            "''{0}'' annotation can only be used for string data type.", ERROR),
    PERSIST_605("PERSIST_605", "invalid use of VarChar and Char annotations. " +
            "only one of either Char or Varchar annotations can be used at a time.", ERROR),
    PERSIST_606("PERSIST_606", "invalid use of Decimal annotation. " +
            "Decimal annotation can only be used for decimal data type.", ERROR),
    PERSIST_607("PERSIST_607", "invalid use of ''{0}'' annotation. " +
            "length cannot be 0.", ERROR),
    PERSIST_608("PERSIST_608", "invalid use of Decimal annotation. " +
            "precision cannot be 0.", ERROR),
    PERSIST_609("PERSIST_609", "invalid use of Decimal annotation. " +
            "precision cannot be less than scale.", ERROR),
    PERSIST_610("PERSIST_610", "invalid use of Mapping annotation. " +
            "duplicate mapping name found.", ERROR),
    PERSIST_611("PERSIST_611", "invalid use of Index annotation. " +
            "Index annotation cannot be used for relation fields.", ERROR),
    PERSIST_612("PERSIST_612", "invalid use of UniqueIndex annotation. " +
            "UniqueIndex annotation cannot be used for relation fields.", ERROR),
    PERSIST_613("PERSIST_613", "invalid use of Index annotation. " +
            "duplicate index names.", ERROR),
    PERSIST_614("PERSIST_614", "invalid use of UniqueIndex annotation. " +
            "duplicate index names.", ERROR),
    PERSIST_615("PERSIST_615", "invalid use of Index annotation. " +
            "there cannot be empty index names.", ERROR),
    PERSIST_616("PERSIST_616", "invalid use of UniqueIndex annotation. " +
            "there cannot be empty index names.", ERROR),

    ;

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
