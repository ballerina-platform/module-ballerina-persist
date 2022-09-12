/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.CheckExpressionNode;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionBodyBlockNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.FunctionSignatureNode;
import io.ballerina.compiler.syntax.tree.MethodCallExpressionNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ParameterNode;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.StatementNode;
import io.ballerina.compiler.syntax.tree.VariableDeclarationNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Persist client validator.
 */
public class PersistClientValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    private final List<String> recordNames;

    PersistClientValidator() {
        recordNames = new ArrayList<>();
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {
        List<Diagnostic> diagnostics = ctx.semanticModel().diagnostics();
        for (Diagnostic diagnostic : diagnostics) {
            if (diagnostic.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)) {
                return;
            }
        }
        if (ctx.node().toSourceCode().trim().contains(Constants.BALLERINA_PERSIST)) {
            NodeList<ModuleMemberDeclarationNode> memberNodes = ((ModulePartNode) ctx.syntaxTree().rootNode()).
                    members();
            for (ModuleMemberDeclarationNode memberNode : memberNodes) {
                if (!(memberNode instanceof ClassDefinitionNode)) {
                    continue;
                }
                NodeList<Node> members = ((ClassDefinitionNode) memberNode).members();
                for (Node member : members) {
                    if (member instanceof FunctionDefinitionNode) {
                        processFunctionDefinitionNode(ctx, member);
                    }
                }
            }
        }
    }

    private void processFunctionDefinitionNode(SyntaxNodeAnalysisContext ctx, Node member) {
        FunctionDefinitionNode functionDefinitionNode = ((FunctionDefinitionNode) member);
        FunctionSignatureNode functionSignatureNode = functionDefinitionNode.functionSignature();
        SeparatedNodeList<ParameterNode> parameters = functionSignatureNode.parameters();
        if (functionDefinitionNode.functionBody().toSourceCode().contains(Constants.INSERT_METHOD_NAME) &&
                parameters.size() > 0) {
            String recordName = parameters.get(0).toSourceCode().split(" ")[0].trim();
            if (recordNames.contains(recordName)) {
                Utils.reportDiagnostic(ctx, functionSignatureNode.location(),
                        DiagnosticsCodes.PERSIST_113.getCode(), DiagnosticsCodes.PERSIST_113.getMessage(),
                        DiagnosticsCodes.PERSIST_113.getSeverity());
            } else {
                recordNames.add(recordName);
            }
        } else {
            NodeList<StatementNode> statements = ((FunctionBodyBlockNode) functionDefinitionNode.functionBody()).
                    statements();
            for (StatementNode statement : statements) {
                if (!(statement instanceof VariableDeclarationNode &&
                        statement.toSourceCode().trim().contains(Constants.INSERT_METHOD_NAME))) {
                    continue;
                }
                VariableDeclarationNode variableDeclarationNode = (VariableDeclarationNode) statement;
                Optional<ExpressionNode> initializer = variableDeclarationNode.initializer();
                if (initializer.isPresent()) {
                    ExpressionNode expressionNode = initializer.get();
                    if (expressionNode instanceof CheckExpressionNode) {
                        expressionNode = ((CheckExpressionNode) expressionNode).expression();
                    }
                    PositionalArgumentNode argument =
                            (PositionalArgumentNode) ((((MethodCallExpressionNode) expressionNode).arguments()).
                                    get(0));
                    Optional<TypeSymbol> referenceType = ctx.semanticModel().typeOf(argument);
                    if (referenceType.isPresent()) {
                        TypeSymbol typeSymbol = referenceType.get();
                        if (!(typeSymbol instanceof TypeReferenceTypeSymbol)) {
                            continue;
                        }
                        Optional<String> referenceTypeSymbol =
                                    ((TypeReferenceTypeSymbol) (referenceType.get())).definition().getName();
                        if (referenceTypeSymbol.isPresent()) {
                            String recordName = referenceTypeSymbol.get();
                            if (recordNames.contains(recordName)) {
                                Utils.reportDiagnostic(ctx, functionSignatureNode.location(),
                                        DiagnosticsCodes.PERSIST_113.getCode(),
                                        DiagnosticsCodes.PERSIST_113.getMessage(),
                                        DiagnosticsCodes.PERSIST_113.getSeverity());
                            } else {
                                recordNames.add(recordName);
                            }
                        }
                    }
                }
            }
        }
    }
}
