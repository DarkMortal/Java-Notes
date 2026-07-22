# Spring Stereotypes & Dependency Injection

---

## What is Dependency Injection?
- Instead of a class creating its own dependencies using `new`, an external system (Spring) **creates and provides** them.
- This is called **Inversion of Control (IoC)** — you give up control of object creation to the framework.
- Makes code loosely coupled, easier to test, and easier to swap implementations.

```java
// Without DI — tightly coupled
private PaymentService payment = new PaymentService(); // ❌ hardcoded

// With DI — Spring provides it
private final PaymentService payment; // ✓ injected by Spring
```

---

## Spring IoC Container
- The IoC container is responsible for **creating, wiring, configuring and managing** beans (objects).
- Main implementation used in practice: `ApplicationContext`.
- `BeanFactory` is the simpler parent interface — rarely used directly.
- In Spring Boot, the container starts automatically when you run the app via `@SpringBootApplication`.

```java
// Manually bootstrapping the container (non-Boot apps)
ApplicationContext ctx = new AnnotationConfigApplicationContext(AppConfig.class);
OrderService service = ctx.getBean(OrderService.class);
```

---

## Spring Stereotypes
- Stereotypes are annotations that mark a class as a **Spring-managed bean** and tell Spring which layer it belongs to.
- All stereotypes are specializations of `@Component` — Spring picks them up during component scanning.

```
@Component          ← generic bean
    ├── @Service    ← business logic lives here
    ├── @Repository ← all database logic lives here (+ exception translation)
    └── @Controller ← handles HTTP requests, returns view names
            └── @RestController ← @Controller + @ResponseBody (returns data, not views)
```

### @Configuration
- Treated as a **source of bean definitions**.
- Methods inside it annotated with `@Bean` act as **factory methods** — their sole purpose is to create and return an object that Spring will manage.

```java
@Configuration
public class AppConfig {

    @Bean
    public ObjectMapper objectMapper() {         // factory method — Spring manages this bean
        return new ObjectMapper();
    }
}
```

### @Service
- All **business logic** resides here.
- No extra Spring behavior over `@Component` — it's purely for clarity and layering.

```java
@Service
public class OrderService {

    private final PaymentService paymentService;

    public OrderService(PaymentService paymentService) {    // constructor injection
        this.paymentService = paymentService;
    }

    public String placeOrder(String item, double amount) {
        boolean paid = paymentService.charge(amount);
        return paid ? "Order placed: " + item : "Payment failed";
    }
}
```

### @Repository
- All **database logic** lives here.
- Extra behavior: Spring automatically translates low-level DB exceptions (SQLException, JPA exceptions) into Spring's `DataAccessException` — so the service layer doesn't need to know about DB-specific exceptions.

```java
@Repository
public class UserRepository {

    private final Map<Integer, String> db = new HashMap<>(
        Map.of(1, "Alice", 2, "Bob", 3, "Charlie")
    );

    public Optional<String> findById(int id) {
        return Optional.ofNullable(db.get(id));
    }

    public void save(int id, String name) { db.put(id, name); }
}
```

### @Controller
- Handles **HTTP requests** in Spring MVC.
- Methods return **view names** (for server-side rendering with Thymeleaf etc.).
- Add `@ResponseBody` on a method to return data directly instead of a view.

```java
@Controller
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/{id}")
    @ResponseBody                               // return data, not a view
    public String getUser(@PathVariable int id) {
        return userService.findById(id).orElse("Not found");
    }
}
```

### @RestController
- Shorthand for `@Controller` + `@ResponseBody` applied to every method.
- Use this for **REST APIs** — responses are automatically serialized to JSON.

```java
@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final ProductService productService;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping("/{id}")
    public Product getById(@PathVariable int id) {         // auto → JSON
        return productService.getById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public void create(@RequestBody Product product) {     // JSON → Product
        productService.save(product);
    }
}
```

### @Component
- Generic stereotype — use when a class doesn't fit service/repo/controller roles.
- Example: validators, utilities, helpers.

```java
@Component
public class EmailValidator {
    public boolean isValid(String email) {
        return email != null && email.contains("@");
    }
}
```

---

## Declaring Beans — @Component vs @Bean
- Use `@Component` (or its stereotypes) when **you own the class** — Spring detects it via scanning.
- Use `@Bean` inside a `@Configuration` class when dealing with **third-party classes** or when you need custom initialization logic you can't do with just an annotation.

```java
// You own it → @Component
@Component
public class MyService { ... }

// Third-party → @Bean in config
@Configuration
public class AppConfig {
    @Bean
    public ObjectMapper objectMapper() {       // you can't put @Component on ObjectMapper
        return new ObjectMapper();
    }
}
```

---

## Types of Dependency Injection

### Constructor Injection (Recommended)
- Spring iterates through the constructor's parameter list (via reflection), scans the application context for a bean matching each parameter type, and injects them.
- If there is only **one constructor**, `@Autowired` is optional — Spring automatically uses it (Spring 4.3+).
- If there are **multiple constructors**, you must annotate the one Spring should use with `@Autowired`.
- Preferred because: dependencies can be `final`, clearly visible, easy to unit test by just calling the constructor directly with mocks.

