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

import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.stdlib.persist.compiler.NotSupportedExpressionException;
import io.ballerina.stdlib.persist.compiler.Utils;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.compiler.syntax.tree.SyntaxKind.EQUAL_TOKEN;
import static io.ballerina.stdlib.persist.compiler.Constants.BAL_ESCAPE_TOKEN;
import static io.ballerina.stdlib.persist.compiler.Constants.CLOSE_BRACES;
import static io.ballerina.stdlib.persist.compiler.Constants.OPEN_BRACES;
import static io.ballerina.stdlib.persist.compiler.Constants.SPACE;
import static io.ballerina.stdlib.persist.compiler.Constants.SQLKeyWords.NOT_EQUAL_TOKEN;
import static io.ballerina.stdlib.persist.compiler.Constants.SQLKeyWords.WHERE;
import static io.ballerina.stdlib.persist.compiler.Constants.TokenNodes.INTERPOLATION_END_TOKEN;
import static io.ballerina.stdlib.persist.compiler.Constants.TokenNodes.INTERPOLATION_START_TOKEN;

/**
 * Visitor class for generating WHERE clause.
 */
public class ExpressionVisitor {
    List<Node> whereExpressionNodes = new ArrayList<>();
    StringBuilder expression = new StringBuilder(WHERE).append(SPACE);

    public List<Node> getExpression() {
        this.expression.append(SPACE);
        whereExpressionNodes.add(Utils.getStringLiteralToken(this.expression.toString()));
        return whereExpressionNodes;
    }

    void beginVisitAnd() {

    }

    void endVisitAnd() {

    }

    void beginVisitAndLeftOperand() {

    }

    void endVisitAndLeftOperand() {

    }

    void beginVisitAndRightOperand() {

    }

    void endVisitAndRightOperand() {

    }

    /*Or*/
    void beginVisitOr() {

    }

    void endVisitOr() {

    }

    void beginVisitOrLeftOperand() {

    }

    void endVisitOrLeftOperand() {

    }

    void beginVisitOrRightOperand() {

    }

    void endVisitOrRightOperand() {

    }

    /*Compare*/
    void beginVisitCompare(SyntaxKind operator) throws NotSupportedExpressionException {
        switch (operator) {
            case GT_TOKEN:
            case GT_EQUAL_TOKEN:
            case LT_TOKEN:
            case LT_EQUAL_TOKEN:
            case PERCENT_TOKEN:
            case DOUBLE_EQUAL_TOKEN:
            case NOT_EQUAL_TOKEN:
                break;
            default:
                // todo Need to verify if +,-,/,* is an LHS/RHS. Not supported only if it is the entire operation
                throw new NotSupportedExpressionException(operator.stringValue() + " not supported!");
        }
    }

    void endVisitCompare(SyntaxKind operator) {

    }

    void beginVisitCompareLeftOperand(SyntaxKind operator) {

    }

    void endVisitCompareLeftOperand(SyntaxKind operator) {
        switch (operator) {
            case GT_TOKEN:
            case GT_EQUAL_TOKEN:
            case LT_TOKEN:
            case LT_EQUAL_TOKEN:
            case PERCENT_TOKEN:
                this.expression.append(operator.stringValue()).append(SPACE);
                break;
            case DOUBLE_EQUAL_TOKEN:
                this.expression.append(EQUAL_TOKEN.stringValue()).append(SPACE);
                break;
            case NOT_EQUAL_TOKEN:
                this.expression.append(NOT_EQUAL_TOKEN).append(SPACE);
                break;
            default:
                throw new NotSupportedExpressionException("Unsupported Expression");
        }
    }

    void beginVisitCompareRightOperand(SyntaxKind operator) {

    }

    void endVisitCompareRightOperand(SyntaxKind operator) {

    }

    public void beginVisitBraces() {
        this.expression.append(OPEN_BRACES);
    }

    public void endVisitBraces() {
        this.expression.append(CLOSE_BRACES);
    }

    /*Constant*/
    public void beginVisitConstant(Object value, SyntaxKind type) {
        this.expression.append(value);
    }

    public void endVisitConstant(Object value, SyntaxKind type) {
    }

    void beginVisitStoreVariable(String attributeName) {
        String processedAttributeName = attributeName;
        if (attributeName.startsWith(BAL_ESCAPE_TOKEN)) {
            processedAttributeName = processedAttributeName.substring(1);
        }
        this.expression.append(processedAttributeName).append(SPACE);
    }

    void endVisitStoreVariable(String attributeName) {

    }

    void beginVisitBalVariable(String attributeName) {
        String processedAttributeName = attributeName;
        if (attributeName.startsWith(BAL_ESCAPE_TOKEN)) {
            processedAttributeName = processedAttributeName.substring(1);
        }

        String partialClause = this.expression.toString();
        whereExpressionNodes.add(Utils.getStringLiteralToken(partialClause));
        ExpressionNode expressionNode = NodeFactory.createSimpleNameReferenceNode(
                Utils.getStringLiteralToken(processedAttributeName));
        whereExpressionNodes.add(NodeFactory.createInterpolationNode(
                INTERPOLATION_START_TOKEN, expressionNode, INTERPOLATION_END_TOKEN));
        this.expression.setLength(0);
        this.expression.append(SPACE);
    }

    void endVisitBalVariable(String attributeName) {

    }

}
