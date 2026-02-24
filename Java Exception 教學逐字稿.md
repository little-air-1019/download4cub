# Java 17 課程：Exception 例外處理

---

## 一、什麼是例外（Exception）？

在了解例外之前，我們要先學會區分兩個容易混淆的概念：**例外（Exception）** 與 **錯誤（Error）**。

### 例外（Exception）

例外是指程式在執行過程中，遇到了**不符合預期邏輯**的狀況。關鍵在於：這是程式設計師**可以預見、應該處理**的問題。

舉個銀行業務的例子：你設計了一支匯款功能，使用者卻在「匯款金額」的欄位輸入了「王小明」。這就是一種例外——使用者的操作偏離了預期。我們可以做的處理有：輸入檢核、提示重新輸入、或設定預設值。

例外通常只影響程式中的**特定部分**，不會讓整個系統崩潰，而且大部分情況下是可以預防或復原的。

### 錯誤（Error）

錯誤代表的是**系統層級的嚴重問題**，程式設計師在程式碼中**無法處理，也不應該嘗試處理**。

常見的例子包括 `OutOfMemoryError`（記憶體不足）、`StackOverflowError`（堆疊溢位）。遇到這類問題，解決方式通常不在程式碼層面，而是要請維運人員來擴充硬體資源或排查系統配置。

> **簡單記法：Exception 靠程式處理，Error 靠系統處理。**

---

## 二、例外的繼承架構

Java 中所有可拋出的物件都繼承自 `Throwable` 類別，它底下分成兩大分支：

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

這張架構圖非常重要，它直接決定了「你需不需要在程式碼中強制處理某個例外」。接下來我們就來看這個分界點在哪裡。

---

## 三、例外的種類：Checked vs. Unchecked

Java 設計這套機制的初衷，是為了提升程式的**健壯性（Robustness）**。你可以把它想成 Java 幫你在寫程式時裝了兩套不同的「警報系統」。要理解這兩套系統，最好的切入角度是**「責任歸屬」——這個錯到底是誰造成的？**

簡單來說，Java 是在區分 **「環境造成的意外」** 與 **「程式碼寫錯的失誤」**。

### Checked Exception（受檢例外）——外部環境不可控

- 繼承自 `Exception`，但**不是** `RuntimeException` 的子類別
- **必須在編譯時期處理**，否則程式無法通過編譯
- 編譯器會強制要求你用 `try-catch` 接住，或用 `throws` 往上拋
- 常見範例：`IOException`、`SQLException`、`FileNotFoundException`

**本質：程式碼本身沒有寫錯，但「外部環境」不可控。** 例如：你要讀的檔案剛好被刪了、網路斷了、資料庫連不上。這些事情在現實環境中「一定會發生」，與其讓程式跑起來才崩潰，不如在編譯時就強迫開發者寫好應對方案。

```java
// 這段程式碼無法通過編譯，因為 FileNotFoundException 是 Checked Exception
import java.io.FileReader;

public class CheckedDemo {
    public static void main(String[] args) {
        // ❌ 編譯錯誤！必須處理 FileNotFoundException
        // 編譯器的意思是：「檔案不一定存在，你打算怎麼辦？先寫好再說。」
        FileReader reader = new FileReader("test.txt");
    }
}
```

### Unchecked Exception（非受檢例外）——程式邏輯有瑕疵

- 是 `RuntimeException` 的子類別（或更嚴重的 `Error`）
- **不需要強制處理**，即使不寫 `try-catch`，程式也能通過編譯
- 通常代表**程式邏輯上的 bug**，應該透過**修正邏輯**來避免，而不是靠 `try-catch` 補救
- 常見範例：`NullPointerException`、`ArrayIndexOutOfBoundsException`、`ArithmeticException`

