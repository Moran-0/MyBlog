---
title: GoogleTest使用教程
date: 2025-11-01 14:25:28
tags:
- c++
- GoogleTest
- 单元测试
cover: /img/cover/137067735_p0.jpg
---

# GoogleTest介绍

gtest（Google Test）是Google开发的跨平台C 单元测试框架，支持Linux、Windows、Mac OS X等操作系统。其核心功能包括丰富断言类型（数值比较、字符串匹配、谓词逻辑等）、分层测试用例管理（通过TEST/TEST_F宏组织测试套件）以及非终止失败处理机制。该框架采用xUnit架构，提供自动化测试发现、死亡测试和XML报告生成功能，并可通过参数化配置调整测试执行流程。

gtest需依赖C++17及以上标准编译，通过CMake构建系统集成到项目中。与之配套的gmock框架可模拟未实现类以隔离测试环境，二者协同使用可覆盖复杂场景的测试需求。2025年发布的1.17.0版本引入对C++17标准的全面支持，并通过持续集成体系保障框架稳定性。



# GoogleTest安装



## 1. vcpkg配合现代cmake

- vcpkg安装gtest和使用特定triplet安装gtest

```cmd
vcpkg install gtest
vcpkg install gtest:x64-windows
```

- 在cmake中使用

```cmake
cmake_minimum_required(VERSION 3.14)
project(MyTests LANGUAGES CXX)

# 启用 vcpkg toolchain
# cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=[vcpkg-root]/scripts/buildsystems/vcpkg.cmake

find_package(GTest CONFIG REQUIRED)

add_executable(my_tests test_main.cpp)
target_link_libraries(my_tests PRIVATE GTest::gtest GTest::gtest_main)

include(GoogleTest)
gtest_discover_tests(my_tests)

```

> `gtest_discover_tests()` 会自动扫描所有 `TEST()`、`TEST_F()` 并注册到 CTest 中。
>  之后你可以直接运行 `ctest`。



## 2. 通过源码编译安装

