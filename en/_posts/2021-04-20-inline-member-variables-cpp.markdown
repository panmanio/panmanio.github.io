---
layout: post
title:  "Inline member variables in C++"
date:   2021-04-20 22:28:05 +0200
tags:   c++17 inline
i18n:   2021-04-20_inline_member_variables_cpp
---
Say we need a class member variable (non-const). Global variables should be best avoided, but let's ignore that for now and focus on the solution.

This is a bad choice most often:

{% highlight cpp %}
struct S {
    static int i;
};

// somewhere in cpp file:
int S::i = 0;
{% endhighlight %}

The definition (`int S::i = 0;`) needs to be placed in a single translation unit in the whole project, otherwise we get an error indicating multiple definition of `S::i`.

In pre-C++17 world we need to find some workaround of this problem. One way is to go with a static member function:

{% highlight cpp %}
struct S {
    static int& getStatic() {
        static int i = 0;
        return i;
    }
};

// sample use: ++S::getStatic();
{% endhighlight %}

Another way is to use templates:

{% highlight cpp %}
template <typename T>
struct S
{
    static int i;
};

template <typename T>
int S<T>::i = 0;

using static_instance = S<void>;
// sample use: ++static_instance::i;
{% endhighlight %}

That makes a lot of boilerplate and obscure code. Our problem is solved by *inline variables* in C++17. That looks simple and serves well:

{% highlight cpp %}
struct S {
    static inline int i = 0;
};

// sample use: ++S::i;
{% endhighlight %}

The *inline variable* has an *external linkage* if our class is not inside an *unnamed namespace* (i.e. when the class has *external linkage* too). It enables the possibility of more than one definition of the variable (hence no *multiple definition* errors). The variable must be declared *inline* in all the translation units and it always has the same memory address. All the definitions have to be identical, otherwise we break *one definition rule*. That may lead to hard to detect problems if we are not cautious.


{% highlight cpp %}
// one translation unit file, S has external linkage
struct S {
    static inline int i = 3;
};

// another translation unit, S has external linkage
struct S {
    static inline double i = 3.14159;
};

{% endhighlight %}

The code in the example above is invalid, but it compiles and can behave unexpectedly.

Static *constexpr* members are *inline* by default.

<details markdown="1" style="margin-bottom:16px">
<summary>Interesting resources (click to expand)</summary>
- [inline specifier](https://en.cppreference.com/w/cpp/language/inline) on [en.cppreference.com](https://en.cppreference.com)
- [How to initialize static members in the header](https://stackoverflow.com/questions/18860895/how-to-initialize-static-members-in-the-header) on [stackoverflow.com](https://stackoverflow.com)
- [How do inline variables work](https://stackoverflow.com/questions/38043442/how-do-inline-variables-work) on [stackoverflow.com](https://stackoverflow.com)
</details>

Comments on [dev.to](https://dev.to/maniowy/inline-member-variables-in-c-38a6).
