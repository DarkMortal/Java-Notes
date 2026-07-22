# Java Exceptions

## Table of Contents
1. [Exception Class Hierarchy](#exception-class-hierarchy)
2. [Checked vs Unchecked Exceptions](#checked-vs-unchecked-exceptions)
3. [Syntax — try / catch / finally](#syntax--try--catch--finally)
4. [Multi-catch & Re-throwing](#multi-catch--re-throwing)
5. [try-with-resources](#try-with-resources)
6. [Creating Custom Exceptions](#creating-custom-exceptions)
7. [Common Built-in Exceptions](#common-built-in-exceptions)
8. [Best Practices](#best-practices)
9. [Quick Reference](#quick-reference)

---

## Exception Class Hierarchy

```
java.lang.Object
    └── java.lang.Throwable
            ├── java.lang.Error                        ← NOT meant to be caught
            │       ├── OutOfMemoryError
            │       ├── StackOverflowError
            │       ├── VirtualMachineError
            │       └── AssertionError
            │
            └── java.lang.Exception                    ← Catch & handle
                    ├── IOException                    ← CHECKED
                    │       ├── FileNotFoundException
                    │       └── SocketException
                    ├── SQLException                   ← CHECKED
                    ├── ClassNotFoundException         ← CHECKED
                    ├── CloneNotSupportedException     ← CHECKED
                    │
                    └── RuntimeException               ← UNCHECKED
                            ├── NullPointerException
                            ├── ArrayIndexOutOfBoundsException
                            ├── ClassCastException
                            ├── ArithmeticException
                            ├── NumberFormatException
                            ├── IllegalArgumentException
                            ├── IllegalStateException
                            ├── UnsupportedOperationException
                            └── ConcurrentModificationException
```

> **Rule of thumb:**
> - `Error` → JVM-level, fatal, don't catch
> - `Exception` (non-Runtime) → **Checked** — must handle
> - `RuntimeException` → **Unchecked** — optional to handle

---

## Checked vs Unchecked Exceptions

| Feature | Checked Exception | Unchecked Exception |
|---|---|---|
| Extends | `Exception` (not RuntimeException) | `RuntimeException` |
| Compiler enforces? | **Yes** — must catch or declare `throws` | **No** — optional |
| When to use | Recoverable, external failures (I/O, network, DB) | Programming bugs, invalid state |
| Examples | `IOException`, `SQLException`, `ClassNotFoundException` | `NullPointerException`, `IllegalArgumentException` |
| `throws` declaration | Required in method signature | Optional |

### Checked Exception — compiler forces you to handle it

```java
import java.io.*;

public class CheckedExample {

    // Must declare throws OR wrap in try-catch — compiler enforces this
    public static String readFile(String path) throws IOException {
        BufferedReader reader = new BufferedReader(new FileReader(path));
        return reader.readLine();
    }

    public static void main(String[] args) {
        try {
            String line = readFile("data.txt");
            System.out.println(line);
        } catch (IOException e) {
            System.out.println("File error: " + e.getMessage());
        }
    }
}
```

**Output (if file missing):**
```
File error: data.txt (No such file or directory)
```

### Unchecked Exception — no compiler enforcement

```java
public class UncheckedExample {

    public static int divide(int a, int b) {
        // No throws declaration needed — unchecked
        return a / b;  // throws ArithmeticException if b == 0
    }

    public static void main(String[] args) {
        System.out.println(divide(10, 2));    // 5
        System.out.println(divide(10, 0));    // throws ArithmeticException
    }
}
```

**Output:**
```
5
Exception in thread "main" java.lang.ArithmeticException: / by zero
    at UncheckedExample.divide(UncheckedExample.java:4)
```

---

## Syntax — try / catch / finally

```java
public class TryCatchExample {
    public static void main(String[] args) {

        try {
            System.out.println("Step 1");
            int[] arr = new int[3];
            arr[10] = 5;                        // throws ArrayIndexOutOfBoundsException
            System.out.println("Step 2");       // never reached
        } catch (ArrayIndexOutOfBoundsException e) {
            System.out.println("Caught: " + e.getMessage());   // Index 10 out of bounds
        } finally {
            // ALWAYS executes — even if exception occurs or return is called
            System.out.println("Finally block — cleanup here");
        }

        System.out.println("After try-catch");
    }
}
```

**Output:**
```
Step 1
Caught: Index 10 out of bounds for length 3
Finally block — cleanup here
After try-catch
```

### Catch order matters — most specific first

```java
try {
    // risky code
} catch (FileNotFoundException e) {   // ✓ specific first
    System.out.println("File not found");
} catch (IOException e) {             // ✓ broader second
    System.out.println("IO error");
} catch (Exception e) {               // ✓ broadest last
    System.out.println("General error");
}
// Reversed order → compile error: "exception already caught"
```

---

## Multi-catch & Re-throwing

### Multi-catch (Java 7+) — handle multiple types together

```java
public class MultiCatchExample {
    public static void main(String[] args) {
        try {
            String s = null;
            s.length();           // NullPointerException
        } catch (NullPointerException | IllegalArgumentException e) {
            // Both handled the same way
            System.out.println("Caught: " + e.getClass().getSimpleName());
        }
    }
}
```

**Output:**
```
Caught: NullPointerException
```

### Re-throwing — catch, log, then propagate up

```java
public class RethrowExample {

    static void process() throws IOException {
        try {
            throw new IOException("Disk read failed");
        } catch (IOException e) {
            System.out.println("Logging: " + e.getMessage());
            throw e;   // re-throw original
        }
    }

    public static void main(String[] args) {
        try {
            process();
        } catch (IOException e) {
            System.out.println("Handled in main: " + e.getMessage());
        }
    }
}
```

**Output:**
```
Logging: Disk read failed
Handled in main: Disk read failed
```

### Wrapping (Exception Chaining)

```java
try {
    // low-level operation
    throw new SQLException("DB connection failed");
} catch (SQLException e) {
    // wrap in higher-level exception, preserve cause
    throw new RuntimeException("Order processing failed", e);
}

// Retrieve cause:
try { ... }
catch (RuntimeException e) {
    System.out.println("Cause: " + e.getCause().getMessage());
    // Cause: DB connection failed
}
```

---

## try-with-resources

Automatically closes resources that implement `AutoCloseable`. No need for `finally` to call `close()`.

```java
import java.io.*;

public class TryWithResources {
    public static void main(String[] args) {

        // Resource is auto-closed after the try block — even on exception
        try (BufferedReader reader = new BufferedReader(new FileReader("data.txt"))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
        } catch (IOException e) {
            System.out.println("Error: " + e.getMessage());
        }
        // reader.close() called automatically here
    }
}
```

### Multiple resources (closed in reverse order)

```java
try (
    FileInputStream  in  = new FileInputStream("input.txt");
    FileOutputStream out = new FileOutputStream("output.txt")
) {
    // use both streams
    // out closed first, then in
} catch (IOException e) {
    e.printStackTrace();
}
```

**Output (file missing):**
```
Error: input.txt (No such file or directory)
```

---

## Creating Custom Exceptions

### Custom Checked Exception

```java
// Extend Exception for checked
public class InsufficientFundsException extends Exception {

    private final double amount;

    public InsufficientFundsException(double amount) {
        super("Insufficient funds. Shortfall: " + amount);
        this.amount = amount;
    }

    public double getAmount() { return amount; }
}

class BankAccount {
    private double balance = 100.0;

    public void withdraw(double amount) throws InsufficientFundsException {
        if (amount > balance) {
            throw new InsufficientFundsException(amount - balance);
        }
        balance -= amount;
    }
}

public class CustomCheckedException {
    public static void main(String[] args) {
        BankAccount account = new BankAccount();
        try {
            account.withdraw(150.0);
        } catch (InsufficientFundsException e) {
            System.out.println("Error   : " + e.getMessage());
            System.out.println("Shortfall: " + e.getAmount());
        }
    }
}
```

**Output:**
```
Error   : Insufficient funds. Shortfall: 50.0
Shortfall: 50.0
```

### Custom Unchecked Exception

```java
// Extend RuntimeException for unchecked
public class InvalidAgeException extends RuntimeException {

    public InvalidAgeException(int age) {
        super("Invalid age: " + age + ". Must be between 0 and 150.");
    }
}

class Person {
    private int age;

    public void setAge(int age) {
        if (age < 0 || age > 150) {
            throw new InvalidAgeException(age);   // no throws declaration needed
        }
        this.age = age;
    }
}

public class CustomUncheckedException {
    public static void main(String[] args) {
        Person p = new Person();
        p.setAge(-5);   // throws InvalidAgeException
    }
}
```

**Output:**
```
Exception in thread "main" InvalidAgeException: Invalid age: -5. Must be between 0 and 150.
```

---

## Common Built-in Exceptions

### Unchecked (RuntimeException subclasses)

| Exception | Caused by |
|---|---|
| `NullPointerException` | Accessing a method/field on `null` |
| `ArrayIndexOutOfBoundsException` | Index < 0 or >= array length |
| `StringIndexOutOfBoundsException` | Index out of String range |
| `ClassCastException` | Invalid cast: `(String) someObject` |
| `ArithmeticException` | `int / 0` |
| `NumberFormatException` | `Integer.parseInt("abc")` |
| `IllegalArgumentException` | Invalid argument passed to a method |
| `IllegalStateException` | Method called at wrong time |
| `StackOverflowError` | Infinite/deep recursion |
| `ConcurrentModificationException` | Modifying collection while iterating |
| `UnsupportedOperationException` | Calling unsupported method (e.g., on immutable list) |

### Checked (Exception subclasses)

| Exception | Caused by |
|---|---|
| `IOException` | General I/O failure |
| `FileNotFoundException` | File doesn't exist |
| `SQLException` | Database access error |
| `ClassNotFoundException` | Class not found via `Class.forName()` |
| `InterruptedException` | Thread interrupted while sleeping/waiting |
| `ParseException` | Parsing failure (dates, numbers) |

---

## Best Practices

```java
// ✓ Catch specific exceptions, not broad Exception
catch (FileNotFoundException e) { ... }   // good
catch (Exception e) { ... }               // avoid unless last resort

// ✓ Never swallow exceptions silently
catch (IOException e) {
    // log it at minimum
    logger.error("Failed to read file", e);
}

// ✗ Never do this
catch (IOException e) { }   // silent swallow — hides bugs

// ✓ Use finally / try-with-resources for cleanup
try (Connection conn = dataSource.getConnection()) { ... }

// ✓ Preserve exception cause when wrapping
throw new ServiceException("Order failed", originalException);

// ✓ Use unchecked for programming errors
throw new IllegalArgumentException("id must be positive, got: " + id);

// ✓ Use checked for recoverable external failures
throw new IOException("Could not connect to " + url);

// ✓ Add context to exception messages
throw new IllegalStateException(
    "Cannot cancel order " + orderId + " in state: " + status
);
```

---

## Quick Reference

```
Hierarchy:
  Throwable
    ├── Error         → JVM fatal, don't catch
    └── Exception
          ├── Checked     → must handle (IOException, SQLException)
          └── RuntimeException → Unchecked (NPE, ClassCastException)

Checked vs Unchecked:
  Checked   → extends Exception (not RuntimeException)
              compiler enforces try-catch or throws declaration
  Unchecked → extends RuntimeException
              no compiler enforcement

try-catch-finally:
  try     → risky code
  catch   → handle (specific → broad order)
  finally → ALWAYS runs (cleanup)

try-with-resources:
  try (Resource r = ...) { }   → auto-closes AutoCloseable

Custom exceptions:
  Checked   → extend Exception
  Unchecked → extend RuntimeException

Key methods on Throwable:
  e.getMessage()    → error message
  e.getCause()      → wrapped original exception
  e.getStackTrace() → stack frames
  e.printStackTrace()→ print full trace to stderr
```
