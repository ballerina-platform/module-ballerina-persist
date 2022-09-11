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
package io.ballerina.stdlib.persist.compiler.expression;

import io.ballerina.compiler.syntax.tree.BasicLiteralNode;
import io.ballerina.compiler.syntax.tree.BinaryExpressionNode;
import io.ballerina.compiler.syntax.tree.ChildNodeList;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FieldAccessExpressionNode;
import io.ballerina.compiler.syntax.tree.LiteralValueToken;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.stdlib.persist.compiler.NotSupportedExpressionException;

/**
 * Builder class to process where clause.
 */
public class ExpressionBuilder {
    private final ExpressionNode expressionNode;

    public ExpressionBuilder(ExpressionNode expression) {
        this.expressionNode = expression;
    }

    public void build(ExpressionVisitor expressionVisitor) {
        buildVariableExecutors(expressionNode, expressionVisitor);
    }

    private void buildVariableExecutors(ExpressionNode expressionNode, ExpressionVisitor expressionVisitor)
            throws NotSupportedExpressionException {
        // todo Support usage of variables, constants and bracketed expressions
        if (expressionNode instanceof BinaryExpressionNode) {
            // Simple Compare
            ChildNodeList expressionChildren = expressionNode.children();
            SyntaxKind tokenKind = expressionChildren.get(1).kind();

            if (tokenKind == SyntaxKind.LOGICAL_AND_TOKEN) {
                expressionVisitor.beginVisitAnd();
                expressionVisitor.beginVisitAndLeftOperand();
                buildVariableExecutors((ExpressionNode) expressionChildren.get(0), expressionVisitor);
                expressionVisitor.endVisitAndLeftOperand();
                expressionVisitor.beginVisitAndRightOperand();
                buildVariableExecutors((ExpressionNode) expressionChildren.get(2), expressionVisitor);
                expressionVisitor.endVisitAndRightOperand();
                expressionVisitor.endVisitAnd();
            } else if (tokenKind == SyntaxKind.LOGICAL_OR_TOKEN) {
                expressionVisitor.beginVisitOr();
                expressionVisitor.beginVisitOrLeftOperand();
                buildVariableExecutors((ExpressionNode) expressionChildren.get(0), expressionVisitor);
                expressionVisitor.endVisitOrLeftOperand();
                expressionVisitor.beginVisitOrRightOperand();
                buildVariableExecutors((ExpressionNode) expressionChildren.get(2), expressionVisitor);
                expressionVisitor.endVisitOrRightOperand();
                expressionVisitor.endVisitOr();
            } else {
                expressionVisitor.beginVisitCompare(tokenKind);
                expressionVisitor.beginVisitCompareLeftOperand(tokenKind);
                buildVariableExecutors((ExpressionNode) expressionChildren.get(0), expressionVisitor);
                expressionVisitor.endVisitCompareLeftOperand(tokenKind);
                expressionVisitor.beginVisitCompareRightOperand(tokenKind);
                buildVariableExecutors((ExpressionNode) expressionChildren.get(2), expressionVisitor);
                expressionVisitor.endVisitCompareRightOperand(tokenKind);
                expressionVisitor.endVisitCompare(tokenKind);
            }
        } else if (expressionNode instanceof FieldAccessExpressionNode) {
            // Bracketed Multi Expression
            // todo Validate if this is not part of an expression
            expressionVisitor.beginVisitStoreVariable(
                    ((SimpleNameReferenceNode) expressionNode.children().get(2)).name().text());
            expressionVisitor.endVisitStoreVariable(
                    ((SimpleNameReferenceNode) expressionNode.children().get(2)).name().text());
        } else if (expressionNode instanceof BasicLiteralNode) {
            LiteralValueToken literalValueToken = (LiteralValueToken) expressionNode.children().get(0);
            expressionVisitor.beginVisitConstant(literalValueToken.text(), literalValueToken.kind());
            expressionVisitor.endVisitConstant(literalValueToken.text(), literalValueToken.kind());
        } else {
            throw new NotSupportedExpressionException("Unsupported expression.");
        }
    }
}
