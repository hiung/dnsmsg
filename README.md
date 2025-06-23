# dnsmsg
A DNS message parsing and processing library implemented in [Cangjie](https://cangjie-lang.cn/).[<a href="README-ZH.md">中文</a>] 



## Directory Structure

```
src/                Source code
    header.cj           DNS header structure & parsing
    header_test.cj      Header unit tests
    message.cj          DNS message structure & parsing
    message_test.cj     Message unit tests
    question.cj         DNS question section structure & parsing
    question_test.cj    Question section unit tests
    resource.cj         Resource record structure & parsing
    resource_test.cj    Resource record unit tests
    util_types.cj       Utility type definitions
    util_types_test.cj  Utility type unit tests
.vscode/            VSCode config
target/             Build output & cache
cjpm.toml           Cangjie package config
cjpm.lock           Dependency lock file
.gitignore          Git ignore file
```

## Testing

### Prerequisites

- Install [Cangjie compiler](https://cangjie-lang.cn/download)

### Run unit tests

```sh
cjpm test
```

Or run tests directly via VSCode Debug.

## Features

- Parse DNS message header ([`Header`](src/header.cj))
- Parse DNS question section ([`Question`](src/question.cj))
- Parse DNS resource records ([`Resource`](src/resource.cj))
- Parse and build complete DNS messages ([`Message`](src/message.cj))
- Comprehensive unit test coverage (see `*_test.cj` files)

## Related Files

- [src/header.cj](src/header.cj): DNS header structure & parsing
- [src/question.cj](src/question.cj): DNS question section structure & parsing
- [src/resource.cj](src/resource.cj): Resource record structure & parsing
- [src/message.cj](src/message.cj): DNS message structure & parsing
- [src/util_types.cj](src/util_types.cj): Utility type definitions

## License

MIT