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

import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.CodeModifier;
import io.ballerina.projects.plugins.CodeModifierContext;

/**
 * Code modifier for stream invoking.
 */
public class PersistCodeModifier extends CodeModifier {

    @Override
    public void init(CodeModifierContext codeModifierContext) {
        // todo: Validate that this task is only run for persist clients
        // Add validations for un supported expressions in where, order by and limit
        codeModifierContext.addSyntaxNodeAnalysisTask(new PersistQueryValidator(), SyntaxKind.QUERY_PIPELINE);
        codeModifierContext.addSourceModifierTask(new QueryCodeModifierTask());
    }

}
