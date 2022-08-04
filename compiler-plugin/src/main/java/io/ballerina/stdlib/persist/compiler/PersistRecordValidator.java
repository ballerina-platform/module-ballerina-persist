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

import io.ballerina.compiler.api.symbols.ModuleSymbol;
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
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.MethodCallExpressionNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.RecordFieldNode;
import io.ballerina.compiler.syntax.tree.RecordFieldWithDefaultValueNode;
import io.ballerina.compiler.syntax.tree.RecordTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * PersistRecordAnalyzer.
 */
public class PersistRecordValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {
        List<Diagnostic> diagnostics = ctx.semanticModel().diagnostics();
        for (Diagnostic diagnostic : diagnostics) {
            if (diagnostic.diagnosticInfo().severity() == DiagnosticSeverity.ERROR) {
                return;
            }
        }

        MethodCallExpressionNode methodCallExpNode = (MethodCallExpressionNode) ctx.node();
        // Get the object type to validate arguments
        ExpressionNode methodExpression = methodCallExpNode.expression();
        Optional<TypeSymbol> methodExpReferenceType = ctx.semanticModel().typeOf(methodExpression);
        if (methodExpReferenceType.isEmpty()) {
            return;
        }
        if (methodExpReferenceType.get().typeKind() != TypeDescKind.TYPE_REFERENCE) {
            return;
        }
        TypeReferenceTypeSymbol methodExpTypeSymbol = (TypeReferenceTypeSymbol) methodExpReferenceType.get();
        Optional<ModuleSymbol> optionalModuleSymbol = methodExpTypeSymbol.getModule();
        if (optionalModuleSymbol.isEmpty()) {
            return;
        }
        ModuleSymbol module = optionalModuleSymbol.get();
        if (!(module.id().orgName().equals(Constants.BALLERINA) &&
                module.id().moduleName().equals(Constants.PERSIST))) {
            return;
        }

