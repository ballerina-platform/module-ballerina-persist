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

import java.util.List;

import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_102;

/**
 * Code action for removing module prefix (PERSIST_102).
 */
public class RemoveModulePrefix extends AbstractRemoveUnsupportedSyntax {

    @Override
    protected String getName() {
        return PersistCodeActionName.REMOVE_MODULE_PREFIX.getName();
    }

    @Override
    protected List<String> getSupportedDiagnosticCodes() {
        return List.of(PERSIST_102.getCode());
    }

    @Override
    protected String getTitle() {
        return "Remove import prefix";
    }

    @Override
    protected TextRange getNodeLocation(Diagnostic diagnostic) {
        TextRange nodeTextRange = diagnostic.location().textRange();
        return TextRange.from(nodeTextRange.startOffset() - 1, nodeTextRange.length() + 1);
    }
}
