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

import io.ballerina.projects.plugins.codeaction.CodeActionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_308;
import static io.ballerina.stdlib.persist.compiler.codeaction.PersistCodeActionName.CHANGE_TYPE_TO_NOT_NILLABLE;

/**
 * Change type to not nillable code action.
 */
public class ChangeTypeNotNillable extends AbstractChangeToSupportedType {

    String type = null;

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
        if (type != null && type.endsWith("?")) {
            return type.substring(0, type.length() - 1);
        }
        return type;
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext codeActionContext) {
        this.type = codeActionContext.diagnostic().properties().get(2).value().toString();
        return super.codeActionInfo(codeActionContext);
    }
}

