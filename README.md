Ballerina Persist Library
===================

  [![Build](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/build-timestamped-master.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/build-timestamped-master.yml)
  [![codecov](https://codecov.io/gh/ballerina-platform/module-ballerina-persist/branch/main/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerina-persist)
  [![Trivy](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/trivy-scan.yml)
  [![GraalVM Check](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/build-with-bal-test-native.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/build-with-bal-test-native.yml)
  [![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerina-persist.svg)](https://github.com/ballerina-platform/module-ballerina-persist/commits/main)
  [![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-standard-library/module/persist.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-standard-library/labels/module%2Fpersist)

This library provides Ballerina `persist` Tooling, which provides functionality to store and query data conveniently through a data model instead of SQL query language.

The `persist` commands will make it easy to enable Ballerina Persistence Layer in a bal project. With this support, users need not worry about the persistence layer in a project. Users can define an entity data model, validate the model and generate `persist` clients, which provide convenient APIs to store and query data in a data store.

For more information, see [`persist` API Documentation](https://lib.ballerina.io/ballerina/persist/latest).

## Issues and projects 

Issues and Projects tabs are disabled for this repository as this is part of the Ballerina standard library. To report bugs, request new features, start new discussions, view project boards, etc. please visit Ballerina standard library [parent repository](https://github.com/ballerina-platform/ballerina-standard-library). 

This repository only contains the source code for the package.

## Building from the source

### Set up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).
   * [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)
   * [OpenJDK](https://adoptium.net/)

2. Download and install [Docker](https://www.docker.com/get-started)
   
3. Export your GitHub personal access token with the read package permissions as follows.
        
        export packageUser=<Username>
        export packagePAT=<Personal access token>

### Building the source

Execute the commands below to build from source.

1. To build the library:
        
        ./gradlew clean build

2. To run the integration tests:

        ./gradlew clean test

3. To build the package without the tests:

        ./gradlew clean build -x test

4. To run only specific tests:

        ./gradlew clean build -Pgroups=<Comma separated groups/test cases>

   **Tip:** The following groups of test cases are available.
   
   Groups | Test cases
   ---| ---
   basic | basic
   associations | associations <br> one-to-many
   composite-keys | composite-keys

5. To disable some specific test groups:

        ./gradlew clean build -Pdisable-groups=<Comma separated groups/test cases>

6. To debug the tests:

        ./gradlew clean build -Pdebug=<port>
        ./gradlew clean test -Pdebug=<port>

7. To debug the package with Ballerina language:

        ./gradlew clean build -PbalJavaDebug=<port>
        ./gradlew clean test -PbalJavaDebug=<port>

8. Publish ZIP artifact to the local `.m2` repository:
   
        ./gradlew clean build publishToMavenLocal
   
9. Publish the generated artifacts to the local Ballerina central repository:
   
        ./gradlew clean build -PpublishToLocalCentral=true
   
10. Publish the generated artifacts to the Ballerina central repository:
   
        ./gradlew clean build -PpublishToCentral=true

## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community. 

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All contributors are encouraged to read the [Ballerina code of conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`persist` library](https://lib.ballerina.io/ballerina/persist/latest).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
