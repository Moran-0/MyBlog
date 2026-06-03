---
title: CPP要点记录
date: 2026-05-13 23:01:25
tags:
- c++
---

# 悬挂指针



## 出现问题原因

> 结构体Temp内成员变量都是char*指针，声明并定义了init函数将Temp&作为参数，在函数内部对Temp结构体内的指针进行了赋值操作，然后调用了init函数后将Temp变量传递给其他模块。由于是在init函数内对char*变量进行赋值，出了该函数作用域后对于的内存被释放，导致Temp结构体内的char*指针指向已释放内存地址，变成悬挂指针。



## 悬挂指针概念

> 悬挂指针是指指向已经被释放（或不再有效）内存的指针。这意味着指针仍然持有旧地址，但该地址所指向的内存已被回收或重新分配。



## **产生原因**

- 对象或内存被删除或释放后，指针依然存在，指向已释放的内存。  
- 例如，使用delete或delete[]操作符释放了堆上分配的内存，但指针没有被置为nullptr。



## **示例**

```c++
#include <iostream>

void danglingPointerExample() {
    int* ptr = new int(10); // 动态分配内存
    delete ptr; // 释放内存

    // ptr 现在是悬挂指针，指向已经释放的内存
    std::cout << *ptr << std::endl; // 未定义行为
}

int main() {
    danglingPointerExample();
    return 0;
}
```

在上述代码中，ptr是一个悬挂指针，因为它指向的内存已经被释放，之后访问它将导致未定义行为（可能是崩溃或错误的值）。



## **如何避免**

- • 将悬挂指针置为nullptr：在释放内存后，可以将指针赋值为nullptr，从而避免悬挂指针问题。

```c++
delete ptr;
ptr = nullptr; // 防止悬挂指针
```



# 对象移动（左值和右值）



> **左值**：可以位于赋值号（=）左侧的表达式，有名称的、可以获取到存储地址的表达式
>
> **右值**：只能位于赋值号右侧的表达式，通常没有名称，无法获取其存储地址，如字面量

1. **右值引用**

C++11 引入了右值引用（&&），允许开发者对右值进行操作。右值引用必须立即初始化，且只能使用右值进行初始化。它们允许修改右值，从而支持移动语义和完美转发。右值引用只能绑定到一个即将销毁的对象。例如：

```c++
int &&a = 10; // '10' 是右值，可以被右值引用
a = 11; // 右值引用可以修改右值
```

*std::move* 函数可以将左值强制转换为右值，通常用于触发移动构造函数或移动赋值操作符，避免对象的复制构造。

```c++
int num = 10;

int &&a = std::move(num); // 'num' 被转换为右值
```

**应用场景**

右值引用主要用于实现移动语义，如移动构造函数和移动赋值操作符。这允许资源（如动态分配的内存）从一个对象转移到另一个对象，而不是进行复制，从而提高效率。

2. **移动构造函数和移动赋值运算符**

移动构造函数的第一个参数类型必须是**该类类型的一个右值引用**。移动构造函数需要确保移动资源后销毁源对象是无害的。移动操作不应抛出任何异常，需添加`noexcept`关键字。



# 引用折叠

**引用折叠（Reference Collapsing）** 是 C++11 引入的一条规则，用来规定当多层引用组合出现时（例如 `T& &`、`T& &&`、`T&& &`、`T&& &&`），最终的引用类型是什么。

C++ 标准中明确禁止普通情况下存在“引用的引用”（reference of reference），但在**模板参数推导、类型别名、`decltype`、`auto`** 等场景中，类型系统内部会产生“引用的引用”的情况。
 为此，C++ 定义了一套“折叠规则”来化简为合法的引用类型。

------

##  1.引用折叠规则表

| 组合形式 | 折叠结果 |
| -------- | -------- |
| `T& &`   | `T&`     |
| `T& &&`  | `T&`     |
| `T&& &`  | `T&`     |
| `T&& &&` | `T&&`    |

👉 总结成一句口诀：

> **“有左折左，无左折右。”**
> 也就是说，只要其中有一个是左值引用（`&`），结果就是左值引用，否则就是右值引用。

------

## 2.引用折叠出现的典型场景

#### 模板参数推导 + 转发引用（Forwarding Reference）

```
template<typename T>
void func(T&& x); // T&& 是“转发引用”

int a;
func(a);   // a 是左值 -> T 推导为 int& -> 参数类型为 int& &&
            // 引用折叠 => int&

func(10);  // 10 是右值 -> T 推导为 int -> 参数类型 int&& && -> 折叠为 int&&
```

🔹 因此，`T&&` 在模板中既能接收左值又能接收右值，这就是 **万能引用（Forwarding Reference）** 的核心机制，靠的就是“引用折叠”。

------

####  `std::forward` 的实现依赖引用折叠

```
template <typename T>
T&& forward(typename std::remove_reference<T>::type& arg) noexcept {
    return static_cast<T&&>(arg); // 这里的 T&& 可能折叠
}
```

- 若 `T` 是 `U&`，则 `T&&` → `U& &&` → `U&`
- 若 `T` 是 `U`，则 `T&&` → `U&&`

所以 `std::forward` 能正确地保留值类别（左值或右值）。

------

#### 类型别名、`decltype`、`auto` 推导等

```
using Ref = int&;
Ref& r1 = a;   // int& & → int&
Ref&& r2 = a;  // int& && → int&
```

------

## 3.核心理解

- 普通代码中写不出“引用的引用”，但模板/类型推导过程中类型系统会产生这种组合。
- C++ 通过引用折叠规则来简化类型系统，让模板能够同时支持左值和右值。



# 非类型模板参数(NTTP)

非类型模板参数表示一个**常量值**，可以是整型、指针、引用、枚举值等。

非类型模板参数是在模板参数列表中声明的**常量值参数**：

```
template<int N>
class Array {
    int data[N];
};
```

这里：

- `N` 是非类型模板参数；
- 它在编译期就必须是**常量表达式**；
- 它参与类型定义（不同的 `N` 会生成不同的 `Array<N>` 类型）。

------



## 支持的参数类型

非类型模板参数可以是以下类型（视 C++ 版本而定）：

| C++ 版本 | 允许的类型                                         |
| -------- | -------------------------------------------------- |
| C++98/03 | 整数、枚举、指针、引用、成员指针、空指针           |
| C++14    | 增强 constexpr 表达式支持                          |
| C++17    | 支持 `auto` 非类型模板参数                         |
| C++20    | 支持类类型（必须满足一些 constexpr 条件）          |
| C++23    | 扩展了类类型 NTTP 的使用范围（结构体、聚合类型等） |

------

#### 🔹 示例 1：整数作为 NTTP

```
template<int N>
struct Factorial {
    static constexpr int value = N * Factorial<N - 1>::value;
};

template<>
struct Factorial<0> {
    static constexpr int value = 1;
};

int main() {
    static_assert(Factorial<5>::value == 120);
}
```

> 📍 模板参数 `N` 是编译期常量，因此可以实现**编译期计算**。

------

#### 🔹 示例 2：指针/引用作为 NTTP

```
int global = 42;

template<int* Ptr>
struct PtrWrapper {
    static void print() { std::cout << *Ptr << '\n'; }
};

int main() {
    PtrWrapper<&global>::print();  // 输出 42
}
```

> 注意：`Ptr` 必须是指向**具有静态存储期**（global/static）的对象的指针。

