---
layout: post
title:  "Capture structure bindings in C++17"
date:   2021-04-19 22:04:10 +0200
tags:   c++17 structured_binding lambda capture
i18n:   2021-04-19_structured_binding_lambda_capture
---
C++17 introduced a handy construct called *structured binding*:

{% highlight cpp %}
const auto [first, second] = std::make_tuple(1,2);
{% endhighlight %}

Structured bindings are used to decompose arrays and structs/classes [^1] to named subobjects. Almost any object with non-*static*, accessible data members can be destructured this way. It works even for *bit-field*s:

{% highlight cpp %}
struct BF {
  int x : 2;
};
const auto bf (BF{1});
const auto& [y] = bf;
{% endhighlight %}

Resulting aliases (`first`, `second` and `y` in the examples above) are actually not mere variables but rather *identifiers* or *aliases*.

This may feel unintuitive but there actually is a case when we cannot use these *aliases* as other variables. According to [this][cpp17-wd-n4713] C++ Language Standard working draft we cannot use *structured bindings* in lambda capture list:

> If a *lambda-expression* explicitly captures an entity that is not odr-usable or captures a structured binding (explicitly or implicitly), the program is  **ill-formed**.

(emphasis mine). That means following code is illegal:

{% highlight cpp %}
auto [a, b, c] = std::make_tuple(1, 3, 7);
auto d = [b] { return b; }();
{% endhighlight %}

It actually works on gcc (10.3) and msvc (v19.28) but fails on clang (12.0.0):

> error: 'b' in capture list does not name a variable

This restriction does not apply for *init-captures*, which is reasonable as with *init-captures* there is a new variable defined that is captured and this variable is no longer the *structure binding*, so this compiles well in clang, gcc and msvc:

{% highlight cpp %}
auto [a, b, c] = std::make_tuple(2, 7, 2);
auto d = [&b = b] { return b; }();
{% endhighlight %}

The standard got reworded along the way and in C++ 20 final working draft the restriction is no longer there. But clang still fails, even with `-std=c++20`, while gcc and msvc are still fine with simple capture of the *structured binding*. I feel way more comfortable with gcc and msvc way as there is no need to provide special construct only to capture a single value.

<details markdown="1" style="margin-bottom:16px">
<summary>Interesting resources</summary>
- [C++ Language Standard working draft N4713][cpp17-wd-n4713] (2017-11-27)
- [C++20 Language Standard final working draft N4861][cpp20-wd-n4861] (2020-04-01)
- [Why structured bindings can't declare variables?](https://www.reddit.com/r/cpp_questions/comments/e1ralf/why_structured_bindings_cant_declare_variables/) a Reddit post
- [Lambda implicit capture fails with variable declared from structured binding](https://stackoverflow.com/questions/46114214/lambda-implicit-capture-fails-with-variable-declared-from-structured-binding) Stack overflow thread
- [Reference capture of structured bindings: a Public Proposal](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p1381r1.html) (2019-02-22)
- [Changes between C++17 and C++20 DIS](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2020/p2131r0.html) "Improvements for structured bindings" listed here (2020-03-02)
- [A brief introduction to C++ structured binding](https://devblogs.microsoft.com/oldnewthing/20201014-00/?p=104367) by Raymond on [devblogs.microsoft.com](https://devblogs.microsoft.com)
</details>


[^1]: There is a difference in handling *tuple*-like structs and other structs. You can check [this reference][cppref_sb] for more details.

[cppref_sb]: https://en.cppreference.com/w/cpp/language/structured_binding
[cpp17-wd-n4713]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2017/n4713.pdf
[cpp20-wd-n4861]: http://open-std.org/jtc1/sc22/wg21/docs/papers/2020/n4861.pdf
