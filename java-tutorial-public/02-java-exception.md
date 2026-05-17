# Java Exception 完全指南：寫出健壯程式的錯誤處理之道

> 這是 Java 教學系列的第二篇，主題是 Exception（例外處理）。上一篇我們聊了 [Collections Framework](./SAMPLE-collections-array.md)，這次想把例外處理這個常常被初學者忽略、但卻決定程式是否「健壯」的關鍵主題完整整理一遍。文章如果有任何錯誤或可以補充的地方，歡迎在留言區指教。

## 前言

寫 Java 一陣子之後，你大概對 `NullPointerException`、`ArrayIndexOutOfBoundsException` 這些紅字不陌生。剛入門時，多半的反應是「先用 `try-catch` 包起來再說」，但這樣寫久了會發現一個尷尬的問題——程式雖然不會 crash 了，可是真的出問題的時候，反而更難追到底是哪裡壞掉。

例外處理這件事，看起來只是幾個關鍵字（`try`、`catch`、`finally`、`throw`、`throws`），但背後其實有一整套設計哲學。理解它，才能真正寫出「失敗也能優雅退場」的程式。這篇我想從幾個切入點整理 Java 的例外處理：

1. Exception 跟 Error 的差別
2. 例外的繼承架構
3. Checked 與 Unchecked 的分界與設計理由
4. `try-catch-finally` 與 `try-with-resources` 的語法細節
5. 例外的傳播機制與實務上常踩的坑

我們從最根本的概念開始。

---

## 一、Exception vs Error：誰該負責處理？

在進到語法之前，要先釐清兩個很容易搞混的概念：**Exception（例外）** 跟 **Error（錯誤）**。它們雖然都繼承自 `Throwable`，但在「該不該由程式處理」這件事上，立場完全相反。

### Exception（例外）

例外指的是程式執行時，遇到了**不符合預期邏輯**的狀況。重點在於：**這是程式設計師可以預見、應該處理的問題**。

舉一個生活化的例子：你寫了一個訂單系統，使用者要輸入購買數量，結果他在數量欄位填了 `"五個"`。這就是一種例外——使用者的操作偏離了我們預期的輸入。應對方式很直觀：做輸入檢核、提示重新輸入、或給一個合理的預設值。

例外通常只影響程式中的**特定部分**，不會讓整個系統掛掉，而且大部分情況下都能預防或復原。

### Error（錯誤）

Error 代表的是**系統層級的嚴重問題**，程式設計師在程式碼層面**沒辦法處理，也不該嘗試處理**。

常見的像是 `OutOfMemoryError`（記憶體耗盡）、`StackOverflowError`（堆疊溢位）。遇到這類問題，解法不在程式碼，而是要從硬體、JVM 設定、或整體架構去調整。

> **一句話記法：Exception 靠程式處理，Error 靠系統處理。**

如果你在 `catch (Throwable t)` 裡面接住了 `OutOfMemoryError`，然後試圖「繼續執行」，結果通常不會比直接讓程式停下來好——記憶體都不夠了，你的補救邏輯往往也跑不起來。

---

## 二、例外的繼承架構

Java 中所有可以被「丟出來」的東西都繼承自 `Throwable`，整個體系大概長這樣：

```
                       Throwable
                      /         \
                Exception        Error
               /        \           \
     IOException   RuntimeException   OutOfMemoryError
     SQLException  NullPointerException   StackOverflowError
                   ArithmeticException
                   ClassCastException
                   ArrayIndexOutOfBoundsException
```

這張圖看起來簡單，但它直接決定了一件事——**這個例外，編譯器會不會強迫你處理？** 這就是接下來要談的 Checked 與 Unchecked 分界。

---

## 三、Checked vs Unchecked：Java 設計的雙軌警報系統

Java 設計這套機制，是為了提升程式的**健壯性（Robustness）**。可以把它想成 Java 幫你裝了兩套不同的警報系統，分別對應不同的失敗情境。

要理解這兩套系統，最好的切入角度是「責任歸屬」——**這個錯到底是誰造成的？** 簡單來說，Java 是在區分：**「環境造成的意外」** 與 **「程式碼寫錯的失誤」**。

### Checked Exception（受檢例外）——外部環境不可控

