# Reactive Programming in Java

## Table of Contents
1. [What is Reactive Programming?](#what-is-reactive-programming)
2. [Part 1 — CompletableFuture](#part-1--completablefuture)
   - [Creating CompletableFutures](#creating-completablefutures)
   - [Transforming Results — thenApply / thenAccept / thenRun](#transforming-results)
   - [Chaining Async Steps — thenCompose](#chaining-async-steps--thencompose)
   - [Combining Futures — thenCombine / allOf / anyOf](#combining-futures)
   - [Error Handling](#error-handling--completablefuture)
   - [CompletableFuture Cheat Sheet](#completablefuture-cheat-sheet)
3. [Part 2 — Project Reactor (Flux & Mono)](#part-2--project-reactor-flux--mono)
   - [Setup](#setup)
   - [Mono — 0 or 1 item](#mono--0-or-1-item)
   - [Flux — 0 to N items](#flux--0-to-n-items)
   - [Operators](#operators)
   - [Combining Publishers](#combining-publishers)
   - [Error Handling](#error-handling--reactor)
   - [Backpressure](#backpressure)
   - [Threading — subscribeOn & publishOn](#threading--subscribeon--publishon)
   - [Hot vs Cold Publishers](#hot-vs-cold-publishers)
   - [Flux & Mono Cheat Sheet](#flux--mono-cheat-sheet)
4. [CompletableFuture vs Reactor](#completablefuture-vs-reactor)

---

## What is Reactive Programming?

Reactive programming is a **non-blocking, asynchronous** programming paradigm built around **data streams** and **propagation of change**. Instead of blocking a thread waiting for a result, you declare what to do *when* a result arrives.

**Core principles (Reactive Manifesto):**
- **Responsive** — System responds in a timely manner
- **Resilient** — System stays responsive on failure
- **Elastic** — Scales under varying workload
- **Message-driven** — Async message passing, backpressure support

---

# Part 1 — CompletableFuture

Introduced in **Java 8**. Represents an async computation that you can chain, combine, and compose without blocking threads.

```
Future<T>           → Basic. Can only get() (blocks). No chaining.
CompletableFuture<T>→ Full pipeline: transform, chain, combine, handle errors.
```

---

## Creating CompletableFutures

```java
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class CreatingCF {
    public static void main(String[] args) throws Exception {

        // 1. Already-completed future (useful for testing/defaults)
        CompletableFuture<String> done = CompletableFuture.completedFuture("Hello");
        System.out.println(done.get());                         // Hello

        // 2. Run async — no return value (Runnable)
        CompletableFuture<Void> noResult = CompletableFuture.runAsync(() ->
            System.out.println("Running in: " + Thread.currentThread().getName())
        );
        noResult.get();                                         // wait for it

        // 3. Supply async — returns a value (Supplier)
        CompletableFuture<Integer> withResult = CompletableFuture.supplyAsync(() -> {
            System.out.println("Supplying in: " + Thread.currentThread().getName());
            return 42;
        });
        System.out.println("Result: " + withResult.get());     // Result: 42

        // 4. Custom thread pool (avoid ForkJoinPool.commonPool in production)
        ExecutorService pool = Executors.newFixedThreadPool(4);
        CompletableFuture<String> custom = CompletableFuture.supplyAsync(
            () -> "Custom pool result", pool
        );
        System.out.println(custom.get());                      // Custom pool result
        pool.shutdown();
    }
}
```

**Output:**
```
Hello
Running in: ForkJoinPool.commonPool-worker-1
Supplying in: ForkJoinPool.commonPool-worker-1
Result: 42
Custom pool result
```

---

## Transforming Results

| Method | Input → Output | Async? |
|---|---|---|
| `thenApply(fn)` | `T → U` — transform result | No |
| `thenApplyAsync(fn)` | `T → U` — transform on new thread | Yes |
| `thenAccept(fn)` | `T → void` — consume result | No |
| `thenRun(fn)` | `void → void` — run after, ignores result | No |

```java
import java.util.concurrent.CompletableFuture;

public class TransformExample {
    public static void main(String[] args) throws Exception {

        CompletableFuture.supplyAsync(() -> "  hello world  ")  // Step 1: supply
            .thenApply(String::trim)                            // Step 2: trim
            .thenApply(String::toUpperCase)                     // Step 3: uppercase
            .thenAccept(result -> System.out.println("Result: " + result))  // Step 4: consume
            .thenRun(() -> System.out.println("Pipeline complete"))          // Step 5: done
            .get();
    }
}
```

**Output:**
```
Result: HELLO WORLD
Pipeline complete
```

---

## Chaining Async Steps — thenCompose

Use `thenCompose` (flatMap equivalent) when the next step itself returns a `CompletableFuture`, to avoid `CompletableFuture<CompletableFuture<T>>`.

```java
import java.util.concurrent.CompletableFuture;

public class ComposeExample {

    static CompletableFuture<String> fetchUser(int id) {
        return CompletableFuture.supplyAsync(() -> {
            System.out.println("Fetching user " + id);
            return "User_" + id;
        });
    }

    static CompletableFuture<String> fetchOrders(String user) {
        return CompletableFuture.supplyAsync(() -> {
            System.out.println("Fetching orders for " + user);
            return user + " → [Order1, Order2]";
        });
    }

    public static void main(String[] args) throws Exception {

        // thenApply  → would give CompletableFuture<CompletableFuture<String>> ❌
        // thenCompose → flattens to CompletableFuture<String> ✓
        String result = fetchUser(101)
            .thenCompose(user -> fetchOrders(user))
            .get();

        System.out.println(result);
    }
}
```

**Output:**
```
Fetching user 101
Fetching orders for User_101
User_101 → [Order1, Order2]
```

---

## Combining Futures

### thenCombine — combine two independent futures

```java
import java.util.concurrent.CompletableFuture;

public class CombineExample {
    public static void main(String[] args) throws Exception {

        CompletableFuture<Integer> price = CompletableFuture.supplyAsync(() -> {
            System.out.println("Fetching price...");
            return 100;
        });

        CompletableFuture<Integer> discount = CompletableFuture.supplyAsync(() -> {
            System.out.println("Fetching discount...");
            return 20;
        });

        // Both run concurrently; combine when both are done
        CompletableFuture<Integer> finalPrice = price.thenCombine(discount,
            (p, d) -> p - d
        );

        System.out.println("Final price: " + finalPrice.get());   // 80
    }
}
```

**Output:**
```
Fetching price...
Fetching discount...
Final price: 80
```

### allOf — wait for ALL futures

```java
import java.util.concurrent.CompletableFuture;

public class AllOfExample {
    public static void main(String[] args) throws Exception {

        CompletableFuture<String> f1 = CompletableFuture.supplyAsync(() -> "Result A");
        CompletableFuture<String> f2 = CompletableFuture.supplyAsync(() -> "Result B");
        CompletableFuture<String> f3 = CompletableFuture.supplyAsync(() -> "Result C");

        // allOf returns Void — you must get results individually
        CompletableFuture.allOf(f1, f2, f3).get();   // wait for all

        System.out.println(f1.get());   // Result A
        System.out.println(f2.get());   // Result B
        System.out.println(f3.get());   // Result C
    }
}
```

**Output:**
```
Result A
Result B
Result C
```

### anyOf — return first to complete

```java
import java.util.concurrent.CompletableFuture;

public class AnyOfExample {
    public static void main(String[] args) throws Exception {

        CompletableFuture<String> slow   = CompletableFuture.supplyAsync(() -> { sleep(500); return "Slow"; });
        CompletableFuture<String> fast   = CompletableFuture.supplyAsync(() -> { sleep(100); return "Fast"; });
        CompletableFuture<String> medium = CompletableFuture.supplyAsync(() -> { sleep(300); return "Medium"; });

        Object winner = CompletableFuture.anyOf(slow, fast, medium).get();
        System.out.println("Winner: " + winner);   // Fast
    }

    static void sleep(long ms) { try { Thread.sleep(ms); } catch (InterruptedException e) { Thread.currentThread().interrupt(); } }
}
```

**Output:**
```
Winner: Fast
```

---

## Error Handling — CompletableFuture

| Method | Purpose |
|---|---|
| `exceptionally(fn)` | Recover from exception — provide fallback value |
| `handle(fn)` | Always runs — gets `(result, exception)`, both nullable |
| `whenComplete(fn)` | Side-effect on complete — does not transform result |

```java
import java.util.concurrent.CompletableFuture;

public class ErrorHandlingCF {
    public static void main(String[] args) throws Exception {

        // --- exceptionally: recover with fallback ---
        String result1 = CompletableFuture
            .supplyAsync(() -> {
                if (true) throw new RuntimeException("Service unavailable");
                return "data";
            })
            .exceptionally(ex -> {
                System.out.println("Caught: " + ex.getMessage());
                return "fallback-data";
            })
            .get();
        System.out.println("Result: " + result1);


        // --- handle: transform result OR error ---
        String result2 = CompletableFuture
            .supplyAsync(() -> {
                if (true) throw new RuntimeException("DB error");
                return "db-result";
            })
            .handle((res, ex) -> {
                if (ex != null) {
                    System.out.println("Handled error: " + ex.getMessage());
                    return "default";
                }
                return res.toUpperCase();
            })
            .get();
        System.out.println("Result: " + result2);
    }
}
```

**Output:**
```
Caught: java.lang.RuntimeException: Service unavailable
Result: fallback-data
Handled error: java.lang.RuntimeException: DB error
Result: default
```

---

## CompletableFuture Cheat Sheet

```
Create:
  completedFuture(val)       → already done with value
  runAsync(Runnable)         → async, no return
  supplyAsync(Supplier)      → async, returns value

Transform (return new CF):
  thenApply(T → U)           → map result
  thenCompose(T → CF<U>)     → flatMap / chain async steps
  thenCombine(CF, (T,U) → V) → merge two independent futures

Consume (return CF<Void>):
  thenAccept(T → void)       → use result
  thenRun(Runnable)          → run after, ignores result

Wait for multiple:
  allOf(cf1, cf2, ...)       → wait for all  → CF<Void>
  anyOf(cf1, cf2, ...)       → first to win  → CF<Object>

Error handling:
  exceptionally(ex → T)      → recover with fallback
  handle((T, ex) → U)        → handle both result and error
  whenComplete((T, ex) → void) → side-effect only

Block/get:
  get()                      → block, throws checked exception
  join()                     → block, throws unchecked exception
  getNow(default)            → return default if not done yet
```

---

# Part 2 — Project Reactor (Flux & Mono)

Project Reactor is a **fully non-blocking reactive library** built on the [Reactive Streams](https://www.reactive-streams.org/) specification. Used heavily in Spring WebFlux.

```
Mono<T>  → 0 or 1 item   (like CompletableFuture but reactive)
Flux<T>  → 0 to N items  (like a reactive Stream / list)
```

---

## Setup

**Maven dependency:**
```xml
<dependency>
    <groupId>io.projectreactor</groupId>
    <artifactId>reactor-core</artifactId>
    <version>3.6.0</version>
</dependency>
```

**Gradle:**
```groovy
implementation 'io.projectreactor:reactor-core:3.6.0'
```

---

## Mono — 0 or 1 item

```java
import reactor.core.publisher.Mono;

public class MonoBasics {
    public static void main(String[] args) {

        // 1. Mono with a value
        Mono<String> mono = Mono.just("Hello Reactor");
        mono.subscribe(System.out::println);              // Hello Reactor

        // 2. Empty Mono
        Mono<String> empty = Mono.empty();
        empty.subscribe(
            val -> System.out.println("Got: " + val),
            err -> System.out.println("Error: " + err),
            ()  -> System.out.println("Completed empty")  // onComplete
        );

        // 3. Mono from a Callable (lazy)
        Mono<Integer> lazy = Mono.fromCallable(() -> {
            System.out.println("Computing...");
            return 42;
        });
        lazy.subscribe(val -> System.out.println("Value: " + val));

        // 4. Error Mono
        Mono<String> error = Mono.error(new RuntimeException("Something went wrong"));
        error.subscribe(
            val -> System.out.println(val),
            err -> System.out.println("Caught: " + err.getMessage())
        );
    }
}
```

**Output:**
```
Hello Reactor
Completed empty
Computing...
Value: 42
Caught: Something went wrong
```

---

## Flux — 0 to N items

```java
import reactor.core.publisher.Flux;
import java.time.Duration;
import java.util.List;

public class FluxBasics {
    public static void main(String[] args) throws InterruptedException {

        // 1. From values
        Flux.just("A", "B", "C")
            .subscribe(System.out::println);               // A  B  C

        // 2. From a list
        Flux.fromIterable(List.of(1, 2, 3, 4, 5))
            .subscribe(n -> System.out.print(n + " "));    // 1 2 3 4 5
        System.out.println();

        // 3. Range
        Flux.range(1, 5)
            .subscribe(n -> System.out.print(n + " "));    // 1 2 3 4 5
        System.out.println();

        // 4. Interval (emits every 500ms) — needs a delay to observe
        Flux.interval(Duration.ofMillis(500))
            .take(3)
            .subscribe(n -> System.out.println("Tick: " + n));
        Thread.sleep(2000);                                 // wait to see output

        // 5. subscribe with all three signals
        Flux.just("X", "Y", "Z")
            .subscribe(
                item -> System.out.println("Item: " + item),
                err  -> System.out.println("Error: " + err),
                ()   -> System.out.println("Done!")
            );
    }
}
```

**Output:**
```
A
B
C
1 2 3 4 5
1 2 3 4 5
Tick: 0
Tick: 1
Tick: 2
Item: X
Item: Y
Item: Z
Done!
```

---

## Operators

### Transformation

```java
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public class OperatorsExample {
    public static void main(String[] args) {

        // map — synchronous 1-to-1 transform
        Flux.just("apple", "banana", "cherry")
            .map(String::toUpperCase)
            .subscribe(System.out::println);
        // APPLE  BANANA  CHERRY

        System.out.println("---");

        // flatMap — async 1-to-N transform (merges results, order not guaranteed)
        Flux.just(1, 2, 3)
            .flatMap(n -> Flux.just(n * 10, n * 100))
            .subscribe(n -> System.out.print(n + " "));
        // 10 100 20 200 30 300 (order may vary)
        System.out.println();

        System.out.println("---");

        // flatMapSequential — like flatMap but preserves order
        Flux.just(1, 2, 3)
            .flatMapSequential(n -> Flux.just(n * 10, n * 100))
            .subscribe(n -> System.out.print(n + " "));
        // 10 100 20 200 30 300
        System.out.println();
    }
}
```

**Output:**
```
APPLE
BANANA
CHERRY
---
10 100 20 200 30 300
---
10 100 20 200 30 300
```

### Filtering

```java
import reactor.core.publisher.Flux;

public class FilteringExample {
    public static void main(String[] args) {

        Flux<Integer> numbers = Flux.range(1, 10);

        // filter
        numbers.filter(n -> n % 2 == 0)
               .subscribe(n -> System.out.print(n + " "));    // 2 4 6 8 10
        System.out.println();

        // take — first N
        Flux.range(1, 100).take(4)
            .subscribe(n -> System.out.print(n + " "));       // 1 2 3 4
        System.out.println();

        // skip — skip first N
        Flux.range(1, 5).skip(3)
            .subscribe(n -> System.out.print(n + " "));       // 4 5
        System.out.println();

        // distinct
        Flux.just(1, 2, 2, 3, 3, 3, 4)
            .distinct()
            .subscribe(n -> System.out.print(n + " "));       // 1 2 3 4
        System.out.println();

        // first non-empty (defaultIfEmpty)
        Flux.<String>empty()
            .defaultIfEmpty("fallback")
            .subscribe(System.out::println);                  // fallback
    }
}
```

**Output:**
```
2 4 6 8 10
1 2 3 4
4 5
1 2 3 4
fallback
```

### Reducing / Collecting

```java
import reactor.core.publisher.Flux;

public class ReduceExample {
    public static void main(String[] args) {

        // reduce
        Flux.range(1, 5)
            .reduce(0, Integer::sum)
            .subscribe(sum -> System.out.println("Sum: " + sum));  // Sum: 15

        // collectList — Flux<T> → Mono<List<T>>
        Flux.just("a", "b", "c")
            .collectList()
            .subscribe(list -> System.out.println("List: " + list));  // List: [a, b, c]

        // count
        Flux.range(1, 10)
            .count()
            .subscribe(n -> System.out.println("Count: " + n));    // Count: 10
    }
}
```

**Output:**
```
Sum: 15
List: [a, b, c]
Count: 10
```

---

## Combining Publishers

```java
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public class CombiningExample {
    public static void main(String[] args) {

        // merge — interleaves items as they arrive (concurrent)
        Flux<String> f1 = Flux.just("A", "B");
        Flux<String> f2 = Flux.just("1", "2");
        Flux.merge(f1, f2)
            .subscribe(s -> System.out.print(s + " "));     // A B 1 2 (may vary)
        System.out.println();

        // concat — sequential, waits for first to complete
        Flux.concat(f1, f2)
            .subscribe(s -> System.out.print(s + " "));     // A B 1 2 (guaranteed order)
        System.out.println();

        // zip — pairs items by position → Mono<Tuple>
        Flux.zip(
            Flux.just("name", "age"),
            Flux.just("Alice", "30")
        ).subscribe(tuple -> System.out.println(tuple.getT1() + ": " + tuple.getT2()));

        // zipWith — combine Mono with another Mono
        Mono.just("Hello")
            .zipWith(Mono.just(" World"))
            .map(t -> t.getT1() + t.getT2())
            .subscribe(System.out::println);
    }
}
```

**Output:**
```
A B 1 2
A B 1 2
name: Alice
age: 30
Hello World
```

---

## Error Handling — Reactor

```java
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public class ErrorHandlingReactor {
    public static void main(String[] args) {

        // onErrorReturn — emit a fallback value
        Flux.just(1, 2, 0, 4)
            .map(n -> 10 / n)
            .onErrorReturn(-1)
            .subscribe(System.out::println);
        // 10  5  -1  (stops at error, emits -1)

        System.out.println("---");

        // onErrorResume — switch to a fallback publisher
        Flux.just("data1", "data2", "FAIL", "data4")
            .map(s -> { if (s.equals("FAIL")) throw new RuntimeException("Bad data"); return s; })
            .onErrorResume(ex -> {
                System.out.println("Fallback due to: " + ex.getMessage());
                return Flux.just("default1", "default2");
            })
            .subscribe(System.out::println);

        System.out.println("---");

        // onErrorContinue — skip bad item, continue stream
        Flux.just(1, 2, 0, 4, 5)
            .map(n -> 10 / n)
            .onErrorContinue((ex, item) ->
                System.out.println("Skipped item: " + item + " due to " + ex.getMessage())
            )
            .subscribe(System.out::println);

        System.out.println("---");

        // retry — resubscribe on error N times
        Flux.just("ok", "fail")
            .map(s -> { if (s.equals("fail")) throw new RuntimeException("Retry me"); return s; })
            .retry(2)
            .onErrorReturn("gave-up")
            .subscribe(System.out::println);
    }
}
```

**Output:**
```
10
5
-1
---
data1
data2
Fallback due to: Bad data
default1
default2
---
10
5
Skipped item: 0 due to / by zero
2
2
---
ok
ok
ok
gave-up
```

---

## Backpressure

Backpressure lets a **subscriber control how fast a publisher emits**, preventing it from being overwhelmed.

```java
import reactor.core.publisher.Flux;
import org.reactivestreams.Subscription;
import reactor.core.publisher.BaseSubscriber;

public class BackpressureExample {
    public static void main(String[] args) {

        Flux.range(1, 20)
            .subscribe(new BaseSubscriber<Integer>() {

                @Override
                protected void hookOnSubscribe(Subscription subscription) {
                    System.out.println("Subscribed — requesting 5");
                    request(5);   // Only request 5 items initially
                }

                int count = 0;

                @Override
                protected void hookOnNext(Integer value) {
                    System.out.println("Received: " + value);
                    count++;
                    if (count == 5) {
                        System.out.println("Requesting 3 more...");
                        request(3);   // Request 3 more when done with first 5
                    }
                }

                @Override
                protected void hookOnComplete() {
                    System.out.println("Done");
                }
            });
    }
}
```

**Output:**
```
Subscribed — requesting 5
Received: 1
Received: 2
Received: 3
Received: 4
Received: 5
Requesting 3 more...
Received: 6
Received: 7
Received: 8
Done
```

---

## Threading — subscribeOn & publishOn

By default, Reactor is **single-threaded** (runs on caller's thread). Use these operators to switch threads.

| Operator | Effect |
|---|---|
| `subscribeOn(Scheduler)` | Changes the thread the **source** runs on (upstream) |
| `publishOn(Scheduler)` | Changes the thread **downstream operators** run on |

```java
import reactor.core.publisher.Flux;
import reactor.core.scheduler.Schedulers;

public class ThreadingExample {
    public static void main(String[] args) throws InterruptedException {

        Flux.range(1, 3)
            .map(n -> {
                System.out.println("map1 on: " + Thread.currentThread().getName());
                return n * 10;
            })
            .subscribeOn(Schedulers.boundedElastic())       // source runs on boundedElastic
            .publishOn(Schedulers.parallel())               // downstream runs on parallel
            .map(n -> {
                System.out.println("map2 on: " + Thread.currentThread().getName());
                return n + 1;
            })
            .subscribe(n -> System.out.println("Got " + n + " on: " + Thread.currentThread().getName()));

        Thread.sleep(500);
    }
}
```

**Output:**
```
map1 on: boundedElastic-1
map1 on: boundedElastic-1
map1 on: boundedElastic-1
map2 on: parallel-1
map2 on: parallel-1
map2 on: parallel-1
Got 11 on: parallel-1
Got 21 on: parallel-1
Got 31 on: parallel-1
```

**Common Schedulers:**
| Scheduler | Use case |
|---|---|
| `Schedulers.immediate()` | Current thread (default) |
| `Schedulers.single()` | Single reusable thread |
| `Schedulers.parallel()` | CPU-bound work — `N` threads (N = CPU cores) |
| `Schedulers.boundedElastic()` | I/O-bound work — elastic thread pool (recommended for blocking calls) |

---

## Hot vs Cold Publishers

| | Cold Publisher | Hot Publisher |
|---|---|---|
| **Emits when** | A subscriber subscribes | Regardless of subscribers |
| **Each subscriber** | Gets all items from start | Gets items from join point onward |
| **Example** | `Flux.just(...)`, DB query | Kafka topic, UI events, `Sinks` |

```java
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

public class HotColdExample {
    public static void main(String[] args) throws InterruptedException {

        // Cold — each subscriber gets its own stream from the beginning
        Flux<Integer> cold = Flux.just(1, 2, 3);
        cold.subscribe(n -> System.out.println("Sub1 cold: " + n));
        cold.subscribe(n -> System.out.println("Sub2 cold: " + n));

        System.out.println("---");

        // Hot — using Sinks
        Sinks.Many<String> sink = Sinks.many().multicast().onBackpressureBuffer();
        Flux<String> hot = sink.asFlux();

        hot.subscribe(s -> System.out.println("Sub1 hot: " + s));
        sink.tryEmitNext("Event A");
        sink.tryEmitNext("Event B");

        hot.subscribe(s -> System.out.println("Sub2 hot: " + s));  // joins late
        sink.tryEmitNext("Event C");  // both subscribers receive this
    }
}
```

**Output:**
```
Sub1 cold: 1
Sub1 cold: 2
Sub1 cold: 3
Sub2 cold: 1
Sub2 cold: 2
Sub2 cold: 3
---
Sub1 hot: Event A
Sub1 hot: Event B
Sub1 hot: Event C
Sub2 hot: Event C
```

---

## Flux & Mono Cheat Sheet

```
Create:
  Mono.just(val)              → single value
  Mono.empty()                → no value
  Mono.error(ex)              → immediate error
  Mono.fromCallable(fn)       → lazy, from Callable
  Flux.just(a, b, c)          → fixed values
  Flux.fromIterable(list)     → from collection
  Flux.range(start, count)    → integer sequence
  Flux.interval(Duration)     → timed sequence

Transform:
  .map(T → U)                 → sync 1-to-1
  .flatMap(T → Publisher<U>)  → async 1-to-N, merge
  .flatMapSequential(...)     → async 1-to-N, preserve order
  .concatMap(...)             → sequential flatMap

Filter:
  .filter(predicate)          → keep matching
  .take(n)                    → first N
  .skip(n)                    → skip first N
  .distinct()                 → remove duplicates
  .defaultIfEmpty(val)        → fallback if empty

Reduce/Collect:
  .reduce(seed, (a,b) → c)    → fold to single value → Mono<T>
  .collectList()              → Flux<T> → Mono<List<T>>
  .count()                    → Mono<Long>

Combine:
  Flux.merge(f1, f2)          → concurrent, interleaved
  Flux.concat(f1, f2)         → sequential, ordered
  Flux.zip(f1, f2)            → pair by position → Tuple
  mono.zipWith(other)         → pair two Monos

Error:
  .onErrorReturn(val)         → fallback value on error
  .onErrorResume(fn)          → fallback publisher on error
  .onErrorContinue((e,v) →)   → skip bad item, continue
  .retry(n)                   → resubscribe N times on error
  .timeout(Duration)          → error if no item within duration

Threading:
  .subscribeOn(Scheduler)     → source thread
  .publishOn(Scheduler)       → downstream thread
```

---

# CompletableFuture vs Reactor

| Feature | `CompletableFuture` | `Flux` / `Mono` |
|---|---|---|
| Items | Single value | 0 to N values |
| Backpressure | No | Yes |
| Lazy | No (starts immediately) | Yes (starts on subscribe) |
| Cancellation | `cancel()` (best-effort) | Dispose subscription |
| Operators | ~20 combinators | 100+ operators |
| Error handling | `exceptionally`, `handle` | `onErrorReturn`, `onErrorResume`, `retry` |
| Threading | Manual `Executor` | Built-in `Schedulers` |
| Spring support | Basic | Native in Spring WebFlux |
| Best for | Simple async tasks, Java SE | Complex pipelines, microservices, streaming |
***