**本質：這些是「程式寫錯了」。** 存取了空物件、陣列索引出界、除以零——這些都該從邏輯上根治。如果編譯時強迫每個地方都要檢查有沒有 `NullPointerException`，那程式碼會變得極度臃腫且難以閱讀。所以 Java 的設計是：讓它直接報錯並停下來，提醒開發者「這裡邏輯寫錯了，請去修程式碼」。

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

### 編譯前後檢查的意義

| 檢查時機                    | 類型      | 意義                                                                                                                     |
| --------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------ |
| **編譯時（Static Check）**  | Checked   | **合約精神：** 強制規定 API 的使用者必須處理潛在的風險。這是一種「強迫式的安全提示」，確保你在開發階段就考慮到失敗路徑。 |
| **執行時（Dynamic Check）** | Unchecked | **防禦邏輯：** 這些錯誤反映的是程式的 Bug。讓它直接報錯停下來，讓開發者知道「這裡邏輯寫錯了，請去修程式碼」。            |

### 常見疑問：Checked Exception 編譯不過，算是「語法錯誤」嗎？

嚴格來說，這**不是語法錯誤（Syntax Error）**，而是一種**語意或契約上的違規（Contract Violation）**。

- **語法錯誤（Syntax Error）：** 像是漏了分號 `;` 或大括號 `{}`，編譯器根本看不懂這行程式碼的意思，無法轉成字節碼（Bytecode）。
- **Checked Exception 編譯失敗：** 編譯器看得懂你的程式碼，但它發現你**「未履行義務」**。

這比較像是在簽合約：語法錯誤是「字寫錯了，合約無法辨讀」；Checked Exception 報錯則是「你這份合約裡提到要負責維護，但你沒寫維護計畫，所以合約不成立」。

### 補充：現代語言的趨勢

雖然 Java 堅持 Checked / Unchecked 的分類設計，但現代許多語言（如 Kotlin、Scala、C#）都傾向於**不使用 Checked Exception**。原因在於開發者發現，強制捕捉例外往往導致大量的「空 `catch` 塊」或是層層疊疊的 `throws`，反而讓程式碼變得難以維護。

這也是為什麼在現代 Java 開發框架（如 Spring）中，許多 Checked Exception 會被**包裝成 Unchecked Exception** 丟出。例如 Spring 的 `DataAccessException` 就是 `RuntimeException` 的子類別，它把 JDBC 的 `SQLException`（Checked）包裝了起來，讓開發者不必在每一層都寫 `throws`。

不過在本課程中，我們仍然要扎實地理解 Checked Exception 的機制，因為底層 API（如 JDBC）依然大量使用它，後續課程會頻繁遇到。

### 補充：Lambda / forEach 中可以拋出例外嗎？

這個問題在實務開發中很常遇到，答案取決於例外的類型。

**Unchecked Exception → 可以直接拋出，沒有限制。**

```java
import java.util.List;

public class LambdaUncheckedDemo {
    public static void main(String[] args) {
        var names = List.of("Alice", "Bob", "");

        // forEach 中拋出 Unchecked Exception：完全合法
        names.forEach(name -> {
            if (name.isEmpty()) {
                throw new IllegalArgumentException("名字不可為空字串");
            }
            System.out.println(name.toUpperCase());
        });
    }
}
```

**Checked Exception → 無法直接拋出，編譯會失敗！**

原因在於 Java 標準函式介面（如 `Consumer<T>`、`Function<T,R>`）的抽象方法簽章**沒有宣告 `throws`**，所以你無法在 Lambda 中直接拋出 Checked Exception。

```java
import java.util.List;
import java.io.IOException;

public class LambdaCheckedDemo {
    public static void main(String[] args) {
        var fileNames = List.of("a.txt", "b.txt");

        // ❌ 編譯錯誤！Consumer.accept() 沒有宣告 throws IOException
        fileNames.forEach(name -> {
            throw new IOException("找不到檔案：" + name);
        });
    }
}
```

