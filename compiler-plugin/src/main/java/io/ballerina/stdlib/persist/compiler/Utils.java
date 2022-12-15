/*
 * Copyright (c) 2022, WSO2 Inc. (http:www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http:www.apache.orglicensesLICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.persist.compiler;

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.FromClauseNode;
import io.ballerina.compiler.syntax.tree.LiteralValueToken;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.RemoteMethodCallActionNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;

import static io.ballerina.compiler.syntax.tree.AbstractNodeFactory.createEmptyMinutiaeList;
import static io.ballerina.stdlib.persist.compiler.Constants.READ_FUNCTION;

/**
 * This class includes utility functions.
 */
public class Utils {

    protected static String eliminateDoubleQuotes(String text) {
        return text.substring(1, text.length() - 1);
    }

    public static boolean hasCompilationErrors(SyntaxNodeAnalysisContext context) {
        for (Diagnostic diagnostic : context.semanticModel().diagnostics()) {
            if (diagnostic.diagnosticInfo().severity() == DiagnosticSeverity.ERROR) {
                return true;
            }
        }
        return false;
    }

    public static void reportDiagnostic(SyntaxNodeAnalysisContext ctx, Location location, String code,
                                        String message, DiagnosticSeverity diagnosticSeverity) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(code, message, diagnosticSeverity);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }

    public static LiteralValueToken getStringLiteralToken(String value) {
        return NodeFactory.createLiteralValueToken(
                SyntaxKind.STRING_LITERAL, value, createEmptyMinutiaeList(), createEmptyMinutiaeList());
    }

    public static boolean isQueryUsingPersistentClient(FromClauseNode fromClauseNode) {

        // From clause should contain remote call invocation
        if (fromClauseNode.expression() instanceof RemoteMethodCallActionNode) {
            RemoteMethodCallActionNode remoteCall = (RemoteMethodCallActionNode) fromClauseNode.expression();
            String functionName = remoteCall.methodName().name().text();

            // Remote function name should be read
            return functionName.trim().equals(READ_FUNCTION);
        }
        return false;
    }

    public static boolean isPersistAnnotation(AnnotationNode annotation, String annotationName) {
        if (annotation.annotReference() instanceof QualifiedNameReferenceNode) {
            QualifiedNameReferenceNode annotationReference = (QualifiedNameReferenceNode) annotation.annotReference();
            return annotationReference.modulePrefix().text().equals(Constants.PERSIST_MODULE) &&
                    annotationReference.identifier().text().equals(annotationName);
        }
        return false;
    }
}
