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

import io.ballerina.compiler.syntax.tree.BindingPatternNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FieldAccessExpressionNode;
import io.ballerina.compiler.syntax.tree.FieldBindingPatternVarnameNode;
import io.ballerina.compiler.syntax.tree.FromClauseNode;
import io.ballerina.compiler.syntax.tree.IntermediateClauseNode;
import io.ballerina.compiler.syntax.tree.LimitClauseNode;
import io.ballerina.compiler.syntax.tree.MappingBindingPatternNode;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.OrderByClauseNode;
import io.ballerina.compiler.syntax.tree.OrderKeyNode;
import io.ballerina.compiler.syntax.tree.QueryPipelineNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.WhereClauseNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.persist.compiler.expression.ExpressionBuilder;
import io.ballerina.stdlib.persist.compiler.expression.ExpressionVisitor;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;

import java.util.List;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_202;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_203;
import static io.ballerina.stdlib.persist.compiler.Utils.isQueryUsingPersistentClient;

/**
 * PersistQueryAnalyzer.
 */
public class PersistQueryValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {

        if (Utils.hasCompilationErrors(ctx)) {
            return;
        }

        QueryPipelineNode queryPipelineNode = (QueryPipelineNode) ctx.node();
        FromClauseNode fromClauseNode = queryPipelineNode.fromClause();
        if (!isQueryUsingPersistentClient(fromClauseNode)) {
            return;
        }

        NodeList<IntermediateClauseNode> intermediateClauseNodes = queryPipelineNode.intermediateClauses();
        List<IntermediateClauseNode> whereClauseNodes = intermediateClauseNodes.stream()
                .filter((node) -> node instanceof WhereClauseNode)
                .collect(Collectors.toList());

        List<IntermediateClauseNode> orderByClauseNodes = intermediateClauseNodes.stream()
                .filter((node) -> node instanceof OrderByClauseNode)
                .collect(Collectors.toList());

        List<IntermediateClauseNode> limitClauseNodes = intermediateClauseNodes.stream()
                .filter((node) -> node instanceof LimitClauseNode)
                .collect(Collectors.toList());

        boolean isWhereClauseUsed = whereClauseNodes.size() != 0;
        boolean isOrderByClauseUsed = orderByClauseNodes.size() != 0;
        boolean isLimitClauseUsed = limitClauseNodes.size() != 0;

        if (!isWhereClauseUsed && !isOrderByClauseUsed && !isLimitClauseUsed) {
            return;
        }

        // todo: Verify for all 10 binding patters
        BindingPatternNode bindingPatternNode = fromClauseNode.typedBindingPattern().bindingPattern();
        if (isWhereClauseUsed) {
            WhereClauseNode whereClauseNode = (WhereClauseNode) whereClauseNodes.get(0);
            try {
                ExpressionBuilder expressionBuilder = new ExpressionBuilder(whereClauseNode.expression(),
                        bindingPatternNode);
                ExpressionVisitor expressionVisitor = new ExpressionVisitor();
                expressionBuilder.build(expressionVisitor);
            } catch (NotSupportedExpressionException e) {
                ctx.reportDiagnostic(e.getDiagnostic());
            }
        }
        if (isOrderByClauseUsed) {
            OrderByClauseNode orderByClauseNode = (OrderByClauseNode) orderByClauseNodes.get(0);
            SeparatedNodeList<OrderKeyNode> orderKeyNodes = orderByClauseNode.orderKey();
            for (int i = 0; i < orderKeyNodes.size(); i++) {
                ExpressionNode expression = orderKeyNodes.get(i).expression();
                if (expression instanceof SimpleNameReferenceNode) {
                    String fieldName = ((SimpleNameReferenceNode) expression).name().text();
                    boolean isCorrectField = false;
                    if (bindingPatternNode instanceof MappingBindingPatternNode) {
                        SeparatedNodeList<BindingPatternNode> bindingPatternNodes =
                                ((MappingBindingPatternNode) bindingPatternNode).fieldBindingPatterns();
                        for (BindingPatternNode patternNode : bindingPatternNodes) {
                            String field = ((FieldBindingPatternVarnameNode) patternNode).variableName().name().text();
                            if (fieldName.equals(field)) {
                                isCorrectField = true;
                            }
                        }
                        if (!isCorrectField) {
                            ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                                    new DiagnosticInfo(PERSIST_203.getCode(), PERSIST_203.getMessage(),
                                            PERSIST_203.getSeverity()), orderKeyNodes.get(i).expression().location()));
                        }
                    } else {
                        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                                new DiagnosticInfo(PERSIST_203.getCode(), PERSIST_203.getMessage(),
                                        PERSIST_203.getSeverity()), orderKeyNodes.get(i).expression().location()));
                    }
                } else if (expression instanceof FieldAccessExpressionNode) {
                    return;
                } else {
                    ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                            new DiagnosticInfo(PERSIST_203.getCode(), PERSIST_203.getMessage(),
                                    PERSIST_203.getSeverity()), orderKeyNodes.get(i).expression().location()));
                }
            }
        }
        if (isLimitClauseUsed) {
            LimitClauseNode limitClauseNode = (LimitClauseNode) limitClauseNodes.get(0);
            if (limitClauseNode.expression() instanceof SimpleNameReferenceNode) {
                ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                        new DiagnosticInfo(PERSIST_202.getCode(), PERSIST_202.getMessage(), PERSIST_202.getSeverity()),
                        limitClauseNode.expression().location()));
            }
        }

    }
}