**那如果真的需要在 Lambda 中處理 Checked Exception 怎麼辦？** 有兩種常見做法：

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

**做法二：將 Checked Exception 包裝成 Unchecked Exception 後再拋出**

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

> **小結：Lambda / forEach 中只能「直接拋出」Unchecked Exception。若要處理 Checked Exception，必須在 Lambda 內部 try-catch 或包裝成 RuntimeException。**

---

## 四、例外處理語法：try-catch-finally

### 基本語法結構

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

### 關鍵規則

1. **`catch` 的順序必須從子類到父類**——如果把父類放在前面，子類的 `catch` 永遠不會被執行到，編譯器會報錯。
2. **`finally` 區塊一定會執行**——不管 `try` 中是否發生例外、`catch` 中是否又拋出例外，`finally` 都會在方法回傳之前執行。
3. **`finally` 常用於釋放資源**——例如關閉資料庫連線、檔案串流等（後面會介紹更優雅的 `try-with-resources`）。

### catch 順序示範

```java
import java.io.FileNotFoundException;
import java.io.IOException;

public class CatchOrderDemo {
    public static void main(String[] args) {
        try {
            throw new FileNotFoundException("找不到設定檔");

        } catch (FileNotFoundException e) {
            // ✅ 子類別放前面
            System.out.println("檔案未找到：" + e.getMessage());

        } catch (IOException e) {
            // ✅ 父類別放後面
            System.out.println("IO 錯誤：" + e.getMessage());

        } catch (Exception e) {
            // ✅ 最大的父類別放最後
            System.out.println("其他錯誤：" + e.getMessage());
        }
    }
}
```

如果反過來把 `Exception` 放在第一個 `catch`，後面的 `catch` 就永遠不會被觸發，編譯器會直接報錯。

### Java 7+ 的 Multi-catch 語法

從 Java 7 開始，可以在同一個 `catch` 中用 `|` 同時捕捉多種例外，前提是這些例外之間**沒有繼承關係**：

```java
try {
    // 某些操作
} catch (FileNotFoundException | ArithmeticException e) {
    // 同時處理這兩種不同類型的例外
    System.out.println("發生例外：" + e.getMessage());
}
```

---

## 五、例外的拋出與接住：throw 與 throws

### `throw`：手動拋出一個例外物件

```java
throw new IllegalArgumentException("金額不可為負數");
```

`throw` 是在方法**內部**使用的關鍵字，用來主動拋出一個例外實例。

### `throws`：宣告方法可能拋出的例外

```java
public void readFile(String path) throws IOException {
    var reader = new FileReader(path);
}
```