```java
@Service
public class OrderService {

    private final PaymentService paymentService;   // final — immutable
    private final InventoryService inventoryService;

    // Single constructor — @Autowired not required
    public OrderService(PaymentService paymentService,
                        InventoryService inventoryService) {
        this.paymentService = paymentService;
        this.inventoryService = inventoryService;
    }
}

// Multiple constructors — must mark the one Spring should use
@Service
public class ReportService {

    private final PrintService printService;

    public ReportService() { this.printService = null; }

    @Autowired                                     // Spring uses this one
    public ReportService(PrintService printService) {
        this.printService = printService;
    }
}
```

### Setter Injection
- Spring calls the setter method after creating the bean to inject the dependency.
- Must annotate the setter with `@Autowired`.
- Useful when a dependency is **optional** or needs to be **changed after construction**.

```java
@Service
public class NotificationService {

    private EmailService emailService;

    @Autowired
    public void setEmailService(EmailService emailService) {
        this.emailService = emailService;
    }
}
```

### Field Injection
- Spring stereotypes like `@Component`, `@Service` etc. are scanned; Spring then injects the dependency **directly into the field** via reflection.
- Annotate the field with `@Autowired`.
- Avoid in production — field cannot be `final`, hard to unit test without a running Spring context.

```java
@Service
public class UserService {

    @Autowired                           // injected directly via reflection
    private UserRepository userRepository;

    public Optional<String> findById(int id) {
        return userRepository.findById(id);
    }
}
```

---

## @Autowired
- Tells Spring to **inject a matching bean** at this point.
- Spring resolves by **type** first. If multiple beans of that type exist, it falls back to matching by **field/parameter name**.
- `@Autowired(required = false)` — won't throw an error if no matching bean is found; field stays `null`.
- Can also be placed on a method, constructor, or field.

```java
@Component
public class AppRunner {

    // Optional — won't fail if CacheService bean doesn't exist
    @Autowired(required = false)
    private CacheService cacheService;

    // Inject ALL beans of a type into a List
    @Autowired
    private List<Plugin> plugins;              // gets every @Component that implements Plugin

    // Inject as Map: beanName → bean instance
    @Autowired
    private Map<String, Plugin> pluginMap;
}
```

---

## @Qualifier & @Primary
- When **multiple beans of the same type** exist in the context, Spring doesn't know which one to inject and throws `NoUniqueBeanDefinitionException`.
- `@Primary` — marks one bean as the **default choice** when no further hints are given.
- `@Qualifier("beanName")` — explicitly tells Spring **which exact bean** to inject. Takes priority over `@Primary`.

```java
public interface PaymentGateway { String pay(double amount); }

@Component @Primary                                    // default when no qualifier used
public class StripeGateway implements PaymentGateway {
    public String pay(double amount) { return "Stripe: $" + amount; }
}

@Component
public class PayPalGateway implements PaymentGateway {
    public String pay(double amount) { return "PayPal: $" + amount; }
}

@Service
public class CheckoutService {

    private final PaymentGateway stripe;
    private final PaymentGateway paypal;

    public CheckoutService(
        @Qualifier("stripeGateway") PaymentGateway stripe,   // explicit
        @Qualifier("payPalGateway") PaymentGateway paypal
    ) {
        this.stripe = stripe;
        this.paypal = paypal;
    }
}
```

---

## Bean Scopes
- Controls **how many instances** of a bean Spring creates and how long they live.
- Default scope is **singleton** — one shared instance for the entire application.

| Scope | How to set | Instances |
|---|---|---|
| `singleton` | default | One per container |
| `prototype` | `@Scope("prototype")` | New instance on every injection / `getBean()` |
| `request` | `@RequestScope` | One per HTTP request |
| `session` | `@SessionScope` | One per HTTP session |

```java
@Component                          // singleton by default
public class ConfigService { }

@Component
@Scope("prototype")                 // new instance every time
public class ReportBuilder { }
```

- Singleton beans are **stateless** — safe to share across threads.
- Prototype beans are **stateful** — each caller gets their own copy.

```java
// Singleton — both variables point to the same object
ConfigService s1 = ctx.getBean(ConfigService.class);
ConfigService s2 = ctx.getBean(ConfigService.class);
System.out.println(s1 == s2);   // true

// Prototype — each getBean() returns a brand new instance
ReportBuilder r1 = ctx.getBean(ReportBuilder.class);
ReportBuilder r2 = ctx.getBean(ReportBuilder.class);
System.out.println(r1 == r2);   // false
```

---

## @Value — Injecting Properties
- Used to inject values from `application.properties` (or `application.yml`) directly into a field.
- Syntax: `@Value("${property.key}")` — Spring looks it up in the properties file.
- You can provide a **default** if the property isn't set: `@Value("${key:defaultValue}")`.
- Supports **SpEL (Spring Expression Language)** with `#{}` for computed values.

