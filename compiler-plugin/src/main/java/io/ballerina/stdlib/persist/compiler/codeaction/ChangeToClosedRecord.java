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

import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.codeaction.CodeAction;
import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.projects.plugins.codeaction.DocumentEdit;
import io.ballerina.stdlib.persist.compiler.DiagnosticsCodes;
import io.ballerina.tools.diagnostics.DiagnosticProperty;
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextDocumentChange;
import io.ballerina.tools.text.TextEdit;
import io.ballerina.tools.text.TextRange;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.persist.compiler.Utils.getNumericDiagnosticProperty;
import static io.ballerina.stdlib.persist.compiler.Utils.getTextRangeArgument;

/**
 * Code action for changing to closed record.
 */
public class ChangeToClosedRecord implements CodeAction {

    private static final String START_DELIMITER_TEXT_RANGE = "start.text.range";
    private static final String END_DELIMITER_TEXT_RANGE = "end.text.range";

    @Override
    public List<String> supportedDiagnosticCodes() {
        return List.of(DiagnosticsCodes.PERSIST_201.getCode());
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext context) {
        List<DiagnosticProperty<?>> properties = context.diagnostic().properties();

        TextRange startDelimiterFrom = TextRange.from(getNumericDiagnosticProperty(properties, 0), 0);
        TextRange endDelimiterFrom = TextRange.from(getNumericDiagnosticProperty(properties, 1), 0);

        CodeActionArgument startLocationArg = CodeActionArgument.from(START_DELIMITER_TEXT_RANGE, startDelimiterFrom);
        CodeActionArgument endLocationArg = CodeActionArgument.from(END_DELIMITER_TEXT_RANGE, endDelimiterFrom);
        return Optional.of(CodeActionInfo.from("Change to closed record", List.of(startLocationArg, endLocationArg)));
    }

    @Override
    public List<DocumentEdit> execute(CodeActionExecutionContext context) {
        TextRange startDelimiterFrom = getTextRangeArgument(context, START_DELIMITER_TEXT_RANGE);
        TextRange endDelimiterFrom = getTextRangeArgument(context, END_DELIMITER_TEXT_RANGE);
        if (startDelimiterFrom == null || endDelimiterFrom == null) {
            return Collections.emptyList();
        }

        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();

        List<TextEdit> textEdits = new ArrayList<>();
        textEdits.add(TextEdit.from(startDelimiterFrom, SyntaxKind.PIPE_TOKEN.stringValue()));
        textEdits.add(TextEdit.from(endDelimiterFrom, SyntaxKind.PIPE_TOKEN.stringValue()));

        TextDocumentChange change = TextDocumentChange.from(textEdits.toArray(new TextEdit[0]));
        TextDocument modifiedTextDocument = syntaxTree.textDocument().apply(change);
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(modifiedTextDocument)));
    }

    @Override
    public String name() {
        return PersistCodeActionName.CHANGE_TO_CLOSED_RECORD.getName();
    }
}