- 繼承自 `Exception`，但**不是** `RuntimeException` 的子類別
- **必須在編譯時期處理**，否則程式編譯不過
- 編譯器會強迫你用 `try-catch` 接住，或用 `throws` 往上拋
- 常見的有：`IOException`、`SQLException`、`FileNotFoundException`

**本質：程式碼本身沒寫錯，但「外部環境」不可控。** 例如你要讀的檔案剛好被刪了、網路斷了、資料庫連不上。這些事在現實環境裡「一定會發生」，與其讓程式跑起來才崩潰，不如在編譯期就強迫開發者把應對方案寫好。

```java
import java.io.FileReader;

public class CheckedDemo {
    public static void main(String[] args) {
        // 編譯錯誤！必須處理 FileNotFoundException
        // 編譯器的意思是：「檔案不一定存在，你打算怎麼辦？先寫好再說。」
        FileReader reader = new FileReader("test.txt");
    }
}
```

這段程式碼是無法通過編譯的，因為 `FileNotFoundException` 是 Checked Exception。

### Unchecked Exception（非受檢例外）——程式邏輯有瑕疵

- 是 `RuntimeException` 的子類別（或更嚴重的 `Error`）
- **不強制處理**，沒寫 `try-catch` 也能編譯過
- 通常代表**程式邏輯上的 bug**，應該透過**修正邏輯**避免，而不是用 `try-catch` 補救
- 常見的有：`NullPointerException`、`ArrayIndexOutOfBoundsException`、`ArithmeticException`

**本質：這些是「程式寫錯了」。** 存取了 null 物件、陣列索引算錯、除以零——這些都該從邏輯上根治。試想一下，如果編譯器強迫你在「每個會用到變數的地方」都檢查 NPE，程式碼會臃腫到沒辦法讀。所以 Java 的設計是：讓它直接報錯停下來，提醒開發者「這裡邏輯壞了，去修程式碼」。

```java
public class UncheckedDemo {
    public static void main(String[] args) {
        // 可以編譯通過，但執行時會拋出 ArithmeticException
        // 正確的修法不是 try-catch，而是加上 if (divisor != 0) 的邏輯檢查
        int result = 10 / 0;
        System.out.println(result);
    }
}
```

### 用「檢查時機」來理解這兩種設計

| 檢查時機 | 類型 | 設計理念 |
| --- | --- | --- |
| **編譯時（Static Check）** | Checked | **合約精神：** 強制要求 API 的使用者必須處理潛在風險，這是一種「強迫式的安全提示」，確保你在開發階段就考慮到失敗路徑。 |
| **執行時（Dynamic Check）** | Unchecked | **防禦邏輯：** 這些錯誤反映的是程式的 Bug，讓它直接報錯停下來，讓開發者知道「這裡邏輯寫錯了，去修程式碼」。 |

### 容易搞混的觀念：Checked Exception 編譯不過，是「語法錯誤」嗎？

不是。嚴格來說，這**不是語法錯誤（Syntax Error）**，而是一種**契約上的違規（Contract Violation）**。

- **語法錯誤**：像是漏了分號 `;` 或大括號 `{}`，編譯器根本看不懂這行程式碼的意思，無法轉成 bytecode。
- **Checked Exception 編譯失敗**：編譯器看得懂你的程式碼，但發現你**「未履行義務」**。

用簽合約的比喻來說：語法錯誤是「字寫錯了，合約沒辦法閱讀」；Checked Exception 報錯則是「合約裡寫到要負責維護，但你沒寫維護計畫，所以合約不成立」。

### 補充：現代語言為什麼開始捨棄 Checked Exception？

雖然 Java 堅持 Checked / Unchecked 的分類，但現代的許多語言（Kotlin、Scala、C#）都選擇**不使用 Checked Exception**。原因是實務上發現，強制捕捉例外常常導致兩種反模式：

1. 大量的空 `catch` 塊（吞掉例外什麼都不做）
2. 層層疊疊的 `throws` 宣告（每一層都掛一串）

兩種寫法反而讓程式碼更難維護。

這也是為什麼在現代 Java 框架（如 Spring）中，許多 Checked Exception 會被**包裝成 Unchecked Exception** 再丟出。例如 Spring 的 `DataAccessException` 就是 `RuntimeException` 的子類別，把 JDBC 的 `SQLException` 包裝起來，讓開發者不必在每一層都寫 `throws SQLException`。

