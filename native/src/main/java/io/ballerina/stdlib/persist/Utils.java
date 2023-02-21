/*
 *  Copyright (c) 2022, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 LLC. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.persist;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.StreamType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BStream;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;

import java.util.Map;

/**
 * TODO: add javadoc comment.
 *
 * @since 0.1.0
 */
public class Utils {
    private Utils() {
    }

    public static BStream queryStream(Environment env, BObject client, BTypedesc recordType, BString entity) {
        Future balFuture = env.markAsync();
        BMap<BString, BObject> persistClients = (BMap<BString, BObject>) client.get(Constants.PERSIST_CLIENTS);
        BObject persistClient = persistClients.get(entity);
        Runtime runtime = env.getRuntime();

        RecordType streamConstraint = (RecordType) TypeUtils.getReferredType(recordType.getDescribingType());
        StreamType streamType = TypeCreator.createStreamType(streamConstraint, PredefinedTypes.TYPE_NULL);

        ArrayType stringArrayType = TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING);
        BString[] fields = getFieldsInRecordType(recordType);
        BArray fieldsArray = ValueCreator.createArrayValue(stringArrayType);
        for (BString field : fields) {
            fieldsArray.append(field);
        }

        runtime.invokeMethodAsyncSequentially(persistClient, Constants.RUN_READ_QUERY_METHOD, null, null,
                new Callback() {
                    @Override
                    public void notifySuccess(Object result) {
                        balFuture.complete(result);
                    }

                    @Override
                    public void notifyFailure(BError bError) {
                        BStream errorStream = getErrorStream(recordType, bError);
                        balFuture.complete(errorStream);
                    }
                }, null, streamType, recordType, true, fieldsArray, true);

        return null;
    }

    private static BString[] getFieldsInRecordType(BTypedesc recordType) {
        Map<BString, BObject> fieldsMap = recordType.getDescribingType().getEmptyValue();
        return fieldsMap.keySet().toArray(new BString[0]);
    }

    private static BStream getErrorStream(BTypedesc recordType, BError errorValue) {
        return ValueCreator.createStreamValue(
                TypeCreator.createStreamType((recordType).getDescribingType(),
                        PredefinedTypes.TYPE_NULL), createRecordIterator(errorValue));
    }

    private static BObject createRecordIterator(BError errorValue) {
        return ValueCreator.createObjectValue(
                io.ballerina.stdlib.sql.utils.ModuleUtils.getModule(),
                io.ballerina.stdlib.sql.Constants.RESULT_ITERATOR_OBJECT,
                errorValue, null);
    }

}
