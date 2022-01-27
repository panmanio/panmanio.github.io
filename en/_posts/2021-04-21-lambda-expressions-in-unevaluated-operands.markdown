---
layout: post
title:  "Lambda expressions in unevaluated operands"
date:   2021-04-21 20:46:06 +0200
tags:   c++ c++17 c++20 lambda typeid decltype declval sizeof requires unevaluated
i18n:   2021-04-21_lambda_expressions_in_unevaluated_operands
---
While writing some unit tests today I have run into a compile issue:

> error: lambda expression in an unevaluated operand

I was astonished at first as I've just scratched a simple test case that was not using unevaluated operands. But what are unevaluated operands?

They are literally operands that are not evaluated 😄. They appear in the context of:

- typeid operator (not always [^1])
- sizeof operator
- noexcept operator
- decltype specifier
- require-expressions
- constraint-expressions

There is also `declval` function template that can only be used in unevaluated context.

Unevaluated operands are processed at compile time. What does it mean they are not evaluated? Let's come up with some examples.

```cpp
#include <iostream>
#include <typeinfo>

struct S {
    S() { std::cout << "S()" << std::endl; }
    int fn() {
        std::cout << "S::fn()" << std::endl;
        return 0;
    }
};

template <typename T>
constexpr bool predicate() {
    return true;
}

template <>
constexpr bool predicate<double>() {
    return false;
}

template <typename T>
T fn() requires(predicate<T>()) {
    std::cout << "fn<T>() true branch" << std::endl;
    return T{};
}

template <typename T>
T fn() requires(!predicate<T>()) {
    std::cout << "fn<T>() false branch" << std::endl;
    return T{};
}

int check() {
    constexpr auto x = decltype(fn<int>()){};
    if (typeid(S{}.fn()) == typeid(x) && sizeof(0.) == sizeof(fn<double>())) {
        return x;
    }
    return 1;
}

int main() { return check(); }
```

Above code prints nothing when executed: that means none of `S::S()`, `S::fn()` and `fn<T>()` were invoked. The predicates are also not evaluated.

Fair enough, what was the issue with my unit test? I was trying to count items in a vector using a lambda predicate:

```cpp
EXPECT_EQ(std::count_if(begin(data), end(data),
                        [](const auto& d) { return !d.children.empty(); }),
          13);
```

The thing is gtest's `EXPECT_EQ` macro performs some checks and it has put the count_if in a `sizeof`, but lambda-expressions are not allowed in unevaluated operands up to C++17. Starting from C++20 the limitation is no longer there. Since my project is not yet switched to C++20, I chose a simple fix:

```cpp
const auto count = std::count_if(begin(data), end(data), [](const auto& d) {
    return !d.children.empty();
});
EXPECT_EQ(13, count);
```

I've also reordered the arguments because it has an impact on the error message when the expectation fails: first argument is the expected one, second is the actual one.

Out of curiosity I have checked if I can use lambda in unevaluated context in recent versions of clang (12.0.0), gcc (10.3) and msvc (v19.28):

```cpp
void unevaluated_lambda() {
    decltype([]{}) x;
    (void) x;
    decltype([]{ return 0; }()) y;
    (void) y;
}
```

Clang complains with the same error: *lambda expression in an unevaluated operand*. The code compiles with gcc and msvc.


[^1]: When typeid is used with an object of polymorphic type, its operand is evaluated.