不過，理解 Checked Exception 的機制還是很重要——因為底層 API（JDBC、IO）大量使用它，下一篇講 JDBC 時就會遇到很多。

### 補充：在 Lambda / forEach 裡可以拋例外嗎？

這個問題實務上很常遇到，答案要看例外的類型。

**Unchecked Exception → 可以直接拋，沒有限制。**

```java
import java.util.List;

public class LambdaUncheckedDemo {
    public static void main(String[] args) {
        var names = List.of("莉莉", "海嫄", "");

        // forEach 中拋 Unchecked Exception：完全合法
        names.forEach(name -> {
            if (name.isEmpty()) {
                throw new IllegalArgumentException("名字不可為空字串");
            }
            System.out.println(name);
        });
    }
}
```

**Checked Exception → 沒辦法直接拋，編譯會失敗！**

原因是 Java 標準函式介面（`Consumer<T>`、`Function<T,R>` 等）的抽象方法簽章**沒有宣告 `throws`**，所以你不能在 Lambda 裡直接拋 Checked Exception。

```java
import java.util.List;
import java.io.IOException;

public class LambdaCheckedDemo {
    public static void main(String[] args) {
        var fileNames = List.of("a.txt", "b.txt");

        // 編譯錯誤！Consumer.accept() 沒有宣告 throws IOException
        fileNames.forEach(name -> {
            throw new IOException("找不到檔案：" + name);
        });
    }
}
```

那如果真的需要在 Lambda 裡處理 Checked Exception，有兩種常見做法。

**做法一：在 Lambda 內部用 try-catch 包住**

```java
import java.util.List;
import java.io.FileReader;
import java.io.IOException;

public class LambdaCheckedSolution1 {
    public static void main(String[] args) {
        var fileNames = List.of("a.txt", "b.txt");

        fileNames.forEach(name -> {
            try {
                var reader = new FileReader(name);
                System.out.println(name + " 開啟成功");
            } catch (IOException e) {
                System.out.println("無法開啟 " + name + "：" + e.getMessage());
            }
        });
    }
}
```

**做法二：包裝成 Unchecked Exception 再拋出**

```java
import java.util.List;
import java.io.FileReader;
import java.io.IOException;

public class LambdaCheckedSolution2 {
    public static void main(String[] args) {
        var fileNames = List.of("a.txt", "b.txt");

        try {
            fileNames.forEach(name -> {
                try {
                    var reader = new FileReader(name);
                } catch (IOException e) {
                    // 包裝成 RuntimeException 後拋出
                    throw new RuntimeException("檔案處理失敗：" + name, e);
                }
            });
        } catch (RuntimeException e) {
            System.out.println("發生錯誤：" + e.getMessage());
        }
    }
}
```

> **小結：Lambda / forEach 中只能「直接拋」Unchecked Exception。要處理 Checked Exception，得在 Lambda 內 try-catch，或包裝成 RuntimeException。**

### 章節小結

- Checked 處理的是「外部環境不可控」的意外，編譯期強制處理。
- Unchecked 反映的是「程式邏輯有 bug」，不強制處理，該從邏輯修起。
- 兩者的分界，本質上是 Java 在區分「誰的責任」。

---

## 四、try-catch-finally：基本語法

### 結構

```java
try {
    // 可能會拋出例外的程式碼
} catch (ExceptionType1 e1) {
    // 處理 ExceptionType1
} catch (ExceptionType2 e2) {
    // 處理 ExceptionType2
} finally {
    // 無論是否發生例外，這個區塊都會執行
}
```

### 三條關鍵規則

1. **`catch` 順序必須從子類到父類**——如果父類放前面，子類的 `catch` 永遠不會被執行到，編譯器會直接報錯。
2. **`finally` 一定會執行**——不管 `try` 裡有沒有例外、`catch` 裡有沒有再拋例外，`finally` 都會在方法回傳之前執行。
3. **`finally` 常用來釋放資源**——例如關閉資料庫連線、檔案串流。不過後面會介紹更優雅的 `try-with-resources`。

### catch 順序示範

```java
import java.io.FileNotFoundException;
import java.io.IOException;

public class CatchOrderDemo {
    public static void main(String[] args) {
        try {
            throw new FileNotFoundException("找不到設定檔");

        } catch (FileNotFoundException e) {
            // 子類別放前面
            System.out.println("檔案未找到：" + e.getMessage());

        } catch (IOException e) {
            // 父類別放後面
            System.out.println("IO 錯誤：" + e.getMessage());

        } catch (Exception e) {
            // 最大的父類別放最後
            System.out.println("其他錯誤：" + e.getMessage());
        }
    }
}
```

