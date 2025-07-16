# dnsmsg

A DNS message parsing and processing library implemented in [Cangjie](https://cangjie-lang.cn/).

## Overview

**dnsmsg** provides utilities for parsing, constructing, and manipulating DNS protocol messages, including headers, question sections, and resource records. The library is written in Cangjie and covers all major DNS message sections and record types, with comprehensive unit tests.

## Features

- Parse and construct DNS message headers (see [`src/header.cj`](src/header.cj))
- Parse and build DNS question sections ([`src/question.cj`](src/question.cj))
- Parse and construct DNS resource records, including common types (A, AAAA, NS, CNAME, SOA, MX, PTR, TXT, SRV, OPT, etc.) ([`src/resource.cj`](src/resource.cj), [`src/type.cj`](src/type.cj))
- Parse and assemble complete DNS messages ([`src/message.cj`](src/message.cj))
- Domain name parsing and compression support ([`src/name.cj`](src/name.cj))
- Utility functions for reading/writing DNS wire format ([`src/util.cj`](src/util.cj))
- Comprehensive unit test coverage for all modules

## Directory Structure

```
src/                    Source code
    header.cj               DNS header structure & parsing
    header_test.cj          Header unit tests
    message.cj              DNS message structure & parsing
    message_test.cj         Message unit tests
    question.cj             DNS question section structure & parsing
    question_test.cj        Question section unit tests
    resource.cj             Resource record structure & parsing
    resource_test.cj        Resource record unit tests
    type.cj                 DNS type and class constants
    name.cj                 Domain name parsing & compression
    util.cj                 Utility functions for wire format
    util_types.cj           Utility type definitions
    util_types_test.cj      Utility type unit tests
cjpm.toml               Cangjie package config
cjpm.lock               Dependency lock file
.gitignore              Git ignore file
```

## Getting Started

### Prerequisites

- Install the [Cangjie compiler](https://cangjie-lang.cn/download)

### Running Unit Tests

```sh
cjpm test
```

Or run tests directly via VSCode's integrated debugger.

## DNS Message Structure

A DNS message consists of the following sections, all supported by this library:

- **Header**: Contains ID, flags, and section counts ([`Header`](src/header.cj))
- **Question Section**: Contains queries for resource records ([`Question`](src/question.cj))
- **Answer Section**: Resource records answering the question ([`ResourceRecord`](src/resource.cj))
- **Authority Section**: Resource records pointing toward an authority ([`ResourceRecord`](src/resource.cj))
- **Additional Section**: Resource records holding additional information ([`ResourceRecord`](src/resource.cj))

## Supported Resource Record Types

- A, AAAA, NS, CNAME, SOA, MX, PTR, TXT, SRV, OPT, and more (see [`src/type.cj`](src/type.cj))

## Related Files

- [src/header.cj](src/header.cj): DNS header structure and parsing logic
- [src/question.cj](src/question.cj): DNS question section structure and parsing
- [src/resource.cj](src/resource.cj): DNS resource record structure and parsing
- [src/message.cj](src/message.cj): Complete DNS message structure and parsing
- [src/type.cj](src/type.cj): DNS type and class constants
- [src/name.cj](src/name.cj): Domain name parsing and compression
- [src/util.cj](src/util.cj): Utility functions for DNS wire format
- [src/util_types.cj](src/util_types.cj): Utility type definitions

## License

MIT