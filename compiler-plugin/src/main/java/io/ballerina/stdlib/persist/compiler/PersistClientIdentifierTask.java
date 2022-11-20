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

import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.persist.compiler.Constants.PERSIST_INHERITANCE_NODE;

/**
 * Identify all persist client in the package.
 */
public class PersistClientIdentifierTask implements AnalysisTask<SyntaxNodeAnalysisContext> {
    List<String> persistClientNames = new ArrayList<>();

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {
        if (Utils.hasCompilationErrors(ctx)) {
            return;
        }
        ClassDefinitionNode classDefinitionNode = (ClassDefinitionNode) ctx.node();
        List<Node> persistTypeInheritanceNodes = classDefinitionNode.members().stream().filter(
                        (member) -> member.toString().trim().equals(PERSIST_INHERITANCE_NODE))
                .collect(Collectors.toList());
        if (persistTypeInheritanceNodes.size() > 0) {
            persistClientNames.add(classDefinitionNode.className().text().trim());
        }
    }
}
