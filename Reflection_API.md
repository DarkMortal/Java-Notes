# Java Reflection API

## Table of Contents
1. [What is Reflection?](#what-is-reflection)
2. [Getting the Class Object](#getting-the-class-object)
3. [Inspecting Class Metadata](#inspecting-class-metadata)
4. [Working with Fields](#working-with-fields)
5. [Working with Methods](#working-with-methods)
6. [Working with Constructors](#working-with-constructors)
7. [Working with Annotations](#working-with-annotations)
8. [Access Control — setAccessible()](#access-control--setaccessible)
9. [Practical Examples](#practical-examples)
10. [Limitations & Cautions](#limitations--cautions)

---

## What is Reflection?

Reflection is a Java API (`java.lang.reflect`) that lets you **inspect and manipulate classes, methods, fields, and constructors at runtime** — even if they are private or unknown at compile time.

**Use cases:**
- Frameworks (Spring, Hibernate, JUnit) — dependency injection, ORM mapping, test discovery
- Serialization / deserialization libraries (Jackson, Gson)
- IDEs and debuggers
- Dynamic proxy creation

**Core classes:**
| Class | Purpose |
|---|---|
| `java.lang.Class<T>` | Entry point — represents a class/interface |
| `java.lang.reflect.Field` | Represents a field (variable) |
| `java.lang.reflect.Method` | Represents a method |
| `java.lang.reflect.Constructor<T>` | Represents a constructor |
| `java.lang.reflect.Modifier` | Decodes access modifiers |
| `java.lang.reflect.Annotation` | Represents annotations |

---

## Getting the Class Object

Every operation starts with obtaining a `Class<?>` object.

```java
// 1. From a type name (compile-time known)
Class<String> c1 = String.class;

// 2. From an instance
String str = "hello";
Class<?> c2 = str.getClass();

// 3. From fully-qualified class name (runtime / config-driven)
Class<?> c3 = Class.forName("java.util.ArrayList");

// 4. From a primitive
Class<?> c4 = int.class;       // int
Class<?> c5 = int[].class;     // int array
```

**Output (c3.getName()):**
```
java.util.ArrayList
```

> `Class.forName()` throws `ClassNotFoundException` if the class is not on the classpath.

---

## Inspecting Class Metadata

```java
import java.lang.reflect.*;

public class ClassInspector {
    public static void main(String[] args) {
        Class<?> clazz = ArrayList.class;

        System.out.println("Name        : " + clazz.getName());
        System.out.println("Simple Name : " + clazz.getSimpleName());
        System.out.println("Package     : " + clazz.getPackageName());
        System.out.println("Superclass  : " + clazz.getSuperclass().getSimpleName());
        System.out.println("Is Interface: " + clazz.isInterface());
        System.out.println("Is Abstract : " + Modifier.isAbstract(clazz.getModifiers()));

        // Interfaces implemented
        for (Class<?> iface : clazz.getInterfaces()) {
            System.out.println("Interface   : " + iface.getSimpleName());
        }
    }
}
```

**Output:**
```
Name        : java.util.ArrayList
Simple Name : ArrayList
Package     : java.util
Superclass  : AbstractList
Is Interface: false
Is Abstract : false
Interface   : List
Interface   : RandomAccess
Interface   : Cloneable
Interface   : Serializable
```

---

## Working with Fields

| Method | Returns |
|---|---|
| `getFields()` | All **public** fields (including inherited) |
| `getDeclaredFields()` | All fields **declared in this class** (any access) |
| `getField("name")` | Single public field by name |
| `getDeclaredField("name")` | Single declared field by name |

### Read & Write Field Values

```java
import java.lang.reflect.Field;

class Person {
    public String name = "Alice";
    private int age = 30;
}

public class FieldExample {
    public static void main(String[] args) throws Exception {
        Person p = new Person();
        Class<?> clazz = p.getClass();

        // --- Public field ---
        Field nameField = clazz.getDeclaredField("name");
        System.out.println("Before: " + nameField.get(p));   // Alice
        nameField.set(p, "Bob");
        System.out.println("After : " + nameField.get(p));   // Bob

        // --- Private field ---
        Field ageField = clazz.getDeclaredField("age");
        ageField.setAccessible(true);                        // Bypass private
        System.out.println("Age   : " + ageField.get(p));   // 30
        ageField.set(p, 25);
        System.out.println("New Age: " + ageField.get(p));  // 25

        // --- Print all declared fields ---
        for (Field f : clazz.getDeclaredFields()) {
            f.setAccessible(true);
            System.out.println(f.getName() + " = " + f.get(p));
        }
    }
}
```

**Output:**
```
Before: Alice
After : Bob
Age   : 30
New Age: 25
name = Bob
age = 25
```

---

## Working with Methods

| Method | Returns |
|---|---|
| `getMethods()` | All **public** methods (including inherited) |
| `getDeclaredMethods()` | All methods **declared in this class** |
| `getMethod("name", paramTypes...)` | Single public method by signature |
| `getDeclaredMethod("name", paramTypes...)` | Single declared method by signature |

### Invoke Methods

```java
import java.lang.reflect.Method;

class Calculator {
    public int add(int a, int b) { return a + b; }
    private String secret() { return "hidden value"; }
}

public class MethodExample {
    public static void main(String[] args) throws Exception {
        Calculator calc = new Calculator();
        Class<?> clazz = calc.getClass();

        // --- Invoke public method ---
        Method addMethod = clazz.getMethod("add", int.class, int.class);
        Object result = addMethod.invoke(calc, 10, 20);
        System.out.println("add(10,20) = " + result);          // 30

        // --- Invoke private method ---
        Method secretMethod = clazz.getDeclaredMethod("secret");
        secretMethod.setAccessible(true);
        Object secret = secretMethod.invoke(calc);
        System.out.println("secret()   = " + secret);          // hidden value

        // --- Inspect method metadata ---
        System.out.println("Return type: " + addMethod.getReturnType().getSimpleName());
        System.out.println("Modifiers  : " + Modifier.toString(addMethod.getModifiers()));
        for (Class<?> param : addMethod.getParameterTypes()) {
            System.out.println("Param type : " + param.getSimpleName());
        }
    }
}
```

**Output:**
```
add(10,20) = 30
secret()   = hidden value
Return type: int
Modifiers  : public
Param type : int
Param type : int
```

---

## Working with Constructors

| Method | Returns |
|---|---|
| `getConstructors()` | All **public** constructors |
| `getDeclaredConstructors()` | All constructors (any access) |
| `getConstructor(paramTypes...)` | Single public constructor by param types |
| `getDeclaredConstructor(paramTypes...)` | Single constructor by param types |

### Create Instances via Reflection

```java
import java.lang.reflect.Constructor;

class Animal {
    private String name;
    private int legs;

    public Animal() { this.name = "Unknown"; this.legs = 4; }

    public Animal(String name, int legs) {
        this.name = name;
        this.legs = legs;
    }

    @Override
    public String toString() { return name + " has " + legs + " legs"; }
}

public class ConstructorExample {
    public static void main(String[] args) throws Exception {
        Class<?> clazz = Animal.class;

        // --- No-arg constructor ---
        Constructor<?> noArg = clazz.getConstructor();
        Animal a1 = (Animal) noArg.newInstance();
        System.out.println(a1);                             // Unknown has 4 legs

        // --- Parameterized constructor ---
        Constructor<?> paramCtor = clazz.getConstructor(String.class, int.class);
        Animal a2 = (Animal) paramCtor.newInstance("Spider", 8);
        System.out.println(a2);                             // Spider has 8 legs

        // --- List all constructors ---
        for (Constructor<?> c : clazz.getDeclaredConstructors()) {
            System.out.println("Constructor: " + c);
        }
    }
}
```

**Output:**
```
Unknown has 4 legs
Spider has 8 legs
Constructor: public Animal()
Constructor: public Animal(java.lang.String, int)
```

---

## Working with Annotations

```java
import java.lang.annotation.*;
import java.lang.reflect.*;

// Define a custom annotation
@Retention(RetentionPolicy.RUNTIME)   // Must be RUNTIME to be visible via Reflection
@Target({ElementType.TYPE, ElementType.METHOD})
@interface Info {
    String author();
    String version() default "1.0";
}

@Info(author = "Alice", version = "2.0")
class Service {
    @Info(author = "Bob")
    public void process() {}
}

public class AnnotationExample {
    public static void main(String[] args) throws Exception {
        Class<?> clazz = Service.class;

        // --- Class-level annotation ---
        if (clazz.isAnnotationPresent(Info.class)) {
            Info info = clazz.getAnnotation(Info.class);
            System.out.println("Class author : " + info.author());    // Alice
            System.out.println("Class version: " + info.version());   // 2.0
        }

        // --- Method-level annotation ---
        Method method = clazz.getMethod("process");
        Info methodInfo = method.getAnnotation(Info.class);
        System.out.println("Method author: " + methodInfo.author());  // Bob
        System.out.println("Method version: " + methodInfo.version()); // 1.0 (default)
    }
}
```

**Output:**
```
Class author : Alice
Class version: 2.0
Method author: Bob
Method version: 1.0
```

---

## Access Control — setAccessible()

`setAccessible(true)` suppresses Java access checks, allowing you to read/write private members.

```java
import java.lang.reflect.Field;

class Config {
    private static final String SECRET_KEY = "abc123";
}

public class AccessExample {
    public static void main(String[] args) throws Exception {
        Field field = Config.class.getDeclaredField("SECRET_KEY");
        field.setAccessible(true);

        // Read private static final field
        String key = (String) field.get(null);   // null → static field, no instance needed
        System.out.println("Secret key: " + key);  // abc123
    }
}
```

**Output:**
```
Secret key: abc123
```

> **Note:** From Java 9+, modules restrict `setAccessible()` across module boundaries. Opening a package via `module-info.java` (`opens com.example;`) is required for cross-module reflection.

---

## Practical Examples

### Example 1 — Simple Dependency Injection (like Spring)

```java
import java.lang.annotation.*;
import java.lang.reflect.Field;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
@interface Inject {}

class Engine { public String start() { return "Engine started"; } }

class Car {
    @Inject
    private Engine engine;

    public void drive() {
        System.out.println(engine.start());
    }
}

public class DIContainer {
    // Scans fields annotated with @Inject and sets them automatically
    static void inject(Object target) throws Exception {
        for (Field field : target.getClass().getDeclaredFields()) {
            if (field.isAnnotationPresent(Inject.class)) {
                Object dependency = field.getType().getDeclaredConstructor().newInstance();
                field.setAccessible(true);
                field.set(target, dependency);
                System.out.println("Injected: " + field.getType().getSimpleName()
                        + " into " + target.getClass().getSimpleName());
            }
        }
    }

    public static void main(String[] args) throws Exception {
        Car car = new Car();
        inject(car);
        car.drive();
    }
}
```

**Output:**
```
Injected: Engine into Car
Engine started
```

---

### Example 2 — Generic Object-to-String Serializer

```java
import java.lang.reflect.Field;

class Student {
    private String name = "Alice";
    private int grade = 90;
    private double gpa = 3.8;
}

public class ObjectSerializer {
    static String serialize(Object obj) throws Exception {
        StringBuilder sb = new StringBuilder();
        sb.append(obj.getClass().getSimpleName()).append("{");
        Field[] fields = obj.getClass().getDeclaredFields();
        for (int i = 0; i < fields.length; i++) {
            fields[i].setAccessible(true);
            sb.append(fields[i].getName()).append("=").append(fields[i].get(obj));
            if (i < fields.length - 1) sb.append(", ");
        }
        sb.append("}");
        return sb.toString();
    }

    public static void main(String[] args) throws Exception {
        System.out.println(serialize(new Student()));
    }
}
```

**Output:**
```
Student{name=Alice, grade=90, gpa=3.8}
```

---

### Example 3 — Dynamic Method Dispatcher

```java
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

class Commands {
    public void sayHello() { System.out.println("Hello!"); }
    public void sayBye()   { System.out.println("Goodbye!"); }
    public void status()   { System.out.println("System OK"); }
}

public class MethodDispatcher {
    public static void main(String[] args) throws Exception {
        Commands commands = new Commands();
        Class<?> clazz = commands.getClass();

        // Map command strings to method names dynamically
        String[] userInputs = {"sayHello", "status", "sayBye", "unknown"};

        for (String input : userInputs) {
            try {
                Method method = clazz.getMethod(input);
                method.invoke(commands);
            } catch (NoSuchMethodException e) {
                System.out.println("Unknown command: " + input);
            }
        }
    }
}
```

**Output:**
```
Hello!
System OK
Goodbye!
Unknown command: unknown
```

---

## Limitations & Cautions

| Concern | Detail |
|---|---|
| **Performance** | Reflection is slower than direct calls — avoid in hot paths |
| **Security** | `setAccessible(true)` breaks encapsulation — use carefully |
| **Module system** | Java 9+ modules can block reflective access across module boundaries |
| **Type safety** | No compile-time checks — errors surface at runtime |
| **Refactoring** | Field/method names as strings break silently on rename |

---

## Quick Reference

```
Get Class object:
  ClassName.class          → compile-time known type
  object.getClass()        → from instance
  Class.forName("pkg.Name") → from string (throws ClassNotFoundException)

Inspect:
  clazz.getDeclaredFields()      → all fields in class
  clazz.getDeclaredMethods()     → all methods in class
  clazz.getDeclaredConstructors()→ all constructors

Access private members:
  field.setAccessible(true)
  method.setAccessible(true)

Invoke:
  method.invoke(instance, args...)      → call method
  constructor.newInstance(args...)      → create object
  field.get(instance)                   → read field
  field.set(instance, value)            → write field

Static members: pass null as the instance
  field.get(null)
  method.invoke(null, args...)
```
