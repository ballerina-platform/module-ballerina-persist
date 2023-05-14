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

import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.codeaction.CodeAction;
import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.projects.plugins.codeaction.DocumentEdit;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticProperty;
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextDocumentChange;
import io.ballerina.tools.text.TextEdit;
import io.ballerina.tools.text.TextRange;

import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

import static io.ballerina.stdlib.persist.compiler.Constants.EMPTY_STRING;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_004;
import static io.ballerina.stdlib.persist.compiler.codeaction.PersistCodeActionName.SWITCH_RELATION_OWNER;
import static io.ballerina.stdlib.persist.compiler.utils.Utils.getNumericDiagnosticProperty;
import static io.ballerina.stdlib.persist.compiler.utils.Utils.getStringDiagnosticProperty;

/**
 * Code action to switch owner in multiple relations.
 */
public class SwitchRelationOwner implements CodeAction {

    @Override
    public List<String> supportedDiagnosticCodes() {
        return List.of(
                PERSIST_004.getCode()
        );
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext codeActionContext) {
        Diagnostic diagnostic = codeActionContext.diagnostic();
        List<DiagnosticProperty<?>> properties = diagnostic.properties();
        if (properties.size() % 4 != 1) {
            // For any change 4 properties are required each
            return Optional.empty();
        }

        String ownerName = getStringDiagnosticProperty(properties, 0);
        List<CodeActionArgument> arguments = new ArrayList<>();
        for (int i = 1; i < properties.size(); i += 4) {
            TextRange deleteRange = TextRange.from(getNumericDiagnosticProperty(properties, i),
                    getNumericDiagnosticProperty(properties, i + 1));
            TextRange addRange = TextRange.from(getNumericDiagnosticProperty(properties, i + 2), 0);
            String addText = getStringDiagnosticProperty(properties, i + 3);
            arguments.add(CodeActionArgument.from("remove.text.range." + i, deleteRange));
            arguments.add(CodeActionArgument.from("add.text.range." + i, addRange));
            arguments.add(CodeActionArgument.from("add.text." + i, addText));
        }

        return Optional.of(CodeActionInfo.from(MessageFormat.format("Make ''{0}'' entity relation owner", ownerName),
                arguments));
    }

    @Override
    public List<DocumentEdit> execute(CodeActionExecutionContext context) {
        List<CodeActionArgument> arguments = context.arguments();
        if (arguments.size() % 3 != 0) {
            return Collections.emptyList();
        }
        if (arguments.stream().anyMatch(Objects::isNull)) {
            return Collections.emptyList();
        }

        List<TextEdit> textEdits = new ArrayList<>();
        for (int i = 0; i < arguments.size(); i += 3) {
            TextRange removeRange = arguments.get(i).valueAs(TextRange.class);
            TextRange addRange = arguments.get(i + 1).valueAs(TextRange.class);
            String addText = arguments.get(i + 2).valueAs(String.class);
            textEdits.add(TextEdit.from(removeRange, EMPTY_STRING));
            textEdits.add(TextEdit.from(addRange, addText));
        }
        // Temporary fix for https://github.com/ballerina-platform/ballerina-lang/issues/39860
        textEdits.sort(Comparator.comparingInt(t -> t.range().startOffset()));

        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();

        TextDocumentChange change = TextDocumentChange.from(textEdits.toArray(new TextEdit[0]));
        TextDocument modifiedTextDocument = syntaxTree.textDocument().apply(change);
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(modifiedTextDocument)));
    }

    @Override
    public String name() {
        return SWITCH_RELATION_OWNER.getName();
    }
}
