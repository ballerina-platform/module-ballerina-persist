/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.persist.compiler.utils;

import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.stdlib.persist.compiler.Constants;
import io.ballerina.stdlib.persist.compiler.model.Entity;
import io.ballerina.tools.diagnostics.DiagnosticProperty;

import java.text.MessageFormat;
import java.util.List;

import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTimeTypes.CIVIL;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTimeTypes.DATE;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTimeTypes.TIME_OF_DAY;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTimeTypes.UTC;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.BOOLEAN;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.BYTE;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.DECIMAL;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.ENUM;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.FLOAT;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.INT;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.STRING;
import static io.ballerina.stdlib.persist.compiler.Constants.TIME_MODULE;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_305;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_306;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_308;

/**
 * Class containing util functions.
 */
public final class ValidatorsByDatastore {

    private ValidatorsByDatastore() {
    }

    public static boolean validateSimpleTypes(Entity entity, Node typeNode, String typeNamePostfix,
                                              boolean isArrayType, boolean isOptionalType,
                                              List<DiagnosticProperty<?>> properties, String type, String datastore) {
        boolean validFlag = true;

        if (isOptionalType && (Constants.Datastores.GOOGLE_SHEETS.equals(datastore)
                || Constants.Datastores.REDIS.equals(datastore))) {
            entity.reportDiagnostic(PERSIST_308.getCode(),
                    MessageFormat.format(PERSIST_308.getMessage(), type),
                    PERSIST_308.getSeverity(), typeNode.location(), properties);
            validFlag = false;
        }

        if (isArrayType) {
            if (!isValidArrayType(type, datastore)) {
                if (isValidSimpleType(type, datastore)) {
                    entity.reportDiagnostic(PERSIST_306.getCode(),
                            MessageFormat.format(PERSIST_306.getMessage(), type),
                            PERSIST_306.getSeverity(), typeNode.location(), properties);
                } else {
                    entity.reportDiagnostic(PERSIST_306.getCode(),
                            MessageFormat.format(PERSIST_306.getMessage(), type),
                            PERSIST_306.getSeverity(), typeNode.location());
                }
                validFlag = false;
            }
        } else {
            if (!isValidSimpleType(type, datastore)) {
                entity.reportDiagnostic(PERSIST_305.getCode(), MessageFormat.format(PERSIST_305.getMessage(),
                                type + typeNamePostfix), PERSIST_305.getSeverity(),
                        typeNode.location());
                validFlag = false;
            }
        }
        return validFlag;
    }

    public static boolean validateImportedTypes(Entity entity, Node typeNode,
                                                boolean isArrayType, boolean isOptionalType,
                                                List<DiagnosticProperty<?>> properties,
                                                String modulePrefix, String identifier, String datastore) {
        boolean validFlag = true;

        if (isOptionalType && datastore.equals(Constants.Datastores.REDIS)) {
            entity.reportDiagnostic(PERSIST_308.getCode(),
                    MessageFormat.format(PERSIST_308.getMessage(), modulePrefix + ":" + identifier),
                    PERSIST_308.getSeverity(), typeNode.location(), properties);
            validFlag = false;
        }

        if (ValidatorsByDatastore.isValidImportedType(modulePrefix, identifier, datastore)) {
            if (isArrayType && !ValidatorsByDatastore.isValidArrayType(modulePrefix + ":" + identifier,
            datastore)) {

                entity.reportDiagnostic(PERSIST_306.getCode(),
                        MessageFormat.format(PERSIST_306.getMessage(), modulePrefix + ":" + identifier),
                        PERSIST_306.getSeverity(), typeNode.location(),
                        properties);
            } else {
                validFlag = true;
            }
        } else {
            if (isArrayType) {
                entity.reportDiagnostic(PERSIST_306.getCode(), MessageFormat.format(PERSIST_306.getMessage(),
                                modulePrefix + ":" + identifier), PERSIST_305.getSeverity(),
                        typeNode.location());
            } else {
                entity.reportDiagnostic(PERSIST_305.getCode(), MessageFormat.format(PERSIST_305.getMessage(),
                                modulePrefix + ":" + identifier), PERSIST_305.getSeverity(),
                        typeNode.location());
            }
        }

        return validFlag;
    }

    public static boolean isValidSimpleType(String type, String datastore) {
        // If the datastore is null(ex: before executing the generate command), ignore the data type validation.
        if (null == datastore) {
            return true;
        }
        return switch (datastore) {
            case Constants.Datastores.MYSQL -> isValidMysqlType(type);
            case Constants.Datastores.MSSQL -> isValidMssqlType(type);
            case Constants.Datastores.POSTGRESQL -> isValidPostgresqlType(type);
            case Constants.Datastores.H2 -> isValidH2Type(type);
            case Constants.Datastores.IN_MEMORY -> isValidInMemoryType(type);
            case Constants.Datastores.GOOGLE_SHEETS -> isValidGoogleSheetsType(type);
            case Constants.Datastores.REDIS -> isValidRedisType(type);
            default -> false;
        };
    }

    public static boolean isValidArrayType(String type, String datastore) {
        // If the datastore is null(ex: before executing the generate command), ignore the data type validation.
        if (null == datastore) {
            return true;
        }
        return switch (datastore) {
            case Constants.Datastores.MYSQL -> isValidMysqlArrayType(type);
            case Constants.Datastores.MSSQL -> isValidMssqlArrayType(type);
            case Constants.Datastores.POSTGRESQL -> isValidPostgresqlArrayType(type);
            case Constants.Datastores.H2 -> isValidH2ArrayType(type);
            case Constants.Datastores.IN_MEMORY -> isValidInMemoryArrayType(type);
            case Constants.Datastores.GOOGLE_SHEETS -> isValidGoogleSheetsArrayType(type);
            case Constants.Datastores.REDIS -> isValidRedisArrayType(type);
            default -> false;
        };
    }