------

#### 🔹 示例 3：C++17 的 `auto` NTTP

C++17 允许用 `auto` 定义 NTTP，使模板更通用：

```
template<auto N>
struct Constant {
    static constexpr auto value = N;
};

int main() {
    Constant<5>::value;        // 推断 N 为 int
    Constant<'A'>::value;      // 推断 N 为 char
    Constant<true>::value;     // 推断 N 为 bool
}
```

------

#### 🔹 示例 4：C++20 类类型 NTTP

C++20 起，**某些类类型**可以作为非类型模板参数，前提是它们满足：

- `constexpr` 构造函数；
- 全部成员都是公开且可 constexpr；
- 支持编译期比较（`operator==`）。

```
struct Point {
    int x, y;
    constexpr bool operator==(const Point&) const = default;
};

template<Point P>
struct Plot {
    static void show() { std::cout << P.x << ", " << P.y << '\n'; }
};

int main() {
    constexpr Point p{3, 4};
    Plot<p>::show();  // 输出 3, 4
}
```

------

## 使用限制

非类型模板参数必须是**编译期常量**，且**值在编译期可确定**。

非法的示例：

```
void f(int n) {
    Array<n> arr;  // ❌ 错误：n 不是编译期常量
}
```





# 数组引用

## 一、什么是“数组引用”

在C++中：

- “引用”表示某个对象的**别名（alias）**；
- “数组”是一种固定长度的**聚合类型（aggregate type）**；
- “数组引用”就是：**引用一个整个数组对象，而不是数组中的单个元素。**

------

#### 📘 例子：最基础的数组引用定义

```c++
int arr[5] = {1, 2, 3, 4, 5};
int (&ref)[5] = arr;
```

> ✅ 这里 `ref` 是一个 **引用**，引用的目标是一个类型为 `int[5]` 的数组。

从语义上讲：

- `ref` **不是指针**；
- 它绑定到 `arr`，两者共享同一块内存；
- 不能让 `ref` 引用其他数组（引用不可重新绑定）。

------


## 二、数组引用的语法结构分析

#### 一般形式：

```
T (&name)[N];
```

| 部分   | 含义         |
| ------ | ------------ |
| `T`    | 数组元素类型 |
| `&`    | 表示引用类型 |
| `name` | 引用变量名   |
| `[N]`  | 数组长度     |

所以：

> `T (&name)[N]` 表示一个**对长度为 N 的 T 类型数组的引用**。

------

#### ⚠️ 为什么必须加括号？

如果不加括号：

```
T &name[N];  // ❌
```

这不再是“数组的引用”，而是：

> “一个长度为 N 的数组，数组元素是 T& 类型的引用”。

即：**数组的元素是引用类型**，而不是“引用一个数组”！

------

##### 🔍 对比分析：

| 声明            | 含义                             | 是否正确                       |
| --------------- | -------------------------------- | ------------------------------ |
| `int (&ref)[5]` | 引用一个包含5个int的数组         | ✅ 正确                         |
| `int &ref[5]`   | 一个数组，包含5个int引用（非法） | ❌ 错误（引用不能构成数组元素） |

C++标准规定：

> **引用不是对象类型**，不能构成数组元素。
> 因此 `int &a[5];` 是非法声明。

------



##  三、数组引用与指针的区别

| 项目             | 数组引用 (`T (&)[N]`) | 数组指针 (`T (*)[N]`)  |
| ---------------- | --------------------- | ---------------------- |
| 绑定方式         | 必须绑定已有数组      | 可指向不同数组         |
| 是否退化         | 不会退化              | 普通数组名会退化成指针 |
| 语法操作         | 直接用下标            | 需解引用再下标         |
| 示例             | `int (&r)[3] = arr;`  | `int (*p)[3] = &arr;`  |
| 使用方式         | `r[i]` ✅              | `(*p)[i]` ✅            |
| 是否保持长度信息 | ✅ 编译期知道长度      | ✅ 也知道长度           |
| 常见用途         | 函数参数保持数组类型  | 指针参数传递数组首地址 |

------



##  四、数组引用的主要用途

#### 1️⃣ 函数参数中防止数组退化

默认情况下，数组作为函数参数会**退化为指针**：

```
void f(int arr[5]);  // 实际是 void f(int*);
```

➡️ 无法在函数内知道数组的长度。

使用数组引用可以保留长度信息：

```
void f(int (&arr)[5]) {
    for (int x : arr) std::cout << x << ' ';
}
```

这样：

- 只能传入长度为 5 的数组；
- 编译器会自动检查；
- `sizeof(arr)` 得到整个数组大小，而不是指针大小。

------

#### 2️⃣ 模板中自动推导数组长度

```
template <typename T, size_t N>
constexpr size_t arraySize(T (&)[N]) noexcept {
    return N;
}

int main() {
    int nums[7] = {};
    std::cout << arraySize(nums);  // 输出 7
}
```

📍关键点：

- `T` 自动推导为元素类型；
- `N` 自动推导为数组长度；
- 不需要显式写数字。

------

#### 3️⃣ 与字符串字面量结合

```c++
void printStr(const char (&s)[6]) {
    std::cout << s << '\n';
}

int main() {
    printStr("hello");  // OK
}
```

- `"hello"` 是 `const char[6]`（含结尾 `'\0'`）。
- 参数是 `const char (&)[6]`，精确匹配。

------



##  五、数组引用中的`const`修饰

##### 1️⃣ 修饰元素类型

```c++
const int (&ref)[3] = arr;
```

表示引用的数组元素是 `const int`，不能修改。

##### 2️⃣ 修饰引用本身（几乎无意义）

```
int (&const ref)[3] = arr;  // ❌ 无效
```

> 引用本身不能重新绑定，因此 `const` 对引用本身是多余的。

------



##  六、数组引用与模板非类型参数结合

```c++
template<const char (&str)[N]>
struct StringLiteral {
    static constexpr size_t length = N - 1; // 去掉 '\0'
};

constexpr auto len = StringLiteral<"hello">::length;  // N = 6
```

这里 `const char (&str)[N]` 是一个 **非类型模板参数** 的引用形式。
 它在编译期携带整个字符串字面量。

------



##  七、总结对比与口诀

| 写法            | 类型含义             | 是否合法  |
| --------------- | -------------------- | --------- |
| `int arr[5]`    | 数组                 | ✅         |
| `int (&ref)[5]` | 引用一个数组         | ✅         |
| `int &ref[5]`   | 数组中每个元素是引用 | ❌（非法） |
| `int (*ptr)[5]` | 指针，指向一个数组   | ✅         |
| `int *ptr[5]`   | 数组，每个元素是指针 | ✅         |

> 🧠 口诀：
>
> - `&` **紧贴标识符时** → “引用类型”；
> - `*` **紧贴标识符时** → “指针类型”；
> - 外层 `[N]` → “这是一个数组类型”；
> - 因为 `[]` 的优先级高于 `&` 和 `*`，所以：
>   - 想让引用作用于整个数组，**必须加括号**。

------



##  八、总结

| 要点           | 说明                               |
| -------------- | ---------------------------------- |
| 语法           | `T (&name)[N]`                     |
| 含义           | “引用一个长度为 N 的 T 类型数组”   |
| 是否能去掉括号 | ❌ 不行（否则变成数组的数组）       |
| 典型用途       | 保留数组长度、模板推导、编译期校验 |
| 与指针区别     | 不退化、不可重新绑定、更安全       |
| 编译期行为     | 数组长度信息完整可知               |





