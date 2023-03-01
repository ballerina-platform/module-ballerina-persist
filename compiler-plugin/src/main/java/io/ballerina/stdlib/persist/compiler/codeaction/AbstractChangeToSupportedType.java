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
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextDocumentChange;
import io.ballerina.tools.text.TextEdit;
import io.ballerina.tools.text.TextRange;

import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.persist.compiler.Utils.getTextRangeArgument;

/**
 * Abstract code action for changing field type.
 */
public abstract class AbstractChangeToSupportedType implements CodeAction {

    private static final String TYPE_CHANGE_TEXT_RANGE = "type.change.text.range";

    @Override
    public List<String> supportedDiagnosticCodes() {
        return getSupportedDiagnosticCodes();
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext codeActionContext) {
        String type = getType();
        String title = MessageFormat.format("Change to ''{0}'' type", type);
        CodeActionArgument syntaxLocationArg = CodeActionArgument.from(TYPE_CHANGE_TEXT_RANGE,
                codeActionContext.diagnostic().location().textRange());
        return Optional.of(CodeActionInfo.from(title, List.of(syntaxLocationArg)));
    }

    @Override
    public List<DocumentEdit> execute(CodeActionExecutionContext context) {
        TextRange textRange = getTextRangeArgument(context, TYPE_CHANGE_TEXT_RANGE);
        if (textRange == null) {
            return Collections.emptyList();
        }

        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();

        List<TextEdit> textEdits = new ArrayList<>();
        textEdits.add(TextEdit.from(textRange, getType()));
        TextDocumentChange change = TextDocumentChange.from(textEdits.toArray(new TextEdit[0]));
        TextDocument modifiedTextDocument = syntaxTree.textDocument().apply(change);
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(modifiedTextDocument)));
    }

    @Override
    public String name() {
        return getName();
    }

    protected abstract String getName();

    protected abstract List<String> getSupportedDiagnosticCodes();

    protected abstract String getType();

}
