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

import io.ballerina.compiler.syntax.tree.FromClauseNode;
import io.ballerina.compiler.syntax.tree.IntermediateClauseNode;
import io.ballerina.compiler.syntax.tree.LimitClauseNode;
import io.ballerina.compiler.syntax.tree.LiteralValueToken;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.OrderByClauseNode;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.QueryExpressionNode;
import io.ballerina.compiler.syntax.tree.QueryPipelineNode;
import io.ballerina.compiler.syntax.tree.RemoteMethodCallActionNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.compiler.syntax.tree.TreeModifier;
import io.ballerina.compiler.syntax.tree.WhereClauseNode;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Package;
import io.ballerina.projects.plugins.ModifierTask;
import io.ballerina.projects.plugins.SourceModifierContext;

import java.util.List;
import java.util.stream.Collectors;

import static io.ballerina.compiler.syntax.tree.AbstractNodeFactory.createEmptyMinutiaeList;
import static io.ballerina.compiler.syntax.tree.AbstractNodeFactory.createSeparatedNodeList;
import static io.ballerina.stdlib.persist.compiler.Constants.BACKTICK;
import static io.ballerina.stdlib.persist.compiler.Constants.EXECUTE_FUNCTION;
import static io.ballerina.stdlib.persist.compiler.Constants.READ_FUNCTION;

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

            QueryPipelineNode queryPipelineNode = queryExpressionNode.queryPipeline();
            FromClauseNode fromClauseNode = queryPipelineNode.fromClause();
            // verify if node invokes persist client read() method
            if (!isQueryUsingPersistentClient(fromClauseNode)) {
                return queryExpressionNode;
            }

            // Check if the query contains where/ orderby / limit clause
            NodeList<IntermediateClauseNode> intermediateClauseNodes = queryPipelineNode.intermediateClauses();
            List<IntermediateClauseNode> whereClauseNodes = intermediateClauseNodes.stream()
                    .filter((node) -> node instanceof WhereClauseNode)
                    .collect(Collectors.toList());

            List<IntermediateClauseNode> orderByClause = intermediateClauseNodes.stream()
                    .filter((node) -> node instanceof OrderByClauseNode)
                    .collect(Collectors.toList());

            List<IntermediateClauseNode> limitClause = intermediateClauseNodes.stream()
                    .filter((node) -> node instanceof LimitClauseNode)
                    .collect(Collectors.toList());

            if (whereClauseNodes.size() == 0 && orderByClause.size() == 0 && limitClause.size() == 0) {
                return queryExpressionNode;
            }

            LiteralValueToken backTickLiteral = NodeFactory.createLiteralValueToken(
                    SyntaxKind.BACKTICK_TOKEN,
                    BACKTICK,
                    createEmptyMinutiaeList(),
                    createEmptyMinutiaeList());
            LiteralValueToken emptyStringLiteral = NodeFactory.createLiteralValueToken(
                    SyntaxKind.STRING_LITERAL,
                    "",
                    createEmptyMinutiaeList(),
                    createEmptyMinutiaeList());
            PositionalArgumentNode firstArgument = NodeFactory.createPositionalArgumentNode(
                    NodeFactory.createTemplateExpressionNode(
                            SyntaxKind.RAW_TEMPLATE_EXPRESSION,
                            null,
                            backTickLiteral,
                            createSeparatedNodeList(emptyStringLiteral),
                            backTickLiteral
                    )
            );

            RemoteMethodCallActionNode remoteCall = (RemoteMethodCallActionNode) fromClauseNode.expression();
            FromClauseNode modifiedFromClause = fromClauseNode.modify(
                    fromClauseNode.fromKeyword(),
                    fromClauseNode.typedBindingPattern(),
                    fromClauseNode.inKeyword(),
                    NodeFactory.createRemoteMethodCallActionNode(
                            remoteCall.expression(),
                            remoteCall.rightArrowToken(),
                            NodeFactory.createSimpleNameReferenceNode(
                                    NodeFactory.createLiteralValueToken(
                                            SyntaxKind.STRING_LITERAL, EXECUTE_FUNCTION,
                                            createEmptyMinutiaeList(),
                                            createEmptyMinutiaeList()
                                    )
                            ),
                            remoteCall.openParenToken(),
                            createSeparatedNodeList(firstArgument),
                            remoteCall.closeParenToken()
                    )
            );

            QueryPipelineNode updatedQueryPipeline = queryPipelineNode.modify(
                    modifiedFromClause,
                    intermediateClauseNodes
            );

            return NodeFactory.createQueryExpressionNode(
                    queryExpressionNode.queryConstructType().orElse(null),
                    updatedQueryPipeline,
                    queryExpressionNode.selectClause(),
                    queryExpressionNode.onConflictClause().orElse(null)
            );
        }

        private boolean isQueryUsingPersistentClient(FromClauseNode fromClauseNode) {

            // From clause should contain remote call invocation
            if (fromClauseNode.expression() instanceof RemoteMethodCallActionNode) {
                RemoteMethodCallActionNode remoteCall = (RemoteMethodCallActionNode) fromClauseNode.expression();
                String functionName = remoteCall.methodName().name().text();

                // Remote function name should be read
                if (functionName.trim().equals(READ_FUNCTION)) {

                    // Function should be invoked with no arguments
                    int argumentsCount = remoteCall.arguments().size();
                    return argumentsCount == 0;
                }
            }
            return false;
        }
    }
}
