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

package io.ballerina.stdlib.persist.compiler.codeaction;

import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.text.TextRange;

import java.text.MessageFormat;
import java.util.List;

import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_102;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_302;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_304;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_306;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_502;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_503;
import static io.ballerina.stdlib.persist.compiler.Utils.getNumericDiagnosticProperty;
import static io.ballerina.stdlib.persist.compiler.Utils.getStringDiagnosticProperty;
import static io.ballerina.stdlib.persist.compiler.codeaction.PersistCodeActionName.REMOVE_TEXT_RANGE;

/**
 * Remove test range code action.
 */
public class RemoveTextRange extends AbstractRemoveUnsupportedSyntax {
    @Override
    protected String getName() {
        return REMOVE_TEXT_RANGE.getName();
    }

    @Override
    protected List<String> getSupportedDiagnosticCodes() {
        return List.of(
                PERSIST_102.getCode(),
                PERSIST_302.getCode(),
                PERSIST_304.getCode(),
                PERSIST_503.getCode(),
                PERSIST_306.getCode(),
                PERSIST_502.getCode()
        );
    }

    @Override
    protected String getTitle(Diagnostic diagnostic) {
        String code = diagnostic.diagnosticInfo().code();
        if (code.equals(PERSIST_102.getCode())) {
            return "Remove import prefix";
        } else if (code.equals(PERSIST_302.getCode())) {
            return "Remove default value";
        } else if (code.equals(PERSIST_304.getCode())) {
            return "Make field mandatory";
        } else if (code.equals(PERSIST_503.getCode())) {
            return "Change to non-identity field";
        } else {
            // 306 and 502
            return MessageFormat.format("Change to ''{0}'' type",
                    getStringDiagnosticProperty(diagnostic.properties(), 2));
        }
    }

    @Override
    protected TextRange getNodeLocation(Diagnostic diagnostic) {
        int startOffset = getNumericDiagnosticProperty(diagnostic.properties(), 0);
        int length = getNumericDiagnosticProperty(diagnostic.properties(), 1);
        return TextRange.from(startOffset, length);
    }
}