        Optional<Symbol> methodSymbol = ctx.semanticModel().symbol(methodCallExpNode.methodName());
        if (methodSymbol.isEmpty()) {
            return;
        }
        Optional<String> methodName = methodSymbol.get().getName();
        if (methodName.isEmpty()) {
            return;
        }
        if (!methodName.get().equals(Constants.METHOD_NAME)) {
            return;
        }
        Node argumentNode = methodCallExpNode.arguments().get(0);
        TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) ((TypeReferenceTypeSymbol) ctx.
                semanticModel().typeOf(argumentNode).get()).definition();
        RecordTypeSymbol recordTypeSymbol = (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor();
        NodeList<ModuleMemberDeclarationNode> memberNodes = ((ModulePartNode) ctx.syntaxTree().rootNode()).members();
        for (ModuleMemberDeclarationNode memberNode : memberNodes) {
            if (memberNode instanceof TypeDefinitionNode) {
                TypeDefinitionNode typeDefinitionNode = ((TypeDefinitionNode) memberNode);
                Node recordNode = typeDefinitionNode.typeDescriptor();
                if (recordNode instanceof RecordTypeDescriptorNode &&
                        typeDefinitionNode.typeName().text().equals(typeDefinitionSymbol.getName().get())) {
                    validateEntityAnnotation(ctx, typeDefinitionNode, recordTypeSymbol);
                    validateRecordFieldsAnnotation(ctx, recordNode, recordTypeSymbol.fieldDescriptors());
                    validateRecordFieldType(ctx, recordTypeSymbol.fieldDescriptors());
                }
            }
        }
    }

    private void validateRecordFieldsAnnotation(SyntaxNodeAnalysisContext ctx, Node recordNode,
                                                Map<String, RecordFieldSymbol> fieldDescriptors) {
        RecordTypeDescriptorNode recordTypeDescriptorNode = (RecordTypeDescriptorNode) recordNode;
        NodeList<Node> fields = recordTypeDescriptorNode.fields();
        for (Node field : fields) {
            if (field instanceof RecordFieldNode) {
                RecordFieldNode fieldNode = (RecordFieldNode) field;
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                metadataNode.ifPresent(node -> validateAnnotation(ctx, node, null,
                        fieldNode.typeName().toSourceCode().trim(), fieldNode.readonlyKeyword().isPresent(),
                        fieldNode.location(), fieldDescriptors));
            } else if (field instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode fieldNode = (RecordFieldWithDefaultValueNode) field;
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                metadataNode.ifPresent(node -> validateAnnotation(ctx, node,
                        fieldNode.expression().toSourceCode().trim(), fieldNode.typeName().toSourceCode().trim(),
                        fieldNode.readonlyKeyword().isPresent(), fieldNode.location(), fieldDescriptors));
            }
        }
    }

    private void validateAnnotation(SyntaxNodeAnalysisContext ctx, MetadataNode metadataNode, String filedValue,
                                    String filedType, Boolean isReadOnly, Location location,
                                    Map<String, RecordFieldSymbol> fieldDescriptors) {
        NodeList<AnnotationNode> annotations = metadataNode.annotations();
        for (AnnotationNode annotation : annotations) {
            SeparatedNodeList<MappingFieldNode> annotationFields = annotation.annotValue().get().fields();
            if (annotation.annotReference().toSourceCode().trim().equals(Constants.AUTO_INCREMENT)) {
                if (!filedType.trim().equals("int")) {
                    reportDiagnosticInfo(ctx, location, DiagnosticsCodes.PERSIST_107.getCode(),
                            DiagnosticsCodes.PERSIST_107.getMessage(), DiagnosticsCodes.PERSIST_107.getSeverity());
                } else if (filedValue != null && Integer.parseInt(filedValue) < 0) {
                    reportDiagnosticInfo(ctx, location, DiagnosticsCodes.PERSIST_106.getCode(),
                            DiagnosticsCodes.PERSIST_106.getMessage(), DiagnosticsCodes.PERSIST_106.getSeverity());
                }
                if (!isReadOnly) {
                    reportDiagnosticInfo(ctx, location, DiagnosticsCodes.PERSIST_108.getCode(),
                            DiagnosticsCodes.PERSIST_108.getMessage(), DiagnosticsCodes.PERSIST_108.getSeverity());
                }
                validateAutoIncrementAnnotation(ctx, annotationFields);
            }
            if (annotation.annotReference().toSourceCode().trim().equals(Constants.RELATION)) {
                validateRelationAnnotation(ctx, annotationFields, fieldDescriptors.keySet());
            }
        }
    }

    private void validateEntityAnnotation(SyntaxNodeAnalysisContext ctx, TypeDefinitionNode typeDefinitionNode,
                                          RecordTypeSymbol recordTypeSymbol) {
        Optional<MetadataNode> metadata = typeDefinitionNode.metadata();
        Set<String> tableFields = recordTypeSymbol.fieldDescriptors().keySet();
        if (metadata.isPresent()) {
            boolean hasEntityAnnotation = false;
            for (AnnotationNode annotation : metadata.get().annotations()) {
                if (annotation.annotReference().toSourceCode().equals(Constants.ENTITY)) {
                    hasEntityAnnotation = true;
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
            if (!hasEntityAnnotation) {
                reportDiagnosticInfo(ctx, typeDefinitionNode.location(),
                        DiagnosticsCodes.PERSIST_102.getCode(), DiagnosticsCodes.PERSIST_102.getMessage(),
                        DiagnosticsCodes.PERSIST_102.getSeverity());
            }
        } else {
            reportDiagnosticInfo(ctx, typeDefinitionNode.location(),
                    DiagnosticsCodes.PERSIST_102.getCode(), DiagnosticsCodes.PERSIST_102.getMessage(),
                    DiagnosticsCodes.PERSIST_102.getSeverity());
        }
    }

    private void validateEntityProperties(SyntaxNodeAnalysisContext ctx, Node valueNode, Set<String> tableFields) {
        if (valueNode instanceof BasicLiteralNode) {
            validateFieldWithFieldRecord(ctx, valueNode, tableFields);
        } else {
            ListConstructorExpressionNode listConstructorExpressionNode = (ListConstructorExpressionNode) valueNode;
            SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();
            if (expressions.size() == 0) {
                reportDiagnosticInfo(ctx, listConstructorExpressionNode.location(),
                        DiagnosticsCodes.PERSIST_104.getCode(), DiagnosticsCodes.PERSIST_104.getMessage(),
                        DiagnosticsCodes.PERSIST_104.getSeverity());
            } else {
                for (Node expression : expressions) {
                    if (expression instanceof BasicLiteralNode) {
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
    }

    private void validateFieldWithFieldRecord(SyntaxNodeAnalysisContext ctx, Node valueNode, Set<String> recordFields) {
        String text = ((BasicLiteralNode) valueNode).literalToken().text();
        if (!recordFields.contains(text.substring(1, text.length() - 1))) {
            reportDiagnosticInfo(ctx, valueNode.location(),
                    DiagnosticsCodes.PERSIST_103.getCode(), DiagnosticsCodes.PERSIST_103.getMessage(),
                    DiagnosticsCodes.PERSIST_103.getSeverity());
        }
    }

    private void validateAutoIncrementAnnotation(SyntaxNodeAnalysisContext ctx,
                                                 SeparatedNodeList<MappingFieldNode> annotationFields) {
        for (MappingFieldNode annotationField: annotationFields) {
            SpecificFieldNode annotationFieldNode = (SpecificFieldNode) annotationField;
            String key = annotationFieldNode.fieldName().toSourceCode().trim().replaceAll(
                    Constants.UNNECESSARY_CHARS_REGEX, "");
            ExpressionNode valueNode = annotationFieldNode.valueExpr().get();
            String value = valueNode.toSourceCode();
            if (key.equals(Constants.INCREMENT) && Integer.parseInt(value.trim()) < 1) {
                reportDiagnosticInfo(ctx, valueNode.location(),
                        DiagnosticsCodes.PERSIST_105.getCode(), DiagnosticsCodes.PERSIST_105.getMessage(),
                        DiagnosticsCodes.PERSIST_105.getSeverity());
            }
            if (key.equals(Constants.START_VALUE) && Integer.parseInt(value.trim()) < 0) {
                reportDiagnosticInfo(ctx, valueNode.location(),
                        DiagnosticsCodes.PERSIST_106.getCode(), DiagnosticsCodes.PERSIST_106.getMessage(),
                        DiagnosticsCodes.PERSIST_106.getSeverity());
            }
        }
    }

    private void validateRelationAnnotation(SyntaxNodeAnalysisContext ctx,
                                            SeparatedNodeList<MappingFieldNode> annotationFields,
                                            Set<String> recordFields) {
        for (MappingFieldNode annotationField: annotationFields) {
            SpecificFieldNode annotationFieldNode = (SpecificFieldNode) annotationField;
            String key = annotationFieldNode.fieldName().toSourceCode().trim().replaceAll(
                    Constants.UNNECESSARY_CHARS_REGEX, "");
            if (key.equals(Constants.KEY) || key.equals(Constants.REFERENCE)) {
                ExpressionNode valueNode = annotationFieldNode.valueExpr().get();
                ListConstructorExpressionNode listConstructorExpressionNode = (ListConstructorExpressionNode) valueNode;
                SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();
                if (expressions.size() == 0) {
                    reportDiagnosticInfo(ctx, listConstructorExpressionNode.location(),
                            DiagnosticsCodes.PERSIST_104.getCode(), DiagnosticsCodes.PERSIST_104.getMessage(),
                            DiagnosticsCodes.PERSIST_104.getSeverity());
                } else if (key.equals(Constants.KEY)) {
                    for (Node expression : expressions) {
                        String value = ((BasicLiteralNode) expression).literalToken().text();
                        String value1 = value.substring(1, value.length() - 1);
                        if (!recordFields.contains(value1)) {
                            reportDiagnosticInfo(ctx, valueNode.location(), DiagnosticsCodes.PERSIST_103.getCode(),
                                    DiagnosticsCodes.PERSIST_103.getMessage(),
                                    DiagnosticsCodes.PERSIST_103.getSeverity());
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

    private void reportDiagnosticInfo(SyntaxNodeAnalysisContext ctx, Location location, String code, String message,
                                      DiagnosticSeverity diagnosticSeverity) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(code, message, diagnosticSeverity);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }
}
