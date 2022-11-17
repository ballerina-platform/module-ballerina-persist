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

import io.ballerina.compiler.syntax.tree.FromClauseNode;
import io.ballerina.compiler.syntax.tree.RemoteMethodCallActionNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;

import static io.ballerina.stdlib.persist.compiler.Constants.EXECUTE_FUNCTION;
import static io.ballerina.stdlib.persist.compiler.Constants.READ_FUNCTION;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_210;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_211;

/**
 * Validator to add diagnostics for remote function invocation.
 */
public class PersistQueryRemoteMethodValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {
    boolean inQueryPipelineScope = false;

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {
        if (Utils.hasCompilationErrors(ctx)) {
            return;
        }

        if (ctx.node() instanceof FromClauseNode) {
            // Just to keep track the syntax tree processing is in query pipeline with a remote call action
            FromClauseNode fromClauseNode = (FromClauseNode) ctx.node();
            if (fromClauseNode.expression() instanceof RemoteMethodCallActionNode) {
                this.inQueryPipelineScope = true;
            }
        } else {
            RemoteMethodCallActionNode remoteCall = (RemoteMethodCallActionNode) ctx.node();
            String functionName = remoteCall.methodName().name().text();

            if (functionName.equals(EXECUTE_FUNCTION)) {
                ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                        new DiagnosticInfo(PERSIST_210.getCode(), PERSIST_210.getMessage(), PERSIST_210.getSeverity()),
                        remoteCall.location())
                );
            } else if (functionName.equals(READ_FUNCTION)) {
                if (!this.inQueryPipelineScope) {
                    ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                            new DiagnosticInfo(PERSIST_211.getCode(), PERSIST_211.getMessage(),
                                    PERSIST_211.getSeverity()), remoteCall.location())
                    );
                }
            }
            this.inQueryPipelineScope = false;
        }
    }
}