# 可变参数模板



## 一、可变参数模板的基本概念

在C++中：

- 普通模板只能接受**固定数量**的模板参数；
- 可变参数模板（variadic template）允许模板接受**任意数量（0~N个）**参数。

------

### 定义形式

#### 1️⃣ 模板参数可变：

```c++
template<typename... Args>
void func(Args... args);
```

含义：

- `typename... Args` 是一个**模板参数包（parameter pack）**；
- `Args... args` 是一个**函数参数包**；
- 这两个包长度相同；
- 编译器在实例化时会自动“展开（expand）”。

------

#### 2️⃣ 类模板同理：

```c++
template<class... Types>
struct MyTuple {};
```

`Types...` 可以是任意数量的类型参数。

------



## 二、Parameter Pack（参数包）

### 1️⃣ 模板参数包（Template Parameter Pack）

定义时带 `...`：

```c++
template<typename... Args>
```

这里 `Args` 是一个类型列表，比如 `{int, double, std::string}`。

### 2️⃣ 函数参数包（Function Parameter Pack）

在形参中也带 `...`：

```c++
void f(Args... args)
```

展开后可能是：

```c++
void f(int, double, std::string)
```

### 3️⃣ 参数包的展开（Pack Expansion）

使用 `...` 展开：

```c++
(doSomething(args), ...); // C++17折叠表达式
```

或递归方式展开：

```c++
doSomething(first);
func(rest...);
```

------



## 三、最简单示例

##### ✅ 打印任意数量的参数

```
#include <iostream>

template<typename... Args>
void print(Args... args) {
    (std::cout << ... << args) << '\n';  // C++17 折叠表达式
}

int main() {
    print(1, " hello ", 3.14);  // 输出: 1 hello 3.14
}
```

> `(... << args)` 是一个**右折叠表达式（fold expression）**，C++17起支持。

------



##  四、C++11 实现可变参数模板

在C++11没有折叠表达式前，我们只能用递归展开：

```c++
template<typename T>
void printOne(const T& arg) {
    std::cout << arg << '\n';
}

template<typename T, typename... Rest>
void printOne(const T& first, const Rest&... rest) {
    std::cout << first << ' ';
    printOne(rest...);  // 递归展开
}

int main() {
    printOne(1, 2.5, "hello");
}
```

展开过程如下：

```c++
printOne(1, 2.5, "hello")
→ printOne(2.5, "hello")
→ printOne("hello")
→ printOne(T) 基例
```

------



##  五、可变参数模板的工作机制

可变参数模板在编译时由编译器**自动生成多个具体版本**：

- 模板参数包展开；
- 每个展开实例都是**编译期静态展开**，不会带来运行时开销。

比如：

```c++
template<typename... T>
void f(T... args);
```

若调用：

```c++
f(1, 2.5, "abc");
```

编译器会生成：

```c++
void f(int, double, const char*);
```

------



##  六、模板包展开（Pack Expansion）位置规则

可以在**任何允许出现多个模板参数的地方**使用展开：

| 用法场景     | 示例                          |
| ------------ | ----------------------------- |
| 函数参数     | `f(args...)`                  |
| 初始化列表   | `int arr[] = {args...};`      |
| 模板参数列表 | `std::tuple<Args...>`         |
| 继承列表     | `struct D : Base<Args>... {}` |
| 表达式展开   | `(expr(args), ...);`          |
| 参数转发     | `std::forward<Args>(args)...` |

------



##  七、完美转发与可变参数模板

可变参数模板经常与 **`std::forward`** 配合，用于完美转发。

```c++
#include <utility>

template<typename... Args>
void wrapper(Args&&... args) {
    func(std::forward<Args>(args)...);  // 完美转发
}
```

- `Args&&...` 是**转发引用**（万能引用）；
- 能保持参数的左值/右值特性；
- `std::forward` 保证原有值类别不变。

------



##  八、类模板中的可变参数

```c++
template<typename... Args>
class MyContainer {
public:
    MyContainer(Args... args) {
        ((std::cout << args << " "), ...);
    }
};

int main() {
    MyContainer<int, double, const char*>(1, 3.14, "hi");
}
```

还可以用于继承：

```c++
template<class... Bases>
struct MultiInherit : Bases... {
    using Bases::operator()...; // C++20：批量引入基类函数
};
```

------



##  九、`sizeof...` 运算符

可变参数模板中可以使用 `sizeof...` 获取参数数量：

```c++
template<typename... Args>
void info(Args... args) {
    std::cout << "参数数量: " << sizeof...(Args) << '\n';
}
```

这在元编程、调试、模板约束时都非常有用。

------



##  十、C++17 折叠表达式

C++17 起简化了参数包展开的语法：

| 折叠类型 | 形式                                               | 含义                        |
| -------- | -------------------------------------------------- | --------------------------- |
| 左折叠   | `(... op args)`                                    | `((a1 op a2) op a3) op ...` |
| 右折叠   | `(args op ...)`                                    | `a1 op (a2 op (a3 op ...))` |
| 含初值   | `(init op ... op args)` 或 `(args op ... op init)` | 指定起始值                  |

示例：

```c++
template<typename... Args>
auto sum(Args... args) {
    return (args + ...);  // 右折叠：(a1 + (a2 + (a3 + ...)))
}

int main() {
    std::cout << sum(1, 2, 3, 4);  // 输出 10
}
```

------



##  十一、结合非类型模板参数的可变模板

```
template<int... Ns>
struct Sum {
    static constexpr int value = (Ns + ...);
};

int main() {
    static_assert(Sum<1,2,3,4>::value == 10);
}
```

这就是**编译期可变参数计算**的典型模式。

------

##  十二、实际应用场景

| 场景            | 示例                             | 说明             |
| --------------- | -------------------------------- | ---------------- |
| 元组实现        | `std::tuple<Args...>`            | 存放任意类型参数 |
| 转发构造        | `std::make_shared<T>(Args&&...)` | 保持完美转发     |
| 格式化函数      | `std::format(fmt, Args...)`      | 传任意数量参数   |
| 容器批量初始化  | `emplace_back(Args&&...)`        | 支持多类型构造   |
| 编译期求和/逻辑 | `(Ns + ...)`, `(Preds && ...)`   | 静态计算         |

------

##  十三、常见陷阱与注意点

| 问题             | 原因                    | 解决                         |
| ---------------- | ----------------------- | ---------------------------- |
| 模板递归终止忘写 | 没有终止版本            | 加上“基例”重载               |
| 参数转发错误     | 没有使用 `std::forward` | 使用万能引用+forward         |
| 包展开位置错误   | 展开符放错位置          | 确保语法合法 `(f(args)...);` |
| 混合参数包类型   | 模板推导不匹配          | 明确模板参数或使用折叠表达式 |

------

##  十四、总结表

| 概念                | 说明                         | 版本  |
| ------------------- | ---------------------------- | ----- |
| 可变参数模板        | 接受任意数量模板参数         | C++11 |
| 参数包（Pack）      | 一组参数的抽象集合           | C++11 |
| 包展开（Expansion） | 用 `...` 展开参数            | C++11 |
| `sizeof...` 运算符  | 获取包中参数数量             | C++11 |
| 折叠表达式          | 简化展开写法                 | C++17 |
| 完美转发            | `Args&&...` + `std::forward` | C++11 |