如果反過來把 `Exception` 放在第一個 `catch`，後面的 `catch` 永遠都進不去，編譯器會報 `exception ... has already been caught` 之類的錯誤。

### Java 7+ 的 Multi-catch 語法

從 Java 7 開始，可以在同一個 `catch` 用 `|` 同時捕捉多種例外，前提是這些例外彼此**沒有繼承關係**：

```java
try {
    // 某些操作
} catch (FileNotFoundException | ArithmeticException e) {
    // 同時處理這兩種不同類型的例外
    System.out.println("發生例外：" + e.getMessage());
}
```

如果兩個例外有父子關係（例如 `IOException | FileNotFoundException`），編譯器也會報錯，因為父類本來就會涵蓋子類。

---

## 五、throw 與 throws：兩個容易搞混的關鍵字

這兩個關鍵字長得很像，但功能完全不同。

### `throw`：手動拋出一個例外實例

```java
throw new IllegalArgumentException("金額不可為負數");
```

`throw` 是在方法**內部**使用，用來主動拋出一個例外物件。

### `throws`：宣告方法「可能會」拋出的例外

```java
public void readFile(String path) throws IOException {
    var reader = new FileReader(path);
}
```

`throws` 寫在方法簽章上，是在跟呼叫者宣告：「這個方法可能會拋出某些例外，你要做好準備。」

### 完整範例：手動拋出 + 接住

```java
public class ThrowDemo {

    public static void main(String[] args) {
        try {
            validateAge(-5);
        } catch (IllegalArgumentException e) {
            System.out.println("驗證失敗：" + e.getMessage());
        }
    }

    /**
     * 驗證年齡，若為負數則拋出 IllegalArgumentException。
     * IllegalArgumentException 是 Unchecked，所以 throws 可寫可不寫，
     * 但加上去對閱讀者比較友善。
     */
    private static void validateAge(int age) throws IllegalArgumentException {
        if (age < 0) {
            throw new IllegalArgumentException("年齡不能是負數，收到：" + age);
        }
        System.out.println("年齡驗證通過：" + age);
    }
}
```

實務上一個小建議：即使是 Unchecked Exception，方法簽章寫上 `throws` 對閱讀者很有幫助——你不寫，呼叫者就要自己翻方法內部才能知道「這個方法會丟什麼例外」。

---

## 六、例外的傳播：Call Stack 追溯

這是整個例外處理裡**最重要**的觀念之一。當例外發生時，JVM 不是「就地處理」，而是會沿著**呼叫堆疊（Call Stack）往回找**，看哪一層有對應的 `catch` 可以接住。

### 傳播流程示意

```
main() 呼叫 → methodA() 呼叫 → methodB() 呼叫 → methodC()
                                                    ↑ 例外在這裡發生！

例外傳播方向（往回找 catch）：
methodC() → 沒有 try-catch → 拋給 methodB()
methodB() → 沒有 try-catch → 拋給 methodA()
methodA() → 有 catch！     → 在這裡被接住並處理
```

### 程式碼示範

```java
public class PropagationDemo {

    public static void main(String[] args) {
        System.out.println("1. main 開始");
        try {
            methodA();
        } catch (Exception e) {
            System.out.println("5. main 接住例外：" + e.getMessage());
        }
        System.out.println("6. main 結束");
    }

    private static void methodA() throws Exception {
        System.out.println("2. 進入 methodA");
        methodB();  // methodA 沒有 try-catch，例外會繼續往上拋
        System.out.println("這行不會被執行");
    }

    private static void methodB() throws Exception {
        System.out.println("3. 進入 methodB");
        methodC();  // methodB 也沒有 try-catch
        System.out.println("這行不會被執行");
    }

    private static void methodC() throws Exception {
        System.out.println("4. 進入 methodC，準備拋出例外");
        throw new Exception("methodC 中發生錯誤");
    }
}
```

**輸出結果：**

```
1. main 開始
2. 進入 methodA
3. 進入 methodB
4. 進入 methodC，準備拋出例外
5. main 接住例外：methodC 中發生錯誤
6. main 結束
```

