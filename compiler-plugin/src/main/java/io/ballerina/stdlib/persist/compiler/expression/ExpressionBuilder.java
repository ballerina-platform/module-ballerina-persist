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
import io.ballerina.compiler.syntax.tree.BindingPatternNode;
import io.ballerina.compiler.syntax.tree.BracedExpressionNode;
import io.ballerina.compiler.syntax.tree.CaptureBindingPatternNode;
import io.ballerina.compiler.syntax.tree.ChildNodeList;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FieldAccessExpressionNode;
import io.ballerina.compiler.syntax.tree.FieldBindingPatternVarnameNode;
import io.ballerina.compiler.syntax.tree.LiteralValueToken;
import io.ballerina.compiler.syntax.tree.MappingBindingPatternNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.stdlib.persist.compiler.DiagnosticsCodes;
import io.ballerina.stdlib.persist.compiler.NotSupportedExpressionException;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;

import java.util.ArrayList;
import java.util.List;

/**
 * Builder class to process where clause.
 */
public class ExpressionBuilder {
    private final ExpressionNode expressionNode;
    private boolean isCaptureBindingPattern = false;
    private String bindingVariableName = "";
    private List<String> fieldNames = new ArrayList<>();

    public ExpressionBuilder(ExpressionNode expression, BindingPatternNode bindingPatternNode) {
        this.expressionNode = expression;
        if (bindingPatternNode instanceof CaptureBindingPatternNode) {
            this.isCaptureBindingPattern = true;
            this.bindingVariableName = ((CaptureBindingPatternNode) bindingPatternNode).variableName().text();
        } else if (bindingPatternNode instanceof MappingBindingPatternNode) {
            SeparatedNodeList<BindingPatternNode> bindingPatternNodes =
                    ((MappingBindingPatternNode) bindingPatternNode).fieldBindingPatterns();
            for (BindingPatternNode patternNode : bindingPatternNodes) {
                String field = ((FieldBindingPatternVarnameNode) patternNode).variableName().name().text();
                fieldNames.add(field);
            }
        }
    }

    public void build(ExpressionVisitor expressionVisitor) throws NotSupportedExpressionException {
        buildVariableExecutors(expressionNode, expressionVisitor);
    }

    private void buildVariableExecutors(ExpressionNode expressionNode, ExpressionVisitor expressionVisitor)
            throws NotSupportedExpressionException {
        try {
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
            } else if (expressionNode instanceof BracedExpressionNode) {
                expressionVisitor.beginVisitBraces();
                buildVariableExecutors(((BracedExpressionNode) expressionNode).expression(), expressionVisitor);
                expressionVisitor.endVisitBraces();
            } else if (expressionNode instanceof FieldAccessExpressionNode) {
                // Bracketed Multi Expression
                String fieldAccessName = ((SimpleNameReferenceNode) expressionNode.children().get(0)).name().text();
                if (this.isCaptureBindingPattern &&
                        bindingVariableName.equals(fieldAccessName)) {
                    expressionVisitor.beginVisitStoreVariable(
                            ((SimpleNameReferenceNode) expressionNode.children().get(2)).name().text());
                    expressionVisitor.endVisitStoreVariable(
                            ((SimpleNameReferenceNode) expressionNode.children().get(2)).name().text());
                } else {
                    throw new NotSupportedExpressionException("Unsupported field access in where clause");
                }
            } else if (expressionNode instanceof SimpleNameReferenceNode) {
                String referencedName = ((SimpleNameReferenceNode) expressionNode).name().text();
                if (this.isCaptureBindingPattern) {
                    expressionVisitor.beginVisitBalVariable(referencedName);
                    expressionVisitor.endVisitBalVariable(referencedName);
                } else {
                    // Mapping constructor
                    if (fieldNames.contains(referencedName)) {
                        expressionVisitor.beginVisitStoreVariable(referencedName);
                        expressionVisitor.endVisitStoreVariable(referencedName);
                    } else {
                        // todo Here wrong reference name cannot be identified as error
                        expressionVisitor.beginVisitBalVariable(referencedName);
                        expressionVisitor.endVisitBalVariable(referencedName);
                    }
                }
            } else if (expressionNode instanceof BasicLiteralNode) {
                LiteralValueToken literalValueToken = (LiteralValueToken) expressionNode.children().get(0);
                expressionVisitor.beginVisitConstant(literalValueToken.text(), literalValueToken.kind());
                expressionVisitor.endVisitConstant(literalValueToken.text(), literalValueToken.kind());
            } else {
                throw new NotSupportedExpressionException("Unsupported expression.");
            }
        } catch (NotSupportedExpressionException e) {
            if (e.getDiagnostic() == null) {
                DiagnosticInfo diagnosticInfo = new DiagnosticInfo(DiagnosticsCodes.PERSIST_201.getCode(),
                        DiagnosticsCodes.PERSIST_201.getMessage(), DiagnosticsCodes.PERSIST_201.getSeverity());
                Diagnostic diagnostic = DiagnosticFactory.createDiagnostic(diagnosticInfo, expressionNode.location());
                throw new NotSupportedExpressionException("Unsupported expression.", diagnostic);
            } else {
                throw e;
            }
        }
    }
}
