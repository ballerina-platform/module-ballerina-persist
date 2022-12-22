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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Package;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;

import java.util.ArrayList;
import java.util.List;

/**
 * Implementation for SyntaxNodeAnalysisContext.
 */
public class SyntaxNodeAnalysisContextImpl implements SyntaxNodeAnalysisContext  {
    private final Node node;
    private final ModuleId moduleId;
    private final DocumentId documentId;
    private final SyntaxTree syntaxTree;
    private final SemanticModel semanticModel;
    private final Package currentPackage;
    private final PackageCompilation compilation;
    private final List<Diagnostic> diagnostics = new ArrayList();

    public SyntaxNodeAnalysisContextImpl(Node node, ModuleId moduleId, DocumentId documentId, SyntaxTree syntaxTree,
                                         SemanticModel semanticModel, Package currentPackage,
                                         PackageCompilation compilation) {
        this.node = node;
        this.moduleId = moduleId;
        this.documentId = documentId;
        this.syntaxTree = syntaxTree;
        this.semanticModel = semanticModel;
        this.currentPackage = currentPackage;
        this.compilation = compilation;
    }

    public Node node() {
        return this.node;
    }

    public ModuleId moduleId() {
        return this.moduleId;
    }

    public DocumentId documentId() {
        return this.documentId;
    }

    public SyntaxTree syntaxTree() {
        return this.syntaxTree;
    }

    public SemanticModel semanticModel() {
        return this.semanticModel;
    }

    public Package currentPackage() {
        return this.currentPackage;
    }

    public PackageCompilation compilation() {
        return this.compilation;
    }

    public void reportDiagnostic(Diagnostic diagnostic) {
        this.diagnostics.add(diagnostic);
    }

    List<Diagnostic> reportedDiagnostics() {
        return this.diagnostics;
    }
}
