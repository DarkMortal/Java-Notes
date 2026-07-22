Semantic workspace search is not currently available

Create File

The file creation tool is disabled, so here is the full document — you can copy it into a new file:

---

# Multithreading, Design Patterns & RandomAccessFile — Interview Notes

---

## Key Concepts

### Multithreading
- **Thread** — a lightweight unit of execution within a process; all threads share the same heap but have their own stack.
- **`synchronized`** — acquires the intrinsic (monitor) lock of an object; only one thread can hold it at a time. Can be applied to methods or blocks.
- **`volatile`** — guarantees visibility of writes across threads (no CPU cache hiding); does **not** guarantee atomicity.
- **`wait()` / `notify()` / `notifyAll()`** — must be called inside a `synchronized` block; `wait()` releases the lock; `notify()` wakes one arbitrary waiting thread.
- **`ReentrantLock`** — explicit lock with `lock()` / `unlock()`; supports `tryLock()`, fairness policy, and multiple `Condition` objects.
- **`ExecutorService`** — thread-pool abstraction; decouples task submission from thread management. Key impls: `FixedThreadPool`, `CachedThreadPool`, `ScheduledThreadPool`, `ForkJoinPool`.
- **`Callable<T>` / `Future<T>`** — like `Runnable` but returns a result and can throw checked exceptions; `Future.get()` blocks until done.
- **`CountDownLatch`** — one-shot gate; `await()` blocks until count reaches zero. Not reusable.
- **`CyclicBarrier`** — reusable rendezvous point; all parties must call `await()` before any proceeds.
- **`Semaphore`** — controls access to a fixed number of permits; useful for resource pools.
- **Atomic classes** (`AtomicInteger`, `AtomicReference`, …) — lock-free CAS (Compare-And-Swap); stronger than `volatile`, cheaper than `synchronized`.
- **Happens-before** — a JMM guarantee: if action A happens-before B, B sees A's writes. Established by: `synchronized`, `volatile` writes, `Thread.start()`, `Thread.join()`.

### Design Patterns
- **Creational** — how objects are created: Singleton, Factory Method, Abstract Factory, Builder, Prototype.
- **Structural** — how objects are composed: Adapter, Decorator, Proxy, Facade, Composite, Flyweight.
- **Behavioral** — how objects interact: Strategy, Observer, Command, Template Method, Iterator, State, Chain of Responsibility.
- **Singleton** — one instance per JVM. Thread-safe variants: `enum`, or double-checked locking with `volatile`.
- **Factory Method** — defines an interface for creating an object; subclasses decide which class to instantiate.
- **Builder** — separates construction of a complex object from its representation; avoids telescoping constructors.
- **Strategy** — encapsulates a family of algorithms behind a common interface; swap at runtime.
- **Observer** — subject maintains a list of listeners; notifies all on state change. Basis of event systems and reactive streams.
- **Decorator** — wraps an object to add behaviour without modifying its class. Java I/O streams are the classic example.
- **Proxy** — controls access to another object (lazy init, security checks, logging). Three kinds: virtual, protection, remote.
- **Template Method** — defines a skeleton algorithm in a base class; subclasses fill in specific steps.

### RandomAccessFile
- **`RandomAccessFile`** — allows both reading and writing at arbitrary byte positions in a file; neither `InputStream` nor `OutputStream`.
- **Modes**: `"r"` (read-only), `"rw"` (read-write, lazy flush), `"rws"` (sync content + metadata on every write), `"rwd"` (sync content only).
- **`seek(long pos)`** — moves the file pointer to an absolute byte offset.
- **`getFilePointer()`** — returns the current byte position.
- **`setLength(long)`** — truncates or extends the file.
- Ideal for **fixed-width record files** where records can be read/updated in O(1) without rewriting the whole file.

---

## How It Works (Internals / Mechanics)