    public static boolean isValidImportedType(String modulePrefix, String identifier, String datastore) {
        // If the datastore is null(ex: before executing the generate command), ignore the data type validation.
        if (null == datastore) {
            return true;
        }
        return switch (datastore) {
            case Constants.Datastores.MYSQL -> isValidMysqlImportedType(modulePrefix, identifier);
            case Constants.Datastores.MSSQL -> isValidMssqlImportedType(modulePrefix, identifier);
            case Constants.Datastores.POSTGRESQL -> isValidPostgresqlImportedType(modulePrefix, identifier);
            case Constants.Datastores.H2 -> isValidH2ImportedType(modulePrefix, identifier);
            case Constants.Datastores.IN_MEMORY -> isValidInMemoryImportedType(modulePrefix, identifier);
            case Constants.Datastores.GOOGLE_SHEETS -> isValidGoogleSheetsImportedType(modulePrefix, identifier);
            case Constants.Datastores.REDIS -> isValidRedisImportedType(modulePrefix, identifier);
            default -> false;
        };
    }

    public static boolean isValidMysqlType(String type) {
        switch (type) {
            case INT:
            case BOOLEAN:
            case DECIMAL:
            case FLOAT:
            case STRING:
            case ENUM:
                return true;
            default:
                return false;
        }
    }

    public static boolean isValidMssqlType(String type) {
        switch (type) {
            case INT:
            case BOOLEAN:
            case DECIMAL:
            case FLOAT:
            case STRING:
            case ENUM:
                return true;
            default:
                return false;
        }
    }

    public static boolean isValidPostgresqlType(String type) {
        switch (type) {
            case INT:
            case BOOLEAN:
            case DECIMAL:
            case FLOAT:
            case STRING:
            case ENUM:
                return true;
            default:
                return false;
        }
    }

    private static boolean isValidH2Type(String type) {
        return switch (type) {
            case INT, BOOLEAN, DECIMAL, FLOAT, STRING, ENUM -> true;
            default -> false;
        };
    }

    public static boolean isValidInMemoryType(String type) {
        return true;
    }

    public static boolean isValidGoogleSheetsType(String type) {
        switch (type) {
            case INT:
            case BOOLEAN:
            case DECIMAL:
            case FLOAT:
            case STRING:
            case ENUM:
                return true;
            default:
                return false;
        }
    }

    public static boolean isValidRedisType(String type) {
        switch (type) {
            case INT:
            case BOOLEAN:
            case DECIMAL:
            case FLOAT:
            case STRING:
            case ENUM:
                return true;
            default:
                return false;
        }
    }

    public static boolean isValidMysqlArrayType(String type) {
        switch (type) {
            case BYTE:
                return true;
            default:
                return false;
        }
    }

    public static boolean isValidMssqlArrayType(String type) {
        switch (type) {
            case BYTE:
                return true;
            default:
                return false;
        }
    }

    public static boolean isValidPostgresqlArrayType(String type) {
        switch (type) {
            case BYTE:
                return true;
            default:
                return false;
        }
    }

    private static boolean isValidH2ArrayType(String type) {
        return type.equals(BYTE);
    }

    public static boolean isValidInMemoryArrayType(String type) {
       return true;
    }

    public static boolean isValidGoogleSheetsArrayType(String type) {
        return false;
    }

    public static boolean isValidRedisArrayType(String type) {
        return false;
    }

    public static boolean isValidMysqlImportedType(String modulePrefix, String identifier) {
        if (!modulePrefix.equals(TIME_MODULE)) {
            return false;
        }
        switch (identifier) {
            case DATE:
            case TIME_OF_DAY:
            case UTC:
            case CIVIL:
                return true;
            default:
                return false;
        }
    }

    public static boolean isValidMssqlImportedType(String modulePrefix, String identifier) {
        if (!modulePrefix.equals(TIME_MODULE)) {
            return false;
        }
        switch (identifier) {
            case DATE:
            case TIME_OF_DAY:
            case UTC:
            case CIVIL:
                return true;
            default:
                return false;
        }
    }

    public static boolean isValidPostgresqlImportedType(String modulePrefix, String identifier) {
        if (!modulePrefix.equals(TIME_MODULE)) {
            return false;
        }
        switch (identifier) {
            case DATE:
            case TIME_OF_DAY:
            case UTC:
            case CIVIL:
                return true;
            default:
                return false;
        }
    }

    private static boolean isValidH2ImportedType(String modulePrefix, String identifier) {
        if (!modulePrefix.equals(TIME_MODULE)) {
            return false;
        }
        return switch (identifier) {
            case DATE, TIME_OF_DAY, UTC, CIVIL -> true;
            default -> false;
        };
    }

    public static boolean isValidInMemoryImportedType(String modulePrefix, String identifier) {
        return true;
    }

    public static boolean isValidGoogleSheetsImportedType(String modulePrefix, String identifier) {
        if (!modulePrefix.equals(TIME_MODULE)) {
            return false;
        }
        switch (identifier) {
            case DATE:
            case TIME_OF_DAY:
            case UTC:
            case CIVIL:
                return true;
            default:
                return false;
        }
    }

    public static boolean isValidRedisImportedType(String modulePrefix, String identifier) {
        if (!modulePrefix.equals(TIME_MODULE)) {
            return false;
        }
        switch (identifier) {
            case DATE:
            case TIME_OF_DAY:
            case CIVIL:
            case UTC:
                return true;
            default:
                return false;
        }
    }

}
