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

import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.CheckExpressionNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.ImplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.NamedArgumentNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.RecordTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.TypedBindingPatternNode;
import io.ballerina.compiler.syntax.tree.VariableDeclarationNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Sql script generator.
 */
public class PersistGenerateSqlScript {

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {
        Node node = ctx.node();
        if (node instanceof VariableDeclarationNode) {
            VariableDeclarationNode variableDeclarationNode = (VariableDeclarationNode) ctx.node();
            TypedBindingPatternNode typedBindingPatternNode = variableDeclarationNode.typedBindingPattern();
            if (typedBindingPatternNode.typeDescriptor().toSourceCode().trim().equals(Constants.PERSIST_SQL_CLIENT)) {
                Optional<ExpressionNode> optionalInitializer = variableDeclarationNode.initializer();
                if (optionalInitializer.isPresent()) {
                    ExpressionNode expressionNode = optionalInitializer.get();
                    if (expressionNode instanceof CheckExpressionNode) {
                        expressionNode = ((CheckExpressionNode) expressionNode).expression();
                    }
                    if (expressionNode instanceof ImplicitNewExpressionNode) {
                        SeparatedNodeList<FunctionArgumentNode> fields =
                                ((ImplicitNewExpressionNode) expressionNode).parenthesizedArgList().get().arguments();
                        NodeList<ModuleMemberDeclarationNode> memberNodes = ((ModulePartNode) ctx.syntaxTree().
                                rootNode()).members();
                        String sqlScript = createTableQuery(ctx, fields.get(1), memberNodes) +
                                createFieldsQuery(fields.get(2), memberNodes);
                        sqlScript = sqlScript.substring(0, sqlScript.length() - 1) + "\n);";
                        createSqFile(sqlScript);
                    }
                }
            }
        }
    }
    protected void generateSqlScript(RecordTypeDescriptorNode recordNode, RecordTypeSymbol recordTypeSymbol) {
        recordNode.fields();

    }


    private String createTableQuery(SyntaxNodeAnalysisContext ctx, FunctionArgumentNode field,
                                  NodeList<ModuleMemberDeclarationNode> memberNodes) {
        String tableName = "";
        if (field instanceof PositionalArgumentNode) {
            PositionalArgumentNode fieldNode = (PositionalArgumentNode) field;
            ExpressionNode expression = fieldNode.expression();
            Optional<Symbol> typeDefinitionSymbol = ctx.semanticModel().symbol(expression);
            if (typeDefinitionSymbol.isPresent()) {
                Symbol symbol = typeDefinitionSymbol.get();
                tableName = getTableName(symbol.getName().get().trim(), memberNodes);
            } else {
                tableName = expression.toSourceCode();

            }
        } else if (field instanceof NamedArgumentNode) {
            NamedArgumentNode fieldNode = (NamedArgumentNode) field;
            ExpressionNode expression = fieldNode.expression();
            if (expression instanceof SimpleNameReferenceNode) {
                tableName = getTableName(expression.toSourceCode().trim(), memberNodes);
            } else {
                tableName = expression.toSourceCode();
            }
        }
        tableName = tableName.substring(1, tableName.length() - 1);
        return "DROP TABLE IF EXISTS " + tableName + ";\nCREATE TABLE " + tableName + " (";
    }

    private String getTableName(String symbolName, NodeList<ModuleMemberDeclarationNode> memberNodes) {
        for (ModuleMemberDeclarationNode memberNode : memberNodes) {
            if (memberNode instanceof ModuleVariableDeclarationNode) {
                ModuleVariableDeclarationNode typeDefinitionNode = ((ModuleVariableDeclarationNode) memberNode);
                String metadataNode = typeDefinitionNode.typedBindingPattern().
                        bindingPattern().toSourceCode().trim();
                if (symbolName.equals(metadataNode)) {
                    Optional<ExpressionNode> initializer = typeDefinitionNode.
                            initializer();
                    if (initializer.isPresent()) {
                        ExpressionNode expressionNode = initializer.get();
                        return expressionNode.toSourceCode();
                    }
                }
            }
        }
        return "";
    }

