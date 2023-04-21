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
import io.ballerina.tools.diagnostics.DiagnosticProperty;

import java.util.List;

import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_001;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_002;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_005;
import static io.ballerina.stdlib.persist.compiler.Utils.getStringDiagnosticProperty;

/**
 * Code action to add single text.
 * Expected diagnostic properties: Location, CodeActionTitle, TextToAdd
 */
public class AddSingleText extends AbstractAddSyntax {

    @Override
    protected List<String> getSupportedDiagnosticCodes() {
        return List.of(
                PERSIST_005.getCode(),
                PERSIST_001.getCode(),
                PERSIST_002.getCode()
        );
    }

    @Override
    protected String getTitle(Diagnostic diagnostic) {
        List<DiagnosticProperty<?>> properties = diagnostic.properties();
        return getStringDiagnosticProperty(properties, 1);
    }

    @Override
    protected String getAddText(Diagnostic diagnostic) {
        List<DiagnosticProperty<?>> properties = diagnostic.properties();
        return getStringDiagnosticProperty(properties, 2);
    }
}
