# Java JDBC 入門指南：從連線、PreparedStatement 到交易控制

> 這是 Java 教學系列的第三篇，也是這個系列的最後一篇。前兩篇分別整理了 [Java Collections Framework](#) 跟 [Exception 例外處理](#)，這次想來談 JDBC——Java 連接資料庫的標準 API。寫久了 Spring Boot、JPA 之後，反而會發現很多坑、很多直覺其實都要回到 JDBC 本身才講得清楚。文章內容是我這幾年踩過的坑、整理出來的筆記，如果有任何錯誤或可以補充的地方，歡迎在留言區指教。

## 前言

剛開始接觸 Java 操作資料庫的時候，大多數人應該都是直接從 Spring Data JPA 或 MyBatis 開始的，幾乎不會碰到底層的 `Connection`、`PreparedStatement`。但只要在實務上待夠久，遲早會遇到這些問題：

- 為什麼連線數爆掉，整個服務就掛了？
- 為什麼老前輩看到 `"... WHERE id = '" + userId + "'"` 會立刻臉色發白？
- `@Transactional` 到底背後做了什麼事？

這些問題的答案，幾乎都藏在 JDBC 裡面。所以即使現在你不會直接寫 `DriverManager.getConnection`，理解這一層的運作邏輯，仍然會讓你對「資料庫操作」這件事有完全不同的直覺。

這篇文章我想分成幾個部分慢慢講：

1. JDBC 是什麼，為什麼這樣設計
2. JDBC 操作的四個步驟
3. `Statement` vs `PreparedStatement`，以及 SQL Injection
4. `ResultSet` 的運作原理
5. 為什麼資源一定要關，try-with-resources 怎麼用
6. JNDI 與 DataSource：企業應用的標配
7. 資料庫交易（Transaction）：ACID 與手動控制

我們從第一個問題開始。

---

## 一、JDBC 是什麼？

JDBC 全名是 **Java DataBase Connectivity**，是 Java 用來連接、操作資料庫的標準 API。

它在設計上其實分成兩個部分：

- **應用程式開發者介面**：也就是我們會直接用到的 `java.sql` 跟 `javax.sql` 兩個套件。本篇文章的內容幾乎都在這層。
- **驅動程式開發者介面**：給資料庫廠商實作的。像 Oracle、MySQL、PostgreSQL 各自會根據 JDBC 規範，提供自家的 Driver。

### 為什麼要這樣設計？

想像一下，如果沒有 JDBC，每換一套資料庫就要重學一套 API，那會是什麼地獄。JDBC 的核心理念是：

> **同一套 API，操作所有資料庫。**

這其實就是 OOP 裡「多型」的精神——應用程式只需要依賴 JDBC 的介面（`Connection`、`Statement`、`ResultSet`），而具體用的是 MySQL 還是 PostgreSQL 的 Driver，對程式碼來說幾乎是透明的。要換資料庫的時候，理想情況下只要換 Driver 跟連線字串就好。

---

## 二、專案環境：用 Maven 管理 Driver

在開始寫程式之前，先把 Driver 準備好。

很久以前的 Java 教學會教你「去官網下載 JAR 檔，丟到 classpath」，但這個年代我會直接建議用 Maven（或 Gradle）來管理。Maven 會自動幫你解決：

- 從 Maven Central 下載對應的 JAR
- 處理套件間的相依關係
- 統一專案的建置流程

順便補充一下，JAR 全名是 **Java Archive File**，本質上就是一種壓縮打包格式，跟 ZIP、RAR 是同一個概念。Java 生態系幾十年累積下來的第三方函式庫，幾乎都是以 JAR 的形式發布——靠手動管理絕對會痛不欲生，所以才需要 Maven 這類工具。

### pom.xml 加入 Driver

我比較常用 MySQL，所以以下範例都會以 MySQL 為主：

```xml
<dependencies>
    <!-- MySQL JDBC Driver -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <version>8.2.0</version>
    </dependency>
</dependencies>
```

如果你用的是 PostgreSQL：

```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>42.7.1</version>
</dependency>
```

寫一些 demo / 單元測試的時候，我自己也滿喜歡用 H2 這種純 Java 的嵌入式資料庫，不用安裝就能用：

```xml
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <version>2.2.224</version>
</dependency>
```

Maven 重新整理一下，Driver 就準備好了。

---

## 三、JDBC 操作的四個步驟

整體流程其實不複雜，記住下面四步就好：

1. **取得連線**：透過 `DriverManager` 或 `DataSource` 拿到 `Connection`
2. **準備 SQL**：用 `Statement` 或 `PreparedStatement` 包裝 SQL
3. **執行 SQL**：呼叫 `executeQuery()` 或 `executeUpdate()`
4. **釋放資源**：關閉 `ResultSet`、`Statement`、`Connection`

接下來逐一拆開來看。

---

## 四、取得資料庫連線

第一步是建立連線，最基本的寫法是用 `DriverManager`：

```java
String url = "jdbc:mysql://localhost:3306/mydb";
String user = "root";
String password = "password";

Connection conn = DriverManager.getConnection(url, user, password);
```

三個參數分別是：

- **url**：包含協定、子協定、資料庫位址跟 schema
- **username**：資料庫帳號
- **password**：資料庫密碼

### URL 的格式

不同資料庫的 URL 格式略有差異，這幾個是最常見的：

```
# MySQL
jdbc:mysql://localhost:3306/mydb

# PostgreSQL
jdbc:postgresql://localhost:5432/mydb

# H2（記憶體模式，常用於測試）
jdbc:h2:mem:testdb
```

### 不用再寫 Class.forName 了

如果你看過古老的 Java 教材，會看到一行很神祕的：

```java
// 舊版寫法，現在不用了
Class.forName("com.mysql.cj.jdbc.Driver");
```

這是 JDBC 4.0（Java 6）以前的時代，需要手動把 Driver 類別載入記憶體。從 JDBC 4.0 開始，只要 classpath 上有正確的 Driver JAR，JDBC 會透過 SPI（Service Provider Interface）自動載入，這行 `Class.forName` 完全不需要了。

現代 Java（17、21）的環境下，直接 `getConnection()` 就好，乾淨許多。

---

## 五、準備 SQL：Statement vs PreparedStatement

拿到 `Connection` 之後，下一步是準備 SQL。JDBC 提供了三種 API：`Statement`、`PreparedStatement`、`CallableStatement`。它們是繼承關係：

```
Statement
  └── PreparedStatement
        └── CallableStatement
```

實務上 99% 的情況都是用 `PreparedStatement`，但要理解為什麼，得先看看 `Statement` 有什麼問題。

### Statement：能用但不該用

`Statement` 是最基礎的方式，適合靜態 SQL：

```java
Statement stmt = conn.createStatement();
String sql = "SELECT * FROM users WHERE id = '" + userId + "'";
ResultSet rs = stmt.executeQuery(sql);
```

這種寫法有兩個非常嚴重的問題：

**第一，效能差。** 每次執行都要重新組合字串，資料庫端也要重新解析、重新產生執行計畫。

**第二，會被 SQL Injection 攻擊。** 這個才是大魔王。

### 什麼是 SQL Injection？

SQL Injection 也叫「SQL 隱碼攻擊」，是把惡意 SQL 片段透過使用者輸入塞進原本的查詢字串，改變 SQL 的執行邏輯。

假設我們有一段登入驗證的程式碼：

```java
String sql = "SELECT * FROM users WHERE username = '" + username
           + "' AND password = '" + password + "'";
```

使用者輸入帳號 `lily`、密碼 `1234`，SQL 會組成：

```sql
SELECT * FROM users WHERE username = 'lily' AND password = '1234'
```

看起來沒問題。但如果有人在密碼欄位輸入 `' OR '1'='1`，SQL 就變成：

```sql
SELECT * FROM users WHERE username = 'lily' AND password = '' OR '1'='1'
```

因為 `'1'='1'` 永遠為真，整個 WHERE 條件直接被打穿，攻擊者就這樣繞過了登入驗證。如果是查詢結果寫到網頁上，更厲害的 payload 還可以 `UNION SELECT` 拉出整個 users 資料表，甚至 `DROP TABLE`。

這也是為什麼老前輩看到字串串接的 SQL 會臉色發白——這已經不是「寫法不好」的層級了，這是直接打開後門。

### PreparedStatement：實務上的標配

`PreparedStatement` 用的是**參數化查詢**：SQL 跟參數值是分開傳給資料庫的，由資料庫端負責處理參數的跳脫，不會被當成 SQL 語法解析。

```java
String sql = "SELECT * FROM users WHERE username = ? AND password = ?";

try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
    pstmt.setString(1, username);
    pstmt.setString(2, password);

    try (ResultSet rs = pstmt.executeQuery()) {
        // ...
    }
}
```

幾個小細節值得注意：

- SQL 中會變動的部分用 `?` 表示，稱為 **placeholder**
- 透過 `setString(index, value)`、`setInt(index, value)` 之類的方法填入參數
- **索引從 1 開始**，不是 0（這是 JDBC 的傳統，跟 Java 陣列剛好相反，初學者很常踩這個坑）

PreparedStatement 的好處：

1. **效能好**：SQL 結構會被資料庫預先解析、編譯，多次執行同一個查詢只需要換參數值。
2. **天然防 SQL Injection**：因為參數值不會被當作 SQL 語法的一部分。
3. **可讀性好**：SQL 結構清楚，不會被一堆字串串接打亂。

### CallableStatement：呼叫 Stored Procedure

`CallableStatement` 是用來呼叫資料庫的 Stored Procedure（預儲程序）的：

```java
CallableStatement cstmt = conn.prepareCall("{call my_procedure(?, ?)}");
```

Stored Procedure 的效能很好，但彈性差、跨資料庫移植性差，現代開發越來越少用，這裡只做簡單介紹。

### 三種方式的比較

| 方式 | 適用場景 | 效能 | 安全性 |
|------|----------|------|--------|
| `Statement` | 完全靜態的 SQL（幾乎不該用） | 差 | 差 |
| `PreparedStatement` | 一般動態 SQL（實務最常用） | 好 | 好 |
| `CallableStatement` | 呼叫 Stored Procedure | 最好 | 好 |

**結論：除非你有非常明確的理由，否則一律用 `PreparedStatement`。**

---

## 六、執行 SQL 與處理 ResultSet

SQL 準備好之後，根據是查詢還是寫入，呼叫的方法不一樣。

### 查詢用 executeQuery

SELECT 用 `executeQuery()`，回傳值是 `ResultSet`：

```java
String sql = "SELECT id, name, email FROM users WHERE status = ?";

try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
    pstmt.setString(1, "ACTIVE");
    try (ResultSet rs = pstmt.executeQuery()) {
        while (rs.next()) {
            String id = rs.getString("id");
            String name = rs.getString("name");
            String email = rs.getString("email");
            System.out.printf("ID: %s, Name: %s, Email: %s%n", id, name, email);
        }
    }
}
```

### 寫入用 executeUpdate

INSERT / UPDATE / DELETE 用 `executeUpdate()`，回傳值是 `int`，代表受影響的列數：

```java
String sql = "INSERT INTO users (id, name, email) VALUES (?, ?, ?)";

try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
    pstmt.setString(1, "U001");
    pstmt.setString(2, "朴莉莉");
    pstmt.setString(3, "lily@example.com");

    int affected = pstmt.executeUpdate();
    System.out.println("新增了 " + affected + " 筆資料");
}
```

### ResultSet 的指標模型

`ResultSet` 的結構有點像 `Iterator`，內部維護一個指標（cursor）指向「目前這一筆」。

剛拿到的 `ResultSet`，指標位於第一筆資料**之前**。你必須先呼叫 `next()` 才會移到第一筆：

```java
while (rs.next()) {
    // 這時指標已經指向「下一筆」資料

    // 用欄位名稱取值（推薦）
    String name = rs.getString("name");
    int age = rs.getInt("age");

    // 也可以用欄位索引取值，索引從 1 開始
    String nameByIndex = rs.getString(1);
}
```

幾個容易踩坑的地方：

- `rs.next()` 一次做兩件事：**「檢查是否還有下一筆」+「將指標移到下一筆」**。它回傳 `true` 表示移到了一筆有效資料，`false` 表示沒了。
- 欄位索引一樣**從 1 開始**。
- 我會建議用欄位名稱取值，可讀性比較好；用索引的問題是 SQL 一改順序，程式碼就全錯。

### ResultSet 不是把資料全部載入記憶體

這個概念對效能影響很大，值得花一段講清楚。

很多初學者會以為 `executeQuery()` 是把所有結果都載入 Java 端的記憶體裡。但其實不是——`ResultSet` 維護的是一個指向資料庫端「查詢結果游標」的連結。當你呼叫 `next()` 移動指標時，JDBC Driver 才會從資料庫**逐筆**抓資料回來。

這也是為什麼 `ResultSet` 必須在 `Connection` 還活著的時候才能用——它跟資料庫之間有一條開放的連線。如果你想「先把 `ResultSet` 收起來，等等再用」，那行不通；應該要在 `while (rs.next())` 的迴圈裡，把資料轉成你自己的 DTO 或 List，然後把 ResultSet 關掉。

這個設計在處理大量資料時非常省記憶體，但也意味著：**ResultSet 是有生命週期的，用完就要關，連線也不能斷。**

---

## 七、釋放資源：為什麼一定要關？

這是初學者最容易忽略、實務上踩坑最痛的地方。

資料庫的連線是**有限資源**。每一條 `Connection` 在資料庫端都會佔用一個連線數，背後甚至可能是一個獨立的 OS thread 或 process。如果你用完不關，連線就會一直被佔著，直到逾時。當系統流量上來，連線數爆掉，新的請求就拿不到連線，服務直接掛掉——這就是經典的「連線洩漏（connection leak）」。

我看過最痛的一次，是 production 服務跑了一週才慢慢卡死，因為一個邊角的 API 漏了關連線，每呼叫一次就漏一條，累積到上限才爆。Debug 起來非常痛苦，事後檢討的時候我發誓——以後一律用 try-with-resources。

### try-with-resources（強烈推薦）

從 Java 7 開始，凡是實作了 `AutoCloseable` 介面的物件，都可以放進 try-with-resources 的 `()` 裡，離開 try 區塊時 JVM 會自動呼叫 `close()`。

`Connection`、`PreparedStatement`、`ResultSet` 都有實作 `AutoCloseable`，所以可以這樣寫：

```java
String url = "jdbc:mysql://localhost:3306/mydb";
String user = "root";
String password = "password";

String sql = "SELECT id, name FROM users WHERE status = ?";

try (Connection conn = DriverManager.getConnection(url, user, password);
     PreparedStatement pstmt = conn.prepareStatement(sql)) {

    pstmt.setString(1, "ACTIVE");

    try (ResultSet rs = pstmt.executeQuery()) {
        while (rs.next()) {
            System.out.println(rs.getString("name"));
        }
    }

} catch (SQLException e) {
    e.printStackTrace();
}
// 離開 try 區塊時，rs、pstmt、conn 都會自動依序關閉
```

幾點觀察：

- 多個 resource 用分號 `;` 隔開
- 關閉的順序是**反向**的（最後宣告的最先關），對應到 JDBC 的「由小到大關」的傳統
- 即使中途拋出例外，`close()` 還是會被呼叫

這是現代 Java 寫 JDBC 的標準姿勢，幾乎沒有任何理由不用它。

### 傳統的 try-finally（不建議，但要看得懂）

在 Java 7 之前，或某些舊系統還沒升上來的情況，會看到這種寫法：

```java
Connection conn = null;
PreparedStatement pstmt = null;
ResultSet rs = null;

try {
    conn = DriverManager.getConnection(url, user, password);
    pstmt = conn.prepareStatement(sql);
    pstmt.setString(1, "ACTIVE");
    rs = pstmt.executeQuery();

    while (rs.next()) {
        System.out.println(rs.getString("name"));
    }

} catch (SQLException e) {
    e.printStackTrace();
} finally {
    // 由小到大關：rs → pstmt → conn
    try { if (rs != null) rs.close(); } catch (SQLException e) { e.printStackTrace(); }
    try { if (pstmt != null) pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
    try { if (conn != null) conn.close(); } catch (SQLException e) { e.printStackTrace(); }
}
```

幾個重點：

1. 關閉前一定要先 `!= null` 檢查
2. 關閉順序由小到大：**ResultSet → Statement → Connection**
3. 每個 `close()` 都可能丟例外，所以要分開包，避免前一個失敗影響後面

看就知道有多醜——除非你被困在 Java 6 的時代，否則沒有理由不用 try-with-resources。

---

## 八、整合一個完整範例

把前面的內容整合起來，做一個查詢 + 新增的完整範例。我們用 NMIXX 的成員當測試資料：

```java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class JdbcDemo {

    private static final String URL = "jdbc:mysql://localhost:3306/mydb";
    private static final String USER = "root";
    private static final String PASSWORD = "password";

    public static void main(String[] args) {
        insertExample();
        queryExample();
    }

    /**
     * 新增範例：把 NMIXX 成員寫進 users 表
     */
    private static void insertExample() {
        String sql = "INSERT INTO users (id, name, email, status) VALUES (?, ?, ?, ?)";

        // 注意：朴莉莉、吳海嫄、薛侖娥、裴真率、金智友、張圭珍
        Object[][] members = {
            {"U001", "朴莉莉", "lily@example.com", "ACTIVE"},
            {"U002", "吳海嫄", "haewon@example.com", "ACTIVE"},
            {"U003", "薛侖娥", "sullyoon@example.com", "ACTIVE"},
            {"U004", "裴真率", "jinni@example.com", "ACTIVE"},
            {"U005", "金智友", "jiwoo@example.com", "ACTIVE"},
            {"U006", "張圭珍", "kyujin@example.com", "ACTIVE"},
        };

        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            for (Object[] m : members) {
                pstmt.setString(1, (String) m[0]);
                pstmt.setString(2, (String) m[1]);
                pstmt.setString(3, (String) m[2]);
                pstmt.setString(4, (String) m[3]);
                pstmt.executeUpdate();
            }

            System.out.println("新增完成");

        } catch (SQLException e) {
            System.err.println("資料庫操作錯誤：" + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * 查詢範例
     */
    private static void queryExample() {
        String sql = "SELECT id, name, email FROM users WHERE status = ?";

        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, "ACTIVE");

            try (ResultSet rs = pstmt.executeQuery()) {
                System.out.println("=== 查詢結果 ===");
                while (rs.next()) {
                    String id = rs.getString("id");
                    String name = rs.getString("name");
                    String email = rs.getString("email");
                    System.out.printf("ID: %s, Name: %s, Email: %s%n", id, name, email);
                }
            }

        } catch (SQLException e) {
            System.err.println("資料庫操作錯誤：" + e.getMessage());
            e.printStackTrace();
        }
    }
}
```

這個範例的好處是它已經是「實務上可以直接抄」的版本——`PreparedStatement` 防 Injection、try-with-resources 自動關資源、查詢用 `executeQuery`、寫入用 `executeUpdate`。

---

## 九、JNDI 與 DataSource：企業應用的標配

到目前為止，我們的範例都把 URL、帳號、密碼寫死在程式碼裡。實務上這樣做有幾個問題：

1. **安全性**：帳密放在程式碼裡，git 一推上去就是事故新聞
2. **可維護性**：DB 換伺服器、改密碼，就要重新編譯、重新部署
3. **資源管理**：每次都用 `DriverManager.getConnection` 開新連線，沒有連線池，效能很差

業界的解法是 **JNDI + DataSource**。

### 什麼是 JNDI？

JNDI 全名是 **Java Naming and Directory Interface**，是一個查名字找資源的 API。打個比方：

> JNDI 就像通訊錄。你不需要記每個人的電話號碼，只要記名字，就能透過通訊錄查到電話。

在 Java EE / Jakarta EE 的世界裡，伺服器（Tomcat、WildFly、WebLogic）會幫你管理一個「資源目錄」，你把 DataSource 註冊上去，給它一個 JNDI 名稱（例如 `jdbc/MyDB`），程式裡只要透過這個名稱去查，就能拿到 DataSource。

### 設定 DataSource（以 Tomcat 為例）

在 Tomcat 的 `context.xml` 加入 Resource：

```xml
<Resource name="jdbc/MyDB"
          auth="Container"
          type="javax.sql.DataSource"
          driverClassName="com.mysql.cj.jdbc.Driver"
          url="jdbc:mysql://localhost:3306/mydb"
          username="root"
          password="password"
          maxTotal="20"
          maxIdle="10"
          maxWaitMillis="10000"/>
```

### 在程式裡透過 JNDI 取得連線

```java
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;
import java.sql.Connection;

public class JndiExample {

    public Connection getConnection() throws Exception {
        Context initContext = new InitialContext();
        Context envContext = (Context) initContext.lookup("java:/comp/env");

        DataSource ds = (DataSource) envContext.lookup("jdbc/MyDB");

        return ds.getConnection();
    }
}
```

注意看，程式碼裡完全沒有 URL、帳號、密碼，只有一個 JNDI 名稱 `jdbc/MyDB`。所有連線細節都交給伺服器管。

### 為什麼 DataSource 比 DriverManager 好？

撇開 JNDI 不談，光是 `DataSource` 這個介面本身就比 `DriverManager` 強很多，因為它通常內建**連線池（Connection Pool）**。

連線池的概念很簡單：

- 預先建立一批連線放在池子裡
- 程式要用的時候，從池子借一條
- 用完還回去（呼叫 `close()` 不是真的關，是還給池子）
- 真實的連線就這樣被重複使用

這比每次都 `DriverManager.getConnection` 開一條新連線快非常多。在 Spring Boot 的世界裡，預設用的 HikariCP 就是業界公認最快的連線池實作之一。

實務上現在很少看到純手寫 JNDI lookup 的程式碼了，但理解這個概念對於後面學 Spring 的 `DataSource` 配置非常有幫助——因為本質上是同一件事。

---

## 十、資料庫交易（Transaction）

前面我們處理的都是「單一 SQL 操作」，但在真實的商業應用裡，很多時候我們要做的是一連串相關的操作，這些操作必須被當成一個整體：**要嘛全部成功，要嘛全部失敗，不能只完成一半。**

這就是「資料庫交易」存在的理由。

### 為什麼需要交易？用一個下單情境舉例

假設我們在做一個簡單的電商系統，使用者下訂單時要做兩件事：

1. 在 `orders` 表新增一筆訂單
2. 從 `products` 表扣掉對應的庫存

聽起來很單純，但想像一下沒有交易保護的情況——第 1 步寫入成功了，因為 JDBC 預設是**自動提交**（autoCommit = true），這筆 INSERT 立刻生效。結果第 2 步 UPDATE 庫存的時候，網路斷了、系統崩了，第 2 步沒做完。

結果是：訂單已經產生，但庫存沒扣。下次有人下單，可能就會超賣。或者反過來：庫存扣了但訂單沒建，商品憑空消失。

不管哪一種，都是資料一致性的災難。

### 用購物車比喻 autoCommit

我自己很喜歡用購物車來理解這兩種模式：

- **autoCommit = true**（預設）：就像每拿一件商品就馬上去櫃檯結帳。買五樣東西要刷五次卡，中途任何一件不想買都麻煩——前面已經結帳的退不掉。
- **autoCommit = false**（手動交易）：把商品全部放進購物車，最後一次推到櫃檯結帳。中途想反悔，整車推回去就好，錢包完全沒動。

實務上幾乎所有「多步驟操作」都應該用手動交易。

### 交易的四大特性：ACID

正式一點講，交易必須滿足四個特性，合稱 **ACID**：

**Atomicity（原子性）**：交易裡的所有操作要嘛全做、要嘛全不做，不存在「做一半」的狀態。原子性是交易最核心的特性。

**Consistency（一致性）**：交易執行前後，資料庫必須維持在一致的狀態，所有的 constraint、business rule 都要被滿足。例如下單前後，「訂單數量 + 庫存數量」的總和應該保持不變。

**Isolation（隔離性）**：多個交易同時執行時，彼此之間不應該互相干擾。從每個交易的角度看，就好像整個資料庫只有它一個交易在執行。這背後牽涉到隔離等級（Isolation Level），是一個很深的主題，這篇文章先不展開。

**Durability（持久性）**：交易一旦 commit，這些改變就會永久保存，即使系統當機重啟也不會遺失。

### JDBC 的交易控制三劍客

在 JDBC 裡，交易控制主要靠 `Connection` 上的三個方法：

- `setAutoCommit(false)`：關閉自動提交，從這一刻起，所有 SQL 都不會立即生效
- `commit()`：所有操作成功，正式提交
- `rollback()`：發生錯誤，撤銷所有未提交的操作

### 一個完整的下單範例

把概念套到剛剛的電商下單情境，看一段完整的程式碼。為了讓邏輯清楚，我先用比較傳統的 try-finally 寫法：

```java
Connection conn = null;

try {
    conn = DriverManager.getConnection(URL, USER, PASSWORD);

    // 關閉自動提交，開始手動控制交易
    conn.setAutoCommit(false);

    // 步驟一：新增訂單
    String insertOrderSql =
        "INSERT INTO orders (order_id, user_id, product_id, quantity) VALUES (?, ?, ?, ?)";
    try (PreparedStatement pstmt = conn.prepareStatement(insertOrderSql)) {
        pstmt.setString(1, "ORD20260517001");
        pstmt.setString(2, "U001");
        pstmt.setString(3, "P100");
        pstmt.setInt(4, 2);
        pstmt.executeUpdate();
    }

    // 步驟二：扣減庫存
    String updateStockSql =
        "UPDATE products SET stock = stock - ? WHERE product_id = ? AND stock >= ?";
    try (PreparedStatement pstmt = conn.prepareStatement(updateStockSql)) {
        pstmt.setInt(1, 2);
        pstmt.setString(2, "P100");
        pstmt.setInt(3, 2);
        int affected = pstmt.executeUpdate();
        if (affected == 0) {
            // 庫存不足，主動拋例外讓外層 rollback
            throw new SQLException("商品 P100 庫存不足");
        }
    }

    // 兩個步驟都成功，正式提交
    conn.commit();
    System.out.println("下單成功");

} catch (SQLException e) {
    System.out.println("下單失敗：" + e.getMessage());
    if (conn != null) {
        try {
            conn.rollback();
            System.out.println("已回滾所有操作");
        } catch (SQLException ex) {
            ex.printStackTrace();
        }
    }
} finally {
    // 還回 autoCommit，再關連線
    // 為什麼要還回 autoCommit？因為 conn 如果來自連線池，會被回收給別人用
    if (conn != null) {
        try {
            conn.setAutoCommit(true);
            conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
```

幾個值得注意的細節：

1. **`setAutoCommit(false)` 一定要在所有 SQL 之前呼叫**，不然前面已經 commit 的就回不去了。
2. **rollback 要包在 catch 裡**，並且自己也要 try-catch（rollback 本身也可能丟例外）。
3. **finally 裡記得 `setAutoCommit(true)` 再 close**，因為這條連線可能是從連線池借的，不還回原本的 autoCommit 設定，下一個借到它的人會踩坑。

### commit 之前，資料到底在哪？

這個問題我以前學的時候一直想不通——`executeUpdate` 都執行了，但還沒 commit，資料到底是在 Java 程式裡，還是在資料庫裡？

答案是：**已經在資料庫裡了，只是還沒「正式生效」。**

當你 `executeUpdate`，SQL 已經送到資料庫伺服器執行，資料庫把這些變更記錄在內部的 **Undo Log（回滾日誌）** 跟記憶體緩衝區裡。在這個狀態下：

- 同一個 Connection 的後續查詢，**看得到**這些變更（你扣完庫存，馬上查還是看得到新數字）
- 其他 Connection **看不到**這些變更（這就是隔離性在運作）

只有當你 `commit()`，資料庫才會把這些變更「落盤」、寫入永久儲存區，並對所有連線公開。如果你 `rollback()`，資料庫就用 Undo Log 把資料還原。

### 資料庫不會幫你最佳化交易內的操作

這也是個常見的疑問：如果我在一個交易裡，先 INSERT 一筆資料，再 DELETE 同一筆資料，最後 commit。資料庫會不會聰明到發現「加一減一等於沒做」，直接跳過？

答案是：**不會。**

資料庫會按照你發送 SQL 的順序，逐筆執行每一個操作。INSERT 就 INSERT，DELETE 就 DELETE，每一筆都會在 Undo Log 留下紀錄。commit 時，這些變更一次性轉為永久生效。

為什麼這樣設計？因為原子性 + 隔離性的要求。如果資料庫真的「優化」掉中間步驟，那當這個交易執行到一半時，其他交易來查詢這筆資料，會看到不一致的狀態。而且當你需要 rollback 的時候，每一個步驟都得能還原。所以「按順序執行 + 完整可回滾」才是正解。

### 跟未來學的 @Transactional 接得起來

如果你後面會學 Spring，會發現有個 `@Transactional` 註解，加在 Service 方法上就自動處理交易了。它做的事情，本質上就是這篇講的：

```java
// Spring 幫你自動做的事情大概是這樣
try {
    conn.setAutoCommit(false);
    methodBody();              // 你的業務邏輯
    conn.commit();
} catch (Exception e) {
    conn.rollback();
    throw e;
} finally {
    conn.setAutoCommit(true);
    conn.close();
}
```

理解 JDBC 這一層的交易控制，未來遇到 Spring 交易相關的問題（例如「為什麼我的 `@Transactional` 沒生效」、「為什麼 rollback 沒觸發」），你才有能力追根究底。

---

## 結語：寫在系列文章的最後

這篇文章寫得有點長，但 JDBC 真的是一個怎麼壓縮都很難講完的主題。我自己再整理一次重點：

1. JDBC 是 Java 操作資料庫的標準 API，靠多型的設計做到「同一套 API、多家資料庫」
2. 用 Maven 管 Driver，現代 Java 不用再寫 `Class.forName`
3. 四步驟：取得連線 → 準備 SQL → 執行 SQL → 釋放資源
4. **永遠用 `PreparedStatement`，永遠不要用字串串接 SQL**——SQL Injection 不是學術問題，是真實世界每天都在發生的攻擊
5. `ResultSet` 是游標模型，跟資料庫保持連線；用完就要關
6. **資源一定要關**，能用 try-with-resources 就用 try-with-resources
7. 企業應用透過 JNDI / DataSource 管理連線，背後通常還有連線池
8. 多步驟操作要用交易：`setAutoCommit(false)` → `commit()` 或 `rollback()`
9. 理解 ACID、理解 JDBC 交易控制，未來 Spring 的 `@Transactional` 就不會是黑魔法

這篇是這個 Java 教學系列的最後一篇。回頭看整個系列：

- 第一篇 [Collections Framework](#)：從 Array 的限制談到 List、Set、Queue、Map
- 第二篇 [Exception 例外處理](#)：checked / unchecked、try-with-resources、自訂例外
- 第三篇 JDBC（本篇）：從連線、SQL、ResultSet 一路講到交易

這三個主題其實是有層次關係的——Collections 是資料結構的基礎，Exception 是錯誤處理的基礎，而 JDBC 是「跟外部世界打交道」的入口。理解了這三塊，再去學 Spring、JPA、Spring Boot 才不會踩很深的坑。

文章有任何錯誤或可以補充的地方，歡迎留言指教。我們有緣再見。