幾個重點觀察：

- 例外在 `methodC()` 被拋出後，因為 `methodC`、`methodB`、`methodA` 都沒有 `try-catch`，所以一路往回拋到 `main`。
- `main` 的 `catch` 接住例外後，程式繼續執行 `catch` 之後的程式碼（`"6. main 結束"`）。
- 例外發生點之後的程式碼（`methodA` 跟 `methodB` 裡的 `"這行不會被執行"`）**完全不會跑到**。

> **如果連 `main` 都沒接住，JVM 就會印出 Stack Trace 並終止程式。** 這也是為什麼 Java 程式偶爾會在主控台噴一大串紅字然後直接結束。

---

## 七、finally 的執行時機

`finally` 區塊幾乎在**任何情況下都會執行**，包括：

- `try` 正常結束
- `try` 中發生例外並被 `catch` 接住
- `catch` 中又拋出新的例外
- `try` 或 `catch` 中執行了 `return`

### 小試身手

來個小思考題，先想想下面這段程式的輸出，再看答案：

```java
import java.io.IOException;

public class ExceptionTest {
    public static void main(String[] args) {
        try {
            throwIOExceptionManually();
        } catch (Exception e) {
            System.out.println(e);
        }
    }

    private static void throwIOExceptionManually() throws Exception {
        try {
            throw new IOException();
        } catch (Exception e) {
            throw e;         // 重新拋出例外
        } finally {
            System.out.println("finally");
        }
    }
}
```

**執行流程分析：**

1. `main` 呼叫 `throwIOExceptionManually()`
2. 方法內部 `throw new IOException()` → 被自己的 `catch (Exception e)` 接住
3. `catch` 執行 `throw e`，準備把例外再拋出去——**但在真正拋出之前，`finally` 先跑**
4. 印出 `finally`
5. 例外才被拋回 `main` 的 `catch (Exception e)` 接住
6. 印出 `java.io.IOException`

**輸出結果：**

```
finally
java.io.IOException
```

> **重點：即使 `catch` 裡有 `throw` 或 `return`，`finally` 都會在它們「真正生效」之前先執行。**

這個特性讓 `finally` 變成釋放資源的最佳位置——不管前面發生什麼事，資源都會被清掉。但也要小心一個反模式：**不要在 `finally` 裡 `return`**，那會把原本要往上拋的例外整個吞掉，超難 debug。

---

## 八、try-with-resources（Java 7+）

### 為什麼需要 try-with-resources？

在傳統的 `try-catch-finally` 寫法中，要釋放資源往往得寫成這種又臭又長的樣子：

```java
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.IOException;

public class OldStyleDemo {
    public static void main(String[] args) {
        BufferedReader br = null;
        try {
            br = new BufferedReader(new FileReader("data.txt"));
            System.out.println(br.readLine());
        } catch (IOException e) {
            System.out.println("讀取失敗：" + e.getMessage());
        } finally {
            // 手動關閉資源，還要再處理關閉時可能發生的例外...
            if (br != null) {
                try {
                    br.close();
                } catch (IOException e) {
                    System.out.println("關閉失敗：" + e.getMessage());
                }
            }
        }
    }
}
```

這寫法有三個明顯的問題：`finally` 區塊冗長、容易忘記 `close()`、關閉資源本身又需要額外的 `try-catch`。寫過一輪你就會知道有多繁瑣。

### try-with-resources 語法

只要資源類別有實作 `AutoCloseable`（或它的子介面 `Closeable`），就可以放在 `try(...)` 的小括號裡，JVM 會在 `try` 區塊結束時**自動呼叫 `close()`**。

```java
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.IOException;

public class TryWithResourcesDemo {
    public static void main(String[] args) {
        // 資源宣告在 try 的小括號中，結束時自動關閉
        try (var br = new BufferedReader(new FileReader("data.txt"))) {
            System.out.println(br.readLine());
        } catch (IOException e) {
            System.out.println("讀取失敗：" + e.getMessage());
        }
        // 不需要 finally 手動關閉！br.close() 會自動被呼叫
    }
}
```

短了一大截，而且不會漏關。

### 多個資源的寫法

多個資源之間用分號 `;` 隔開，**關閉順序與宣告順序相反**（後宣告的先關閉，跟堆疊一樣後進先出）：

