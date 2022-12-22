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

import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.RecordTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

/**
 * Tests persist compiler plugin.
 */
public class CompilerPluginTest {

    @Test
    public void testIncrementValue() {
        Path projectPath = Paths.get("src", "test", "resources", "test-src", "package_01").toAbsolutePath();
        BuildProject project = BuildProject.load(projectPath);
        BuildProject project1 = BuildProject.load(
                Paths.get("src", "test", "resources", "test-src", "package_02").toAbsolutePath());
        SyntaxNodeAnalysisContextImpl impl = null;
        for (Module module : project.currentPackage().modules()) {
            for (DocumentId documentId : module.documentIds()) {
                Document document = module.document(documentId); // get the syntax tree for other bal file/document
                SyntaxTree syntaxTree = document.syntaxTree();

                NodeList<ModuleMemberDeclarationNode> memberNodes =
                        ((ModulePartNode) syntaxTree.rootNode()).members();
                for (ModuleMemberDeclarationNode memberNode : memberNodes) {
                    if (!(memberNode instanceof TypeDefinitionNode)) {
                        continue;
                    }
                    TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) memberNode;

                    Node typeDescriptor = typeDefinitionNode.typeDescriptor();
                    if (!(typeDescriptor instanceof RecordTypeDescriptorNode)) {
                        continue;
                    }
                    impl = new SyntaxNodeAnalysisContextImpl(typeDefinitionNode, module.moduleId(),
                            documentId, syntaxTree,
                            project.currentPackage().getCompilation().getSemanticModel(module.moduleId()),
                            project.currentPackage(),
                            project1.currentPackage().getCompilation()
                            );
                    break;
                }
            }
        }
        assert impl != null;
        PersistRecordValidator persistRecordValidator = new PersistRecordValidator();
        persistRecordValidator.perform(impl);
        testDiagnostic(
                impl.reportedDiagnostics(),
                new String[]{
                        "mysql db only allow increment value by one in auto generated field"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_112.getCode()
                });
    }

    private void testDiagnostic(List<Diagnostic> errorDiagnosticsList, String[] msg, String[] code) {
        Assert.assertEquals(errorDiagnosticsList.size(), 1);
        for (int index = 0; index < errorDiagnosticsList.size(); index++) {
            DiagnosticInfo error = errorDiagnosticsList.get(index).diagnosticInfo();
            Assert.assertEquals(error.code(), code[index]);
            Assert.assertTrue(error.messageFormat().startsWith(msg[index]));
        }
    }
}
