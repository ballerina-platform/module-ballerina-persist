# Support Advanced Filter Conditions through Query Expressions

_Owners_: @daneshk @niveathika  
_Reviewers_: @daneshk  
_Created_: 2022/09/01  
_Updated_: 2021/09/26  
_Issues_: [#3303](https://github.com/ballerina-platform/ballerina-standard-library/issues/3303)

## Summary

Advanced filter conditions are a must for the `ballerina/persist` module design. The ballerina query command can be used easily by the users to give filter conditions such as where, limit and order by. In this proposal, we are planning to support advanced filter conditions for persist client through queries with the use of code modifiers.

## Goals

- Support advanced filter conditions (where, limit and order by) for persist client by modifying code with optimized SQL command calling in the background.

## Non-Goals

- Support advanced filter conditions for persist client with associations

## Motivation

Even though the `ballerina/persist` module provides the way for basic filtering when querying data. This is not enough in most cases. For instance if a user wants to query data with a simple compare condition i.e "query all data where age > 20". 

If we try to pass these conditions as parameters to the query API, this will become more and more complex with compound conditions,
```ballerina
client->read({
	gt: {
		left: age,
		right: 20
         }
});
```

With the use of ballerina syntax, the code becomes quite user friendly.
```ballerina
Student students[]? Students = check from Student student in client->read()
             			     where student.age > 20
				     select student;
```

With the use of code modifiers the above code can be re-written, which will make it optimized and user friendly. The user is not even aware of the intermediate steps.
```ballerina
Student students[]? Students = check from Student student in client->execute(`WHERE age > 20`)
				     select student;
```
 
## Description

Introduce `execute` remote method in persist client,
```ballerina
remote function execute(sql:ParameterizedQuery filterClause) returns stream<record {}, error?>;
```

This will be called by the code modifier after processing the filter intermediate conditions if the user has called read() method within a query.

The filter conditions that are supported:
1. Where clause
    All compare and logical operations are supported in this.
    ```ballerina
    Student students[]? Students = check from Student student in client->read()
				              where (student.age > 20 & student.age < 30)
				              select student;
    ```
     Above will be modified to,
    ```ballerina
    Student students[]? Students = check from Student student in client->execute(`WHERE age > 20 and age < 30`)
				              select student;
     ```

2. Order by clause
    Any static order by clause is supported
    ```ballerina
    Student students[]? Students = check from Student student in client->read()
 				              order by student.age
				              select student;
     ```
     Above will be modified to,
    ```ballerina
    Student students[]? Students = check from Student student in client->execute(`order by age`)
				              select student;
     ```
     Users cannot use variables in order by clause

3. Limit clause
    Any static limit clause is supported
    ```ballerina
    Student students[]? Students = check from Student student in client->read()
 				              limit 5
				              select student;
    ```
     Above will be modified to,
    ```ballerina
    Student students[]? Students = check from Student student in client->execute(`limit 5`)
				              select student;
    ```

If the user has used any unsupported expressions, an error will be given.

## Risks and Assumptions

1. If a "read" remote method is invoked from a client in a query syntax, we are assuming this is a persistent client read method. The code modifying task will apply as long as the persist module is imported in the packages. This can lead to errors in unrelated code. 
2. The user is unaware of the modifying step. If the modifying leads to compile failure in a not so happy path, users will be confused with the error message provided by the compiler as lines will be mismatched.
3. Some of the SQL filters cannot be supported such as  `IN`, `LIKE` and `BETWEEN`
