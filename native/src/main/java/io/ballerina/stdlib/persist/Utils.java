/*
 *  Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.flags.TypeFlags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.Parameter;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.ReferenceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import io.ballerina.runtime.transactions.TransactionResourceManager;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;

/**
 * This class has the utility methods required for the Persist module.
 *
 * @since 0.1.0
 */
public class Utils {
    private static final List<String> KNOWN_RECORD_TYPES = Arrays.asList(
            Constants.TimeTypes.CIVIL, Constants.TimeTypes.DATE_RECORD, Constants.TimeTypes.TIME_RECORD,
            Constants.TimeTypes.UTC);

    private Utils() {
    }

    public static BString getEntity(Environment env) {
        String entity = env.getFunctionName().split("\\$")[2];
        return fromString(entity);
    }

    public static BString getEntityFromStreamMethod(Environment env) {
        String functionName = env.getFunctionName();
        String entity = functionName.substring(5, functionName.length() - 6).toLowerCase(Locale.ENGLISH);
        return fromString(entity);
    }

    public static BObject getPersistClient(BObject client, BString entity) {
        BMap<?, ?> persistClients = (BMap<?, ?>) client.get(Constants.PERSIST_CLIENTS);
        return (BObject) persistClients.get(entity);
    }

    public static BArray[] getMetadata(RecordType recordType) {
        ArrayType stringArrayType = TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING);

        //TODO: use PredefinedTypes.TYPE_TYPEDESC once NPE issue is resolved
        ArrayType typeDescriptionArrayType = TypeCreator.createArrayType(PredefinedTypes.TYPE_ANY);
        BArray fieldsArray = ValueCreator.createArrayValue(stringArrayType);
        BArray includeArray = ValueCreator.createArrayValue(stringArrayType);
        BArray typeDescriptionArray = ValueCreator.createArrayValue(typeDescriptionArrayType);

        Map<String, Field> fieldsMap = recordType.getFields();
        for (Field field : fieldsMap.values()) {
            Type type = field.getFieldType();

            boolean arrayType = false;
            if (type.getTag() == TypeTags.ARRAY_TAG) {
                type = ((ArrayType) type).getElementType();
                arrayType = true;
            }

            if ((type.getTag() == TypeTags.RECORD_TYPE_TAG || type.getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) &&
                    !isKnownRecordType(type)) {
                String innerFieldName = field.getFieldName();
                includeArray.append(fromString(innerFieldName));

                BArray innerFieldsArray = getInnerFieldsArray(type);
                for (int i = 0; i < innerFieldsArray.size(); i++) {
                    if (arrayType) {
                        fieldsArray.append(fromString(innerFieldName + "[]." + innerFieldsArray.get(i).toString()));
                    } else {
                        fieldsArray.append(fromString(innerFieldName + "." + innerFieldsArray.get(i).toString()));
                    }
                }

                if (type.getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
                    type = ((ReferenceType) type).getReferredType();
                }
                typeDescriptionArray.append(ValueCreator.createTypedescValue(
                        getRecordTypeWithEnumFieldsReplaced((RecordType) type)));
            } else {
                fieldsArray.append(fromString(field.getFieldName()));
            }
        }

