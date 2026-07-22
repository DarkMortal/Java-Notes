# Java Multithreading Basics

## Table of Contents
1. [What is Multithreading?](#what-is-multithreading)
2. [Thread Lifecycle](#thread-lifecycle)
3. [Runnable Interface](#runnable-interface)
4. [Callable Interface](#callable-interface)
5. [Runnable vs Callable](#runnable-vs-callable)
6. [ExecutorService](#executorservice)
7. [Future Object](#future-object)
8. [Common Examples](#common-examples)
---

## What is Multithreading?

Multithreading allows a program to execute **multiple threads concurrently**, sharing the same process memory. It improves CPU utilization and application responsiveness.

**Key Terms:**
- **Thread** — Smallest unit of execution within a process
- **Concurrency** — Multiple tasks making progress over time
- **Parallelism** — Multiple tasks executing at the exact same instant (requires multiple cores)
- **Race Condition** — Bug when threads access shared data without proper synchronization
- **Deadlock** — Two or more threads waiting on each other indefinitely

---

## Thread Lifecycle

```
NEW → RUNNABLE → RUNNING → BLOCKED/WAITING → TERMINATED
```

| State        | Description                                      |
|--------------|--------------------------------------------------|
| NEW          | Thread created but `start()` not called yet      |
| RUNNABLE     | Ready to run, waiting for CPU                    |
| RUNNING      | Actively executing                               |
| BLOCKED      | Waiting for a monitor lock                       |
| WAITING      | Waiting indefinitely for another thread          |
| TIMED_WAITING| Waiting for a specified time                     |
| TERMINATED   | Execution completed                              |

---

## Runnable Interface

### Definition
```java
@FunctionalInterface
public interface Runnable {
    void run();  // No return value, cannot throw checked exceptions
}
```

### Syntax — Basic Runnable with Thread class

```java
public class BasicRunnableExample {
    public static void main(String[] args) {

        // 1. Using a class that implements Runnable
        Runnable task = new MyTask();
        Thread thread = new Thread(task);
        thread.start();

        // 2. Using an anonymous class
        Runnable anonTask = new Runnable() {
            @Override
            public void run() {
                System.out.println("Running in: " + Thread.currentThread().getName());
            }
        };
        new Thread(anonTask).start();

        // 3. Using a Lambda (Java 8+)
        Runnable lambdaTask = () -> System.out.println("Lambda thread running");
        new Thread(lambdaTask).start();
    }
}

class MyTask implements Runnable {
    @Override
    public void run() {
        System.out.println("MyTask running in: " + Thread.currentThread().getName());
    }
}
```

### Syntax — Runnable with ExecutorService

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class RunnableWithExecutor {
    public static void main(String[] args) {

        // Fixed thread pool with 3 threads
        ExecutorService executor = Executors.newFixedThreadPool(3);

        for (int i = 1; i <= 5; i++) {
            final int taskId = i;
            Runnable task = () -> {
                System.out.println("Task " + taskId + " executed by "
                        + Thread.currentThread().getName());
            };
            executor.submit(task);   // or executor.execute(task)
        }

        executor.shutdown();  // Initiates orderly shutdown, no new tasks accepted
    }
}
```

**Output (order may vary):**
```
Task 1 executed by pool-1-thread-1
Task 2 executed by pool-1-thread-2
Task 3 executed by pool-1-thread-3
Task 4 executed by pool-1-thread-1
Task 5 executed by pool-1-thread-2
```

### Syntax — Runnable with shared state (synchronized)

```java
public class SharedStateRunnable {

    private static int counter = 0;

    public static void main(String[] args) throws InterruptedException {

        Runnable increment = () -> {
            for (int i = 0; i < 1000; i++) {
                synchronized (SharedStateRunnable.class) {
                    counter++;   // synchronized block prevents race condition
                }
            }
        };

        Thread t1 = new Thread(increment);
        Thread t2 = new Thread(increment);

        t1.start();
        t2.start();

        t1.join();   // main thread waits for t1 to finish
        t2.join();   // main thread waits for t2 to finish

        System.out.println("Final counter: " + counter);  // Expected: 2000
    }
}
```

---

## Callable Interface

### Definition
```java
@FunctionalInterface
public interface Callable<V> {
    V call() throws Exception;  // Returns a value AND can throw checked exceptions
}
```

### Syntax — Basic Callable with ExecutorService

```java
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class BasicCallableExample {
    public static void main(String[] args) throws Exception {

        ExecutorService executor = Executors.newSingleThreadExecutor();

        // 1. Using a class that implements Callable
        Callable<Integer> task = new SumTask(1, 100);

        // submit() returns a Future holding the result
        Future<Integer> future = executor.submit(task);

        System.out.println("Doing other work while task runs...");

        // future.get() blocks until result is available
        Integer result = future.get();
        System.out.println("Sum result: " + result);  // 5050

        executor.shutdown();
    }
}

class SumTask implements Callable<Integer> {
    private final int start;
    private final int end;

    SumTask(int start, int end) {
        this.start = start;
        this.end = end;
    }

    @Override
    public Integer call() throws Exception {
        int sum = 0;
        for (int i = start; i <= end; i++) {
            sum += i;
        }
        System.out.println("Computed by: " + Thread.currentThread().getName());
        return sum;
    }
}
```

### Syntax — Callable with Lambda

```java
import java.util.concurrent.*;

public class CallableLambdaExample {
    public static void main(String[] args) throws Exception {

        ExecutorService executor = Executors.newFixedThreadPool(2);

        // Lambda Callable returning a String
        Callable<String> task = () -> {
            Thread.sleep(1000);  // Simulate work
            return "Result from " + Thread.currentThread().getName();
        };

        Future<String> future = executor.submit(task);

        // future.get(timeout, unit) — avoids blocking forever
        String result = future.get(2, TimeUnit.SECONDS);
        System.out.println(result);

        executor.shutdown();
    }
}
```

### Syntax — Multiple Callables with invokeAll()

```java
import java.util.concurrent.*;
import java.util.List;
import java.util.ArrayList;

public class MultipleCallables {
    public static void main(String[] args) throws Exception {

        ExecutorService executor = Executors.newFixedThreadPool(3);

        List<Callable<String>> tasks = new ArrayList<>();
        tasks.add(() -> { Thread.sleep(300); return "Task A done"; });
        tasks.add(() -> { Thread.sleep(100); return "Task B done"; });
        tasks.add(() -> { Thread.sleep(200); return "Task C done"; });

        // invokeAll() waits for ALL tasks to complete
        List<Future<String>> futures = executor.invokeAll(tasks);

        for (Future<String> f : futures) {
            System.out.println(f.get());  // Prints in submission order
        }

        executor.shutdown();
    }
}
```

**Output:**
```
Task A done
Task B done
Task C done
```

### Syntax — invokeAny() (first to finish wins)

```java
import java.util.concurrent.*;
import java.util.List;
import java.util.Arrays;

public class InvokeAnyExample {
    public static void main(String[] args) throws Exception {

        ExecutorService executor = Executors.newFixedThreadPool(3);

        List<Callable<String>> tasks = Arrays.asList(
            () -> { Thread.sleep(500); return "Slow task"; },
            () -> { Thread.sleep(100); return "Fast task"; },
            () -> { Thread.sleep(300); return "Medium task"; }
        );

        // invokeAny() returns result of FIRST task that completes successfully
        String winner = executor.invokeAny(tasks);
        System.out.println("Winner: " + winner);  // Fast task

        executor.shutdown();
    }
}
```

### Syntax — Callable with Exception Handling

```java
import java.util.concurrent.*;

public class CallableExceptionExample {
    public static void main(String[] args) {

        ExecutorService executor = Executors.newSingleThreadExecutor();

        Callable<Integer> riskyTask = () -> {
            int value = Integer.parseInt("not-a-number");  // throws NumberFormatException
            return value;
        };

        Future<Integer> future = executor.submit(riskyTask);

        try {
            Integer result = future.get();
        } catch (ExecutionException e) {
            // The original exception is wrapped in ExecutionException
            System.out.println("Task failed: " + e.getCause().getMessage());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        executor.shutdown();
    }
}
```

---

## Runnable vs Callable

| Feature              | `Runnable`                  | `Callable<V>`                    |
|----------------------|-----------------------------|----------------------------------|
| Return value         | `void` — no return          | Returns `V` via `Future<V>`      |
| Checked exceptions   | Cannot throw                | Can throw `Exception`            |
| Method name          | `run()`                     | `call()`                         |
| Used with            | `Thread`, `ExecutorService` | `ExecutorService` only           |
| Java version         | Since Java 1.0              | Since Java 5                     |
| Result retrieval     | Not possible                | Via `Future.get()`               |

---

## ExecutorService

`ExecutorService` manages a pool of threads and submits tasks to them.

### Thread Pool Types

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

// Fixed pool — fixed number of threads, excess tasks queue up
ExecutorService fixed = Executors.newFixedThreadPool(4);

// Cached pool — creates new threads as needed, reuses idle ones
ExecutorService cached = Executors.newCachedThreadPool();

// Single thread — ensures tasks run sequentially
ExecutorService single = Executors.newSingleThreadExecutor();

// Scheduled — for delayed or periodic tasks
ScheduledExecutorService scheduled = Executors.newScheduledThreadPool(2);
```

### Shutdown Patterns

```java
executor.shutdown();               // Waits for running tasks, no new tasks
executor.shutdownNow();            // Attempts to stop all tasks immediately

// Graceful shutdown pattern
executor.shutdown();
try {
    if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
        executor.shutdownNow();
    }
} catch (InterruptedException e) {
    executor.shutdownNow();
    Thread.currentThread().interrupt();
}
```

---

## Future Object

A `Future<V>` represents a **pending result** of an asynchronous computation.

```java
Future<Integer> future = executor.submit(callableTask);

future.isDone();           // true if completed (normally, exceptionally, or cancelled)
future.isCancelled();      // true if cancelled before completion

future.cancel(true);       // Attempt to cancel; true = interrupt if running

future.get();              // Block indefinitely until result is available
future.get(2, TimeUnit.SECONDS);  // Block for at most 2 seconds → TimeoutException
```

---

## Common Examples

### Example 1 — Parallel File Processing with Callable

```java
import java.util.concurrent.*;
import java.util.List;
import java.util.Arrays;

public class ParallelProcessing {

    static int processFile(String filename) throws InterruptedException {
        Thread.sleep(200);  // Simulate I/O
        System.out.println("Processed: " + filename);
        return filename.length();
    }

    public static void main(String[] args) throws Exception {

        List<String> files = Arrays.asList("report.pdf", "data.csv", "image.png", "notes.txt");

        ExecutorService executor = Executors.newFixedThreadPool(2);

        List<Future<Integer>> futures = new ArrayList<>();
        for (String file : files) {
            futures.add(executor.submit(() -> processFile(file)));
        }

        int totalChars = 0;
        for (Future<Integer> f : futures) {
            totalChars += f.get();
        }

        System.out.println("Total filename chars: " + totalChars);
        executor.shutdown();
    }
}
```

### Example 2 — Producer-Consumer with Runnable

```java
import java.util.concurrent.*;

public class ProducerConsumer {

    private static final BlockingQueue<Integer> queue = new LinkedBlockingQueue<>(5);

    public static void main(String[] args) {

        Runnable producer = () -> {
            for (int i = 1; i <= 10; i++) {
                try {
                    queue.put(i);   // Blocks if queue is full
                    System.out.println("Produced: " + i);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        };

        Runnable consumer = () -> {
            for (int i = 0; i < 10; i++) {
                try {
                    int value = queue.take();   // Blocks if queue is empty
                    System.out.println("Consumed: " + value);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        };

        ExecutorService executor = Executors.newFixedThreadPool(2);
        executor.submit(producer);
        executor.submit(consumer);
        executor.shutdown();
    }
}
```

### Example 3 — Timeout with Callable

```java
import java.util.concurrent.*;

public class TimeoutExample {
    public static void main(String[] args) {

        ExecutorService executor = Executors.newSingleThreadExecutor();

        Callable<String> longTask = () -> {
            Thread.sleep(5000);  // Takes too long
            return "Done";
        };

        Future<String> future = executor.submit(longTask);

        try {
            String result = future.get(2, TimeUnit.SECONDS);  // Only wait 2s
        } catch (TimeoutException e) {
            System.out.println("Task timed out! Cancelling...");
            future.cancel(true);  // Interrupt the running thread
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
        }

        executor.shutdown();
    }
}
```

---

## Quick Reference

```
Thread creation:
  Runnable  → new Thread(runnable).start()
  Callable  → executor.submit(callable) → Future<V>

Return value:
  Runnable  → void
  Callable  → future.get()

Exception handling:
  Runnable  → catch inside run()
  Callable  → catch ExecutionException from future.get()

Always:
  → Call executor.shutdown() after use
  → Call thread.join() if you need to wait for thread completion
  → Use synchronized / AtomicInteger for shared mutable state
```