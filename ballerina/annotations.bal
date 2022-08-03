public type EntityConfig record {|
    string[] key; // Primary key, this is required.
    string[][] unique?; // unique indexes, it can be multiple composite keys
    string tableName?; // table name
|};
 
public annotation EntityConfig Entity on type;

public type AutoIncrementConfig record {|
    int startValue = 1;
    int increment = 1;
|};
 
public annotation AutoIncrementConfig AutoIncrement on record field;