### Thread Lifecycle
```
NEW → RUNNABLE → (BLOCKED | WAITING | TIMED_WAITING) → TERMINATED
         ↑___________________↓  (lock acquired / notified)
```
- `BLOCKED` — waiting to enter a `synchronized` block held by another thread.
- `WAITING` — called `wait()`, `join()`, or `LockSupport.park()` with no timeout.
- `TIMED_WAITING` — same but with a timeout (`sleep(ms)`, `wait(ms)`, `tryLock(time, unit)`).

### Double-Checked Locking (Singleton)
```java
public class Singleton {
    private static volatile Singleton instance;   // volatile is mandatory

    private Singleton() {}

    public static Singleton getInstance() {
        if (instance == null) {                   // first check (no lock)
            synchronized (Singleton.class) {
                if (instance == null) {           // second check (with lock)
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}
```
Without `volatile`, the JIT may publish a partially-constructed object due to instruction reordering.

### Enum Singleton (preferred)
```java
public enum Singleton {
    INSTANCE;
    public void doWork() { ... }
}
```
Thread-safety and serialisation safety guaranteed by the JVM class loader.

### ForkJoinPool & Work-Stealing
- Each worker thread has its own deque of tasks.
- Idle threads **steal** tasks from the tail of busy threads' deques → high CPU utilisation for recursive, divide-and-conquer tasks.
- Backing pool for parallel streams (`ForkJoinPool.commonPool()`).

### RandomAccessFile Under the Hood
```
File on disk
 ┌──────────────────────────────────────────┐
 │ record 0 (64 bytes) │ record 1 (64 bytes)│ ...
 └──────────────────────────────────────────┘
           ↑ seek(64) moves pointer here → read/write record 1
```
- Backed by a native file descriptor; reads/writes map to OS `pread`/`pwrite` syscalls.
- No internal buffering by default — every call may hit disk unless the OS page cache helps.

---

## Common Pitfalls & Edge Cases

### Multithreading
- **`volatile` ≠ atomic** — `count++` on a `volatile int` is still a read-modify-write race. Use `AtomicInteger.incrementAndGet()`.
- **Calling `notify()` without owning the lock** → `IllegalMonitorStateException`.
- **Spurious wakeups** — `wait()` can return without `notify()`. Always guard with a loop:
  ```java
  while (!condition) { wait(); }
  ```
- **`ThreadLocal` leaks** — in thread-pool environments, always call `threadLocal.remove()` after use; threads are reused and old values persist.
- **`synchronized` on non-final fields** — if the reference changes, different threads may lock on different objects.
- **`ExecutorService` not shut down** — threads stay alive and prevent JVM exit. Always call `shutdown()` in a `finally` block.
- **Deadlock** — Thread A holds lock 1 and waits for lock 2; Thread B holds lock 2 and waits for lock 1. Detect with `jstack` or `ThreadMXBean.findDeadlockedThreads()`.