# C++异常

完整异常类体系

```ini
std::exception (基类)
├── std::bad_alloc
├── std::bad_cast
├── std::bad_typeid
├── std::bad_exception
├── std::bad_array_new_length (C++11)
├── std::bad_optional_access (C++17)
├── std::bad_variant_access (C++17)
├── std::bad_weak_ptr (C++11)
├── std::bad_function_call (C++11)
├── std::ios_base::failure
└── std::logic_error
    ├── std::domain_error
    ├── std::invalid_argument
    ├── std::length_error
    ├── std::out_of_range
    ├── std::future_error (C++11)
    └── std::regex_error (C++11)
└── std::runtime_error
    ├── std::range_error
    ├── std::overflow_error
    ├── std::underflow_error
    ├── std::system_error (C++11)
    │   └── std::filesystem::filesystem_error (C++17)
    ├── std::tx_exception (TM TS)
    └── std::format_error (C++20)
```

## 详细分类说明

### **1. 基类：std::exception**

cpp

```c++
class exception {
public:
    exception() noexcept;
    exception(const exception&) noexcept;
    exception& operator=(const exception&) noexcept;
    virtual ~exception();
    virtual const char* what() const noexcept;  // 关键方法：返回错误信息
};
```



### **2. 语言支持异常（Language Support）**

这些异常与C++语言特性相关：

cpp

```c++
// 内存分配失败
std::bad_alloc               // new操作失败时抛出

// 类型转换失败
std::bad_cast                // dynamic_cast失败时抛出（引用类型）
std::bad_typeid              // typeid操作符应用于空指针时

// 其他语言特性
std::bad_exception           // 意外异常（unexpected handler）
std::bad_array_new_length    // 数组new长度无效 (C++11)
std::bad_optional_access     // 访问空的optional (C++17)
std::bad_variant_access      // 访问错误类型的variant (C++17)
std::bad_weak_ptr            // 从空weak_ptr构造shared_ptr (C++11)
std::bad_function_call       // 调用空的std::function (C++11)
```



### **3. 逻辑错误（Logic Errors）**

程序逻辑错误，可以在编码时预防：

cpp

```c++
std::logic_error             // 逻辑错误基类
├── std::domain_error        // 数学函数域错误（如sqrt(-1)）
├── std::invalid_argument    // 无效参数传递
├── std::length_error        // 超出最大允许长度（如vector::reserve）
├── std::out_of_range        // 索引越界（如vector::at()）
├── std::future_error        // future/promise操作错误 (C++11)
└── std::regex_error         // 正则表达式错误 (C++11)

// 使用示例
void process(int value) {
    if (value < 0) {
        throw std::invalid_argument("Value must be non-negative");
    }
    if (value > MAX_SIZE) {
        throw std::out_of_range("Value exceeds maximum size");
    }
}
```



### **4. 运行时错误（Runtime Errors）**

程序运行时发生的错误，难以在编码时完全预防：

cpp

```c++
std::runtime_error           // 运行时错误基类
├── std::range_error         // 计算结果超出有效范围
├── std::overflow_error      // 算术上溢（如INT_MAX + 1）
├── std::underflow_error     // 算术下溢
├── std::system_error        // 操作系统错误 (C++11)
│   └── std::filesystem::filesystem_error  // 文件系统错误 (C++17)
└── std::format_error        // 格式化错误 (C++20)

// 使用示例
double safe_divide(double a, double b) {
    if (b == 0) {
        throw std::runtime_error("Division by zero");
    }
    return a / b;
}
```



### **5. I/O流异常**

cpp

```c++
std::ios_base::failure       // 流操作失败
// 通常与std::ios::failure相同
```



## 使用示例

### **完整捕获示例**

cpp

```c++
#include <iostream>
#include <stdexcept>
#include <vector>
#include <memory>
#include <new>

void exampleFunction() {
    std::vector<int> vec(10);
    
    try {
        // 可能抛出 out_of_range
        int value = vec.at(20);
        
        // 可能抛出 bad_alloc
        int* huge_array = new int[1000000000000LL];
        
        // 可能抛出 bad_cast
        class Base { virtual void foo() {} };
        class Derived : public Base {};
        Base b;
        Derived& d = dynamic_cast<Derived&>(b);
        
    } catch (const std::out_of_range& e) {
        std::cout << "范围错误: " << e.what() << std::endl;
    } catch (const std::bad_alloc& e) {
        std::cout << "内存分配失败: " << e.what() << std::endl;
    } catch (const std::bad_cast& e) {
        std::cout << "类型转换失败: " << e.what() << std::endl;
    } catch (const std::logic_error& e) {
        // 捕获所有逻辑错误
        std::cout << "逻辑错误: " << e.what() << std::endl;
    } catch (const std::runtime_error& e) {
        // 捕获所有运行时错误
        std::cout << "运行时错误: " << e.what() << std::endl;
    } catch (const std::exception& e) {
        // 捕获所有标准异常
        std::cout << "标准异常: " << e.what() << std::endl;
    } catch (...) {
        // 捕获所有其他异常
        std::cout << "未知异常" << std::endl;
    }
}
```



### **自定义异常类**

cpp

```c++
#include <stdexcept>
#include <string>

// 自定义异常，继承标准异常
class MyException : public std::runtime_error {
public:
    explicit MyException(const std::string& msg, int error_code = 0)
        : std::runtime_error(msg), code_(error_code) {}
    
    int code() const noexcept { return code_; }
    
private:
    int code_;
};

void useCustomException() {
    try {
        throw MyException("Custom error occurred", 42);
    } catch (const MyException& e) {
        std::cout << "错误: " << e.what() 
                  << ", 代码: " << e.code() << std::endl;
    }
}
```



## 最佳实践

1. **按层次捕获**：从具体到一般
2. **优先使用标准异常**：不要随意抛出基本类型
3. **继承标准异常**：自定义异常应继承`std::exception`
4. **提供有用信息**：覆盖`what()`方法返回有意义的信息
5. **异常安全**：保证资源正确释放

## C++11/14/17新增异常

| 版本  | 新增异常类                          | 用途                  |
| :---- | :---------------------------------- | :-------------------- |
| C++11 | `std::bad_array_new_length`         | 无效数组new长度       |
| C++11 | `std::bad_weak_ptr`                 | weak_ptr操作失败      |
| C++11 | `std::bad_function_call`            | 调用空的std::function |
| C++17 | `std::bad_optional_access`          | 访问空的optional      |
| C++17 | `std::bad_variant_access`           | variant类型访问错误   |
| C++17 | `std::filesystem::filesystem_error` | 文件系统操作错误      |
| C++20 | `std::format_error`                 | 格式化字符串错误      |

这个异常体系提供了丰富的错误处理机制，使得C++程序的错误处理更加结构化、可维护。



# 数值极限

`std::numeric_limits`是定义在`#include <limits>`中的一个 **类型 traits（类型特征类）**，用于**查询数值类型的各种极限属性和特性**，用于在编译期/运行期安全地获取数值边界，而不是写死常量。

## **完整成员列表**

