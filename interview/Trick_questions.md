# Java Trick Questions — Interview Notes

---

## Key Concepts

- **Trick questions** target assumptions candidates carry from other languages or from surface-level Java knowledge. The correct answer is almost always "it depends" or "not exactly".
- Java sits at the intersection of compiled and interpreted execution, object-oriented and procedural style, value and reference semantics — each a common source of confusion.
- Understanding **why** the answer is what it is (JVM spec, language spec, JLS) is what separates a senior answer from a junior answer.

---

## How It Works (Internals / Mechanics)

### Compilation + Execution Pipeline
```
.java source
    ↓  javac (compiler)
.class bytecode  ← platform-independent
    ↓  JVM (interpreter + JIT)
Native machine code  ← platform-specific, generated at runtime
```
- `javac` compiles to **bytecode**, not native code → Java is **compiled**.
- The JVM interprets bytecode and the JIT recompiles hot paths to native code → Java is also **interpreted** (and JIT-compiled).
- Correct answer: **"Both — compiled to bytecode, then interpreted/JIT-compiled at runtime."**

### Pass-by-Value Mechanics
```
int x = 5;          →  copy of 5 passed         (primitive)
Dog d = new Dog();  →  copy of reference passed  (object)
                        ↑ same object on heap, different variable
```
- Java always passes a **copy of the bits in the variable**.
- For primitives: copy of the value. For objects: copy of the reference (pointer).
- Reassigning the parameter inside a method never affects the caller's variable. Mutating the object the reference points to **does** affect the caller.

### String Pool & `==` vs `.equals()`
```
String a = "hello";          // points to pool entry
String b = "hello";          // same pool entry → a == b is TRUE
String c = new String("hello"); // new heap object → a == c is FALSE
```
- String literals are interned automatically. `new String(...)` always creates a new heap object.

---

## Common Pitfalls & Edge Cases

- **`null` method calls** — calling a **static** method via a null reference compiles and runs without `NullPointerException` because the compiler resolves the method at compile time from the declared type, not the runtime value.
- **Integer cache** — `Integer.valueOf(127) == Integer.valueOf(127)` is `true` (cached range −128 to 127); `Integer.valueOf(128) == Integer.valueOf(128)` is `false`. Using `==` on `Integer` objects is a trap.
- **`finally` overrides `return`** — a `return` inside a `finally` block silently discards any `return` or thrown exception from the `try`/`catch` block.
- **`main` method overloading** — you can define multiple `main` methods with different signatures; the JVM only calls `public static void main(String[] args)`.
- **Abstract class constructors** — abstract classes *do* have constructors; they are called when a concrete subclass is instantiated via `super()`.
- **`char` is numeric** — `char` is an unsigned 16-bit integer; `'a' + 1` compiles and equals `98`. It participates in arithmetic promotion.
- **String `+` with mixed types** — the `+` operator is left-associative; numeric addition happens before string concatenation unless parentheses force otherwise.

---

## Interview Q&A

### Conceptual Questions

**Q: Is Java a fully object-oriented language?**
> **A:** No. Java has **eight primitive types** (`int`, `long`, `double`, `float`, `boolean`, `byte`, `short`, `char`) that are not objects — they have no methods and do not inherit from `Object`. A purely OO language (like Smalltalk or Ruby) has no such primitives. Java also allows `static` methods and fields, which belong to the class rather than any instance. Autoboxing (Java 5+) wraps primitives into objects automatically, but the primitives themselves remain.

**Q: Is Java a compiled language or an interpreted language?**
> **A:** Both. `javac` compiles `.java` source into platform-independent `.class` **bytecode** — so it is compiled. The JVM then either interprets that bytecode or, for frequently executed ("hot") paths, the JIT compiler recompiles it to native machine code at runtime. This dual nature is what makes "write once, run anywhere" possible while still achieving near-native performance.

**Q: Is Java pass-by-value or pass-by-reference?**
> **A:** Java is strictly **pass-by-value** — always. For primitives, a copy of the value is passed. For object references, a copy of the reference (memory address) is passed. This means you can mutate the object the reference points to (the caller sees the mutation), but you can never make the caller's variable point to a different object by reassigning the parameter inside the method.

**Q: Can you override a `static` method in Java?**
> **A:** No — you can **hide** it, but not override it. If a subclass declares a static method with the same signature, it hides the parent's method rather than overriding it. Method resolution for `static` methods happens at **compile time** based on the declared type, not at runtime based on the actual object type. Polymorphism (runtime dispatch) does not apply. Calling `Parent.method()` vs `Child.method()` always invokes the respective class's version regardless of the actual object.

**Q: Can an interface have a constructor?**
> **A:** No. Interfaces cannot be instantiated directly, so they have no constructors. They can, however, have `default` methods (Java 8+), `static` methods (Java 8+), `private` methods (Java 9+), and constants (`public static final` fields). The distinction matters because `abstract` classes *can* have constructors even though they also cannot be instantiated directly.

**Q: Can you have a `try` block without a `catch` block?**
> **A:** Yes — a `try` block can be paired with only a `finally` block (`try { } finally { }`). This is valid and commonly used to guarantee cleanup (e.g., closing a resource) even if no exception handling is needed. You cannot have a bare `try` with neither `catch` nor `finally` — that is a compile error.

