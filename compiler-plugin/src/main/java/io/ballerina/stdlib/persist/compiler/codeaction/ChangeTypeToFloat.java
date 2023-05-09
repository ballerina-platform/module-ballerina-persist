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

import java.util.List;

import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.FLOAT;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_305;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_306;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_503;
import static io.ballerina.stdlib.persist.compiler.codeaction.PersistCodeActionName.CHANGE_TYPE_TO_FLOAT;

/**
 * Change type to float code action.
 */
public class ChangeTypeToFloat extends AbstractChangeToSupportedType {
    @Override
    protected String getName() {
        return CHANGE_TYPE_TO_FLOAT.getName();
    }

    @Override
    protected List<String> getSupportedDiagnosticCodes() {
        return List.of(PERSIST_305.getCode(), PERSIST_503.getCode(), PERSIST_306.getCode());
    }

    @Override
    protected String getType() {
        return FLOAT;
    }
}