```c++
template<typename T>
struct numeric_limits {
    // 基本信息
    static constexpr bool is_specialized = false;  // 该类型是否有特化
    static constexpr bool is_signed = false;       // 是否有符号
    static constexpr bool is_integer = false;      // 是否是整数类型
    static constexpr bool is_exact = false;        // 是否是精确表示
    
    // 数值范围
    static constexpr T min() noexcept;             // 最小值（对浮点数是正规范化最小值）
    static constexpr T max() noexcept;             // 最大值
    static constexpr T lowest() noexcept;          // 最小负值（C++11）
    
    // 精度
    static constexpr int digits = 0;               // 基数位数（整数：不含符号位）
    static constexpr int digits10 = 0;             // 十进制精度位数
    
    // 特殊值支持
    static constexpr bool has_infinity = false;    // 是否有无穷大
    static constexpr bool has_quiet_NaN = false;   // 是否有静默NaN
    static constexpr bool has_signaling_NaN = false; // 是否有信号NaN
    static constexpr bool has_denorm = false;      // 是否有非规范化数
    static constexpr bool has_denorm_loss = false; // 是否有精度损失
    
    // 舍入和异常
    static constexpr float_round_style round_style = round_toward_zero;
    static constexpr bool traps = false;           // 是否捕获算术异常
    static constexpr bool tinyness_before = false; // 是否在舍入前检测tiny值
    
    // 特殊值（如果支持）
    static constexpr T infinity() noexcept;        // 无穷大
    static constexpr T quiet_NaN() noexcept;       // 静默NaN
    static constexpr T signaling_NaN() noexcept;   // 信号NaN
    static constexpr T denorm_min() noexcept;      // 最小正非规范化值
    
    // C++11新增
    static constexpr int max_digits10 = 0;         // 唯一表示所需的最大十进制位数
    static constexpr T epsilon() noexcept;         // 机器epsilon（1与大于1的最小值差）
    static constexpr int min_exponent = 0;         // 最小负指数（基数=2或10）
    static constexpr int min_exponent10 = 0;
    static constexpr int max_exponent = 0;         // 最大正指数
    static constexpr int max_exponent10 = 0;
};
```

## 不同数据类型的特化

### **整数类型示例**

```c++
#include <limits>
#include <iostream>

void integer_limits() {
    using namespace std;
    
    cout << "=== 整数类型限制 ===" << endl;
    
    // int类型
    cout << "int:" << endl;
    cout << "  大小: " << sizeof(int) << " 字节" << endl;
    cout << "  最大值: " << numeric_limits<int>::max() << endl;
    cout << "  最小值: " << numeric_limits<int>::min() << endl;
    cout << "  是否有符号: " << numeric_limits<int>::is_signed << endl;
    cout << "  位数: " << numeric_limits<int>::digits << " (不含符号位)" << endl;
    cout << "  十进制位数: " << numeric_limits<int>::digits10 << endl;
    
    // unsigned int
    cout << "\nunsigned int:" << endl;
    cout << "  最大值: " << numeric_limits<unsigned int>::max() << endl;
    cout << "  是否有符号: " << numeric_limits<unsigned int>::is_signed << endl;
    
    // 其他整数类型
    cout << "\n其他整数类型:" << endl;
    cout << "  short 最大值: " << numeric_limits<short>::max() << endl;
    cout << "  long long 最大值: " << numeric_limits<long long>::max() << endl;
    cout << "  size_t 最大值: " << numeric_limits<size_t>::max() << endl;
}
```



### **浮点数类型示例**

```c++
void float_limits() {
    using namespace std;
    
    cout << "\n=== 浮点数类型限制 ===" << endl;
    
    // float类型
    cout << "float:" << endl;
    cout << "  大小: " << sizeof(float) << " 字节" << endl;
    cout << "  最大值: " << numeric_limits<float>::max() << endl;
    cout << "  最小值: " << numeric_limits<float>::min() << endl;  // 正规范化最小值
    cout << "  最小负值: " << numeric_limits<float>::lowest() << endl;
    cout << "  精度位数: " << numeric_limits<float>::digits << endl;
    cout << "  十进制精度: " << numeric_limits<float>::digits10 << endl;
    cout << "  机器epsilon: " << numeric_limits<float>::epsilon() << endl;
    cout << "  是否有无穷大: " << numeric_limits<float>::has_infinity << endl;
    cout << "  无穷大值: " << numeric_limits<float>::infinity() << endl;
    cout << "  是否有NaN: " << numeric_limits<float>::has_quiet_NaN << endl;
    
    // double类型
    cout << "\ndouble:" << endl;
    cout << "  大小: " << sizeof(double) << " 字节" << endl;
    cout << "  十进制精度: " << numeric_limits<double>::digits10 << endl;
    cout << "  指数范围: 10^" << numeric_limits<double>::min_exponent10 
         << " 到 10^" << numeric_limits<double>::max_exponent10 << endl;
}
```



### **特殊类型示例**

```c++
void special_limits() {
    using namespace std;
    
    cout << "\n=== 特殊类型限制 ===" << endl;
    
    // 字符类型
    cout << "char:" << endl;
    cout << "  是否有符号: " << numeric_limits<char>::is_signed << endl;  // 实现定义
    cout << "  是否是字符类型: " << numeric_limits<char>::is_integer << endl;
    
    // 布尔类型
    cout << "\nbool:" << endl;
    cout << "  是否是整数: " << numeric_limits<bool>::is_integer << endl;
    cout << "  最大值: " << numeric_limits<bool>::max() << endl;  // 1
    cout << "  最小值: " << numeric_limits<bool>::min() << endl;  // 0
    
    // 指针类型（通常未特化）
    cout << "\n指针类型是否有特化: " 
         << numeric_limits<int*>::is_specialized << endl;  // 通常是false
}
```



## 实际应用场景

### **场景1：安全数值运算**

```c++
#include <limits>
#include <type_traits>
#include <stdexcept>

template<typename T>
T safe_add(T a, T b) {
    static_assert(std::is_arithmetic<T>::value, "必须是算术类型");
    
    // 检查加法是否溢出
    if (a > 0 && b > 0) {
        if (a > std::numeric_limits<T>::max() - b) {
            throw std::overflow_error("加法溢出");
        }
    } else if (a < 0 && b < 0) {
        if (a < std::numeric_limits<T>::min() - b) {
            throw std::underflow_error("加法下溢");
        }
    }
    
    return a + b;
}

template<typename T>
T safe_multiply(T a, T b) {
    if (a == 0 || b == 0) return 0;
    
    // 检查乘法溢出
    if (a > 0 && b > 0) {
        if (a > std::numeric_limits<T>::max() / b) {
            throw std::overflow_error("乘法溢出");
        }
    } else if (a < 0 && b < 0) {
        if (a < std::numeric_limits<T>::max() / b) {
            throw std::overflow_error("乘法溢出");
        }
    } else {
        // 符号不同
        if (a < std::numeric_limits<T>::min() / b) {
            throw std::underflow_error("乘法下溢");
        }
    }
    
    return a * b;
}
```



### **场景2：通用数值算法**

```c++
#include <limits>
#include <cmath>
#include <type_traits>

// 计算数值类型的最大值
template<typename T>
constexpr T get_max_value() {
    return std::numeric_limits<T>::max();
}

// 检查浮点数是否有效
template<typename T>
bool is_valid_float(T value) {
    static_assert(std::is_floating_point<T>::value, 
                  "必须是浮点类型");
    
    if (std::numeric_limits<T>::has_infinity && 
        std::isinf(value)) {
        return false;  // 无穷大
    }
    
    if (std::numeric_limits<T>::has_quiet_NaN && 
        std::isnan(value)) {
        return false;  // NaN
    }
    
    return true;
}

// 获取类型的默认精度
template<typename T>
int get_default_precision() {
    if constexpr (std::is_integral_v<T>) {
        return 0;  // 整数没有小数精度
    } else if constexpr (std::is_floating_point_v<T>) {
        return std::numeric_limits<T>::digits10;
    } else {
        return 0;
    }
}
```



