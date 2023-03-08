import ballerina/sql;

public class PersistStream {
    
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;
    private string[]? include;
    private SQLClient? persistClient;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = (), string[]? include = (), SQLClient? persistClient = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
        self.include = include;
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
                    check (<SQLClient>self.persistClient).getManyRelations(nextRecord.value, <string[]>self.include);
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
