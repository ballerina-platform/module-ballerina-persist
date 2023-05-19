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

package io.ballerina.stdlib.persist.compiler.codeaction;

import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.stdlib.persist.compiler.BalException;
import io.ballerina.stdlib.persist.compiler.Constants;
import io.ballerina.stdlib.persist.compiler.utils.Utils;
import io.ballerina.stdlib.persist.compiler.utils.ValidatorsByDatastore;

import java.text.MessageFormat;
import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_308;
import static io.ballerina.stdlib.persist.compiler.codeaction.PersistCodeActionName.CHANGE_TYPE_TO_NOT_NILLABLE;

/**
 * Change type to not nillable code action.
 */
public class ChangeTypeNotNillable extends AbstractChangeToSupportedType {

    @Override
    protected String getName() {
        return CHANGE_TYPE_TO_NOT_NILLABLE.getName();
    }

    @Override
    protected List<String> getSupportedDiagnosticCodes() {
        return List.of(PERSIST_308.getCode());
    }

    @Override
    protected String getType() {
        return null;
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext codeActionContext) {
        String type = codeActionContext.diagnostic().properties().get(2).value().toString();
        if (type.endsWith("?")) {
            type = type.substring(0, type.length() - 1);
        }

        try {
            String datastore = Utils.getDatastore(codeActionContext);
            if (type.endsWith(Constants.ARRAY)) {
                String arrayType = type.substring(0, type.length() - 2);
                if (!ValidatorsByDatastore.isValidArrayType(arrayType, datastore)) {
                    return Optional.empty();
                }
            } else {
                if (!ValidatorsByDatastore.isValidSimpleType(type, datastore)) {
                    return Optional.empty();
                }
            }
        } catch (BalException e) {
            throw new RuntimeException(e);
        }

        String title = MessageFormat.format("Change to ''{0}'' type", type);
        CodeActionArgument syntaxLocationArg = CodeActionArgument.from(TYPE_CHANGE_TEXT_RANGE,
                codeActionContext.diagnostic().location().textRange());
        return Optional.of(CodeActionInfo.from(title, List.of(syntaxLocationArg)));

    }
}

