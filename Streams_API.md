# Java Streams API

## Table of Contents
1. [What is the Streams API?](#what-is-the-streams-api)
2. [Creating Streams](#creating-streams)
3. [Intermediate Operations](#intermediate-operations)
4. [Terminal Operations](#terminal-operations)
5. [Collectors](#collectors)
6. [FlatMap](#flatmap)
7. [Optional](#optional)
8. [Parallel Streams](#parallel-streams)
9. [Primitive Streams](#primitive-streams)
10. [Common Interview Patterns](#common-interview-patterns)
11. [Quick Reference](#quick-reference)

---

## What is the Streams API?

Introduced in **Java 8**. A Stream is a **sequence of elements** supporting sequential and parallel aggregate operations. It does **not store data** — it processes it on the fly from a source (collection, array, I/O).

```
Source → Intermediate Operations (lazy) → Terminal Operation (triggers processing)
```

**Key properties:**
- **Lazy** — intermediate ops don't execute until a terminal op is called
- **Non-reusable** — a stream can only be consumed once
- **Does not mutate** the source collection
- **Functional** — operations take lambdas / method references

---

## Creating Streams

```java
import java.util.stream.*;
import java.util.*;

public class CreatingStreams {
    public static void main(String[] args) {

        // 1. From a Collection
        List<String> list = List.of("a", "b", "c");
        Stream<String> s1 = list.stream();

        // 2. From varargs / values
        Stream<Integer> s2 = Stream.of(1, 2, 3, 4, 5);

        // 3. From an array
        String[] arr = {"x", "y", "z"};
        Stream<String> s3 = Arrays.stream(arr);

        // 4. Infinite stream — generate
        Stream<Double> randoms = Stream.generate(Math::random).limit(3);
        randoms.forEach(System.out::println);

        // 5. Infinite stream — iterate
        Stream<Integer> evens = Stream.iterate(0, n -> n + 2).limit(5);
        evens.forEach(n -> System.out.print(n + " "));   // 0 2 4 6 8
        System.out.println();

        // 6. Empty stream
        Stream<String> empty = Stream.empty();

        // 7. From a String (chars)
        "hello".chars()
               .forEach(c -> System.out.print((char) c + " "));  // h e l l o
    }
}
```

**Output:**
```
(3 random doubles)
0 2 4 6 8
h e l l o
```

---

## Intermediate Operations

Intermediate ops are **lazy** — they return a new Stream and do nothing until a terminal op is called.

### filter — keep elements matching predicate

```java
List<Integer> nums = List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

nums.stream()
    .filter(n -> n % 2 == 0)          // keep evens
    .forEach(n -> System.out.print(n + " "));
// Output: 2 4 6 8 10
```

### map — transform each element (1-to-1)

```java
List<String> names = List.of("alice", "bob", "charlie");

names.stream()
     .map(String::toUpperCase)
     .forEach(System.out::println);
// Output: ALICE  BOB  CHARLIE
```

### sorted — sort elements

```java
List<Integer> nums = List.of(5, 3, 1, 4, 2);

// Natural order
nums.stream()
    .sorted()
    .forEach(n -> System.out.print(n + " "));
// Output: 1 2 3 4 5

System.out.println();

// Custom comparator — reverse order
nums.stream()
    .sorted(Comparator.reverseOrder())
    .forEach(n -> System.out.print(n + " "));
// Output: 5 4 3 2 1
```

### distinct — remove duplicates

```java
Stream.of(1, 2, 2, 3, 3, 3, 4)
      .distinct()
      .forEach(n -> System.out.print(n + " "));
// Output: 1 2 3 4
```

### limit & skip

```java
Stream.iterate(1, n -> n + 1)
      .skip(4)           // skip first 4
      .limit(5)          // take next 5
      .forEach(n -> System.out.print(n + " "));
// Output: 5 6 7 8 9
```

### peek — debug side-effect (does not consume)

```java
List.of("a", "b", "c").stream()
    .peek(s -> System.out.println("Before map: " + s))
    .map(String::toUpperCase)
    .peek(s -> System.out.println("After map : " + s))
    .forEach(s -> {});
```

**Output:**
```
Before map: a
After map : A
Before map: b
After map : B
Before map: c
After map : C
```

---

## Terminal Operations

Terminal ops **trigger** the stream pipeline and produce a result. After this, the stream is consumed.

### forEach

```java
List.of(1, 2, 3).stream()
    .forEach(System.out::println);
// 1  2  3
```

### collect — gather into a collection

```java
List<String> names = List.of("Alice", "Bob", "Charlie", "Anna");

// To List
List<String> result = names.stream()
    .filter(n -> n.startsWith("A"))
    .collect(Collectors.toList());
System.out.println(result);   // [Alice, Anna]

// To Set
Set<String> set = names.stream().collect(Collectors.toSet());

// To Map
Map<String, Integer> nameLengths = names.stream()
    .collect(Collectors.toMap(
        name -> name,          // key
        String::length         // value
    ));
System.out.println(nameLengths);  // {Alice=5, Bob=3, Charlie=7, Anna=4}
```

### reduce — fold elements into a single value

```java
List<Integer> nums = List.of(1, 2, 3, 4, 5);

// With identity (seed)
int sum = nums.stream()
              .reduce(0, Integer::sum);
System.out.println("Sum: " + sum);       // Sum: 15

// Without identity → returns Optional
Optional<Integer> product = nums.stream()
    .reduce((a, b) -> a * b);
product.ifPresent(p -> System.out.println("Product: " + p));  // Product: 120
```

### count

```java
long count = List.of(1, 2, 3, 4, 5).stream()
                 .filter(n -> n > 2)
                 .count();
System.out.println(count);   // 3
```

### min / max

```java
List<Integer> nums = List.of(3, 1, 4, 1, 5, 9, 2, 6);

Optional<Integer> max = nums.stream().max(Comparator.naturalOrder());
Optional<Integer> min = nums.stream().min(Comparator.naturalOrder());

System.out.println("Max: " + max.get());   // Max: 9
System.out.println("Min: " + min.get());   // Min: 1
```

### findFirst / findAny

```java
Optional<String> first = List.of("apple", "banana", "avocado").stream()
    .filter(s -> s.startsWith("a"))
    .findFirst();

System.out.println(first.get());   // apple
```

### anyMatch / allMatch / noneMatch

```java
List<Integer> nums = List.of(2, 4, 6, 8, 9);

System.out.println(nums.stream().anyMatch(n -> n % 2 != 0));  // true  (9 is odd)
System.out.println(nums.stream().allMatch(n -> n % 2 == 0));  // false (9 is odd)
System.out.println(nums.stream().noneMatch(n -> n > 100));    // true
```

---

## Collectors

```java
import java.util.stream.Collectors;
import java.util.*;

record Employee(String name, String dept, double salary) {}

public class CollectorsExample {
    public static void main(String[] args) {

        List<Employee> employees = List.of(
            new Employee("Alice",   "Engineering", 90000),
            new Employee("Bob",     "Engineering", 85000),
            new Employee("Charlie", "HR",          60000),
            new Employee("Diana",   "HR",          65000),
            new Employee("Eve",     "Engineering", 95000)
        );

        // --- groupingBy — group into a Map<K, List<V>> ---
        Map<String, List<Employee>> byDept = employees.stream()
            .collect(Collectors.groupingBy(Employee::dept));

        byDept.forEach((dept, emps) ->
            System.out.println(dept + ": " + emps.stream()
                .map(Employee::name).toList()));


        // --- groupingBy + counting ---
        Map<String, Long> countByDept = employees.stream()
            .collect(Collectors.groupingBy(Employee::dept, Collectors.counting()));
        System.out.println(countByDept);   // {Engineering=3, HR=2}


        // --- groupingBy + averagingDouble ---
        Map<String, Double> avgSalaryByDept = employees.stream()
            .collect(Collectors.groupingBy(Employee::dept,
                     Collectors.averagingDouble(Employee::salary)));
        System.out.println(avgSalaryByDept);  // {Engineering=90000.0, HR=62500.0}


        // --- partitioningBy — splits into true/false map ---
        Map<Boolean, List<Employee>> partitioned = employees.stream()
            .collect(Collectors.partitioningBy(e -> e.salary() > 80000));
        System.out.println("High earners: " + partitioned.get(true)
            .stream().map(Employee::name).toList());


        // --- joining ---
        String names = employees.stream()
            .map(Employee::name)
            .collect(Collectors.joining(", ", "[", "]"));
        System.out.println(names);   // [Alice, Bob, Charlie, Diana, Eve]


        // --- toUnmodifiableList (Java 10+) ---
        List<String> immutable = employees.stream()
            .map(Employee::name)
            .collect(Collectors.toUnmodifiableList());
    }
}
```

**Output:**
```
Engineering: [Alice, Bob, Eve]
HR: [Charlie, Diana]
{Engineering=3, HR=2}
{Engineering=90000.0, HR=62500.0}
High earners: [Alice, Bob, Eve]
[Alice, Bob, Charlie, Diana, Eve]
```

---

## FlatMap

Use `flatMap` when each element maps to **multiple elements** (1-to-N). It flattens the nested streams.

```java
// map → Stream<Stream<String>> ❌
// flatMap → Stream<String> ✓

List<List<Integer>> nested = List.of(
    List.of(1, 2, 3),
    List.of(4, 5),
    List.of(6, 7, 8, 9)
);

// Flatten nested list of lists
List<Integer> flat = nested.stream()
    .flatMap(Collection::stream)
    .collect(Collectors.toList());
System.out.println(flat);   // [1, 2, 3, 4, 5, 6, 7, 8, 9]


// Split sentences into words
List<String> sentences = List.of("Hello World", "Java Streams", "Are Great");

List<String> words = sentences.stream()
    .flatMap(s -> Arrays.stream(s.split(" ")))
    .map(String::toLowerCase)
    .sorted()
    .collect(Collectors.toList());
System.out.println(words);
// [are, great, hello, java, streams, world]
```

**Output:**
```
[1, 2, 3, 4, 5, 6, 7, 8, 9]
[are, great, hello, java, streams, world]
```

---

## Optional

`Optional<T>` wraps a value that **may or may not be present**. Avoids `NullPointerException`.

```java
import java.util.Optional;

public class OptionalExample {
    public static void main(String[] args) {

        // Creating
        Optional<String> present = Optional.of("Hello");
        Optional<String> empty   = Optional.empty();
        Optional<String> nullable = Optional.ofNullable(null);  // safe — won't throw

        // Checking & getting
        System.out.println(present.isPresent());   // true
        System.out.println(empty.isEmpty());       // true
        System.out.println(present.get());         // Hello (throws if empty)

        // Safe retrieval
        String val1 = empty.orElse("default");                    // default
        String val2 = empty.orElseGet(() -> "computed-default");  // lazy
        String val3 = present.orElseThrow(() ->
                        new RuntimeException("Missing!"));         // Hello

        // map — transform value if present
        Optional<Integer> length = present.map(String::length);
        System.out.println(length.get());   // 5

        // flatMap — when mapper returns Optional
        Optional<String> upper = present
            .flatMap(s -> Optional.of(s.toUpperCase()));
        System.out.println(upper.get());    // HELLO

        // filter
        Optional<String> filtered = present.filter(s -> s.length() > 3);
        System.out.println(filtered.isPresent());  // true

        // ifPresent — side effect
        present.ifPresent(s -> System.out.println("Value: " + s));  // Value: Hello
    }
}
```

**Output:**
```
true
true
Hello
5
HELLO
true
Value: Hello
```

---

## Parallel Streams

Parallel streams split work across multiple threads using `ForkJoinPool.commonPool()`.

```java
import java.util.stream.*;
import java.util.List;

public class ParallelStreamExample {
    public static void main(String[] args) {

        // Sequential
        long seqStart = System.currentTimeMillis();
        long seqSum = LongStream.rangeClosed(1, 100_000_000L).sum();
        System.out.println("Sequential sum: " + seqSum +
            " in " + (System.currentTimeMillis() - seqStart) + "ms");

        // Parallel — splits across CPU cores automatically
        long parStart = System.currentTimeMillis();
        long parSum = LongStream.rangeClosed(1, 100_000_000L).parallel().sum();
        System.out.println("Parallel sum  : " + parSum +
            " in " + (System.currentTimeMillis() - parStart) + "ms");

        // Convert collection stream to parallel
        List<Integer> nums = List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
        int total = nums.parallelStream()
                        .mapToInt(Integer::intValue)
                        .sum();
        System.out.println("Total: " + total);   // 55
    }
}
```

**Output:**
```
Sequential sum: 5000000050000000 in ~180ms
Parallel sum  : 5000000050000000 in ~45ms
Total: 55
```

> **When to use parallel:**
> - Large data sets (> 10,000 elements)
> - CPU-bound, stateless operations
> - No shared mutable state
>
> **Avoid parallel when:**
> - Small data sets (overhead exceeds benefit)
> - Operations have side effects
> - Order matters (`forEachOrdered` preserves order but kills parallelism benefit)

---

## Primitive Streams

Avoid boxing overhead with specialized primitive streams.

| Stream | For type | Extra terminal ops |
|---|---|---|
| `IntStream` | `int` | `sum()`, `average()`, `min()`, `max()`, `summaryStatistics()` |
| `LongStream` | `long` | same |
| `DoubleStream` | `double` | same |

```java
import java.util.stream.*;

public class PrimitiveStreams {
    public static void main(String[] args) {

        // IntStream.range — exclusive end
        IntStream.range(1, 6)
                 .forEach(n -> System.out.print(n + " "));  // 1 2 3 4 5
        System.out.println();

        // IntStream.rangeClosed — inclusive end
        IntStream.rangeClosed(1, 5)
                 .forEach(n -> System.out.print(n + " "));  // 1 2 3 4 5
        System.out.println();

        // sum, average, min, max
        int[] arr = {3, 1, 4, 1, 5, 9, 2, 6};
        IntStream stream = Arrays.stream(arr);
        System.out.println("Sum: " + Arrays.stream(arr).sum());          // 31
        System.out.println("Avg: " + Arrays.stream(arr).average().getAsDouble()); // 3.875
        System.out.println("Max: " + Arrays.stream(arr).max().getAsInt());        // 9

        // summaryStatistics
        IntSummaryStatistics stats = Arrays.stream(arr).summaryStatistics();
        System.out.println(stats);
        // IntSummaryStatistics{count=8, sum=31, min=1, average=3.875, max=9}

        // mapToInt — convert Stream<T> to IntStream (avoids boxing)
        List<String> words = List.of("hello", "world", "java");
        int totalLen = words.stream()
                            .mapToInt(String::length)
                            .sum();
        System.out.println("Total length: " + totalLen);  // 14

        // boxed() — convert back to Stream<Integer>
        List<Integer> boxed = IntStream.range(1, 6)
                                       .boxed()
                                       .collect(Collectors.toList());
        System.out.println(boxed);   // [1, 2, 3, 4, 5]
    }
}
```

**Output:**
```
1 2 3 4 5
1 2 3 4 5
Sum: 31
Avg: 3.875
Max: 9
IntSummaryStatistics{count=8, sum=31, min=1, average=3.875, max=9}
Total length: 14
[1, 2, 3, 4, 5]
```

---

## Common Interview Patterns

### 1 — Find second highest number

```java
List<Integer> nums = List.of(5, 3, 9, 1, 7, 9, 4);

Optional<Integer> second = nums.stream()
    .distinct()
    .sorted(Comparator.reverseOrder())
    .skip(1)
    .findFirst();

System.out.println("Second highest: " + second.get());  // 7
```

### 2 — Group and count occurrences (frequency map)

```java
List<String> items = List.of("apple", "banana", "apple", "cherry", "banana", "apple");

Map<String, Long> freq = items.stream()
    .collect(Collectors.groupingBy(s -> s, Collectors.counting()));

System.out.println(freq);  // {apple=3, banana=2, cherry=1}
```

### 3 — Find most frequent element

```java
String mostFrequent = freq.entrySet().stream()
    .max(Map.Entry.comparingByValue())
    .map(Map.Entry::getKey)
    .orElseThrow();

System.out.println("Most frequent: " + mostFrequent);  // apple
```

### 4 — Partition employees by salary threshold

```java
Map<Boolean, List<String>> result = employees.stream()
    .collect(Collectors.partitioningBy(
        e -> e.salary() >= 80000,
        Collectors.mapping(Employee::name, Collectors.toList())
    ));

System.out.println("Above 80k: " + result.get(true));
System.out.println("Below 80k: " + result.get(false));
```

**Output:**
```
Above 80k: [Alice, Bob, Eve]
Below 80k: [Charlie, Diana]
```

### 5 — Convert list to map (ID → Object)

```java
record Product(int id, String name, double price) {}

List<Product> products = List.of(
    new Product(1, "Laptop", 999.99),
    new Product(2, "Phone",  499.99),
    new Product(3, "Tablet", 299.99)
);

Map<Integer, Product> productMap = products.stream()
    .collect(Collectors.toMap(Product::id, p -> p));

System.out.println(productMap.get(2).name());  // Phone
```

### 6 — Chained operations (real-world style)

```java
// Top 3 salaries in Engineering dept, as a comma-separated string
String top3 = employees.stream()
    .filter(e -> e.dept().equals("Engineering"))
    .sorted(Comparator.comparingDouble(Employee::salary).reversed())
    .limit(3)
    .map(e -> e.name() + "(" + e.salary() + ")")
    .collect(Collectors.joining(", "));

System.out.println(top3);
// Eve(95000.0), Alice(90000.0), Bob(85000.0)
```

---

## Quick Reference

```
Create:
  collection.stream()           → sequential stream
  collection.parallelStream()   → parallel stream
  Stream.of(a, b, c)            → from values
  Arrays.stream(arr)            → from array
  Stream.generate(fn).limit(n)  → infinite, generated
  Stream.iterate(seed, fn)      → infinite, iterated
  IntStream.range(0, 10)        → 0..9
  IntStream.rangeClosed(0, 10)  → 0..10

Intermediate (lazy, return Stream):
  .filter(predicate)            → keep matching
  .map(fn)                      → transform 1-to-1
  .flatMap(fn)                  → transform 1-to-N, flatten
  .sorted() / .sorted(comp)     → sort
  .distinct()                   → remove duplicates
  .limit(n)                     → first N
  .skip(n)                      → skip first N
  .peek(fn)                     → debug side-effect

Terminal (eager, consumes stream):
  .forEach(fn)                  → iterate
  .collect(collector)           → gather into collection
  .reduce(identity, fn)         → fold to single value
  .count()                      → number of elements
  .min(comp) / .max(comp)       → Optional<T>
  .findFirst() / .findAny()     → Optional<T>
  .anyMatch / allMatch / noneMatch → boolean
  .toList()                     → Java 16+ shorthand

Key Collectors:
  toList() / toSet() / toMap()
  groupingBy(fn)                → Map<K, List<V>>
  groupingBy(fn, downstream)    → Map<K, Result>
  counting()                    → Long
  averagingDouble(fn)           → Double
  joining(delim, prefix, suffix)→ String
  partitioningBy(predicate)     → Map<Boolean, List<V>>

Primitive streams (avoid boxing):
  mapToInt / mapToLong / mapToDouble
  .sum() / .average() / .summaryStatistics()
  .boxed() → back to Stream<T>

Optional:
  Optional.of(val)              → non-null value
  Optional.ofNullable(val)      → nullable
  Optional.empty()              → empty
  .orElse(default)              → value or default
  .orElseGet(fn)                → lazy default
  .orElseThrow(fn)              → throw if empty
  .map(fn) / .flatMap(fn) / .filter(fn)
```
***