### **场景3：模板元编程中的类型选择**

```c++
#include <limits>
#include <type_traits>

// 根据数值范围选择类型
template<typename T>
auto get_larger_type() {
    if constexpr (std::numeric_limits<T>::max() < 1000) {
        return int{};
    } else if constexpr (std::numeric_limits<T>::max() < 1000000) {
        return long{};
    } else {
        return long long{};
    }
}

// 检查类型是否适合存储特定范围的值
template<typename T, typename U>
constexpr bool can_store_value(U value) {
    using limits = std::numeric_limits<T>;
    using ulimits = std::numeric_limits<U>;
    
    if constexpr (std::is_signed_v<T> == std::is_signed_v<U>) {
        // 符号相同
        return (value >= limits::min() && value <= limits::max());
    } else if constexpr (std::is_signed_v<T> && !std::is_signed_v<U>) {
        // T有符号，U无符号
        return (value <= static_cast<U>(limits::max()));
    } else {
        // T无符号，U有符号
        return (value >= 0 && value <= static_cast<U>(limits::max()));
    }
}
```



### **场景4：序列化和反序列化**

```c++
#include <limits>
#include <cstdint>
#include <stdexcept>

// 安全地将大类型转换为小类型
template<typename Dest, typename Src>
Dest safe_numeric_cast(Src value) {
    // 检查范围
    if (value < static_cast<Src>(std::numeric_limits<Dest>::min()) ||
        value > static_cast<Src>(std::numeric_limits<Dest>::max())) {
        throw std::overflow_error("数值转换溢出");
    }
    
    // 检查浮点数到整数的转换
    if constexpr (std::is_floating_point_v<Src> && 
                  std::is_integral_v<Dest>) {
        // 检查是否有小数部分
        Src int_part;
        Src frac_part = std::modf(value, &int_part);
        if (frac_part != 0.0) {
            throw std::runtime_error("浮点数有小数部分");
        }
    }
    
    return static_cast<Dest>(value);
}

// 网络字节序转换（确保在范围内）
template<typename T>
T network_to_host(T network_value) {
    // 假设network_value是从网络接收的
    // 首先检查是否在类型的有效范围内
    static_assert(std::is_arithmetic_v<T>, 
                  "必须是算术类型");
    
    // 对于有符号类型，确保值有效
    if constexpr (std::is_signed_v<T>) {
        // 实际实现中需要根据字节序转换
        // 这里只是演示范围检查
        if (network_value < std::numeric_limits<T>::min() ||
            network_value > std::numeric_limits<T>::max()) {
            throw std::runtime_error("网络数据超出类型范围");
        }
    }
    
    return network_value;  // 实际应进行字节序转换
}
```



### **场景5：数学库实现**

```c++
#include <limits>
#include <cmath>
#include <type_traits>

// 计算相对误差
template<typename T>
T relative_error(T actual, T expected) {
    static_assert(std::is_floating_point_v<T>, 
                  "必须是浮点类型");
    
    if (expected == T(0)) {
        // 处理零的情况
        return std::abs(actual);
    }
    
    T error = std::abs((actual - expected) / expected);
    
    // 处理溢出
    if (error > std::numeric_limits<T>::max()) {
        return std::numeric_limits<T>::infinity();
    }
    
    return error;
}

// 自适应精度比较
template<typename T>
bool almost_equal(T a, T b, T epsilon_multiplier = 1) {
    static_assert(std::is_floating_point_v<T>, 
                  "必须是浮点类型");
    
    // 使用机器epsilon作为基础精度
    T epsilon = std::numeric_limits<T>::epsilon() * epsilon_multiplier;
    
    // 处理接近零的情况
    if (std::abs(a - b) <= epsilon) {
        return true;
    }
    
    // 相对误差比较
    T abs_a = std::abs(a);
    T abs_b = std::abs(b);
    T diff = std::abs(a - b);
    
    if (a == 0 || b == 0 || diff < epsilon) {
        return diff < (epsilon * epsilon);
    }
    
    return diff / (abs_a + abs_b) < epsilon;
}
```



## C++17/20新特性

### **变量模板（C++17）**

cpp

```c++
// C++17引入的变量模板，更方便
#include <limits>

template<typename T>
constexpr bool is_bounded = std::numeric_limits<T>::is_bounded;

template<typename T>
constexpr T max_value = std::numeric_limits<T>::max();

// 使用示例
static_assert(max_value<int> == 2147483647);  // 通常值
static_assert(is_bounded<int> == true);
```



### **概念约束（C++20）**

cpp

```c++
#include <concepts>
#include <limits>

// 约束只接受算术类型
template<std::floating_point T>
T compute_epsilon_multiple(T multiplier) {
    return std::numeric_limits<T>::epsilon() * multiplier;
}

// 约束只接受有界类型
template<typename T>
concept BoundedType = std::numeric_limits<T>::is_bounded;

template<BoundedType T>
T get_midpoint() {
    return (std::numeric_limits<T>::max() + 
            std::numeric_limits<T>::min()) / 2;
}
```



## 最佳实践

1. **编译时检查**：使用`static_assert`进行编译时验证
2. **类型安全**：结合`type_traits`确保类型正确
3. **异常处理**：数值操作时检查边界
4. **性能考虑**：编译时计算优于运行时
5. **可移植性**：不要假设特定数值大小

## 重要注意事项

- `min()`对整数返回最小值，对浮点数返回**正规范化最小值**
- `lowest()`（C++11）对所有类型都返回最小负值
- `digits`：整数是值位数量，浮点数是尾数位数
- `epsilon`：1与大于1的最小值之差，不是最小正数
- 特化检查：使用`is_specialized`检查类型是否有特化

`std::numeric_limits`是编写健壮、可移植数值代码的重要工具，特别适用于模板编程和数值计算。







# constexpr

`constexpr`（constant expression，常量表达式）是一个极其强大的工具。简单来说，它的核心思想是：**“如果一件事可以在编译期间完成，就不要留到运行期间去做。”**

通过将计算过程从“运行阶段”提前到“编译阶段”，`constexpr` 不仅能提升程序性能，还能让代码更加安全。

------

## 1. `constexpr` 的核心概念

在 `constexpr` 出现之前，我们主要依靠宏（`#define`）或 `const` 来定义常量。但它们都有局限性。`constexpr` 的出现，正式让“编译期计算”成为了语言的一等公民。

### `const` vs `constexpr`

这是初学者最容易混淆的地方。

- **`const`**：表示“只读”。它保证变量在初始化后不会被修改，但它的值**不一定**在编译期就知道（比如 `const int pulse = get_heart_rate();`）。
- **`constexpr`**：表示“常量表达式”。它不仅是只读的，而且其值**必须**在编译期就能确定。

| **特性**               | **const**        | **constexpr**                      |
| ---------------------- | ---------------- | ---------------------------------- |
| **语义**               | 只读 (Read-only) | 编译期常量 (Compile-time constant) |
| **初始化时机**         | 运行时或编译时   | 必须在编译时                       |
| **是否可用于模板参数** | 仅当其值已知时   | 总是可以                           |

