---
layout: post
title: "Enabling structured binding for std::complex (and custom non-POD types)"
date: 2022-08-09 23:59:01 +0200
tags: c++17 structured_binding complex
i18n: 2022-08-09_structured_binding_for_std_complex
---

The father of C++, Bjarne Stroustrup, mentions in _A Tour of C++_ that it's possible to use structured binding declaration with `std::complex`, which is a non-POD type (it encapsulates the data attributes, values are obtained with `real()` and `imag()` method calls). As of today it actually does not work for `std::complex` (checked with the [Compiler Explorer](https://godbolt.org)), also the [WG21 standard working draft](https://eel.is/c++draft/) does not mention that ability of `std::complex`. But it is possible to make it work by making `std::complex` a __tuple-like__ type by incorporating these rules (see [structured binding](https://eel.is/c++draft/dcl.struct.bind#4)):

* `std::tuple_size<std::complex<T>>::value` should be an integer constant expression denoting the number of identifiers that are part of the structured binding,
* for each identifier an expression `std::tuple_element<i, std::complex<T>>::type`, where `i` is the constant expression identifier index, should be the identifiers types,
* for each identifier, the function `get<i>(c)`, where `i` is the constant expression identifier index, and `c` is the complex object, should provide the value of the identifiers

We simply need to extend the `std` namespace and provide all ingredients.

```cpp
namespace std {
    template<typename T>
    class tuple_size<complex<T>> {
    public:
        static constexpr size_t value = 2;
    };
    template<size_t I, typename T>
    auto get(const complex<T>& c) {
        if constexpr (I == 0) return c.real();
        return c.imag();
    }
    template <size_t I, typename T>
    class tuple_element<I, complex<T>> {
    public:
        using type = decltype(get<I>(declval<complex<T>>()));
    };
}
```

Now this works nicely:

```cpp
auto c = std::complex<int>{1,1};
auto [r, i] = c + 2;
```

Similarly for a custom type:

```cpp
template <typename X, typename Y>
class NonPOD {
    X x;
    Y y;
public:
    NonPOD(X x, Y y): x{x}, y{y} {}
    X getX() const { return x; }
    Y getY() const { return y; }
};

namespace std {
template <size_t I, typename Arg, typename ...Args>
class type_alternatives {
public:
    using type = typename type_alternatives<I-1, Args...>::type;
};

template <typename Arg, typename ...Args>
class type_alternatives<0, Arg, Args...> {
public:
    using type = Arg;
};

template <size_t I, typename X, typename Y>
class tuple_element<I, NonPOD<X, Y>> {
public:
    using type = typename type_alternatives<I, X, Y>::type;
};
} // namespace std

template <size_t I, typename X, typename Y>
typename std::tuple_element<I, NonPOD<X, Y>>::type
get(const NonPOD<X, Y>& t) {
    if constexpr (I == 0) return t.getX();
    return t.getY();
}

auto test() {
 auto sb = NonPOD{1, 2.};
 auto [s, b] = sb;
 return s+b;
}
```

In our own types we can define a member `get<i>()` method instead of standalone `get<i>(obj)`.


Side note: there is an interesting property of std::complex&lt;T&gt;:
> [4](https://eel.is/c++draft/complex.numbers#general-4)
> If z is an lvalue of type cv complex<T> then:
>
>    [(4.1)](https://eel.is/c++draft/complex.numbers#general-4.1)
> the expression reinterpret_cast<cv T(&)[2]>(z) is well-formed,
>
>    [(4.2)](https://eel.is/c++draft/complex.numbers#general-4.2)
> reinterpret_cast<cv T(&)[2]>(z)[0] designates the real part of z, and
>
>    [(4.3)](https://eel.is/c++draft/complex.numbers#general-4.3)
> reinterpret_cast<cv T(&)[2]>(z)[1] designates the imaginary part of z[.](https://eel.is/c++draft/complex.numbers#general-4.sentence-1)

That means we could simply cast:

```cpp
auto c = std::complex<int>{1,1};
auto [r, i] = reinterpret_cast<int(&)[2]>(c);
```

Better not use it with a temporary though.
