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

import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.stdlib.persist.compiler.NotSupportedExpressionException;

import static io.ballerina.compiler.syntax.tree.SyntaxKind.EQUAL_TOKEN;
import static io.ballerina.stdlib.persist.compiler.Constants.SPACE;
import static io.ballerina.stdlib.persist.compiler.Constants.SQLKeyWords.WHERE;

/**
 * Visitor class for generating WHERE clause.
 */
public class ExpressionVisitor {
    StringBuilder expression = new StringBuilder(WHERE).append(SPACE);

    public StringBuilder getExpression() {
        return expression.append(SPACE);
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
            case ASTERISK_TOKEN:
            case SLASH_TOKEN:
            case PLUS_TOKEN:
            case MINUS_TOKEN:
            case DOUBLE_LT_TOKEN:
            case DOUBLE_GT_TOKEN:
            case TRIPPLE_GT_TOKEN:
            case ELLIPSIS_TOKEN:
            case DOUBLE_DOT_LT_TOKEN:
            case TRIPPLE_EQUAL_TOKEN:
            case NOT_DOUBLE_EQUAL_TOKEN:
            case BITWISE_AND_TOKEN:
            case BITWISE_XOR_TOKEN:
            case PIPE_TOKEN:
                // todo Need to verify if +,-,/,* is an LHS/RHS. Not supported only if it is the entire operation
                throw new NotSupportedExpressionException("Asterisk token not supported!");
            default:
                // Continue with expression processing
                break;
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
                this.expression.append("<>").append(SPACE);
                break;
            default:
                throw new NotSupportedExpressionException("Unsupported Expression");
        }
    }

    void beginVisitCompareRightOperand(SyntaxKind operator) {

    }

    void endVisitCompareRightOperand(SyntaxKind operator) {

    }

    public void beginVisitConstant(Object value, SyntaxKind type) {
        this.expression.append(value);
        // todo if string append quotes
    }

    public void endVisitConstant(Object value, SyntaxKind type) {
    }


    /*Constant*/
    void beginVisitStoreVariable(String attributeName) {
        String processedAttributeName = attributeName;
        if (attributeName.startsWith("'")) {
            processedAttributeName = processedAttributeName.substring(1);
        }
        this.expression.append(processedAttributeName).append(" ");
    }

    void endVisitStoreVariable(String attributeName) {

    }
}
