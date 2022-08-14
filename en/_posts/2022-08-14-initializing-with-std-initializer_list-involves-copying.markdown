---
layout: post
title: "Initializing with std::initializer_list involves copying"
date: 2022-08-14 17:44:02 +0200
tags: c++17 initializer_list vector memory heap
i18n: 2022-08-14_initializing_with_std_initializer_list
---

A convenient way to initialize STL containers is to use a initializer list, like this:

```cpp
auto data = std::vector<std::string>{"example", "input", "data"};
```

There's a caveat: the arguments of the vector constructor are first constructed and then copied. It's a trait of `std::initializer_list`. It may become an issue when the parameters are not trivially copyable because they handle some resources etc. Short strings are not an issue as they should be handled with small-string optimization, but long ones (it depends on the compiler implementation which ones are small and which aren't) will need three memory allocations: one during string creation, the second one for the vector item and the third one for the copy.

```cpp
auto data = std::vector<std::string>{
    "long string that will likely be allocated on the heap"
}; // three memory allocations
```

Let's write a test program that traces the number of memory allocations:

```cpp
void* operator new (std::size_t count) {
    std::cout << "new " << count << " bytes\n";
    return std::malloc(count);
}

int main() {
    std::cout << "Vector with small string:\n";
    auto data = std::vector<std::string>{"small string"};
    std::cout << "\nVector with long string:\n";
    data = std::vector<std::string>{
        "long string that will likely be allocated on the heap"
    };
}
```

I've compiled it with g++ 9.4.0 with the optimizations on: `g++ test.cpp --std=c++17 -O2 -o test`. The output of the program execution is:

```shell
./test
Vector with small string:
new 32 bytes

Vector with long string:
new 56 bytes
new 32 bytes
new 56 bytes
```

We can see here that for the small string std::vector has allocated 32 bytes, which is the size of `std::string`. Creating the vector that handles long string involves 3 memory allocations: the first one comes from the construction of the parameter, the second one is the allocation of the memory for `std::string` inside the vector and the last one is the copy of our parameter.

To get rid of the copy we have to avoid `std::initializer_list`. Let's write a `make_vector` function instead. My draft looks like this:

```cpp
template <typename T, typename... U>
std::vector<std::decay_t<T>> make_vector(T&& arg, U&&... args) {
    auto result = std::vector<std::decay_t<T>>{};
    result.reserve(1 + sizeof...(args));
    result.emplace_back(std::forward<T>(arg));
    (result.emplace_back(std::forward<U>(args)), ...);
    return result;
}
```

Now the parameters won't be copied because they are forwarded to the `emplace_back` method which constructs them in place. An important thing is to allocate the memory for all the parameters at once using `reserve` method, otherwise we save the copy allocations but add redundant allocations for vector items.

Let's tweak the test program:

```cpp
int main() {
    std::cout << "String size: " << sizeof(std::string) << "\n";
    std::cout << "\nVector with small string:\n";
    auto data = std::vector<std::string>{"short vector"};
    std::cout << "\nVector with a long string:\n";
    data = std::vector<std::string>{
        "a long string that will likely be allocated on the heap"};
    using namespace std::literals;
    std::cout << "\nmake_vector with a long string:\n";
    data = make_vector(
        "a long string that will likely be allocated on the heap"s);
    std::cout << "\nVector with two long strings:\n";
    data = std::vector<std::string>{
        "a long string that will likely be allocated on the heap",
        "another long string that will likely be allocated on the heap"};
    using namespace std::literals;
    std::cout << "\nmake_vector, two long strings:\n";
    data = make_vector(
        "a long string that will likely be allocated on the heap"s,
        "another long string that will likely be allocated on the heap"s);
}
```

The output looks better now, I've added comments for the explanation:

```shell
String size: 32

Vector with small string:
new 32 bytes # vector item (sizeof std::string)

Vector with a long string:
new 56 bytes # the argument
new 32 bytes # the vector item
new 56 bytes # argument copy

make_vector with a long string:
new 56 bytes # the string argument
new 32 bytes # the vector item

Vector with two long strings:
new 56 bytes # the first argument
new 62 bytes # the second argument
new 64 bytes # memory for two vector items
new 56 bytes # copy of the 1st argument
new 62 bytes # copy of the 2nd argument

make_vector, two long strings:
new 62 bytes # the second argument
new 56 bytes # the first argument
new 64 bytes # memory for two vector items
```

The strings are not copied anymore when `make_vector` is used.
