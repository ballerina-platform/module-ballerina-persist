/*
 * Copyright (c) 2022, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.persist.compiler;

import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.VariableDeclarationNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.persist.compiler.models.Variable;

import java.util.List;

/**
 * Analysis task to identify all declared variables.
 */
public class PersistClientVariableIdentifierTask implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final List<Variable> variables;

    public PersistClientVariableIdentifierTask(List<Variable> variables) {
        this.variables = variables;
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {
        if (Utils.hasCompilationErrors(ctx)) {
            return;
        }
        Node variableDeclarationNode = ctx.node();
        if (variableDeclarationNode instanceof ModuleVariableDeclarationNode) {
            ModuleVariableDeclarationNode moduleVariableNode = (ModuleVariableDeclarationNode) variableDeclarationNode;
            String type = moduleVariableNode.typedBindingPattern().typeDescriptor().toString().trim();
            String variableName = moduleVariableNode.typedBindingPattern().bindingPattern().toString().trim();
            variables.add(new Variable(variableName, type));
        } else if (variableDeclarationNode instanceof VariableDeclarationNode) {
            VariableDeclarationNode moduleVariableNode = (VariableDeclarationNode) variableDeclarationNode;
            String type = moduleVariableNode.typedBindingPattern().typeDescriptor().toString().trim();
            String variableName = moduleVariableNode.typedBindingPattern().bindingPattern().toString().trim();
            variables.add(new Variable(variableName, type));
        }
    }
}