        return new BArray[]{fieldsArray, includeArray, typeDescriptionArray};
    }

    public static BMap<BString, Object> getFieldTypes(RecordType recordType) {
        MapType stringMapType = TypeCreator.createMapType(PredefinedTypes.TYPE_STRING);
        BMap<BString, Object> typeMap = ValueCreator.createMapValue(stringMapType);
        Map<String, Field> fieldsMap = recordType.getFields();
        for (Field field : fieldsMap.values()) {

            Type type = field.getFieldType();
            String fieldName = field.getFieldName();
            typeMap.put(StringUtils.fromString(fieldName), StringUtils.fromString(type.getName()));
        }
        return typeMap;
    }

    private static BArray getInnerFieldsArray(Type type) {
        RecordType recordType;
        if (type.getTag() == TypeTags.RECORD_TYPE_TAG) {
            recordType = (RecordType) type;
        } else {
            recordType = (RecordType) ((ReferenceType) type).getReferredType();
        }

        ArrayType stringArrayType = TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING);
        BArray fieldsArray = ValueCreator.createArrayValue(stringArrayType);
        Map<String, Field> fieldsMap = recordType.getFields();
        for (Field field : fieldsMap.values()) {
            fieldsArray.append(fromString(field.getFieldName()));
        }

        return fieldsArray;
    }

    static boolean isKnownRecordType(Type ballerinaType) {
        return KNOWN_RECORD_TYPES.contains(getBTypeName(ballerinaType));
    }

    private static String getBTypeName(Type ballerinaType) {
        if (ballerinaType.getName() == null || ballerinaType.getName().equals("")) {
            return ballerinaType.toString();
        }
        return ballerinaType.getName();
    }

    public static BArray convertToArray(BTypedesc recordType, BArray arr) {
        ArrayType array = TypeCreator.createArrayType(recordType.getDescribingType());
        BArray returnArray = ValueCreator.createArrayValue(array);
        for (Object element : arr.getValues()) {
            if (element == null) {
                break;
            }
            returnArray.append(element);
        }
        return returnArray;
    }

    public static Object getKey(Environment env, BArray path) {
        Parameter[] pathParams = env.getFunctionPathParameters();
        if (pathParams.length == 1) {
            return path.get(0);
        } else {
            BMap<BString, Object> keyMap = ValueCreator.createMapValue();
            for (int i = 0; i < pathParams.length; i++) {
                keyMap.put(fromString(pathParams[i].name), path.get(i));
            }
            return keyMap;
        }
    }

    public static RecordType getRecordTypeWithKeyFields(BArray keyFields, RecordType recordType) {
        Map<String, Field> fieldsMap = new HashMap<>();
        for (Field field : recordType.getFields().values()) {
            if (isEnumType(field.getFieldType())) {
                Type updatedType = PredefinedTypes.TYPE_STRING;
                if (field.getFieldType().isNilable()) {
                    updatedType = TypeCreator.createUnionType(Arrays.asList(
                            PredefinedTypes.TYPE_STRING, PredefinedTypes.TYPE_NULL));
                }
                fieldsMap.put(field.getFieldName(), TypeCreator.createField(updatedType, field.getFieldName(), 0));
            } else {
                fieldsMap.put(field.getFieldName(), field);
            }
        }

        for (int i = 0; i < keyFields.size(); i++) {
            String key = keyFields.get(i).toString();
            if (!fieldsMap.containsKey(key)) {
                fieldsMap.put(key, TypeCreator.createField(PredefinedTypes.TYPE_STRING, key, 0));
            }
        }

        return TypeCreator.createRecordType(
                Constants.DEFAULT_STREAM_CONSTRAINT_NAME, Constants.BALLERINA_ANNOTATIONS_MODULE, 1,
                fieldsMap, null, true,
                TypeFlags.asMask(TypeFlags.ANYDATA, TypeFlags.PURETYPE)
        );
    }

    private static RecordType getRecordTypeWithEnumFieldsReplaced(RecordType recordType) {
        Map<String, Field> fieldsMap = new HashMap<>();
        for (Field field : recordType.getFields().values()) {
            if (isEnumType(field.getFieldType())) {
                Type updatedType = PredefinedTypes.TYPE_STRING;
                if (field.getFieldType().isNilable()) {
                    updatedType = TypeCreator.createUnionType(Arrays.asList(
                            PredefinedTypes.TYPE_STRING, PredefinedTypes.TYPE_NULL));
                }
                fieldsMap.put(field.getFieldName(), TypeCreator.createField(updatedType, field.getFieldName(), 0));
            } else {
                fieldsMap.put(field.getFieldName(), field);
            }
        }

        return TypeCreator.createRecordType(
                recordType.getName(), recordType.getPkg(), recordType.getFlags(),
                fieldsMap, recordType.getRestFieldType(), recordType.isSealed(),
                recordType.getTypeFlags()
        );
    }

    private static boolean isWithinTrxBlock(TransactionResourceManager trxResourceManager) {
        return trxResourceManager.isInTransaction() &&
                trxResourceManager.getCurrentTransactionContext().hasTransactionBlock();
    }

    public static Map<String, Object> getTransactionContextProperties() {
        Map<String, Object> properties = null;
        TransactionResourceManager trxResourceManager = TransactionResourceManager.getInstance();
        if (isWithinTrxBlock(trxResourceManager)) {
            properties = new HashMap<>();
            properties.put(Constants.CURRENT_TRANSACTION_CONTEXT, trxResourceManager.getCurrentTransactionContext());
        }

        return properties;
    }

    private static boolean isEnumType(Type type) {
        return type.getTag() == TypeTags.UNION_TAG &&
                ((UnionType) type).getMemberTypes().stream().allMatch(memberType ->
                        memberType.getTag() == TypeTags.FINITE_TYPE_TAG ||
                        memberType.getTag() == TypeTags.NULL_TAG);
    }

}
