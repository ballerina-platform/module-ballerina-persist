/*
 * Copyright (c) 2022, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.QueryExpressionNode;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.compiler.syntax.tree.TreeModifier;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Package;
import io.ballerina.projects.plugins.ModifierTask;
import io.ballerina.projects.plugins.SourceModifierContext;

/**
 * Code Modifier task for stream invoking.
 */
public class QueryCodeModifierTask implements ModifierTask<SourceModifierContext> {

    @Override
    public void modify(SourceModifierContext ctx) {
        Package pkg = ctx.currentPackage();

        for (ModuleId moduleId : pkg.moduleIds()) {
            Module module = pkg.module(moduleId);
            for (DocumentId documentId : module.documentIds()) {
                ctx.modifySourceFile(getUpdatedSyntaxTree(module, documentId).textDocument(), documentId);
            }
            for (DocumentId documentId : module.testDocumentIds()) {
                ctx.modifyTestSourceFile(getUpdatedSyntaxTree(module, documentId).textDocument(), documentId);
            }
        }
    }

    private SyntaxTree getUpdatedSyntaxTree(Module module, DocumentId documentId) {

        Document document = module.document(documentId);
        ModulePartNode rootNode = document.syntaxTree().rootNode();

        QueryConstructModifier queryConstructModifier = new QueryConstructModifier();
        ModulePartNode newRoot = (ModulePartNode) rootNode.apply(queryConstructModifier);

        return document.syntaxTree().modifyWith(newRoot);
    }

    private static class QueryConstructModifier extends TreeModifier {

        @Override
        public QueryExpressionNode transform(QueryExpressionNode queryExpressionNode) {
            return queryExpressionNode;
        }
    }
}
