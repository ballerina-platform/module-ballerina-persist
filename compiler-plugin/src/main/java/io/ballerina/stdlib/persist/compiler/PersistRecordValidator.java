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

import io.ballerina.compiler.api.symbols.NilTypeSymbol;
import io.ballerina.compiler.api.symbols.RecordFieldSymbol;
import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.BasicLiteralNode;
import io.ballerina.compiler.syntax.tree.CheckExpressionNode;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionBodyBlockNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.FunctionSignatureNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.MethodCallExpressionNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.NodeLocation;
import io.ballerina.compiler.syntax.tree.ParameterNode;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.RecordFieldNode;
import io.ballerina.compiler.syntax.tree.RecordFieldWithDefaultValueNode;
import io.ballerina.compiler.syntax.tree.RecordTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.StatementNode;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.compiler.syntax.tree.VariableDeclarationNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * PersistRecordAnalyzer.
 */
public class PersistRecordValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    private final List<String> primaryKeys = new ArrayList<>();
    private boolean hasPersisAnnotation = false;

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {
        List<Diagnostic> diagnostics = ctx.semanticModel().diagnostics();
        for (Diagnostic diagnostic : diagnostics) {
            if (diagnostic.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)) {
                return;
            }
        }
        TypeDefinitionNode typeDefinitionNode =  (TypeDefinitionNode) ctx.node();
        Node recordNode = typeDefinitionNode.typeDescriptor();
        if (recordNode instanceof RecordTypeDescriptorNode) {
            TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) ctx.semanticModel().
                    symbol(typeDefinitionNode).get();
            RecordTypeSymbol recordTypeSymbol = (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor();
            validateEntityAnnotation(ctx, typeDefinitionNode, recordTypeSymbol);
            validateRecordFieldsAnnotation(ctx, recordNode, recordTypeSymbol.fieldDescriptors(),
                    ((ModulePartNode) ctx.syntaxTree().rootNode()).members());
            if (hasPersisAnnotation) {
                validateRecordFieldType(ctx, recordTypeSymbol.fieldDescriptors());
            } else {
                NodeList<ModuleMemberDeclarationNode> memberNodes = ((ModulePartNode) ctx.syntaxTree().rootNode()).
                        members();
                for (ModuleMemberDeclarationNode memberNode : memberNodes) {
                    if (memberNode instanceof ClassDefinitionNode) {
                        NodeList<Node> members = ((ClassDefinitionNode) memberNode).members();
                        for (Node member : members) {
                            if (member instanceof FunctionDefinitionNode) {
                                processFunctionDefinitionNode(ctx, member, typeDefinitionNode, recordTypeSymbol);
                            }
                        }
                    } else if (memberNode instanceof FunctionDefinitionNode) {
                        processFunctionDefinitionNode(ctx, memberNode, typeDefinitionNode, recordTypeSymbol);
                    }
                }
            }
        }
    }

    private void processFunctionDefinitionNode(SyntaxNodeAnalysisContext ctx, Node member,
                                               TypeDefinitionNode typeDefinitionNode,
                                               RecordTypeSymbol recordTypeSymbol) {
        FunctionDefinitionNode functionDefinitionNode = ((FunctionDefinitionNode) member);
        FunctionSignatureNode functionSignatureNode = functionDefinitionNode.functionSignature();
        SeparatedNodeList<ParameterNode> parameters = functionSignatureNode.parameters();
        String recordName = typeDefinitionNode.typeName().toSourceCode().trim();
        if (functionDefinitionNode.functionBody().toSourceCode().
                contains(Constants.INSERT_METHOD_NAME) && parameters.size() > 0 &&
                parameters.get(0).toSourceCode().split(" ")[0].trim().equals(recordName)) {
            validateRecordFieldType(ctx, recordTypeSymbol.fieldDescriptors());
        } else {
            NodeList<StatementNode> statements = ((FunctionBodyBlockNode) functionDefinitionNode.functionBody()).
                    statements();
            for (StatementNode statement : statements) {
                if (statement instanceof VariableDeclarationNode &&
                        statement.toSourceCode().trim().contains(Constants.INSERT_METHOD_NAME)) {
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
                        Optional<TypeSymbol> referenceType = (ctx.semanticModel().typeOf(argument));
                        if (referenceType.isPresent()) {
                            TypeSymbol typeSymbol = referenceType.get();
                            if (typeSymbol instanceof TypeReferenceTypeSymbol &&
                                    ((TypeReferenceTypeSymbol) (referenceType.get())).definition().
                                            getName().get().equals(recordName)) {
                                validateRecordFieldType(ctx, recordTypeSymbol.fieldDescriptors());
                            }
                        }
                    }
                }
            }
        }
    }

    private void validateRecordFieldsAnnotation(SyntaxNodeAnalysisContext ctx, Node recordNode,
                                                Map<String, RecordFieldSymbol> fieldDescriptors,
                                                NodeList<ModuleMemberDeclarationNode> memberNodes) {
        RecordTypeDescriptorNode recordTypeDescriptorNode = (RecordTypeDescriptorNode) recordNode;
        NodeList<Node> fields = recordTypeDescriptorNode.fields();
        for (Node field : fields) {
            if (field instanceof RecordFieldNode) {
                RecordFieldNode fieldNode = (RecordFieldNode) field;
                if (primaryKeys.contains(fieldNode.fieldName().text().trim())) {
                    validateReadOnly(ctx, fieldNode.readonlyKeyword().isPresent(), fieldNode.location());
                    primaryKeys.remove(fieldNode.fieldName().text().trim());
                }
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                metadataNode.ifPresent(node -> validateAnnotation(ctx, node, fieldNode.typeName().toSourceCode().trim(),
                        fieldNode.location(), fieldDescriptors, memberNodes));
            } else if (field instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode fieldNode = (RecordFieldWithDefaultValueNode) field;
                if (primaryKeys.contains(fieldNode.fieldName().text().trim())) {
                    validateReadOnly(ctx, fieldNode.readonlyKeyword().isPresent(), fieldNode.location());
                    primaryKeys.remove(fieldNode.fieldName().text().trim());
                }
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                metadataNode.ifPresent(node -> validateAnnotation(ctx, node, fieldNode.typeName().toSourceCode().trim(),
                        fieldNode.location(), fieldDescriptors, memberNodes));
            }
        }
    }

    private void validateReadOnly(SyntaxNodeAnalysisContext ctx, boolean isReadOnly, NodeLocation location) {
        if (!isReadOnly) {
            reportDiagnosticInfo(ctx, location, DiagnosticsCodes.PERSIST_106.getCode(),
                    DiagnosticsCodes.PERSIST_106.getMessage(), DiagnosticsCodes.PERSIST_106.getSeverity());
        }
    }

    private void validateAnnotation(SyntaxNodeAnalysisContext ctx, MetadataNode metadataNode, String filedType,
                                    Location location, Map<String, RecordFieldSymbol> fieldDescriptors,
                                    NodeList<ModuleMemberDeclarationNode> memberNodes) {
        NodeList<AnnotationNode> annotations = metadataNode.annotations();
        for (AnnotationNode annotation : annotations) {
            Optional<MappingConstructorExpressionNode> mappingConstructorExpressionNode = annotation.annotValue();
            if (mappingConstructorExpressionNode.isPresent()) {
                SeparatedNodeList<MappingFieldNode> annotationFields = mappingConstructorExpressionNode.get().fields();
                if (annotation.annotReference().toSourceCode().trim().equals(Constants.AUTO_INCREMENT)) {
                    this.hasPersisAnnotation = true;
                    if (!filedType.trim().equals("int")) {
                        reportDiagnosticInfo(ctx, location, DiagnosticsCodes.PERSIST_105.getCode(),
                                DiagnosticsCodes.PERSIST_105.getMessage(), DiagnosticsCodes.PERSIST_105.getSeverity());
                    }
                    if (annotationFields.size() > 0) {
                        validateAutoIncrementAnnotation(ctx, annotationFields);
                    }
                }
                if (annotation.annotReference().toSourceCode().trim().equals(Constants.RELATION)) {
                    this.hasPersisAnnotation = true;
                    validateRelationAnnotation(ctx, annotationFields, fieldDescriptors.keySet(), memberNodes,
                            filedType);
                }
            }
        }
    }

    private void validateEntityAnnotation(SyntaxNodeAnalysisContext ctx, TypeDefinitionNode typeDefinitionNode,
                                          RecordTypeSymbol recordTypeSymbol) {
        Optional<MetadataNode> metadata = typeDefinitionNode.metadata();
        Set<String> tableFields = recordTypeSymbol.fieldDescriptors().keySet();
        if (metadata.isPresent()) {
            for (AnnotationNode annotation : metadata.get().annotations()) {
                if (annotation.annotReference().toSourceCode().equals(Constants.ENTITY)) {
                    this.hasPersisAnnotation = true;
                    SeparatedNodeList<MappingFieldNode> fields = annotation.annotValue().get().fields();
                    for (MappingFieldNode mappingFieldNode : fields) {
                        SpecificFieldNode fieldNode = (SpecificFieldNode) mappingFieldNode;
                        String name = fieldNode.fieldName().toSourceCode().trim().
                                replaceAll(Constants.UNNECESSARY_CHARS_REGEX, "");
                        if (!name.equals(Constants.TABLE_NAME)) {
                            validateEntityProperties(ctx, fieldNode.valueExpr().get(), tableFields);
                        }
                    }
                }
            }
        }
    }

    private void validateEntityProperties(SyntaxNodeAnalysisContext ctx, Node valueNode, Set<String> tableFields) {
        if (valueNode instanceof BasicLiteralNode) {
            validateFieldWithFieldRecord(ctx, valueNode, tableFields);
        } else {
            ListConstructorExpressionNode listConstructorExpressionNode = (ListConstructorExpressionNode) valueNode;
            SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();
            for (Node expression : expressions) {
                if (expression instanceof BasicLiteralNode) {
                    this.primaryKeys.add(getValue(expression.toSourceCode().trim()));
                    validateFieldWithFieldRecord(ctx, expression, tableFields);
                } else {
                    listConstructorExpressionNode = (ListConstructorExpressionNode) expression;
                    SeparatedNodeList<Node> exps = listConstructorExpressionNode.expressions();
                    for (Node exp : exps) {
                        if (exp instanceof BasicLiteralNode) {
                            validateFieldWithFieldRecord(ctx, exp, tableFields);
                        }
                    }
                }
            }
        }
    }

    private void validateFieldWithFieldRecord(SyntaxNodeAnalysisContext ctx, Node valueNode,
                                              Set<String> recordFields) {
        if (!recordFields.contains(getValue(((BasicLiteralNode) valueNode).literalToken().text()))) {
            reportDiagnosticInfo(ctx, valueNode.location(),
                    DiagnosticsCodes.PERSIST_102.getCode(), DiagnosticsCodes.PERSIST_102.getMessage(),
                    DiagnosticsCodes.PERSIST_102.getSeverity());
        }
    }

    private String getValue(String text) {
        return text.substring(1, text.length() - 1);
    }

    private void validateAutoIncrementAnnotation(SyntaxNodeAnalysisContext ctx,
                                                 SeparatedNodeList<MappingFieldNode> annotationFields) {
        for (MappingFieldNode annotationField: annotationFields) {
            SpecificFieldNode annotationFieldNode = (SpecificFieldNode) annotationField;
            String key = annotationFieldNode.fieldName().toSourceCode().trim().replaceAll(
                    Constants.UNNECESSARY_CHARS_REGEX, "");
            ExpressionNode valueNode = annotationFieldNode.valueExpr().get();
            String value = valueNode.toSourceCode();
            if (key.equals(Constants.INCREMENT)) {
                Optional<Symbol> fieldSymbol = ctx.semanticModel().symbol(annotationFieldNode);
                if (fieldSymbol.isPresent() && fieldSymbol.get() instanceof RecordFieldSymbol) {
                    RecordFieldSymbol recordFieldSymbol = ((RecordFieldSymbol) (fieldSymbol.get()));
                    if (isIntType(recordFieldSymbol) && Integer.parseInt(value.trim()) < 1) {
                        reportDiagnosticInfo(ctx, valueNode.location(),
                                DiagnosticsCodes.PERSIST_103.getCode(), DiagnosticsCodes.PERSIST_103.getMessage(),
                                DiagnosticsCodes.PERSIST_103.getSeverity());
                    }
                }
            }
        }
    }

    private boolean isIntType(RecordFieldSymbol recordFieldSymbol) {
        return recordFieldSymbol.typeDescriptor().typeKind() == TypeDescKind.INT_UNSIGNED8 ||
                recordFieldSymbol.typeDescriptor().typeKind() == TypeDescKind.INT_UNSIGNED16 ||
                recordFieldSymbol.typeDescriptor().typeKind() == TypeDescKind.INT_UNSIGNED32 ||
                recordFieldSymbol.typeDescriptor().typeKind() == TypeDescKind.INT;
    }

    private void validateRelationAnnotation(SyntaxNodeAnalysisContext ctx,
                                            SeparatedNodeList<MappingFieldNode> annotationFields,
                                            Set<String> recordFields,
                                            NodeList<ModuleMemberDeclarationNode> memberNodes, String filedType) {
        for (MappingFieldNode annotationField: annotationFields) {
            SpecificFieldNode annotationFieldNode = (SpecificFieldNode) annotationField;
            String key = annotationFieldNode.fieldName().toSourceCode().trim().replaceAll(
                    Constants.UNNECESSARY_CHARS_REGEX, "");
            if (key.equals(Constants.KEY) || key.equals(Constants.REFERENCE)) {
                ExpressionNode valueNode = annotationFieldNode.valueExpr().get();
                ListConstructorExpressionNode listConstructorExpressionNode = (ListConstructorExpressionNode) valueNode;
                SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();
                if (key.equals(Constants.KEY)) {
                    for (Node expression : expressions) {
                        String value = ((BasicLiteralNode) expression).literalToken().text();
                        if (!recordFields.contains(value.substring(1, value.length() - 1))) {
                            reportDiagnosticInfo(ctx, valueNode.location(), DiagnosticsCodes.PERSIST_102.getCode(),
                                    DiagnosticsCodes.PERSIST_102.getMessage(),
                                    DiagnosticsCodes.PERSIST_102.getSeverity());
                        }
                    }
                } else {
                    for (Node expression : expressions) {
                        validateRelationAnnotationReference(ctx, memberNodes, filedType,
                                ((BasicLiteralNode) expression).literalToken().text().trim(), valueNode);
                    }
                }
            }
        }
    }

    private void validateRelationAnnotationReference(SyntaxNodeAnalysisContext ctx,
                                                     NodeList<ModuleMemberDeclarationNode> memberNodes,
                                                     String filedType, String value, ExpressionNode valueNode) {
        for (ModuleMemberDeclarationNode memberNode : memberNodes) {
            if (memberNode instanceof TypeDefinitionNode) {
                Symbol memberNodeSymbol = ctx.semanticModel().symbol(memberNode).get();
                if (memberNodeSymbol.getName().get().trim().equals(filedType)) {
                    TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol)  memberNodeSymbol;
                    RecordTypeSymbol recordTypeSymbol = (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor();
                    if (!recordTypeSymbol.fieldDescriptors().containsKey(value.substring(1, value.length() - 1))) {
                        reportDiagnosticInfo(ctx, valueNode.location(),
                                DiagnosticsCodes.PERSIST_102.getCode(), DiagnosticsCodes.PERSIST_102.getMessage(),
                                DiagnosticsCodes.PERSIST_102.getSeverity());
                    }
                }
            }
        }
    }

    private void validateRecordFieldType(SyntaxNodeAnalysisContext ctx,
                                         Map<String, RecordFieldSymbol> fieldDescriptors) {
        for (Map.Entry<String, RecordFieldSymbol> fieldDescriptor : fieldDescriptors.entrySet()) {
            RecordFieldSymbol recordFieldSymbol = fieldDescriptor.getValue();
            TypeSymbol fieldTypeSymbol = recordFieldSymbol.typeDescriptor();
            if (fieldTypeSymbol instanceof UnionTypeSymbol) {
                List<TypeSymbol> unionTypes = ((UnionTypeSymbol) fieldTypeSymbol).memberTypeDescriptors();
                if (!hasOptionalType(unionTypes) || unionTypes.size() > 2) {
                    reportDiagnosticInfo(ctx, recordFieldSymbol.getLocation().get(),
                            DiagnosticsCodes.PERSIST_101.getCode(), DiagnosticsCodes.PERSIST_101.getMessage(),
                            DiagnosticsCodes.PERSIST_101.getSeverity());
                }
            }
        }
    }

    private boolean hasOptionalType(List<TypeSymbol> unionTypes) {
        return (unionTypes.size() == 2 && (unionTypes.get(0) instanceof NilTypeSymbol ||
                unionTypes.get(1) instanceof NilTypeSymbol));
    }

    private void reportDiagnosticInfo(SyntaxNodeAnalysisContext ctx, Location location, String code, String message,
                                      DiagnosticSeverity diagnosticSeverity) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(code, message, diagnosticSeverity);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }
}