访问[GoogleTest仓库](https://github.com/google/googletest)克隆下载源码，通过cmake构建得到静态库`libgtest.a`和`libgtest_main.a`，将GoogleTest仓库源码中的include/gtest文件夹添加到项目third-party文件夹中，将编译得到静态库添加到项目中lib文件夹。

编写如下cmakelists.txt文件

```cmake
cmake_minimum_required(VERSION 3.16)

# 创建测试可执行文件
add_executable(unit_tests
    gtest_math_utils.cpp
)

# 设置库文件目录
set(LIBS_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/lib)
# 链接库目录
target_link_directories(unit_tests PRIVATE ${LIBS_DIRS})

# gtest为文件libgtest.a去除lib前缀和.a后缀得到的库名，具体是编译后得到的库文件而定
target_link_libraries(unit_tests PRIVATE CMakeLearn gtest)

# 启用测试
enable_testing()
include(GoogleTest)
include(CTest) # 若出现错误cannot find file DartConfiguration.tcl时添加这行.CTest（CMake 的测试系统）
gtest_discover_tests(unit_tests)
```



# 断言

这些宏大致分为两类：

- **致命断言（ASSERT_）**：失败后**立即中止**当前测试用例。
- **非致命断言（EXPECT_）**：失败后**继续执行**后续语句。

------

### 🔹 一、基本比较断言

| 断言宏                  | 含义             | 示例                           |
| ----------------------- | ---------------- | ------------------------------ |
| `EXPECT_EQ(val1, val2)` | 断言相等（==）   | `EXPECT_EQ(x, 10);`            |
| `EXPECT_NE(val1, val2)` | 断言不相等（!=） | `EXPECT_NE(status, OK);`       |
| `EXPECT_LT(val1, val2)` | 小于（<）        | `EXPECT_LT(a, b);`             |
| `EXPECT_LE(val1, val2)` | 小于等于（≤）    | `EXPECT_LE(score, max_score);` |
| `EXPECT_GT(val1, val2)` | 大于（>）        | `EXPECT_GT(result, 0);`        |
| `EXPECT_GE(val1, val2)` | 大于等于（≥）    | `EXPECT_GE(level, 1);`         |

对应的致命版本只需替换前缀为 `ASSERT_`，如：

```
ASSERT_EQ(x, y);
ASSERT_LT(a, b);
```

------

### 🔹 二、布尔断言

| 断言宏                    | 含义     | 示例                           |
| ------------------------- | -------- | ------------------------------ |
| `EXPECT_TRUE(condition)`  | 条件为真 | `EXPECT_TRUE(ptr != nullptr);` |
| `EXPECT_FALSE(condition)` | 条件为假 | `EXPECT_FALSE(isEmpty());`     |

------

### 🔹 三、字符串断言

| 断言宏                         | 说明                       | 示例                              |
| ------------------------------ | -------------------------- | --------------------------------- |
| `EXPECT_STREQ(str1, str2)`     | C 字符串相等（区分大小写） | `EXPECT_STREQ("OK", result);`     |
| `EXPECT_STRNE(str1, str2)`     | C 字符串不相等             | `EXPECT_STRNE("error", msg);`     |
| `EXPECT_STRCASEEQ(str1, str2)` | 忽略大小写相等             | `EXPECT_STRCASEEQ("ok", "OK");`   |
| `EXPECT_STRCASENE(str1, str2)` | 忽略大小写不相等           | `EXPECT_STRCASENE("OK", "Fail");` |

------

### 🔹 四、异常断言

| 断言宏                                    | 说明                 | 示例                                       |
| ----------------------------------------- | -------------------- | ------------------------------------------ |
| `EXPECT_THROW(statement, exception_type)` | 预期抛出指定类型异常 | `EXPECT_THROW(Foo(), std::runtime_error);` |
| `EXPECT_ANY_THROW(statement)`             | 预期抛出任意异常     | `EXPECT_ANY_THROW(DoSomething());`         |
| `EXPECT_NO_THROW(statement)`              | 预期不抛出异常       | `EXPECT_NO_THROW(OpenFile());`             |

------

### 🔹 五、浮点比较断言

浮点数比较使用近似断言：

| 断言宏                               | 说明                           | 示例                                  |
| ------------------------------------ | ------------------------------ | ------------------------------------- |
| `EXPECT_FLOAT_EQ(val1, val2)`        | 单精度浮点比较                 | `EXPECT_FLOAT_EQ(0.1f + 0.2f, 0.3f);` |
| `EXPECT_DOUBLE_EQ(val1, val2)`       | 双精度浮点比较                 | `EXPECT_DOUBLE_EQ(0.1 + 0.2, 0.3);`   |
| `EXPECT_NEAR(val1, val2, abs_error)` | 判断两个值是否在指定误差范围内 | `EXPECT_NEAR(a, b, 1e-5);`            |

------

### 🔹 六、自定义消息

每个断言都可以附加自定义输出信息：

```c++
EXPECT_EQ(x, y) << "x and y should be equal!";
```



# 谓词断言

`EXPECT_PRED*` 系列宏是 **Google Test** 提供的用于**自定义条件判断（谓词断言）** 的一组工具，主要用于在测试中验证复杂或自定义类型的比较逻辑。

##  一、基本概念

`EXPECT_PREDn` 家族中的 `n` 表示谓词（predicate）参数的数量（1–5）。
 常见形式如下：

| 宏名                             | 参数个数 | 说明             |
| -------------------------------- | -------- | ---------------- |
| `EXPECT_PRED1(pred, val1)`       | 1        | 对单个值执行谓词 |
| `EXPECT_PRED2(pred, val1, val2)` | 2        | 对两个值执行谓词 |
| `EXPECT_PRED3(pred, v1, v2, v3)` | 3        | 三参数谓词       |
| `EXPECT_PRED4(pred, ...)`        | 4        | 四参数谓词       |
| `EXPECT_PRED5(pred, ...)`        | 5        | 五参数谓词       |

- 宏会执行 `pred(val1, val2, ...)`，
- 断言该结果为 **true**，否则测试失败。
- 失败时会打印表达式文本和各参数的实际值。

------



##  二、与普通 `EXPECT_TRUE` 的区别

`EXPECT_TRUE(pred(a, b))` 也能做类似的检查，但输出信息不够详细。
 `EXPECT_PRED*` 会自动输出每个参数的名字和值，方便调试。

**示例：**

```
bool IsNear(int a, int b) {
    return std::abs(a - b) < 5;
}

TEST(PredExample, Basic) {
    int x = 10, y = 20;
    EXPECT_PRED2(IsNear, x, y);
}
```

如果失败，会输出：

```
Value of: IsNear(x, y)
  Actual: false
Expected: true
x evaluates to 10
y evaluates to 20
```

而 `EXPECT_TRUE(IsNear(x, y))` 只会告诉你表达式为 false，不显示参数细节。

------



##  三、ASSERT 版本

对应的致命断言宏：

| 非致命         | 致命（失败中止测试） |
| -------------- | -------------------- |
| `EXPECT_PREDn` | `ASSERT_PREDn`       |

------



##  四、扩展：EXPECT_PRED_FORMATn

EXPECT_PRED_FORMATn` 是 Google Test 中的 **自定义断言宏系列**，用于在测试中通过 **自定义格式化函数（predicate formatter）** 检查条件并输出**详细的失败信息**。

### 1、基本含义

- 形式：

  ```c++
  EXPECT_PRED_FORMATn(pred_format, val1, val2, ..., valn);
  ```

- `n` 表示参数个数（1～5）。

- `pred_format` 是一个 **谓词格式化函数（predicate formatter）**，它决定了断言如何判断真假以及失败时打印什么内容。

------

### 2、谓词格式化函数签名

以两个参数为例：

```c++
::testing::AssertionResult MyPredFormat(
    const char* expr1, const char* expr2,
    const T1& val1, const T2& val2);
```

- `expr1`, `expr2` 是传入表达式的**源码文本**（例如 `"a"`, `"b + 1"`），方便打印；
- `val1`, `val2` 是实际的值；
- 返回 `::testing::AssertionSuccess()` 或
   `::testing::AssertionFailure() << "错误信息"`。

------



###  3、作用与优点

| 功能                   | 说明                                           |
| ---------------------- | ---------------------------------------------- |
| 自定义判断逻辑         | 你决定如何比较值                               |
| 自定义输出信息         | 失败时可输出详细上下文                         |
| 支持多参数             | `EXPECT_PRED_FORMAT1` 到 `EXPECT_PRED_FORMAT5` |
| 与 `EXPECT_PREDn` 区别 | 后者的谓词返回 `bool`，无法自定义失败信息      |

------



###  4、简单示例

```c++
#include <gtest/gtest.h>

::testing::AssertionResult NearPredFormat(
    const char* e1, const char* e2,
    const double& a, const double& b) {
    double diff = fabs(a - b);
    if (diff < 0.01)
        return ::testing::AssertionSuccess();
    return ::testing::AssertionFailure()
        << e1 << " and " << e2 << " differ by " << diff;
}

TEST(PredFormatExample, FloatNear) {
    double x = 3.14, y = 3.17;
    EXPECT_PRED_FORMAT2(NearPredFormat, x, y);
}
```

若失败，输出会包含表达式名和值及详细误差信息。

------
