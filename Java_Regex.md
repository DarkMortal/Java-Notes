# Java Regular Expressions (Regex)

## Table of Contents
1. [Core Classes](#core-classes)
2. [Regex Syntax Cheat Sheet](#regex-syntax-cheat-sheet)
3. [Pattern & Matcher](#pattern--matcher)
4. [String Methods with Regex](#string-methods-with-regex)
5. [Common Patterns & Examples](#common-patterns--examples)
6. [Groups & Capturing](#groups--capturing)
7. [Flags / Modifiers](#flags--modifiers)
8. [Find vs Match vs Lookups](#find-vs-match-vs-lookups)
9. [Quick Reference](#quick-reference)
---

## Core Classes

| Class | Package | Purpose |
|---|---|---|
| `Pattern` | `java.util.regex` | Compiled regex — reusable, thread-safe |
| `Matcher` | `java.util.regex` | Applies a Pattern to an input string |
| `PatternSyntaxException` | `java.util.regex` | Thrown for invalid regex syntax |

**Basic flow:**
```
regex String → Pattern.compile() → Pattern → matcher(input) → Matcher → results
```

---

## Regex Syntax Cheat Sheet

### Character Classes

| Pattern | Matches |
|---|---|
| `.` | Any character except newline |
| `\d` | Digit `[0-9]` |
| `\D` | Non-digit |
| `\w` | Word character `[a-zA-Z0-9_]` |
| `\W` | Non-word character |
| `\s` | Whitespace (space, tab, newline) |
| `\S` | Non-whitespace |
| `[abc]` | a, b, or c |
| `[^abc]` | Any character except a, b, c |
| `[a-z]` | Any lowercase letter |
| `[a-zA-Z0-9]` | Alphanumeric |

### Quantifiers

| Pattern | Matches |
|---|---|
| `*` | 0 or more |
| `+` | 1 or more |
| `?` | 0 or 1 (optional) |
| `{n}` | Exactly n times |
| `{n,}` | n or more times |
| `{n,m}` | Between n and m times |
| `*?` `+?` `??` | Lazy (non-greedy) versions |

### Anchors

| Pattern | Matches |
|---|---|
| `^` | Start of string (or line with MULTILINE) |
| `$` | End of string (or line with MULTILINE) |
| `\b` | Word boundary |
| `\B` | Non-word boundary |

### Groups & Alternation

| Pattern | Meaning |
|---|---|
| `(abc)` | Capturing group |
| `(?:abc)` | Non-capturing group |
| `(?<name>abc)` | Named capturing group |
| `a\|b` | a or b |
| `(?=abc)` | Positive lookahead — followed by abc |
| `(?!abc)` | Negative lookahead — not followed by abc |
| `(?<=abc)` | Positive lookbehind — preceded by abc |
| `(?<!abc)` | Negative lookbehind — not preceded by abc |

### Escaping in Java Strings

> In Java strings, `\` must be written as `\\`.  
> So regex `\d` → Java string `"\\d"`, regex `\d+` → `"\\d+"`

```java
// Regex: \d{3}-\d{4}
// Java:
Pattern p = Pattern.compile("\\d{3}-\\d{4}");
```

---

## Pattern & Matcher

### Basic Usage

```java
import java.util.regex.*;

public class BasicPatternMatcher {
    public static void main(String[] args) {

        Pattern pattern = Pattern.compile("\\d{3}-\\d{2}-\\d{4}");
        Matcher matcher = pattern.matcher("SSN: 123-45-6789 on file.");

        if (matcher.find()) {
            System.out.println("Found: " + matcher.group());   // 123-45-6789
            System.out.println("Start: " + matcher.start());   // 5
            System.out.println("End  : " + matcher.end());     // 16
        }
    }
}
```

**Output:**
```
Found: 123-45-6789
Start: 5
End  : 16
```

### find() — iterate over all matches

```java
import java.util.regex.*;

public class FindAllMatches {
    public static void main(String[] args) {

        String text = "Call 555-1234 or 555-5678 for support.";
        Pattern pattern = Pattern.compile("\\d{3}-\\d{4}");
        Matcher matcher = pattern.matcher(text);

        while (matcher.find()) {
            System.out.println("Match: " + matcher.group() +
                " at [" + matcher.start() + ", " + matcher.end() + ")");
        }
    }
}
```

**Output:**
```
Match: 555-1234 at [5, 13)
Match: 555-5678 at [17, 25)
```

### matches() vs find()

```java
Pattern p = Pattern.compile("\\d+");

System.out.println(p.matcher("12345").matches());   // true  — entire string must match
System.out.println(p.matcher("123ab").matches());   // false — "ab" not matched
System.out.println(p.matcher("123ab").find());      // true  — finds "123" anywhere
```

### results() — Stream of matches (Java 9+)

```java
import java.util.regex.*;
import java.util.List;
import java.util.stream.Collectors;

public class StreamMatches {
    public static void main(String[] args) {

        String text = "Prices: $10, $250, $3, $1099";
        Pattern pattern = Pattern.compile("\\$\\d+");

        List<String> prices = pattern.matcher(text)
            .results()
            .map(MatchResult::group)
            .collect(Collectors.toList());

        System.out.println(prices);  // [$10, $250, $3, $1099]
    }
}
```

**Output:**
```
[$10, $250, $3, $1099]
```

---

## String Methods with Regex

Java's `String` class has several built-in regex methods — no need to use `Pattern`/`Matcher` directly for simple cases.

```java
public class StringRegexMethods {
    public static void main(String[] args) {

        String text = "Hello, World! 123";

        // matches() — entire string must match
        System.out.println("12345".matches("\\d+"));         // true
        System.out.println("123ab".matches("\\d+"));         // false

        // replaceAll() — replace ALL matches
        String noDigits = text.replaceAll("\\d", "*");
        System.out.println(noDigits);                        // Hello, World! ***

        // replaceFirst() — replace only the FIRST match
        String firstReplaced = text.replaceFirst("\\d+", "NUM");
        System.out.println(firstReplaced);                   // Hello, World! NUM

        // split() — split by regex
        String csv = "one,two,,three,  four  ";
        String[] parts = csv.split(",");
        System.out.println(parts.length);                    // 5 (empty string included)

        // split with limit
        String[] limited = csv.split(",", 3);
        for (String p : limited) System.out.println("[" + p + "]");
        // [one]  [two]  [,three,  four  ]

        // split on whitespace
        String[] words = "  hello   world   java  ".trim().split("\\s+");
        System.out.println(words.length);                    // 3
    }
}
```

**Output:**
```
true
false
Hello, World! ***
Hello, World! NUM
5
[one]
[two]
[,three,  four  ]
3
```

---

## Common Patterns & Examples

```java
import java.util.regex.*;

public class CommonPatterns {

    // Validate email (simplified)
    static final Pattern EMAIL =
        Pattern.compile("^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$");

    // Validate phone — formats: 555-1234, (555) 123-4567, 5551234567
    static final Pattern PHONE =
        Pattern.compile("^(\\(\\d{3}\\)\\s?|\\d{3}[-.]?)\\d{3}[-.]?\\d{4}$");

    // Validate URL (basic)
    static final Pattern URL =
        Pattern.compile("^(https?|ftp)://[^\\s/$.?#].[^\\s]*$");

    // Validate IPv4
    static final Pattern IPV4 =
        Pattern.compile("^((25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\\.){3}(25[0-5]|2[0-4]\\d|[01]?\\d\\d?)$");

    // Validate date — YYYY-MM-DD
    static final Pattern DATE =
        Pattern.compile("^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])$");

    // Strong password: min 8 chars, 1 upper, 1 lower, 1 digit, 1 special
    static final Pattern PASSWORD =
        Pattern.compile("^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[@#$%^&+=!]).{8,}$");

    static boolean validate(Pattern p, String input) {
        return p.matcher(input).matches();
    }

    public static void main(String[] args) {
        System.out.println(validate(EMAIL,    "user@example.com"));   // true
        System.out.println(validate(EMAIL,    "not-an-email"));       // false
        System.out.println(validate(PHONE,    "555-1234"));           // true
        System.out.println(validate(PHONE,    "(555) 123-4567"));     // true
        System.out.println(validate(IPV4,     "192.168.1.1"));        // true
        System.out.println(validate(IPV4,     "999.0.0.1"));          // false
        System.out.println(validate(DATE,     "2026-07-21"));         // true
        System.out.println(validate(DATE,     "2026-13-01"));         // false
        System.out.println(validate(PASSWORD, "Secret@1"));           // true
        System.out.println(validate(PASSWORD, "weakpass"));           // false
    }
}
```

**Output:**
```
true
false
true
true
true
false
true
false
true
false
```

---

## Groups & Capturing

### Numbered Groups

```java
import java.util.regex.*;

public class GroupsExample {
    public static void main(String[] args) {

        // Group 1: area code, Group 2: prefix, Group 3: line
        Pattern pattern = Pattern.compile("\\((\\d{3})\\)\\s(\\d{3})-(\\d{4})");
        Matcher matcher = pattern.matcher("Call (800) 555-1234 today.");

        if (matcher.find()) {
            System.out.println("Full match : " + matcher.group(0));  // (800) 555-1234
            System.out.println("Area code  : " + matcher.group(1));  // 800
            System.out.println("Prefix     : " + matcher.group(2));  // 555
            System.out.println("Line number: " + matcher.group(3));  // 1234
        }
    }
}
```

**Output:**
```
Full match : (800) 555-1234
Area code  : 800
Prefix     : 555
Line number: 1234
```

### Named Groups (Java 7+)

```java
import java.util.regex.*;

public class NamedGroups {
    public static void main(String[] args) {

        // (?<name>...) — named capturing group
        Pattern pattern = Pattern.compile(
            "(?<year>\\d{4})-(?<month>\\d{2})-(?<day>\\d{2})"
        );
        Matcher matcher = pattern.matcher("Event date: 2026-07-21");

        if (matcher.find()) {
            System.out.println("Year : " + matcher.group("year"));   // 2026
            System.out.println("Month: " + matcher.group("month"));  // 07
            System.out.println("Day  : " + matcher.group("day"));    // 21
        }
    }
}
```

**Output:**
```
Year : 2026
Month: 07
Day  : 21
```

### replaceAll with Group Back-references

```java
// Swap first and last name: "Doe, John" → "John Doe"
String name = "Doe, John";
String swapped = name.replaceAll("(\\w+),\\s(\\w+)", "$2 $1");
System.out.println(swapped);   // John Doe

// Wrap all numbers in brackets
String text = "I have 3 cats and 12 dogs";
String result = text.replaceAll("(\\d+)", "[$1]");
System.out.println(result);    // I have [3] cats and [12] dogs
```

**Output:**
```
John Doe
I have [3] cats and [12] dogs
```

---

## Flags / Modifiers

```java
import java.util.regex.*;

public class FlagsExample {
    public static void main(String[] args) {

        String text = "Hello\nWorld\nhello again";

        // CASE_INSENSITIVE — ignore case
        Pattern ci = Pattern.compile("hello", Pattern.CASE_INSENSITIVE);
        Matcher m = ci.matcher(text);
        while (m.find()) System.out.println("Found: " + m.group());
        // Found: Hello
        // Found: hello

        // MULTILINE — ^ and $ match start/end of each LINE
        Pattern ml = Pattern.compile("^\\w+", Pattern.MULTILINE);
        Matcher m2 = ml.matcher(text);
        while (m2.find()) System.out.println("Line start: " + m2.group());
        // Line start: Hello
        // Line start: World
        // Line start: hello

        // DOTALL — . matches newlines too
        Pattern ds = Pattern.compile("Hello.World", Pattern.DOTALL);
        System.out.println(ds.matcher("Hello\nWorld").find());   // true

        // Combining flags with |
        Pattern combined = Pattern.compile("^hello",
            Pattern.CASE_INSENSITIVE | Pattern.MULTILINE);

        // Inline flags inside the regex string
        Pattern inline = Pattern.compile("(?i)hello");           // same as CASE_INSENSITIVE
    }
}
```

**Output:**
```
Found: Hello
Found: hello
Line start: Hello
Line start: World
Line start: hello
true
```

| Flag | Constant | Inline | Effect |
|---|---|---|---|
| Case insensitive | `Pattern.CASE_INSENSITIVE` | `(?i)` | Ignore case |
| Multiline | `Pattern.MULTILINE` | `(?m)` | `^`/`$` match line boundaries |
| Dot-all | `Pattern.DOTALL` | `(?s)` | `.` matches `\n` too |
| Comments | `Pattern.COMMENTS` | `(?x)` | Whitespace and `#` comments ignored in regex |
| Unicode case | `Pattern.UNICODE_CASE` | `(?u)` | Unicode-aware case folding |

---

## Find vs Match vs Lookups

```java
import java.util.regex.*;

public class FindVsMatch {
    public static void main(String[] args) {

        Pattern p = Pattern.compile("\\d+");
        String input = "abc 123 def";

        // find()   — finds pattern ANYWHERE in input
        System.out.println(p.matcher(input).find());     // true

        // matches() — pattern must match ENTIRE input
        System.out.println(p.matcher(input).matches());  // false
        System.out.println(p.matcher("123").matches());  // true

        // lookingAt() — pattern must match from the BEGINNING (not necessarily all)
        System.out.println(Pattern.compile("\\d+").matcher("123abc").lookingAt()); // true
        System.out.println(Pattern.compile("\\d+").matcher("abc123").lookingAt()); // false

        // Lookahead — match "price" only if followed by digits
        Pattern lookahead = Pattern.compile("price(?=\\d+)");
        System.out.println(lookahead.matcher("price100").find());   // true
        System.out.println(lookahead.matcher("priceXYZ").find());   // false

        // Negative lookahead — match "error" NOT followed by "404"
        Pattern negLook = Pattern.compile("error(?!404)");
        System.out.println(negLook.matcher("error500").find());     // true
        System.out.println(negLook.matcher("error404").find());     // false
    }
}
```

**Output:**
```
true
false
true
true
false
true
false
true
false
```

---

## Quick Reference

```
Core classes:
  Pattern.compile("regex")         → compiled pattern (reusable)
  pattern.matcher("input")         → Matcher
  Pattern.matches("regex","input") → quick one-off full match

Matcher methods:
  .find()          → find next match anywhere
  .matches()       → entire input must match
  .lookingAt()     → must match from beginning
  .group()         → last matched text (group 0)
  .group(n)        → nth capturing group
  .group("name")   → named capturing group
  .start() / .end()→ index of match
  .results()       → Stream<MatchResult> (Java 9+)
  .replaceAll(fn)  → replace with function (Java 9+)

String shortcuts:
  str.matches(regex)               → full string match
  str.replaceAll(regex, repl)      → replace all
  str.replaceFirst(regex, repl)    → replace first
  str.split(regex)                 → split into array
  Back-reference in replacement:   $1, $2, ${name}

Common symbols:
  \d \D  → digit / non-digit
  \w \W  → word char / non-word
  \s \S  → whitespace / non-whitespace
  .      → any char (except \n)
  ^  $   → start / end of string
  \b     → word boundary

Quantifiers:
  *   → 0 or more (greedy)
  +   → 1 or more (greedy)
  ?   → 0 or 1
  {n,m}→ n to m times
  *? +? → lazy (non-greedy)

Flags:
  Pattern.CASE_INSENSITIVE  (?i)  → ignore case
  Pattern.MULTILINE         (?m)  → ^/$ per line
  Pattern.DOTALL            (?s)  → . matches \n

Performance tip:
  Compile Pattern once (static final) and reuse — 
  Pattern.compile() is expensive, Matcher is cheap.
```
