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
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * PersistRecordAnalyzer.
 */
public class PersistRecordValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    private final List<String> primaryKeys;
    private final List<List<String>> uniqueConstraints;
    private boolean hasPersistAnnotation;
    private boolean hasAutoIncrementAnnotation;
    private boolean isPersistEntity;
    private String tableName;
    private int noOfReportDiagnostic;
    private final List<String> recordNamesOfForeignKey;
    private final HashMap<String, List<String>> referenceTables;

    public PersistRecordValidator() {
        primaryKeys = new ArrayList<>();
        uniqueConstraints = new ArrayList<>();
        recordNamesOfForeignKey = new ArrayList<>();
        hasPersistAnnotation = false;
        hasAutoIncrementAnnotation = false;
        isPersistEntity = false;
        tableName = "";
        noOfReportDiagnostic = 0;
        referenceTables = new HashMap<>();
    }

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
        NodeList<ModuleMemberDeclarationNode> memberNodes = ((ModulePartNode) ctx.syntaxTree().rootNode()).members();
        if (recordNode instanceof RecordTypeDescriptorNode) {
            Optional<Symbol> symbol = ctx.semanticModel().symbol(typeDefinitionNode);
            if (symbol.isPresent()) {
                TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) symbol.get();
                RecordTypeSymbol recordTypeSymbol = (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor();
                validateEntityAnnotation(ctx, typeDefinitionNode, recordTypeSymbol);
                validateRecordFieldsAnnotation(ctx, recordNode,
                        ((ModulePartNode) ctx.syntaxTree().rootNode()).members());
                validateRecordField(ctx, typeDefinitionNode, recordTypeSymbol, memberNodes);
                if ((hasPersistAnnotation || isPersistEntity)) {
                    validateRecordType(ctx, typeDefinitionNode);
                    if (this.noOfReportDiagnostic == 0) {
                        PersistGenerateSqlScript.generateSqlScript((RecordTypeDescriptorNode) recordNode,
                                typeDefinitionNode, tableName, memberNodes, this.primaryKeys,
                                this.uniqueConstraints, ctx, referenceTables);
                    }
                }
            }
        }
        this.hasAutoIncrementAnnotation = false;
        this.hasPersistAnnotation = false;
        this.primaryKeys.clear();
        this.uniqueConstraints.clear();
        this.tableName = "";
        this.isPersistEntity = false;
    }

    private void validateRecordType(SyntaxNodeAnalysisContext ctx, TypeDefinitionNode typeDefinitionNode) {
        if (typeDefinitionNode.visibilityQualifier().isEmpty()) {
            reportDiagnosticInfo(ctx, typeDefinitionNode.location(), DiagnosticsCodes.PERSIST_111.getCode(),
                    DiagnosticsCodes.PERSIST_111.getMessage(), DiagnosticsCodes.PERSIST_111.getSeverity());
        }
    }

    private void validateRecordField(SyntaxNodeAnalysisContext ctx, TypeDefinitionNode typeDefinitionNode,
                                     RecordTypeSymbol recordTypeSymbol,
                                     NodeList<ModuleMemberDeclarationNode> memberNodes) {
        String recordName = typeDefinitionNode.typeName().toSourceCode().trim();
        if (this.recordNamesOfForeignKey.contains(recordName)) {
            isPersistEntity = true;
            validateRecordFieldType(ctx, recordTypeSymbol.fieldDescriptors());
        } else if (hasPersistAnnotation) {
            validateRecordFieldType(ctx, recordTypeSymbol.fieldDescriptors());
        } else {
            for (ModuleMemberDeclarationNode memberNode : memberNodes) {
                if (memberNode instanceof ClassDefinitionNode) {
                    NodeList<Node> members = ((ClassDefinitionNode) memberNode).members();
                    for (Node member : members) {
                        if (member instanceof FunctionDefinitionNode) {
                            processFunctionDefinitionNode(ctx, member, recordName, recordTypeSymbol);
                        }
                    }
                } else if (memberNode instanceof FunctionDefinitionNode) {
                    processFunctionDefinitionNode(ctx, memberNode, recordName, recordTypeSymbol);
                }
            }
        }
    }

    private void processFunctionDefinitionNode(SyntaxNodeAnalysisContext ctx, Node member,
                                               String recordName,
                                               RecordTypeSymbol recordTypeSymbol) {
        FunctionDefinitionNode functionDefinitionNode = ((FunctionDefinitionNode) member);
        FunctionSignatureNode functionSignatureNode = functionDefinitionNode.functionSignature();
        SeparatedNodeList<ParameterNode> parameters = functionSignatureNode.parameters();
        if ((functionDefinitionNode.functionBody().toSourceCode().
                contains(Constants.INSERT_METHOD_NAME) && parameters.size() > 0 &&
                parameters.get(0).toSourceCode().split(" ")[0].trim().equals(recordName))) {
            isPersistEntity = true;
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
                            if (typeSymbol instanceof TypeReferenceTypeSymbol) {
                                Optional<String> referenceTypeSymbol =
                                        ((TypeReferenceTypeSymbol) (referenceType.get())).definition().getName();
                                if (referenceTypeSymbol.isPresent() && referenceTypeSymbol.get().equals(recordName)) {
                                    isPersistEntity = true;
                                    validateRecordFieldType(ctx, recordTypeSymbol.fieldDescriptors());
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private void validateRecordFieldsAnnotation(SyntaxNodeAnalysisContext ctx, Node recordNode,
                                                NodeList<ModuleMemberDeclarationNode> memberNodes) {
        RecordTypeDescriptorNode recordTypeDescriptorNode = (RecordTypeDescriptorNode) recordNode;
        NodeList<Node> fields = recordTypeDescriptorNode.fields();
        for (Node field : fields) {
            if (field instanceof RecordFieldNode) {
                RecordFieldNode fieldNode = (RecordFieldNode) field;
                if (primaryKeys.contains(fieldNode.fieldName().text().trim())) {
                    validateReadOnly(ctx, fieldNode.readonlyKeyword().isPresent(), fieldNode.location());
                }
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                metadataNode.ifPresent(node -> validateAnnotation(ctx, node, fieldNode.typeName().toSourceCode().trim(),
                        fieldNode.location(), memberNodes, fieldNode.fieldName().text().trim()));
            } else if (field instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode fieldNode = (RecordFieldWithDefaultValueNode) field;
                if (primaryKeys.contains(fieldNode.fieldName().text().trim())) {
                    validateReadOnly(ctx, fieldNode.readonlyKeyword().isPresent(), fieldNode.location());
                }
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                metadataNode.ifPresent(node -> validateAnnotation(ctx, node, fieldNode.typeName().toSourceCode().trim(),
                        fieldNode.location(), memberNodes, fieldNode.fieldName().text().trim()));
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
                                    Location location, NodeList<ModuleMemberDeclarationNode> memberNodes,
                                    String fieldName) {
        NodeList<AnnotationNode> annotations = metadataNode.annotations();
        for (AnnotationNode annotation : annotations) {
            String annotationName = annotation.annotReference().toSourceCode().trim();
            Optional<MappingConstructorExpressionNode> mappingConstructorExpressionNode = annotation.annotValue();
            if (annotationName.equals(Constants.AUTO_INCREMENT)) {
                if (this.hasAutoIncrementAnnotation) {
                    reportDiagnosticInfo(ctx, location, DiagnosticsCodes.PERSIST_107.getCode(),
                            DiagnosticsCodes.PERSIST_107.getMessage(), DiagnosticsCodes.PERSIST_107.getSeverity());
                }
                checkAutoIncrementFieldMarkAsKey(ctx, location, fieldName);
            }
            if (mappingConstructorExpressionNode.isPresent()) {
                SeparatedNodeList<MappingFieldNode> annotationFields = mappingConstructorExpressionNode.get().fields();
                if (annotationName.equals(Constants.AUTO_INCREMENT)) {
                    this.hasPersistAnnotation = true;
                    if (!filedType.trim().equals("int")) {
                        reportDiagnosticInfo(ctx, location, DiagnosticsCodes.PERSIST_105.getCode(),
                                DiagnosticsCodes.PERSIST_105.getMessage(), DiagnosticsCodes.PERSIST_105.getSeverity());
                    }
                    if (annotationFields.size() > 0) {
                        validateAutoIncrementAnnotation(ctx, annotationFields);
                    }
                    this.hasAutoIncrementAnnotation = true;
                }
                if (annotation.annotReference().toSourceCode().trim().equals(Constants.RELATION)) {
                    this.recordNamesOfForeignKey.add(filedType);
                    this.hasPersistAnnotation = true;
                    validateRelationAnnotation(ctx, annotationFields,  memberNodes, filedType);
                }
            }
        }
    }

    private void checkAutoIncrementFieldMarkAsKey(SyntaxNodeAnalysisContext ctx, Location location, String fieldName) {
        if (!primaryKeys.contains(fieldName)) {
            boolean hasKey = false;
            for (List<String> list : this.uniqueConstraints) {
                if (list.contains(fieldName)) {
                    hasKey = true;
                    break;
                }
            }
            if (!hasKey) {
                reportDiagnosticInfo(ctx, location, DiagnosticsCodes.PERSIST_108.getCode(),
                        DiagnosticsCodes.PERSIST_108.getMessage(), DiagnosticsCodes.PERSIST_108.getSeverity());
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
                    this.hasPersistAnnotation = true;
                    Optional<MappingConstructorExpressionNode> mappingConstructorExpressionNode =
                            annotation.annotValue();
                    if (mappingConstructorExpressionNode.isPresent()) {
                        SeparatedNodeList<MappingFieldNode> fields = mappingConstructorExpressionNode.get().fields();
                        for (MappingFieldNode mappingFieldNode : fields) {
                            SpecificFieldNode fieldNode = (SpecificFieldNode) mappingFieldNode;
                            String name = fieldNode.fieldName().toSourceCode().trim().
                                    replaceAll(Constants.UNNECESSARY_CHARS_REGEX, "");
                            Optional<ExpressionNode> expressionNode = fieldNode.valueExpr();
                            if (expressionNode.isPresent()) {
                                if (!name.equals(Constants.TABLE_NAME)) {
                                    validateEntityProperties(ctx, expressionNode.get(), tableFields);
                                } else {
                                    tableName = Utils.eliminateDoubleQuotes(expressionNode.get().toSourceCode().trim());
                                }
                            }
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
                    this.primaryKeys.add(Utils.eliminateDoubleQuotes(expression.toSourceCode().trim()));
                    validateFieldWithFieldRecord(ctx, expression, tableFields);
                } else {
                    listConstructorExpressionNode = (ListConstructorExpressionNode) expression;
                    SeparatedNodeList<Node> exps = listConstructorExpressionNode.expressions();
                    List<String> uniqueConstraint = new ArrayList<>();
                    for (Node exp : exps) {
                        if (exp instanceof BasicLiteralNode) {
                            uniqueConstraint.add(Utils.eliminateDoubleQuotes(exp.toSourceCode().trim()));
                            validateFieldWithFieldRecord(ctx, exp, tableFields);
                        }
                    }
                    this.uniqueConstraints.add(uniqueConstraint);
                }
            }
        }
    }

    private void validateFieldWithFieldRecord(SyntaxNodeAnalysisContext ctx, Node valueNode,
                                              Set<String> recordFields) {
        if (!recordFields.contains(Utils.eliminateDoubleQuotes(((BasicLiteralNode) valueNode).literalToken().text()))) {
            reportDiagnosticInfo(ctx, valueNode.location(),
                    DiagnosticsCodes.PERSIST_102.getCode(), DiagnosticsCodes.PERSIST_102.getMessage(),
                    DiagnosticsCodes.PERSIST_102.getSeverity());
        }
    }

    private void validateAutoIncrementAnnotation(SyntaxNodeAnalysisContext ctx,
                                                 SeparatedNodeList<MappingFieldNode> annotationFields) {
        for (MappingFieldNode annotationField: annotationFields) {
            SpecificFieldNode annotationFieldNode = (SpecificFieldNode) annotationField;
            String key = annotationFieldNode.fieldName().toSourceCode().trim().replaceAll(
                    Constants.UNNECESSARY_CHARS_REGEX, "");
            Optional<ExpressionNode> expressionNode = annotationFieldNode.valueExpr();
            if (expressionNode.isPresent()) {
                ExpressionNode valueNode = expressionNode.get();
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
    }

    private boolean isIntType(RecordFieldSymbol recordFieldSymbol) {
        return recordFieldSymbol.typeDescriptor().typeKind() == TypeDescKind.INT_UNSIGNED8 ||
                recordFieldSymbol.typeDescriptor().typeKind() == TypeDescKind.INT_UNSIGNED16 ||
                recordFieldSymbol.typeDescriptor().typeKind() == TypeDescKind.INT_UNSIGNED32 ||
                recordFieldSymbol.typeDescriptor().typeKind() == TypeDescKind.INT;
    }

    private void validateRelationAnnotation(SyntaxNodeAnalysisContext ctx,
                                            SeparatedNodeList<MappingFieldNode> annotationFields,
                                            NodeList<ModuleMemberDeclarationNode> memberNodes, String filedType) {
        int noOfForeignKeys = 0;
        int noOfReferences = 0;
        Location location = null;
        for (MappingFieldNode annotationField: annotationFields) {
            SpecificFieldNode annotationFieldNode = (SpecificFieldNode) annotationField;
            String key = annotationFieldNode.fieldName().toSourceCode().trim().replaceAll(
                    Constants.UNNECESSARY_CHARS_REGEX, "");
            if (key.equals(Constants.KEY) || key.equals(Constants.REFERENCE)) {
                Optional<ExpressionNode> expressionNode = annotationFieldNode.valueExpr();
                if (expressionNode.isPresent()) {
                    ExpressionNode valueNode = expressionNode.get();
                    ListConstructorExpressionNode listConstructorExpressionNode =
                            (ListConstructorExpressionNode) valueNode;
                    SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();
                    if (key.equals(Constants.KEY)) {
                        noOfForeignKeys = expressions.size();
                        location = valueNode.location();
                    } else {
                        for (Node expression : expressions) {
                            noOfReferences = expressions.size();
                            location = valueNode.location();
                            validateRelationAnnotationReference(ctx, memberNodes, filedType,
                                    ((BasicLiteralNode) expression).literalToken().text().trim(), valueNode);
                        }
                    }
                }
            }
        }
        // todo If foreign keys or references have one value and one of these is missing in the config,
        //  the missing key has to be inferred from that entity.
        // todo if foreign keys or references miss, both keys have to be inferred from those entity.
        if ((noOfForeignKeys > 1 || noOfReferences > 1) && (noOfForeignKeys != noOfReferences)) {
            reportDiagnosticInfo(ctx, location, DiagnosticsCodes.PERSIST_109.getCode(),
                    DiagnosticsCodes.PERSIST_109.getMessage(),
                    DiagnosticsCodes.PERSIST_109.getSeverity());
        }
    }

    private void validateRelationAnnotationReference(SyntaxNodeAnalysisContext ctx,
                                                     NodeList<ModuleMemberDeclarationNode> memberNodes,
                                                     String filedType, String value, ExpressionNode valueNode) {
        for (ModuleMemberDeclarationNode memberNode : memberNodes) {
            if (memberNode instanceof TypeDefinitionNode) {
                Optional<Symbol> symbol = ctx.semanticModel().symbol(memberNode);
                if (symbol.isPresent()) {
                    Symbol memberNodeSymbol = symbol.get();
                    Optional<String> name = memberNodeSymbol.getName();
                    if (name.isPresent() && name.get().trim().equals(filedType)) {
                        TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) memberNodeSymbol;
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

    public void reportDiagnosticInfo(SyntaxNodeAnalysisContext ctx, Location location, String code, String message,
                                     DiagnosticSeverity diagnosticSeverity) {
        Utils.reportDiagnostic(ctx, location, code, message, diagnosticSeverity);
        this.noOfReportDiagnostic++;
    }
}
