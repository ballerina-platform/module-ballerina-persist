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

import io.ballerina.projects.plugins.CompilerPlugin;
import io.ballerina.projects.plugins.CompilerPluginContext;
import io.ballerina.projects.plugins.codeaction.CodeAction;
import io.ballerina.stdlib.persist.compiler.codeaction.AddRelationFieldInRelatedEntity;
import io.ballerina.stdlib.persist.compiler.codeaction.ChangeToClosedRecord;
import io.ballerina.stdlib.persist.compiler.codeaction.ChangeTypeToBoolean;
import io.ballerina.stdlib.persist.compiler.codeaction.ChangeTypeToByteArray;
import io.ballerina.stdlib.persist.compiler.codeaction.ChangeTypeToDecimal;
import io.ballerina.stdlib.persist.compiler.codeaction.ChangeTypeToFloat;
import io.ballerina.stdlib.persist.compiler.codeaction.ChangeTypeToInt;
import io.ballerina.stdlib.persist.compiler.codeaction.ChangeTypeToString;
import io.ballerina.stdlib.persist.compiler.codeaction.MakeEntityRelationOwner;
import io.ballerina.stdlib.persist.compiler.codeaction.MarkFieldAsIdentityField;
import io.ballerina.stdlib.persist.compiler.codeaction.RemoveDiagnosticLocation;
import io.ballerina.stdlib.persist.compiler.codeaction.RemoveTextRange;

import java.util.List;

/**
 * Persist compiler plugin.
 */
public class PersistCompilerPlugin extends CompilerPlugin {

    @Override
    public void init(CompilerPluginContext compilerPluginContext) {
        compilerPluginContext.addCodeAnalyzer(new PersistCodeAnalyzer());
        getCodeActions().forEach(compilerPluginContext::addCodeAction);
    }

    private List<CodeAction> getCodeActions() {
        return List.of(
                new RemoveDiagnosticLocation(),
                new RemoveTextRange(),
                new ChangeToClosedRecord(),
                new AddRelationFieldInRelatedEntity(),
                new MarkFieldAsIdentityField(),
                new MakeEntityRelationOwner(),
                new ChangeTypeToInt(),
                new ChangeTypeToString(),
                new ChangeTypeToBoolean(),
                new ChangeTypeToFloat(),
                new ChangeTypeToDecimal(),
                new ChangeTypeToByteArray()
        );
    }
}
