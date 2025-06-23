# dnsmsg

一个用 [Cangjie](https://cangjie-lang.cn/) 语言实现的 DNS 消息解析与处理库。 [<a href="README.md">English</a>] 

## 目录结构

```
src/                源代码目录
    header.cj           DNS 消息头部结构与解析
    header_test.cj      头部相关单元测试
    message.cj          DNS 消息整体结构与解析
    message_test.cj     消息相关单元测试
    question.cj         DNS 问题区结构与解析
    question_test.cj    问题区相关单元测试
    resource.cj         资源记录结构与解析
    resource_test.cj    资源记录相关单元测试
    util_types.cj       工具类型定义
    util_types_test.cj  工具类型相关单元测试
.vscode/            VSCode 配置
target/             构建输出与缓存
cjpm.toml           Cangjie 包管理配置
cjpm.lock           依赖锁定文件
.gitignore          Git 忽略文件
```

## 测试

### 环境准备

- 安装 [Cangjie 编译器](https://cangjie-lang.cn/download)

### 运行单元测试

```sh
cjpm test
```

或直接运行 VSCode Debug 测试。

## 主要功能

- 解析 DNS 消息头部（[`Header`](src/header.cj)）
- 解析 DNS 问题区（[`Question`](src/question.cj)）
- 解析 DNS 资源记录（[`Resource`](src/resource.cj)）
- DNS 消息整体解析与构建（[`Message`](src/message.cj)）
- 丰富的单元测试覆盖（见各 `*_test.cj` 文件）

## 相关文件

- [src/header.cj](src/header.cj)：DNS 消息头部结构与解析
- [src/question.cj](src/question.cj)：DNS 问题区结构与解析
- [src/resource.cj](src/resource.cj)：资源记录结构与解析
- [src/message.cj](src/message.cj)：DNS 消息整体结构与解析
- [src/util_types.cj](src/util_types.cj)：工具类型定义

## 许可证

MIT