`throws` 寫在方法簽章上，告訴呼叫者：「這個方法可能會拋出某種例外，你必須處理。」

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
     * 但為了可讀性，這裡加上了。
     */
    private static void validateAge(int age) {
        if (age < 0) {
            throw new IllegalArgumentException("年齡不能是負數，收到：" + age);
        }
        System.out.println("年齡驗證通過：" + age);
    }
}
```

---

## 六、例外的傳播順序（Call Stack 追溯）

這是整個例外處理中最重要的觀念之一。當例外發生時，JVM 會沿著**呼叫堆疊（Call Stack）往回找**，看哪一層有對應的 `catch` 可以接住。

### 傳播流程圖

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

**重點觀察：**

- 例外在 `methodC()` 被拋出後，因為 `methodC`、`methodB`、`methodA` 都沒有 `try-catch`，所以一路往回拋到 `main`。
- `main` 的 `catch` 接住了這個例外，程式繼續執行 `catch` 之後的程式碼。
- 例外發生點之後的程式碼（`methodA` 和 `methodB` 中的 `"這行不會被執行"`）**不會被執行**。

> **如果連 `main` 都沒有 `catch` 住，JVM 就會印出堆疊追蹤（Stack Trace）並終止程式。**

---

## 七、finally 的執行時機

`finally` 區塊幾乎在**任何情況下都會執行**，包括：

- `try` 正常結束
- `try` 中發生例外並被 `catch` 接住
- `catch` 中又拋出新的例外

### 小試身手

請先思考以下程式的輸出結果，再看答案：

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
3. `catch` 區塊執行 `throw e`，準備把例外再拋出去——**但在拋出之前，`finally` 先執行**
4. 印出 `finally`
5. 例外被拋回 `main` 的 `catch (Exception e)` 接住
6. 印出 `java.io.IOException`

**輸出結果：**

```
finally
java.io.IOException
```

> **記住：即使 `catch` 中有 `throw` 或 `return`，`finally` 都會在它們「真正生效」之前先執行。**

---

## 八、try-with-resources（Java 7+）

### 為什麼需要 try-with-resources？

在傳統的 `try-catch-finally` 寫法中，釋放資源的程式碼往往又臭又長：

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

這樣的寫法有幾個問題：`finally` 區塊冗長、容易忘記關閉資源、關閉資源本身又需要額外的 `try-catch`。

### try-with-resources 語法

只要資源類別有實作 `AutoCloseable`（或其子介面 `Closeable`），就可以放在 `try(...)` 的小括號中，JVM 會在 `try` 區塊結束時**自動呼叫 `close()` 方法**。

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

### 多個資源的寫法

多個資源之間用分號 `;` 隔開，**關閉順序與宣告順序相反**（後宣告的先關閉）：

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

> **預告：在後續的 JDBC 課程中，`Connection`、`PreparedStatement`、`ResultSet` 都有實作 `AutoCloseable`，屆時我們會大量使用 `try-with-resources` 來管理資料庫資源，寫起來大致像這樣：**

```java
try (
    var conn = DriverManager.getConnection(url, user, password);
    var pstmt = conn.prepareStatement("SELECT * FROM employees WHERE dept = ?");
) {
    pstmt.setString(1, "IT");
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

---

## 九、練習題

### 練習一：try-catch-finally 基礎

建立類別 `ExceptionDemo.java`，將下列程式片段置入 `main` 方法：

```java
FileReader file = new FileReader("D:/testException.txt");
```

**要求：**

- 加上 `try-catch-finally` 區塊使程式可正常執行
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

**進階挑戰：請試著用 try-with-resources 改寫這個練習。**

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

---

### 練習二：手動拋出例外

建立類別 `ExceptionHandle.java`：

**要求：**

- 產生介於 1~100 的隨機整數
- 使用 `%` 運算子判斷奇偶
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

## 十、重點回顧

| 主題                | 重點                                                                           |
| ------------------- | ------------------------------------------------------------------------------ |
| Exception vs Error  | Exception 可處理；Error 不應處理                                               |
| Checked Exception   | 「外部環境不可控」的意外，編譯時期強制處理（IOException、SQLException）        |
| Unchecked Exception | 「程式邏輯有瑕疵」的失誤，不強制處理，為 RuntimeException 子類別               |
| Checked ≠ 語法錯誤  | 不是語法錯誤，而是「契約違規」——編譯器看得懂，但你未履行處理義務               |
| Lambda 中的例外     | Unchecked 可直接拋；Checked 需在 Lambda 內 try-catch 或包裝為 RuntimeException |
| catch 順序          | 子類別在前，父類別在後                                                         |
| 例外傳播            | 沿 Call Stack 往回找，直到遇到匹配的 catch 或由 JVM 終止程式                   |
| finally             | 幾乎一定會執行，包括 catch 中有 throw 或 return 的情況                         |
| throw vs throws     | throw 拋出例外實例；throws 宣告方法可能拋出的例外類型                          |
| try-with-resources  | 資源實作 AutoCloseable 即可自動關閉，取代冗長的 finally 關閉邏輯               |
| 現代趨勢            | 許多語言與框架傾向用 Unchecked 包裝 Checked，減少 throws 傳播鏈                |