```java
import java.io.*;

public class MultiResourceDemo {
    public static void main(String[] args) {
        try (
            var fr = new FileReader("data.txt");       // 第一個開啟
            var br = new BufferedReader(fr)             // 第二個開啟
        ) {
            String line;
            while ((line = br.readLine()) != null) {
                System.out.println(line);
            }
        } catch (IOException e) {
            System.out.println("錯誤：" + e.getMessage());
        }
        // 關閉順序：br 先關 → fr 再關（與宣告順序相反）
    }
}
```

### 自訂 AutoCloseable 資源

你也可以讓自己的類別實作 `AutoCloseable`，就能搭配 `try-with-resources` 使用：

```java
public class DatabaseConnection implements AutoCloseable {
    private final String name;

    public DatabaseConnection(String name) {
        this.name = name;
        System.out.println("開啟連線：" + name);
    }

    public void query(String sql) {
        System.out.println("[" + name + "] 執行查詢：" + sql);
    }

    @Override
    public void close() {
        System.out.println("關閉連線：" + name);
    }

    public static void main(String[] args) {
        try (var conn = new DatabaseConnection("MyDB")) {
            conn.query("SELECT * FROM users");
        }
        // 離開 try 區塊時，自動呼叫 conn.close()
    }
}
```

**輸出結果：**

```
開啟連線：MyDB
[MyDB] 執行查詢：SELECT * FROM users
關閉連線：MyDB
```

> **下一篇預告：在 JDBC 中，`Connection`、`PreparedStatement`、`ResultSet` 都有實作 `AutoCloseable`，到時候會大量用 `try-with-resources` 來管理資料庫資源，寫起來大致像這樣：**

```java
try (
    var conn = DriverManager.getConnection(url, user, password);
    var pstmt = conn.prepareStatement("SELECT * FROM products WHERE category = ?");
) {
    pstmt.setString(1, "電子產品");
    try (var rs = pstmt.executeQuery()) {
        while (rs.next()) {
            System.out.println(rs.getString("name"));
        }
    }
} catch (SQLException e) {
    System.out.println("資料庫錯誤：" + e.getMessage());
}
// conn、pstmt、rs 全部自動關閉，不用寫任何 finally
```

對比傳統寫法，省下來的程式碼量相當可觀。

---

## 九、自訂 Exception：把領域語意帶進例外

當內建的例外類型（`IllegalArgumentException`、`IllegalStateException` 等）無法精確表達你的錯誤情境時，可以考慮自訂 Exception。

### 自訂 Unchecked Exception

繼承 `RuntimeException` 即可：

```java
public class InsufficientStockException extends RuntimeException {

    private final String productId;
    private final int requested;
    private final int available;

    public InsufficientStockException(String productId, int requested, int available) {
        super(String.format("商品 %s 庫存不足：請求 %d 個，僅剩 %d 個",
                productId, requested, available));
        this.productId = productId;
        this.requested = requested;
        this.available = available;
    }

    public String getProductId() { return productId; }
    public int getRequested()    { return requested; }
    public int getAvailable()    { return available; }
}
```

使用時：

```java
public class OrderService {
    public void placeOrder(String productId, int quantity, int stock) {
        if (quantity > stock) {
            throw new InsufficientStockException(productId, quantity, stock);
        }
        System.out.println("訂單建立成功");
    }
}
```

這樣寫的好處是：呼叫端 `catch` 到例外後，可以從 `getProductId()`、`getAvailable()` 直接拿到結構化資訊，不用再去 parse `getMessage()` 字串。

### 自訂 Checked Exception

繼承 `Exception` 即可（注意不要繼承 `RuntimeException`）：

```java
public class ConfigLoadException extends Exception {
    public ConfigLoadException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

實務經驗：除非有強烈的「呼叫端一定要處理」需求，否則我個人傾向自訂 Unchecked Exception，理由跟前面提到的一樣——Checked 容易讓 `throws` 鏈一路擴散，最後變得難以維護。

### 章節小結

- 自訂例外的價值在於**帶入領域語意**跟**結構化資訊**。
- 預設選 Unchecked（繼承 `RuntimeException`），除非真的需要強制呼叫端處理。

---

## 十、練習題

最後放兩個練習題，可以動手寫寫看。

### 練習一：try-catch-finally 基礎

建立類別 `ExceptionDemo.java`，將下列程式片段置入 `main` 方法：

```java
FileReader file = new FileReader("D:/testException.txt");
```

**要求：**

- 加上 `try-catch-finally` 區塊讓程式可正常執行
- `catch` 區塊印出例外發生原因
- `finally` 區塊印出 `"Finally Block"`

**參考解答：**

```java
import java.io.FileReader;
import java.io.FileNotFoundException;

