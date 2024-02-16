import ballerina/persist as _;
import ballerina/time;
import ballerinax/persist.sql;

public enum AppointmentStatus {
    SCHEDULED = "SCHEDULED",
    STARTED = "STARTED",
    ENDED = "ENDED"
}

public enum PatientGender {
    MALE = "MALE",
    FEMALE = "FEMALE"
}

@sql:Mapping {name: "appointment"}
public type Appointment record {|
    readonly int id;
    @sql:UniqueIndex {name: "reason_index"}
    string reason;
    time:Civil appointmentTime;
    AppointmentStatus status;
    @sql:Index {name: "patientId"}
    int _patientId;
    @sql:Index {name: "doctorId"}
    int doctorId;
    @sql:Relation {refs: ["_patientId"]}
    Patient patient;
    Doctor doctor;
    Doctor tester;
|};

@sql:Mapping {name: "patients"}
public type Patient record {|
    @sql:Generated
    readonly int id;
    string name;
    int age;
    @sql:Mapping {name: "ADDRESS"}
    string address;
    @sql:Char {length: 10}
    string phoneNumber;
    PatientGender gender;
    @sql:Relation {refs: ["doctorId"]}
    Appointment[] appointments;
|};

public type Doctor record {|
    readonly int id;
    string name;
    @sql:Index {name: "specialty_index"}
    string specialty;
    @sql:Mapping {name: "phone_number"}
    string phoneNumber;
    Appointment[] appointments;
    Appointment[] testAppointments;
|};