    private String createFieldsQuery(FunctionArgumentNode field, NodeList<ModuleMemberDeclarationNode> memberNodes) {
        if (field instanceof NamedArgumentNode) {
            NamedArgumentNode fieldNode = (NamedArgumentNode) field;
            ExpressionNode expression = fieldNode.expression();
            if (expression instanceof SimpleNameReferenceNode) {
                SimpleNameReferenceNode simpleNameReferenceNode = (SimpleNameReferenceNode) expression;
                return getField(simpleNameReferenceNode.toSourceCode().trim(), memberNodes);
            } else {
                return constructFieldsQuery((MappingConstructorExpressionNode) expression);
            }
        } else {
            PositionalArgumentNode positionalArgumentNode = (PositionalArgumentNode) field;
            return getField(positionalArgumentNode.toSourceCode().trim(), memberNodes);
        }
    }

    private String getField(String symbolName, NodeList<ModuleMemberDeclarationNode> memberNodes) {
        for (ModuleMemberDeclarationNode memberNode : memberNodes) {
            if (memberNode instanceof ModuleVariableDeclarationNode) {
                ModuleVariableDeclarationNode typeDefinitionNode = ((ModuleVariableDeclarationNode) memberNode);
                String metadataNode = typeDefinitionNode.typedBindingPattern().
                        bindingPattern().toSourceCode().trim();
                if (symbolName.equals(metadataNode)) {
                    Optional<ExpressionNode> initializer = typeDefinitionNode.
                            initializer();
                    if (initializer.isPresent()) {
                        MappingConstructorExpressionNode expressionNode =
                                (MappingConstructorExpressionNode) initializer.get();
                        return constructFieldsQuery(expressionNode);
                    }
                }
            }
        }
        return "";
    }

    private String constructFieldsQuery(MappingConstructorExpressionNode expressionNode) {
        String sqlQuery = "";
        for (MappingFieldNode fieldNode: expressionNode.fields()) {
            SeparatedNodeList<MappingFieldNode> fieldProperties =
                    ((MappingConstructorExpressionNode) ((SpecificFieldNode) fieldNode).valueExpr().get()).fields();
            List<String> list = new ArrayList<>(3);
            for (MappingFieldNode fieldProperty : fieldProperties) {
                SpecificFieldNode property = (SpecificFieldNode) fieldProperty;
                String name = property.fieldName().toSourceCode();
                String value = property.valueExpr().get().toSourceCode();
                if (name.equals(Constants.COLUMN_NAME)) {
                    list.add(0, value.substring(1, value.length() - 1));
                } else if (name.equals(Constants.TYPE)) {
                    list.add(1, value);
                } else {
                    list.add(2, value);
                }
            }
            if (list.size() == 3) {
                sqlQuery = sqlQuery + "\n\t" + list.get(0) + " " + getType(list.get(1)) + " " +
                        getAutoIncrement(list.get(2)) + ",";
            } else {
                sqlQuery = sqlQuery + "\n\t" + list.get(0) + " " + getType(list.get(1)) + ",";
            }
        }
        return sqlQuery;
    }

    private String getType (String type) {
        switch (type) {
            case Constants.BallerinaTypes.INT:
                return Constants.SqlTypes.INT;
            case Constants.BallerinaTypes.BOOLEAN:
                return Constants.SqlTypes.BOOLEAN;
            case Constants.BallerinaTypes.DECIMAL:
                return Constants.SqlTypes.DECIMAL;
            case Constants.BallerinaTypes.FLOAT:
                return Constants.SqlTypes.FLOAT;
            default:
                return Constants.SqlTypes.VARCHAR;
        }
    }

    private String getAutoIncrement(String autoIncrement) {
        if (autoIncrement.equals(Constants.TRUE)) {
            return Constants.AUTO_INCREMENT;
        }
        return "";
    }

    private void createSqFile(String script) {
        try {
            Files.writeString(Paths.get("../", "target", "sql_script.sql").toAbsolutePath(), script);
        } catch (IOException e) {

        }
    }
}
