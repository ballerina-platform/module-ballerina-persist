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

import java.util.Collections;
import java.util.List;

import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_101;

/**
 * Code action for removing unsupported members (PERSIST_101).
 */
public class RemoveUnsupportedMembers extends AbstractRemoveUnsupportedSyntax {

    @Override
    protected String getName() {
        return PersistCodeActionName.REMOVE_UNSUPPORTED_MEMBERS.getName();
    }

    @Override
    protected List<String> getSupportedDiagnosticCodes() {
        return Collections.singletonList(PERSIST_101.getCode());
    }

    @Override
    protected String getTitle() {
        return "Remove unsupported member";
    }

    @Override
    protected TextRange getNodeLocation(Diagnostic diagnostic) {
        return diagnostic.location().textRange();
    }
}