### Design Patterns
- **Singleton and serialisation** — a non-enum Singleton breaks on deserialisation unless you implement `readResolve()`.
- **Observer memory leaks** — listeners that are never deregistered keep the subject alive (classic Android/Swing bug).
- **Overusing Singleton** — turns into global state; makes unit testing difficult (can't easily swap the dependency).
- **Builder vs constructor** — Builder shines at ≥4 optional parameters; for 1–2 params it's over-engineering.

### RandomAccessFile
- **Not buffered** — wrapping with `BufferedInputStream` doesn't help; use `FileChannel` with `MappedByteBuffer` for high-throughput sequential reads.
- **Mode `"rw"` does not `fsync`** — data may sit in the OS page cache; use `"rws"` or call `getFD().sync()` for durability guarantees.
- **No charset handling** — `readUTF()` / `writeUTF()` use a modified UTF-8; for arbitrary charsets, read raw bytes and decode manually.
- **Not thread-safe** — external synchronisation required for concurrent access.

---

## Interview Q&A

### Conceptual Questions

**Q: What is the difference between `synchronized` and `ReentrantLock`?**
> **A:** Both provide mutual exclusion, but `ReentrantLock` offers more control: `tryLock()` with a timeout (avoids indefinite blocking), multiple `Condition` objects per lock (vs one `wait`/`notify` per intrinsic lock), and a fairness option. `synchronized` is simpler and automatically releases on exception; `ReentrantLock` requires explicit `unlock()` in a `finally` block. Prefer `synchronized` unless you need the advanced features.

**Q: What does `volatile` guarantee and what does it not guarantee?**
> **A:** `volatile` guarantees **visibility** — a write is immediately visible to all threads, and reads always see the latest written value. It also prevents instruction reordering around the variable. It does **not** guarantee **atomicity** — compound actions like `i++` are still subject to race conditions and must use `Atomic*` classes or `synchronized`.

**Q: What is the happens-before relationship in the Java Memory Model?**
> **A:** Happens-before is a guarantee that the effects of one action are visible to another. Key rules: a `synchronized` unlock happens-before the next lock on that monitor; a `volatile` write happens-before every subsequent read of that variable; `Thread.start()` happens-before any action in the started thread; all actions in a thread happen-before `Thread.join()` returns. Without happens-before, the JMM allows compilers and CPUs to reorder reads and writes freely.

**Q: What is the difference between `CountDownLatch` and `CyclicBarrier`?**
> **A:** `CountDownLatch` is a one-shot counter — once it reaches zero it cannot be reset. It is used when one or more threads wait for a set of operations in other threads to complete. `CyclicBarrier` is reusable — after all parties have called `await()`, the barrier resets automatically for the next round. It is used for iterative parallel algorithms where threads synchronise at the end of each phase.

**Q: When would you choose the Strategy pattern over inheritance?**
> **A:** Use Strategy when the varying part is an algorithm or policy that you want to swap at runtime without changing the host class. Inheritance bakes behaviour into the class hierarchy — swapping it requires a new subclass. Strategy favours composition over inheritance, keeping the host class open for extension (new strategies) without modification (Open/Closed Principle). Classic examples: sorting comparators, payment processors, compression algorithms.

**Q: What is the difference between the Decorator and Proxy patterns?**
> **A:** Both wrap an object and implement the same interface, but their intent differs. **Decorator** adds or augments behaviour — `BufferedInputStream` adds buffering to any `InputStream`. **Proxy** controls access — it may add lazy initialisation, access checks, logging, or remote invocation, but the client believes it is talking to the real object. Decorators are typically stacked in multiple layers; proxies typically have one level of wrapping.

**Q: What is `RandomAccessFile` and how does it differ from `FileInputStream`?**
> **A:** `RandomAccessFile` allows both reading and writing at any arbitrary byte offset using `seek()`, making it ideal for fixed-width record files or binary formats. `FileInputStream` is a forward-only read stream — you cannot jump to an arbitrary position without skipping bytes, and you cannot write. `RandomAccessFile` is backed directly by a file descriptor and has no parent in the stream hierarchy.

---

### Scenario-Based Questions

**Q: A Singleton works fine in single-threaded tests but occasionally returns a partially-initialised instance in production under load. What is the cause and how do you fix it?**
> **A:** The cause is double-checked locking without `volatile`. Without `volatile`, the JIT can reorder the write to `instance` before the constructor finishes, so another thread sees a non-null but not-yet-constructed object. Fix 1 — add `volatile` to the `instance` field, which establishes a happens-before barrier. Fix 2 (preferred) — use an `enum` singleton, which the JVM class loader initialises atomically with no extra boilerplate.

**Q: Given this code, what is the output and why?**
```java
int count = 0; // shared, no synchronisation
Runnable r = () -> { for (int i = 0; i < 1000; i++) count++; };
Thread t1 = new Thread(r), t2 = new Thread(r);
t1.start(); t2.start();
t1.join(); t2.join();
System.out.println(count);
```
> **A:** The output is **non-deterministic** and almost certainly less than 2000. `count++` is three operations (read, increment, write); without synchronisation, threads read stale cached values and overwrite each other's increments. Fix: use `AtomicInteger.incrementAndGet()`, or `synchronized` on the block, or accumulate results locally and combine after `join()`.

**Q: You need to update a single employee record (128 bytes each) in a binary file containing millions of records, by record ID, in under 1ms. How do you implement this?**
> **A:** Use `RandomAccessFile` in `"rw"` mode. Calculate the byte offset as `recordId * 128`, call `seek(offset)`, then write the 128 bytes. This is O(1) and avoids reading the entire file. For durability call `getFD().sync()` or open in `"rws"` mode after the write.
> ```java
> try (RandomAccessFile raf = new RandomAccessFile("employees.dat", "rw")) {
>     raf.seek((long) recordId * 128);
>     raf.write(recordBytes); // exactly 128 bytes
> }
> ```

**Q: You need a thread-safe cache where the first thread requesting an absent key computes the value while other threads for the same key wait — but threads requesting different keys must not block each other. How do you design this?**
> **A:** Use `ConcurrentHashMap` with `Future<V>` values. `computeIfAbsent()` provides per-key locking internally — different keys proceed in parallel. Storing a `Future` prevents duplicate computation even across the brief window before the first result is written:
> ```java
> ConcurrentHashMap<String, Future<Value>> cache = new ConcurrentHashMap<>();
> 
> Value get(String key) throws Exception {
>     Future<Value> f = cache.computeIfAbsent(key,
>         k -> executor.submit(() -> compute(k)));
>     return f.get();
> }
> ```

**Q: You must add request-logging to every method on a third-party `PaymentGateway` interface without modifying its source. Which pattern do you use?**
> **A:** Use the **Proxy** pattern. Either write a hand-rolled wrapper class (type-safe, easy to test) or use `java.lang.reflect.Proxy` for a dynamic solution:
> ```java
> PaymentGateway proxy = (PaymentGateway) Proxy.newProxyInstance(
>     real.getClass().getClassLoader(),
>     new Class[]{PaymentGateway.class},
>     (p, method, args) -> {
>         log.info("→ {}", method.getName());
>         Object result = method.invoke(real, args);
>         log.info("← {}", method.getName());
>         return result;
>     }
> );
> ```
> For production use, Spring AOP achieves the same result declaratively with `@Around` advice.

---

## Quick Reference

### Multithreading

| Tool | Guarantee | Use When |
|---|---|---|
| `synchronized` | Mutual exclusion + visibility | Simple critical sections |
| `volatile` | Visibility only | Single-writer flag / state |
| `AtomicInteger` | Atomic CAS | Lock-free counters |
| `ReentrantLock` | Mutex + `tryLock` + `Condition` | Need timeout or multiple conditions |
| `CountDownLatch` | One-shot await | Wait for N tasks to finish |
| `CyclicBarrier` | Reusable rendezvous | Iterative parallel phases |
| `Semaphore` | N permits | Throttle concurrent access |
| `CompletableFuture` | Async pipeline | Composing async results (Java 8+) |

### Design Patterns

| Pattern | Type | One-line purpose |
|---|---|---|
| Singleton | Creational | One instance per JVM |
| Factory Method | Creational | Subclass decides which object to create |
| Builder | Creational | Step-by-step construction, no telescoping constructors |
| Strategy | Behavioral | Swap algorithms at runtime |
| Observer | Behavioral | Event notification to multiple listeners |
| Template Method | Behavioral | Fixed skeleton, variable steps in subclasses |
| Decorator | Structural | Add behaviour by wrapping (`BufferedInputStream`) |
| Proxy | Structural | Control access — logging, lazy init, security |
| Adapter | Structural | Bridge incompatible interfaces |

### RandomAccessFile

```java
RandomAccessFile raf = new RandomAccessFile("data.bin", "rw");
raf.seek(offset);                // move to byte position
long pos = raf.getFilePointer(); // current position
raf.readInt() / raf.writeInt(n); // typed reads/writes
raf.setLength(newSize);          // truncate or extend
raf.getFD().sync();              // force flush to disk
raf.close();                     // or use try-with-resources
```

- Modes: `"r"` read-only · `"rw"` read-write · `"rws"` sync all · `"rwd"` sync data only
- Record seek formula: `seek((long) recordIndex * RECORD_SIZE)`
***