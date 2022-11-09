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
package io.ballerina.stdlib.persist.tooling;

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.RecordFieldNode;
import io.ballerina.compiler.syntax.tree.RecordFieldWithDefaultValueNode;
import io.ballerina.compiler.syntax.tree.RecordTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.projects.Project;
import io.ballerina.projects.TomlDocument;
import io.ballerina.toml.syntax.tree.KeyValueNode;
import io.ballerina.toml.syntax.tree.DocumentMemberDeclarationNode;
import io.ballerina.toml.syntax.tree.DocumentNode;
import io.ballerina.toml.syntax.tree.SyntaxTree;
import io.ballerina.toml.syntax.tree.TableNode;
import org.ballerinalang.annotation.JavaSPIService;
import org.ballerinalang.langserver.LSClientLogger;
import org.ballerinalang.langserver.commons.CodeActionContext;
import org.ballerinalang.langserver.commons.codeaction.spi.RangeBasedCodeActionProvider;
import org.ballerinalang.langserver.commons.codeaction.spi.RangeBasedPositionDetails;
import org.eclipse.lsp4j.CodeAction;
import org.eclipse.lsp4j.CodeActionKind;
import org.eclipse.lsp4j.Position;
import org.eclipse.lsp4j.Range;
import org.eclipse.lsp4j.TextDocumentEdit;
import org.eclipse.lsp4j.TextDocumentIdentifier;
import org.eclipse.lsp4j.TextEdit;
import org.eclipse.lsp4j.VersionedTextDocumentIdentifier;
import org.eclipse.lsp4j.WorkspaceEdit;
import org.eclipse.lsp4j.jsonrpc.messages.Either;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

/**
 * Code Action for adding configurable variable into Config.toml.
 *
 * @since 0.1.0
 */
@JavaSPIService("org.ballerinalang.langserver.commons.codeaction.spi.LSCodeActionProvider")
public class AddConfigsToCodeAction implements RangeBasedCodeActionProvider {

    @Override
    public List<CodeAction> getCodeActions(CodeActionContext codeActionContext,
                                           RangeBasedPositionDetails positionDetails) {
        boolean hasConfig = false;
        boolean hasHost = false;
        boolean hasPort = false;
        boolean hasUser = false;
        boolean hasPassword = false;
        boolean hasDatabase = false;
        String codeActionTitle = "Add database configs to Config.toml";
        String CONFIG_TOML = "Config.toml";
        NonTerminalNode matchedNode = positionDetails.matchedCodeActionNode();
        if (matchedNode.kind() != SyntaxKind.RECORD_TYPE_DESC) {
            return Collections.emptyList();
        }
        TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) matchedNode.parent();
        if (!hasEntityAnnotation(typeDefinitionNode)) {
            return Collections.emptyList();
        }

