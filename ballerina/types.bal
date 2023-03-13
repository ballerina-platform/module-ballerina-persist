import ballerina/sql;

public class PersistStream {
    
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;
    private string[]? fields;
    private string[]? include;
    private typedesc<record{}>[]? typeDescriptions = ();
    private SQLClient? persistClient;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = (), string[]? fields = (), string[]? include = (), any[]? typeDescriptions = (), SQLClient? persistClient = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
        self.fields = fields;
        self.include = include;

        if typeDescriptions is any[] {
            typedesc<record{}>[] typeDescriptionsArray = [];
            foreach any typeDescription in typeDescriptions {
                typeDescriptionsArray.push(<typedesc<record {}>>typeDescription);
            }
            self.typeDescriptions = typeDescriptionsArray;
        } 
        
        self.persistClient = persistClient;
    }

    public isolated function next() returns record {|anydata value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                anydata|error value = streamValue.value;
                if value is error {
                    return <Error>error(value.message());
                }
                record {|anydata value;|} nextRecord = {value: value};
                if self.include is string[] {
                    check (<SQLClient>self.persistClient).getManyRelations(nextRecord.value, <string[]> self.fields, <string[]>self.include, <typedesc<record {}>[]>self.typeDescriptions);
                }
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}