```java
@Component
public class AppSettings {

    @Value("${app.name}")               // from application.properties
    private String appName;

    @Value("${app.timeout:30}")         // default = 30 if not set
    private int timeout;

    @Value("#{T(java.lang.Math).PI}")   // SpEL — evaluates Math.PI
    private double pi;
}
```

**application.properties:**
```properties
app.name=MyApp
app.timeout=60
```

---

## @Configuration & @Bean
- `@Configuration` marks a class as a source of bean definitions.
- Methods inside annotated with `@Bean` are **factory methods** — their whole job is to create and return an object for Spring to manage.
- The method name becomes the **bean name** by default.
- Use `@Bean(name = "customName")` to override.
- `@Bean` methods can take parameters — Spring automatically injects matching beans for them.

```java
@Configuration
public class AppConfig {

    @Bean                                         // bean name = "objectMapper"
    public ObjectMapper objectMapper() {
        return new ObjectMapper()
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
    }

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    // Spring injects restTemplate bean automatically as a parameter
    @Bean
    public ApiClient apiClient(RestTemplate restTemplate,
                               @Value("${api.base-url}") String baseUrl) {
        return new ApiClient(restTemplate, baseUrl);
    }
}
```

### Bean Lifecycle Hooks
- `@PostConstruct` — runs **after** the bean is created and all dependencies are injected. Good for initialization logic.
- `@PreDestroy` — runs **before** the bean is removed from the container. Good for cleanup (closing connections, flushing cache).

```java
@Component
public class CacheManager {

    @PostConstruct
    public void init() {
        System.out.println("Cache warming up...");    // runs after DI is done
    }

    @PreDestroy
    public void cleanup() {
        System.out.println("Cache flushing...");      // runs before app shuts down
    }
}
```

---

## Component Scanning
- Spring needs to know **where to look** for classes annotated with `@Component`, `@Service`, `@Repository`, etc.
- `@ComponentScan("com.example")` tells Spring which package to scan.
- In Spring Boot, `@SpringBootApplication` already includes `@ComponentScan` — it automatically scans the package it sits in and all sub-packages. So you rarely need to configure this manually.

```java
// Non-Boot: explicit scan
@Configuration
@ComponentScan("com.example")
public class AppConfig { }

// Spring Boot: scanning is automatic
@SpringBootApplication      // = @Configuration + @EnableAutoConfiguration + @ComponentScan
public class MyApp {
    public static void main(String[] args) {
        SpringApplication.run(MyApp.class, args);
    }
}
```

---

## Practical Example — Layered App

```java
// Domain
record Product(int id, String name, double price) {}

// Repository — data access
@Repository
public class ProductRepository {
    private final Map<Integer, Product> store = new HashMap<>(Map.of(
        1, new Product(1, "Laptop", 999.99),
        2, new Product(2, "Phone",  499.99)
    ));
    public Optional<Product> findById(int id) { return Optional.ofNullable(store.get(id)); }
    public List<Product> findAll()             { return new ArrayList<>(store.values()); }
}

// Service — business logic
@Service
public class ProductService {
    private final ProductRepository repo;
    public ProductService(ProductRepository repo) { this.repo = repo; }

    public List<Product> getAffordable(double max) {
        return repo.findAll().stream().filter(p -> p.price() <= max).toList();
    }
    public Product getById(int id) {
        return repo.findById(id).orElseThrow(() -> new RuntimeException("Not found: " + id));
    }
}

// Controller — REST API
@RestController
@RequestMapping("/api/products")
public class ProductController {
    private final ProductService productService;
    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping
    public List<Product> getAffordable(@RequestParam(defaultValue = "1000") double max) {
        return productService.getAffordable(max);
    }

    @GetMapping("/{id}")
    public Product getById(@PathVariable int id) {
        return productService.getById(id);
    }
}

// Entry point
@SpringBootApplication
public class StoreApp {
    public static void main(String[] args) { SpringApplication.run(StoreApp.class, args); }
}
```

**GET /api/products?max=600:**
```json
[{"id":2,"name":"Phone","price":499.99}]
```
---

## Quick Reference
- `@Component` → generic Spring bean
- `@Service` → business logic layer
- `@Repository` → data access layer (+ DB exception translation)
- `@Controller` → web layer, returns view names
- `@RestController` → `@Controller` + `@ResponseBody`, returns JSON/data
- `@Configuration` → source of bean definitions
- `@Bean` → factory method inside `@Configuration` (for third-party or custom beans)
- `@Autowired` → inject by type; falls back to name if ambiguous
- `@Qualifier("name")` → force a specific bean when multiple of same type exist
- `@Primary` → default bean when no qualifier is specified
- `@Value("${key}")` → inject from `application.properties`
- `@Scope("prototype")` → new instance every injection (default is singleton)
- `@PostConstruct` → run code after DI is complete
- `@PreDestroy` → run code before bean is destroyed
- `@SpringBootApplication` → enables config + auto-config + component scan for current package
***