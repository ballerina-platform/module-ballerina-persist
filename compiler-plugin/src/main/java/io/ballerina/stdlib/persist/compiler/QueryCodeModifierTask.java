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

import io.ballerina.compiler.syntax.tree.BasicLiteralNode;
import io.ballerina.compiler.syntax.tree.BindingPatternNode;
import io.ballerina.compiler.syntax.tree.CaptureBindingPatternNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FieldAccessExpressionNode;
import io.ballerina.compiler.syntax.tree.FieldBindingPatternVarnameNode;
import io.ballerina.compiler.syntax.tree.FromClauseNode;
import io.ballerina.compiler.syntax.tree.IntermediateClauseNode;
import io.ballerina.compiler.syntax.tree.LimitClauseNode;
import io.ballerina.compiler.syntax.tree.LiteralValueToken;
import io.ballerina.compiler.syntax.tree.MappingBindingPatternNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.OrderByClauseNode;
import io.ballerina.compiler.syntax.tree.OrderKeyNode;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.QueryExpressionNode;
import io.ballerina.compiler.syntax.tree.QueryPipelineNode;
import io.ballerina.compiler.syntax.tree.RemoteMethodCallActionNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.compiler.syntax.tree.Token;
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
import static io.ballerina.stdlib.persist.compiler.Constants.ASCENDING;
import static io.ballerina.stdlib.persist.compiler.Constants.BACKTICK;
import static io.ballerina.stdlib.persist.compiler.Constants.EXECUTE_FUNCTION;
import static io.ballerina.stdlib.persist.compiler.Constants.READ_FUNCTION;
import static io.ballerina.stdlib.persist.compiler.Constants.SPACE;
import static io.ballerina.stdlib.persist.compiler.Constants.SQLKeyWords.LIMIT;
import static io.ballerina.stdlib.persist.compiler.Constants.SQLKeyWords.ORDERBY;
import static io.ballerina.stdlib.persist.compiler.Constants.SQLKeyWords.ORDER_BY_ASCENDING;
import static io.ballerina.stdlib.persist.compiler.Constants.SQLKeyWords.ORDER_BY_DECENDING;

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
            List<IntermediateClauseNode> whereClauseNode = intermediateClauseNodes.stream()
                    .filter((node) -> node instanceof WhereClauseNode)
                    .collect(Collectors.toList());

            List<IntermediateClauseNode> orderByClauseNode = intermediateClauseNodes.stream()
                    .filter((node) -> node instanceof OrderByClauseNode)
                    .collect(Collectors.toList());

            List<IntermediateClauseNode> limitClauseNode = intermediateClauseNodes.stream()
                    .filter((node) -> node instanceof LimitClauseNode)
                    .collect(Collectors.toList());

            boolean isWhereClauseUsed = whereClauseNode.size() != 0;
            boolean isOrderByClauseUsed = orderByClauseNode.size() != 0;
            boolean isLimitClauseUsed = limitClauseNode.size() != 0;

            if (!isWhereClauseUsed && !isOrderByClauseUsed && !isLimitClauseUsed) {
                return queryExpressionNode;
            }

            StringBuilder filterQuery = new StringBuilder();
            if (isOrderByClauseUsed) {
                StringBuilder orderByClause = processOrderByClause(((OrderByClauseNode) orderByClauseNode.get(0)),
                        fromClauseNode.typedBindingPattern().bindingPattern());
                if (orderByClause != null) {
                    filterQuery.append(orderByClause);
                } else {
                    // If we cannot process orderby clause, query syntax is left as it is
                    return queryExpressionNode;
                }
            }
            if (isLimitClauseUsed) {
                StringBuilder limitClause = processLimitClause(((LimitClauseNode) limitClauseNode.get(0)));
                if (limitClause.length() != 0) {
                    filterQuery.append(limitClause);
                } else {
                    // If we cannot process limit clause, query syntax is left as it is
                    return queryExpressionNode;
                }
            }

            LiteralValueToken backTickLiteral = NodeFactory.createLiteralValueToken(
                    SyntaxKind.BACKTICK_TOKEN,
                    BACKTICK,
                    createEmptyMinutiaeList(),
                    createEmptyMinutiaeList());
            LiteralValueToken emptyStringLiteral = NodeFactory.createLiteralValueToken(
                    SyntaxKind.STRING_LITERAL,
                    filterQuery.toString(),
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

            NodeList<IntermediateClauseNode> processedClauses = intermediateClauseNodes;
            if (isOrderByClauseUsed) {
                int orderByClauseIndex = 0;
                for (int i = 0; i < intermediateClauseNodes.size(); i++) {
                    if (intermediateClauseNodes.get(i) instanceof OrderByClauseNode) {
                        orderByClauseIndex = i;
                        break;
                    }
                }
                processedClauses = processedClauses.remove(orderByClauseIndex);
            }
            if (isLimitClauseUsed) {
                int limitByClauseIndex = 0;
                for (int i = 0; i < intermediateClauseNodes.size(); i++) {
                    if (intermediateClauseNodes.get(i) instanceof LimitClauseNode) {
                        limitByClauseIndex = i;
                        break;
                    }
                }
                processedClauses = processedClauses.remove(limitByClauseIndex);
            }

            QueryPipelineNode updatedQueryPipeline = queryPipelineNode.modify(
                    modifiedFromClause,
                    processedClauses
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

        private StringBuilder processOrderByClause(OrderByClauseNode orderByClauseNode,
                                                   BindingPatternNode bindingPatternNode) {
            StringBuilder orderByClause = new StringBuilder(ORDERBY).append(SPACE);
            SeparatedNodeList<OrderKeyNode> orderKeyNodes = orderByClauseNode.orderKey();
            for (int i = 0; i < orderKeyNodes.size(); i++) {
                if (i != 0) {
                    orderByClause.append(", ");
                }
                ExpressionNode expression = orderKeyNodes.get(i).expression();
                if (expression instanceof FieldAccessExpressionNode) {
                    FieldAccessExpressionNode fieldAccessNode = (FieldAccessExpressionNode) expression;
                    if (!(bindingPatternNode instanceof CaptureBindingPatternNode)) {
                        // If this is not capture pattern there is compilation error
                        return null;
                    }
                    String bindingVariableName = ((CaptureBindingPatternNode) bindingPatternNode).variableName().text();
                    String recordName = ((SimpleNameReferenceNode) fieldAccessNode.expression()).name().text();
                    if (!bindingVariableName.equals(recordName)) {
                        return null;
                    }
                    // todo Validate column name is valid
                    String fieldName = ((SimpleNameReferenceNode) fieldAccessNode.fieldName()).name().text();
                    orderByClause.append(fieldName);
                } else if (expression instanceof SimpleNameReferenceNode) {
                    String fieldName = ((SimpleNameReferenceNode) expression).name().text();

                    if (!(bindingPatternNode instanceof MappingBindingPatternNode)) {
                        // If this is not mapping pattern there is compilation error
                        return null;
                    }
                    boolean isCorrectField = false;
                    SeparatedNodeList<BindingPatternNode> bindingPatternNodes =
                            ((MappingBindingPatternNode) bindingPatternNode).fieldBindingPatterns();
                    for (BindingPatternNode patternNode : bindingPatternNodes) {
                        String field = ((FieldBindingPatternVarnameNode) patternNode).variableName().name().text();
                        if (fieldName.equals(field)) {
                            isCorrectField = true;
                        }
                    }
                    if (!isCorrectField) {
                        return null;
                    }
                    orderByClause.append(fieldName);
                } else {
                    // Persistent client does not support order by using parameters
                    return null;
                }
                if (orderKeyNodes.get(i).orderDirection().isPresent()) {
                    Token orderDirection = orderKeyNodes.get(i).orderDirection().get();
                    if (orderDirection.text().equals(ASCENDING)) {
                        orderByClause.append(SPACE).append(ORDER_BY_ASCENDING);
                    } else {
                        orderByClause.append(SPACE).append(ORDER_BY_DECENDING);
                    }
                    // Any typos are recognised as order by direction missing
                }
                orderByClause.append(SPACE);
            }
            return orderByClause;
        }

        private StringBuilder processLimitClause(LimitClauseNode limitClauseNode) {
            StringBuilder limitClause = new StringBuilder();
            ExpressionNode limitByExpression = limitClauseNode.expression();
            if (limitByExpression instanceof BasicLiteralNode &&
                    limitByExpression.kind() == SyntaxKind.NUMERIC_LITERAL) {
                limitClause.append(LIMIT).append(SPACE)
                        .append(((BasicLiteralNode) limitByExpression).literalToken().text());
            }
            return limitClause;
        }
    }
}