public class ExceptionDemo {
    public static void main(String[] args) {
        FileReader file = null;
        try {
            file = new FileReader("D:/testException.txt");
            System.out.println("檔案開啟成功");
        } catch (FileNotFoundException e) {
            System.out.println("Catch Block, Error Message：" + e.getMessage());
        } finally {
            System.out.println("Finally Block");
        }
    }
}
```

**預期輸出（檔案不存在時）：**

```
Catch Block, Error Message：D:\testException.txt（系統找不到指定的檔案。）
Finally Block
```

**預期輸出（檔案存在時）：**

```
檔案開啟成功
Finally Block
```

**進階挑戰：用 try-with-resources 改寫看看。**

```java
import java.io.FileReader;
import java.io.IOException;

public class ExceptionDemoV2 {
    public static void main(String[] args) {
        try (var file = new FileReader("D:/testException.txt")) {
            System.out.println("檔案開啟成功");
        } catch (IOException e) {
            System.out.println("Catch Block, Error Message：" + e.getMessage());
        }
        // FileReader 會自動關閉，不需要 finally
    }
}
```

### 練習二：手動拋出例外

建立類別 `ExceptionHandle.java`：

**要求：**

- 產生介於 1~100 的隨機整數
- 用 `%` 運算子判斷奇偶
- 若為**奇數**：印出該數字
- 若為**偶數**：拋出 `Exception` 並印出該數字

**參考解答：**

```java
public class ExceptionHandle {
    public static void main(String[] args) {
        // 產生 1~100 的隨機數
        int randomNum = (int) (Math.random() * 100) + 1;

        try {
            if (randomNum % 2 == 0) {
                // 偶數 → 手動拋出例外
                throw new Exception("偶數：" + randomNum);
            }
            // 奇數 → 正常印出
            System.out.println("奇數：" + randomNum);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

**可能的輸出：**

```
奇數：67
```

或

```
java.lang.Exception: 偶數：22
    at ExceptionHandle.main(ExceptionHandle.java:9)
```

---

## 小結

這篇我們從頭到尾整理了 Java 的例外處理：

| 主題 | 重點 |
| --- | --- |
| Exception vs Error | Exception 可處理；Error 不該由程式處理 |
| Checked Exception | 「外部環境不可控」的意外，編譯期強制處理（`IOException`、`SQLException`） |
| Unchecked Exception | 「程式邏輯有瑕疵」的失誤，不強制處理，為 `RuntimeException` 子類別 |
| Checked ≠ 語法錯誤 | 不是語法錯誤，而是「契約違規」——編譯器看得懂，但你未履行處理義務 |
| Lambda 中的例外 | Unchecked 可直接拋；Checked 需在 Lambda 內 try-catch 或包裝成 RuntimeException |
| catch 順序 | 子類別在前，父類別在後 |
| 例外傳播 | 沿 Call Stack 往回找，直到遇到匹配的 catch 或由 JVM 終止程式 |
| finally | 幾乎一定會執行，包括 catch 中有 throw 或 return 的情況 |
| throw vs throws | `throw` 拋出例外實例；`throws` 宣告方法可能拋出的例外類型 |
| try-with-resources | 資源實作 `AutoCloseable` 即可自動關閉，取代冗長的 finally 關閉邏輯 |
| 自訂 Exception | 帶入領域語意與結構化資訊，預設選 Unchecked |
| 現代趨勢 | 許多語言與框架傾向用 Unchecked 包裝 Checked，減少 throws 傳播鏈 |

例外處理的核心精神，其實是「設計失敗的劇本」。寫順手的人會發現，與其想著「怎麼讓程式不要出錯」，不如想著「出錯時要怎麼優雅退場」——這也是健壯程式跟脆弱程式最大的差別。

下一篇我們會進入 **Java JDBC**，會大量用到這篇講到的 `try-with-resources` 跟 `SQLException` 處理。如果有任何錯誤或可以補充的地方，歡迎留言指教，我們下一篇見。