**Q: Does Java support multiple inheritance?**
> **A:** Java does **not** support multiple inheritance of *state* (you cannot extend more than one class) to avoid the diamond problem of ambiguous fields. However, since Java 8, it supports a limited form of multiple inheritance of *behaviour* via **`default` methods in interfaces** — a class can implement multiple interfaces each providing default method implementations. If two interfaces provide conflicting defaults, the implementing class must override the method to resolve the ambiguity.

**Q: What is the difference between `==` and `.equals()` for `String`?**
> **A:** `==` compares **references** (memory addresses). `.equals()` compares **content** (character sequence). Two string literals with the same value share the same pool entry, so `==` can accidentally return `true`, misleading developers into thinking `==` works for strings. With `new String("hello")`, a new heap object is created and `==` returns `false` even if the content is identical. Always use `.equals()` (or `Objects.equals()`) for string comparison.

---

### Scenario-Based Questions

**Q: What is the output of this code and why?**
```java
System.out.println(1 + 2 + "3");
System.out.println("3" + 1 + 2);
```
> **A:** Output:
> ```
> 33
> 312
> ```
> The `+` operator is **left-associative**. In the first line, `1 + 2` evaluates first (both ints) → `3`, then `3 + "3"` triggers string concatenation → `"33"`. In the second line, `"3" + 1` triggers string concatenation first → `"31"`, then `"31" + 2` → `"312"`. Parentheses control this: `"3" + (1 + 2)` → `"33"`.

**Q: What does this code print?**
```java
String s = null;
System.out.println(s.valueOf(42));
```
> **A:** It prints `"42"` without throwing a `NullPointerException`. `String.valueOf()` is a **static method**. Even though it is called on a null reference, the compiler resolves it to `String.valueOf(42)` based on the declared type `String`. The null value of `s` is irrelevant. This is a common trap — it looks like it should NPE but doesn't. Calling `s.length()` on the same null reference **would** throw `NullPointerException`.

**Q: What is the output of this code?**
```java
public static int getValue() {
    try {
        return 1;
    } finally {
        return 2;
    }
}
System.out.println(getValue());
```
> **A:** Prints `2`. The `finally` block **always executes** before the method actually returns, and a `return` statement inside `finally` overrides any `return` in `try` or `catch`. The return value `1` from the `try` block is silently discarded. This is considered very bad practice — a `return` (or thrown exception) in `finally` can mask real exceptions and makes control flow extremely hard to reason about.

**Q: What does this code print?**
```java
Integer a = 127;
Integer b = 127;
Integer c = 128;
Integer d = 128;
System.out.println(a == b);
System.out.println(c == d);
```
> **A:**
> ```
> true
> false
> ```
> `Integer.valueOf()` (used by autoboxing) caches instances for the range **−128 to 127** (JLS §5.1.7). `a` and `b` both point to the same cached object → `==` is `true`. `c` and `d` are outside the cache range → two distinct heap objects are created → `==` is `false`. Always use `.equals()` when comparing `Integer` objects.

**Q: Will this code compile and run? What does it print?**
```java
public class Main {
    public static void main(String[] args) {
        System.out.println("main 1");
    }
    public static void main(String arg) {
        System.out.println("main 2");
    }
}
```
> **A:** Yes, it compiles and prints `main 1`. The JVM entry point is specifically `public static void main(String[] args)` (array of String). The second `main(String)` is simply an overloaded method — valid Java, never called by the JVM automatically. You can have as many overloads of `main` as you like; only the exact JVM-required signature is the program entry point.

**Q: Can you instantiate an abstract class? What about this code?**
```java
abstract class Shape { abstract void draw(); }
Shape s = new Shape() { void draw() { System.out.println("drawn"); } };
s.draw();
```
> **A:** You cannot instantiate an `abstract` class with `new Shape()`, but this code **is valid**. It creates an **anonymous class** — an unnamed concrete subclass of `Shape` defined inline. The `new Shape() { ... }` syntax declares and instantiates the subclass in one expression. This is a standard Java feature used heavily before lambdas (Java 8+). The output is `drawn`.

---

## Quick Reference

| Trick Question | Correct Answer |
|---|---|
| Is Java fully OO? | No — 8 primitive types, static members exist |
| Compiled or interpreted? | Both — bytecode (compiled) + JVM interprets / JIT compiles |
| Pass-by-value or reference? | Always pass-by-value (copy of reference for objects) |
| Can you override `static` methods? | No — you **hide** them; no runtime dispatch |
| Can interface have constructor? | No; can have `default`, `static`, `private` methods (Java 8/9+) |
| `try` without `catch`? | Valid if paired with `finally` |
| Multiple inheritance in Java? | No class MI; `default` methods allow behaviour MI |
| `==` vs `.equals()` on String? | `==` = reference; `.equals()` = content |
| `1 + 2 + "3"` | `"33"` (int addition first, then concat) |
| `"3" + 1 + 2` | `"312"` (concat left-to-right) |
| `null.staticMethod()` | No NPE — static calls resolve at compile time |
| `return` in `finally` | Overrides `try`/`catch` return; discards exceptions |
| `Integer a = 127; Integer b = 127; a == b`? | `true` (cached range −128 to 127) |
| `Integer a = 128; Integer b = 128; a == b`? | `false` (outside cache, distinct heap objects) |
| Can abstract class have constructor? | Yes — called by subclass `super()` |
| Can you instantiate abstract class? | Only via anonymous class (`new Abstract() { ... }`) |