------

## 2. `constexpr` 变量

当你声明一个变量为 `constexpr` 时，你是在告诉编译器：“去算一下这个值，然后把它硬编码进程序里。”

```c++
constexpr int max_users = 100;          // 正确
constexpr int buffer_size = max_users * 2; // 正确，编译期算出是 200

int limit = 10;
// constexpr int error_val = limit;     // 错误！limit 是运行时变量，编译器不知道它是多少
```

------

## 3. `constexpr` 函数

这是 `constexpr` 最出彩的地方。它允许你编写看起来像普通函数、但在编译期运行的逻辑。

### 基本规则：

1. **参数和返回值**：必须都是字面值类型（Literal Types）。
2. **函数体**：在 C++11 中非常严格（只能有一条 `return` 语句），但在 C++14 及之后版本中，你可以使用循环、`if` 分支和局部变量。

```c++
constexpr int factorial(int n) {
    int res = 1;
    for (int i = 1; i <= n; ++i) {
        res *= i;
    }
    return res;
}

// 在编译期就会被替换为 120
int arr[factorial(5)]; 
```

> **注意**：`constexpr` 函数非常聪明。如果你给它传递的是编译期常量，它就在编译期执行；如果你给它传递的是运行时变量，它就会退化成一个普通的运行时函数。

------

## 4. `if constexpr` (C++17)

这是泛型编程（Template Programming）的救星。它允许编译器根据条件直接“丢弃”掉不符合条件的代码块。

在没有 `if constexpr` 之前，我们需要写大量的模板特化（Template Specialization）。现在：

```c++
template <typename T>
void process(T value) {
    if constexpr (std::is_integral_v<T>) {
        // 如果 T 是整数，编译这段
        std::cout << "Processing integer: " << value << std::endl;
    } else {
        // 否则编译这段
        std::cout << "Processing other type" << std::endl;
    }
}
```

------

## 5. constexpr的优势

1. **性能巅峰**：运行时的计算量变成了零。对于嵌入式开发或高性能计算来说，这是刚需。
2. **更早报错**：如果你的逻辑有误，编译器在编译阶段就会报错，而不是等到程序跑起来崩溃了你才去找 Bug。
3. **ROM 友好**：在嵌入式系统中，`constexpr` 定义的常量通常可以直接存放在只读存储器（ROM）中，节省 RAM。

------

## 6. 进阶：C++20 的增强

在 C++20 中，`constexpr` 的版图进一步扩大：

- **`consteval`**：强制函数必须在编译期执行。如果无法在编译期执行，直接报错（不再像 `constexpr` 那样可以退化）。
- **`constinit`**：强制变量必须在编译期初始化，但之后它是可以修改的（主要解决“全局变量初始化顺序”的问题）。
- **动态内存分配**：现在可以在 `constexpr` 环境下使用 `std::vector` 和 `std::string` 了（虽然有生命周期限制）。

------

### 总结一下

如果确定一个逻辑在编写代码时就已经定死了，那么可以直接加上 `constexpr`。`constexpr`将计算在编译器提前完成，减少了程序运行时消耗。







# 内存对齐

在 C++ 中，**内存对齐（Memory Alignment）**是一个让初学者感到困惑，但对底层性能和硬件兼容性至关重要的概念。

简单来说，内存对齐就是将数据存放在内存地址为某个值（通常是 2、4 或 8）的倍数的地方。这并不是为了浪费内存，而是为了让 CPU 跑得更快。

------

## 1. 为什么要内存对齐？

你可能会认为内存是一个字节一个字节组成的“长跑道”，CPU 可以随意访问任何位置。但实际上，CPU 访问内存是**“成块”**读取的（通常是 4 字节或 8 字节，称为一个 **Word**）。

- **性能提升：** 如果一个 `int`（4 字节）存储在地址 0。CPU 一次读取就能把它取出来。如果它跨在了地址 3 和 4 之间，CPU 可能需要进行两次内存访问，再通过移位和合并操作才能拿到完整数据。
- **硬件限制：** 某些架构（如某些 ARM 或 MIPS）甚至不支持非对齐访问，强行读取会导致程序崩溃（Bus Error）。

------

## 2. 核心规则

内存对齐遵循两个主要原则：

1. **成员对齐规则：** 结构体中的第一个成员放在偏移量为 0 的地方。以后的每个成员，都要存放在**它自己对齐要求**（通常是其类型大小）的整数倍地址上。
2. **结构体整体对齐规则：** 结构体的总大小，必须是其**最大成员对齐要求**的整数倍。如果不够，编译器会在末尾填充（Padding）。

------

## 3. 实战案例对比

让我们看看不同的成员顺序如何影响内存占用：

### 案例 A：未优化的布局

```c++
struct BadStruct {
    char a;     // 1 字节
    // 填充 3 字节 (为了让 b 在 4 的倍数地址上)
    int b;      // 4 字节
    char c;     // 1 字节
    // 填充 3 字节 (为了让整体大小是最大成员 int 的倍数，即 4 的倍数)
};
// sizeof(BadStruct) = 12
```

### 案例 B：优化后的布局

如果我们把小的变量放在一起：

```c++
struct GoodStruct {
    int b;      // 4 字节
    char a;     // 1 字节
    char c;     // 1 字节
    // 填充 2 字节 (为了让整体大小是 4 的倍数)
};
// sizeof(GoodStruct) = 8
```

**结论：** 仅仅改变成员顺序，内存占用就减少了 $33\%$。

------

## 4. C++11 及以后的现代工具

现代 C++ 提供了直接操作对齐的关键字：

- **`alignof(type)`**：查询类型的对齐要求。
- **`alignas(n)`**：强制要求某个变量或结构的对齐方式。

```c++
struct alignas(16) MyCacheLine {
    int x;
};
// 即使只有一个 int，这个结构体的大小也会被强制设为 16 字节。
```

------

## 5. 强制改变对齐（编译器指令）

有时候在编写网络协议或处理二进制文件格式时，我们需要“禁用”对齐，让数据紧凑排列。这通常使用编译器特定的指令：

- **GCC/Clang:** `__attribute__((packed))`
- **MSVC (Visual Studio):** `#pragma pack(push, 1)`

| **指令**          | **效果**                                             |
| ----------------- | ---------------------------------------------------- |
| **默认**          | 速度快，空间可能有浪费。                             |
| **Packed (紧凑)** | 空间利用率最高，但访问速度变慢，且可能引发硬件异常。 |

------

## 总结

内存对齐是 **“空间换时间”** 的经典权衡。作为开发者，你不需要手动去计算每个字节的偏移，但**养成“将相同类型的变量放在一起”或“按大小降序排列成员”的习惯**，能无形中优化程序的内存足迹。







# final的作用

在 C++ 中，`final` 是 C++11 引入的一个**说明符（Specifier）**。虽然我们常称之为“关键字”，但它在技术上是“上下文相关”的，这意味着它仅在特定位置才有特殊含义，在其他地方（如变量名）仍可使用。

`final` 的主要作用有两个：**防止类被继承** 和 **防止虚函数被重写**。

------

## 1. 禁用类继承 (Final Classes)

当你希望一个类作为继承树的终点，不允许任何其他类继承它时，可以在类名后面加上 `final`。

### 语法：

```C++
class 类名 final {
    // ...
};
```

### 示例：