        Path configFilePath = codeActionContext.workspace().projectRoot(codeActionContext.filePath()).
                resolve(CONFIG_TOML);
        String configFilePathInString = configFilePath.toString();
        Project project = codeActionContext.workspace().project(codeActionContext.filePath()).orElseThrow();
        if (!Files.exists(configFilePath)) {
            try {
                Files.createFile(configFilePath);
            } catch (Exception e) {
                LSClientLogger clientLogger = LSClientLogger.getInstance(codeActionContext.languageServercontext());
                String msg = "Operation 'configFile/creation' failed!";
                Position position = new Position(typeDefinitionNode.position(), 0);
                clientLogger.logError(LSContextOperations.FILE_CREATION, msg, e,
                        new TextDocumentIdentifier(codeActionContext.filePath().toString()), position);
            }
        }
        List<CodeAction> codeActionList = new ArrayList<>();
        try {
            String content = Files.readString(configFilePath);
            String importText =  project.currentPackage().descriptor().org().value() + "." +
                    project.currentPackage().descriptor().name().value() + "." + "clients";
            TomlDocument tomlDocument = TomlDocument.from(CONFIG_TOML, content);
            SyntaxTree tomlSyntaxTree = tomlDocument.syntaxTree();
            DocumentNode documentNode = tomlSyntaxTree.rootNode();
            if (content.trim().isEmpty()) {
                importText = getImportText(importText);
                addCodeAction(codeActionList, documentNode, importText, configFilePathInString, codeActionTitle);
            } else {
                for (DocumentMemberDeclarationNode member : documentNode.members()) {
                    TableNode tableNode = (TableNode) member;
                    String tableName = tableNode.identifier().toSourceCode().trim();
                    if (tableName.equals(importText)) {
                        hasConfig = true;
                        io.ballerina.toml.syntax.tree.NodeList<KeyValueNode> fields = tableNode.fields();
                        for (KeyValueNode field: fields) {
                            String key = field.identifier().toSourceCode().trim();
                            switch (key) {
                                case "host":
                                    hasHost = true;
                                    break;
                                case "port":
                                    hasPort = true;
                                    break;
                                case "user":
                                    hasUser = true;
                                    break;
                                case "password":
                                    hasPassword = true;
                                    break;
                                case "database":
                                    hasDatabase = true;
                                    break;
                            }
                        }
                    }
                }
                if (!hasConfig) {
                    importText = getImportText(importText);
                    addCodeAction(codeActionList, documentNode, importText, configFilePathInString, codeActionTitle);
                } else {
                    if (!hasHost) {
                        addCodeAction(codeActionList, documentNode, "host = \"localhost\"\n",
                                configFilePathInString, "Add host config to Config.toml");
                    }
                    if (!hasPort) {
                        addCodeAction(codeActionList, documentNode, "port = 3306\n",
                                configFilePathInString, "Add port config to Config.toml");
                    }
                    if (!hasUser) {
                        addCodeAction(codeActionList, documentNode, "user = \"root\"\n",
                                configFilePathInString, "Add user config to Config.toml");
                    }
                    if (!hasPassword) {
                        addCodeAction(codeActionList, documentNode, "password = \"\"\n",
                                configFilePathInString, "Add password config to Config.toml");
                    }
                    if (!hasDatabase) {
                        addCodeAction(codeActionList, documentNode, "database = \"\"\n",
                                configFilePathInString, "Add database config to Config.toml");
                    }
                }
            }
        } catch (IOException e) {
            LSClientLogger clientLogger = LSClientLogger.getInstance(codeActionContext.languageServercontext());
            String msg = "Operation 'configFile/reading' failed!";
            Position position = new Position(typeDefinitionNode.position(), 0);
            clientLogger.logError(LSContextOperations.FILE_CREATION, msg, e,
                    new TextDocumentIdentifier(codeActionContext.filePath().toString()), position);
        }
        return codeActionList;
    }

    @Override
    public List<SyntaxKind> getSyntaxKinds() {
        return Collections.singletonList(SyntaxKind.RECORD_TYPE_DESC);
    }

    @Override
    public String getName() {
        return "Add Configs To persist CodeAction";
    }

    private boolean hasEntityAnnotation(TypeDefinitionNode typeDefinitionNode) {
        Optional<MetadataNode> metadata = typeDefinitionNode.metadata();
        if (metadata.isPresent()) {
            for (AnnotationNode annotation : metadata.get().annotations()) {
                String ENTITY = "persist:Entity";
                if (annotation.annotReference().toSourceCode().trim().equals(ENTITY)) {
                    return true;
                }
            }
        }
        Node recordNode = typeDefinitionNode.typeDescriptor();
        RecordTypeDescriptorNode recordTypeDescriptorNode = (RecordTypeDescriptorNode) recordNode;
        NodeList<Node> fields = recordTypeDescriptorNode.fields();
        for (Node field : fields) {
            if (field instanceof RecordFieldNode) {
                RecordFieldNode fieldNode = (RecordFieldNode) field;
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                if (metadataNode.isPresent()) {
                   return hasPersistAnnotation(metadataNode.get());
                }
            } else if (field instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode fieldNode = (RecordFieldWithDefaultValueNode) field;
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                if (metadataNode.isPresent()) {
                    return hasPersistAnnotation(metadataNode.get());
                }
            }
        }
        return false;
    }

    private boolean hasPersistAnnotation(MetadataNode metadataNode) {
        String AUTO_INCREMENT = "persist:AutoIncrement";
        String RELATION = "persist:Relation";
        NodeList<AnnotationNode> annotations = metadataNode.annotations();
        for (AnnotationNode annotation : annotations) {
            String annotationName = annotation.annotReference().toSourceCode().trim();
            if (annotationName.equals(AUTO_INCREMENT)) {
                return true;
            }
            if (annotationName.equals(RELATION)) {
                return true;
            }
        }
        return false;
    }

    private void addCodeAction(List<CodeAction> codeActionList, DocumentNode documentNode, String importText,
                               String configFilePath, String codeActionTitle) {
        io.ballerina.toml.syntax.tree.NodeList<DocumentMemberDeclarationNode> members = documentNode.members();
        int size = members.size();
        org.eclipse.lsp4j.Position position;
        if (size > 0) {
            int endLine = members.get(size- 1).lineRange().endLine().line() + 1;
            position = new org.eclipse.lsp4j.Position(endLine, 0);
        } else {
            position = new org.eclipse.lsp4j.Position(1, 0);
        }

        List<TextEdit> edits = Collections.singletonList(new TextEdit(new Range(position, position), importText));
        CodeAction action = createQuickFixCodeAction(edits, configFilePath, codeActionTitle);
        codeActionList.add(action);
    }

    private CodeAction createQuickFixCodeAction(List<TextEdit> edits, String uri, String codeActionTitle) {
        CodeAction action = new CodeAction(codeActionTitle);
        action.setKind(CodeActionKind.QuickFix);
        action.setEdit(new WorkspaceEdit(Collections.singletonList(Either.forLeft(
                new TextDocumentEdit(new VersionedTextDocumentIdentifier(uri, null), edits)))));
        action.setDiagnostics(new ArrayList<>());
        return action;
    }

    private String getImportText(String importText) {
        return  "[" + importText + "]\nhost = \"localhost\"\nport = 3306\nuser = \"root\"\n" +
                "password = \"\"\ndatabase = \"\"\n";
    }
}
