# Changelog
This file contains all the notable changes done to the Ballerina Persist package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- [Added compiler plugin validations for Postgresql as a datasource](https://github.com/ballerina-platform/ballerina-library/issues/5829)
- [Added compiler plugin validations for new advanced SQL database annotations](https://github.com/ballerina-platform/ballerina-library/issues/6068)

### Changed
- [Changed the behavior of foreign key presence validation to account for Relation annotation](https://github.com/ballerina-platform/ballerina-library/issues/6068)

## [1.1.0] - 2023-06-30

### Added
- [Added util methods to generate error messages which are consistent across data sources](https://github.com/ballerina-platform/ballerina-standard-library/issues/4360)
- [Added compiler plugin validations for MSSQL as a datasource](https://github.com/ballerina-platform/ballerina-standard-library/issues/4506)

### Changed

## [1.0.0] - 2023-06-01

### Added
- [Add Quick Fix code actions to Entity Model Definition File validations](https://github.com/ballerina-platform/ballerina-standard-library/issues/4088)
- [Add support for duplicate relations across two entities](https://github.com/ballerina-platform/ballerina-standard-library/issues/4178)

### Changed
- [Change one-to-one association owner retrieval logic](https://github.com/ballerina-platform/ballerina-standard-library/issues/4163)

## [0.1.0] - 2023-02-20

### Added

- Support to define Entity Data Model (Explicit entities, 1-1 associations and 1-n associations)
- Support for generic persistent client
- Support for validations based on EDM specification