```C++
class Base {
    virtual void doSomething() {}
};

class Derived final : public Base {
    // Derived 类被标记为 final，不能再被继承
};

// 编译错误：无法从 'Derived' 继承
// class DeeplyDerived : public Derived {}; 
```

**使用场景：**

- **设计意图：** 明确告知其他开发者，这个类不应该被扩展。
- **性能优化：** 编译器知道该类没有子类，在某些情况下可以进行“去虚拟化”（Devirtualization）优化。

------

## 2. 禁用虚函数重写 (Final Methods)

如果你希望某个虚函数在当前的派生类中是最后一个版本，不允许其子类再次重写该函数，可以在函数声明的括号后加上 `final`。

### 语法：

```C++
virtual 返回类型 函数名(参数) final;
```

### 示例：

```C++
class A {
public:
    virtual void func() { cout << "A::func" << endl; }
};

class B : public A {
public:
    // 使用 final 明确表示：B 之后的子类不能再重写 func
    void func() override final { cout << "B::func" << endl; }
};

class C : public B {
public:
    // 编译错误：重写了被声明为 final 的虚函数
    // void func() override { cout << "C::func" << endl; }
};
```

**使用场景：**

- **逻辑锁定：** 当你实现了一个复杂的算法逻辑，并认为子类不应更改其核心行为时。
- **安全性：** 防止意外重写导致基类契约被破坏。

------

## 3. 核心细节与注意事项

### A. 必须是虚函数

`final` 只能用于 `virtual` 函数。如果你尝试在非虚函数上使用 `final`，编译器会报错。

### B. 配合 `override` 使用

在重写函数时，建议同时使用 `override` 和 `final`（如 `void func() override final`）。

- `override` 确保你确实是在重写基类的函数（防止拼写错误或参数不匹配）。
- `final` 确保你的子类不能再动它。

### C. 上下文相关性 (Context-sensitive)

`final` 不是保留关键字。这意味着你依然可以定义名为 `final` 的变量（虽然极其不推荐）：

```C++
int final = 10; // 合法，但不建议
```

### D. 性能优势：去虚拟化 (Devirtualization)

这是 `final` 在底层的一个重要贡献。

在通常情况下，通过指针或引用调用虚函数需要查虚函数表（Vtable）。但如果编译器发现对象类型被标记为 `final`，或者调用的函数被标记为 `final`，它就能确定**不可能存在更深层的重写**。

这时，编译器可以将“动态绑定”转化为“静态绑定”，甚至直接将函数**内联（Inline）**，从而显著提升性能。

------

## 4. 总结对比

| **用途**              | **放置位置**                       | **效果**                   |
| --------------------- | ---------------------------------- | -------------------------- |
| **类 (Class)**        | 类名之后                           | 禁止该类被任何其他类继承   |
| **虚函数 (Function)** | 函数签名之后 (const/override 之后) | 禁止该函数在派生类中被重写 |

**一句话总结：** `final` 是为了给继承体系“封顶”，无论是为了架构设计的安全性，还是为了运行时的性能优化。





# placement new

在 C++ 中，**placement new**（定位映射 `new`）是一个进阶特性。简单来说，普通的 `new` 是“找一块地皮并盖房子”，而 `placement new` 则是“在你已经买好的地皮上盖房子”。

它是 C++ 标准库的一部分（在 `<new>` 头文件中定义），允许你在**已经分配好的内存基地址上**构造对象。

------

## 1. 核心原理：普通 `new` vs Placement `new`

要理解 `placement new`，首先要拆解普通 `new` 的操作。执行 `T* ptr = new T();` 时，编译器实际上做了两件事：

1. **分配内存**：调用 `operator new` 在堆上分配足够大小的原始内存。
2. **调用构造函数**：在分配的内存上初始化对象。

**Placement new** 略过了第一步，直接执行第二步。

### 语法

C++

```
#include <new> // 必须包含此头文件

new (address) Type(arguments);
```

- `address`：一个指向预先分配好的内存的指针。
- `Type`：要创建的对象类型。
- `arguments`：传递给构造函数的参数。

------

## 2. 使用步骤与代码示例

使用 `placement new` 时，内存的管理完全由程序员负责。

### 示例代码：

C++

```
#include <iostream>
#include <new>      // placement new
#include <string>

class Task {
public:
    Task(std::string name) : m_name(name) { std::cout << "构造任务: " << m_name << std::endl; }
    ~Task() { std::cout << "析构任务: " << m_name << std::endl; }
private:
    std::string m_name;
};

int main() {
    // 1. 预先分配原始内存 (可以是栈空间、堆空间甚至是硬件地址)
    char buffer[sizeof(Task)];

    // 2. 在 buffer 上使用 placement new 构造对象
    Task* tPtr = new (buffer) Task("CleanRoom");

    // 3. 使用对象
    // ...

    // 4. 重要：必须手动调用析构函数！
    // 因为 placement new 没有配套的 'delete'
    tPtr->~Task();

    // 5. 如果内存是动态分配的（如 malloc），还需要释放内存
    return 0;
}
```

------

## 3. 为什么要用 Placement new？

既然普通的 `new` 更好用，为什么还要折腾这个？

### A. 性能优化 (Memory Pooling)

在高性能系统中，频繁地在堆上申请/释放内存（`malloc`/`free`）非常耗时。你可以预先申请一大块内存（内存池），然后使用 `placement new` 在其中快速创建对象，避免了系统调用的开销。

### B. 硬件驱动编程

在嵌入式开发中，某些硬件寄存器或特定的内存区域映射到固定的地址。你可以直接在这些特定的地址上构造对象来操作硬件。

### C. 容器实现 (如 `std::vector`)

`std::vector` 的底层实现就大量使用了 `placement new`。

当 `vector` 扩容时，它会先申请一大块原始内存（不调用构造函数）。只有当你真正 `push_back` 一个元素时，它才会在预留的位置上用 `placement new` 构造对象。

------

## 4. 致命陷阱（使用注意事项）

使用 `placement new` 就像是手持利刃，威力大但也容易伤到自己：

1. **手动析构**：普通的 `delete` 会尝试释放内存。但 placement new 的内存不是它申请的，所以**绝对不能对它使用 `delete`**。你必须显式调用析构函数 `ptr->~Type()`。
2. **内存对齐 (Alignment)**：这是最容易忽视的一点。你提供给 `placement new` 的地址必须符合类型的对齐要求。例如，在某些架构上，`int` 必须起始于 4 的倍数地址。如果地址不对齐，程序可能会崩溃或性能大幅下降。
   - *提示：可以使用 `std::aligned_storage` 来声明对齐的缓冲区。*
3. **缓冲区大小**：你必须确保提供的内存空间足够大，至少等于 `sizeof(Type)`。

------

## 5. 总结对比

| **特性**     | **普通 new**                 | **Placement new**          |
| ------------ | ---------------------------- | -------------------------- |
| **分配内存** | 自动分配（堆）               | 使用提供的现有地址         |
| **构造对象** | 自动调用构造函数             | 自动调用构造函数           |
| **销毁对象** | `delete` (自动析构+释放内存) | **手动显式调用析构函数**   |
| **内存释放** | 自动释放                     | **手动释放**（如果需要）   |
| **适用场景** | 常规开发                     | 内存池、嵌入式、高性能开发 |

**一句话总结：** `placement new` 给了你“在指定位置初始化对象”的精细控制权，但代价是你必须亲自接管对象的生命周期和内存对齐。
