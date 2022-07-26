import ballerina/time;

public type MedicalNeed record {|
  readonly int needId = -1;
  int itemId; 
  int beneficiaryId; 
  time:Civil  period;
  
  //TODO: How can we handle enum types?
  string urgency;
  int quantity;
|};

public type MedicalItem record {|
    int itemId; 
    string name;
    string 'type;
    string unit;  
|};
