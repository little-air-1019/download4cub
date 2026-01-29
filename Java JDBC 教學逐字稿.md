# JDBC 教學講義（Java 17 版）

---

## 第一章：JDBC 簡介

### 什麼是 JDBC？

JDBC 的全名是 **Java DataBase Connectivity**，是 Java 用於連接和操作資料庫的標準 API。

我們可以把 JDBC 分成兩個部分來理解：

第一個部分是**應用程式開發者介面**，也就是我們一般開發者會用到的 `java.sql` 和 `javax.sql` 這兩個套件。這是我們今天課程的重點。

第二個部分是**驅動程式開發者介面**，這是給資料庫廠商實作的。像是 Oracle、MySQL、PostgreSQL 這些廠商，他們會根據 JDBC 的規範，提供自己的驅動程式，我們稱之為 **Driver**。

### 為什麼需要 JDBC？

這裡要請大家思考一個問題：市面上有這麼多種資料庫，Oracle、MySQL、PostgreSQL、SQL Server 等等，每一家的底層實作都不一樣。如果沒有 JDBC，我們是不是要針對每一種資料庫學習不同的操作方式？那會非常麻煩對吧？

JDBC 的設計理念就是：**讓開發者用同一套 API 操作所有資料庫**。

這裡我要問大家一個問題：這種設計是不是很像我們之前學過的**多型**？沒錯！我們不需要知道 Oracle 或 MySQL 底層是怎麼實作的，只要它們的 Driver 遵守 JDBC 的規範，我們就可以用相同的程式碼來操作不同的資料庫。

---

## 第二章：專案環境設定

在開始寫程式之前，我們要先把環境準備好。

### 使用 Maven 管理相依套件

在 Java 8 的時代，我們可能會手動下載 JAR 檔然後放到專案裡面。但是從 Java 17 開始，我們**強烈建議使用 Maven 來管理專案的相依套件**。

#### 什麼是 Maven？

Maven 是一個專案管理工具，它可以幫我們：

- 自動下載需要的套件
- 管理套件之間的相依關係
- 統一專案的建置流程

#### 什麼是 JAR？

這裡補充說明一下 JAR 是什麼。JAR 的全名是 **Java Archive File**，它其實就是一種打包檔案的格式，就像大家熟悉的 ZIP 或 RAR 一樣。

我們通常會把可以重複使用的程式碼打包成 JAR 檔，這樣在其他專案就可以直接引入使用。因為 Java 是開源的生態系，同樣的功能可能有成千上萬種第三方 JAR 檔可以選擇，如果用手動管理會非常混亂，所以我們才需要 Maven 來幫我們管理。

### 建立 Maven 專案

首先，請大家建立一個新的 Maven 專案。在 `pom.xml` 檔案中，加入資料庫驅動程式的相依套件。

以 Oracle 資料庫為例，請在 `<dependencies>` 區塊中加入以下內容：

```xml
<dependencies>
    <!-- Oracle JDBC Driver -->
    <dependency>
        <groupId>com.oracle.database.jdbc</groupId>
        <artifactId>ojdbc11</artifactId>
        <version>23.3.0.23.09</version>
    </dependency>
</dependencies>
```

如果你使用的是 MySQL，則改成：

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

如果是 PostgreSQL：

```xml
<dependencies>
    <!-- PostgreSQL JDBC Driver -->
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <version>42.7.1</version>
    </dependency>
</dependencies>
```

加入之後，Maven 就會自動幫我們下載對應的驅動程式，不需要手動去官網下載了。是不是很方便？

---

## 第三章：JDBC 操作流程

接下來我們來看 JDBC 的操作流程。整個流程可以分成四個步驟：

1. **取得連線** - 建立與資料庫的連線
2. **寫入 SQL 指令** - 準備要執行的 SQL
3. **執行 SQL 指令** - 送出並執行 SQL
4. **釋放資源** - 關閉連線，釋放系統資源

這四個步驟我們會一一詳細說明。

---

## 第四章：取得資料庫連線

### 連接資料庫

要操作資料庫，第一步當然是要先建立連線。在 JDBC 中，我們使用 `DriverManager.getConnection()` 方法來取得連線：

```java
Connection conn = DriverManager.getConnection(url, username, password);
```

這個方法需要三個參數：

- **url**：定義了連接資料庫的位址，包含協定、子協定、資料來源識別
- **username**：資料庫的帳號
- **password**：資料庫的密碼

#### URL 的格式說明

不同資料庫的 URL 格式不太一樣，這裡列出幾個常見的範例：

**Oracle：**
```
jdbc:oracle:thin:@主機名稱:1521:資料庫名稱
```

**MySQL：**
```
jdbc:mysql://主機名稱:3306/資料庫名稱
```

**PostgreSQL：**
```
jdbc:postgresql://主機名稱:5432/資料庫名稱
```

### 關於 Driver 的載入

在舊版的 Java（JDBC 4.0 之前），我們需要手動載入驅動程式，會看到這樣的程式碼：

```java
// 舊版寫法，現在不需要了
Class.forName("oracle.jdbc.driver.OracleDriver");
```

但是從 **JDBC 4.0**（Java 6）開始，驅動程式會**自動載入**，我們不需要再寫 `Class.forName()` 了。只要在專案中引入了正確的驅動程式 JAR 檔（透過 Maven），JDBC 就會自動偵測並載入。

所以在 Java 17 的環境下，我們直接呼叫 `getConnection()` 就可以了，非常簡潔。

---

## 第五章：寫入 SQL 指令

取得連線之後，下一步是準備我們要執行的 SQL 指令。JDBC 提供了三種方式來處理 SQL：

### 方式一：Statement

`Statement` 是最基礎的方式，適合執行靜態的 SQL 指令。

```java
Statement stmt = conn.createStatement();
```

使用範例：

```java
String sql = "SELECT * FROM MEMBER WHERE ID = '" + userId + "'";
ResultSet rs = stmt.executeQuery(sql);
```

但是，這種寫法有兩個很大的問題：

第一，**效能較差**。每次執行都要重新組合字串，資料庫也需要重新解析 SQL。

第二，**有安全性漏洞**。這種寫法容易受到 **SQL Injection（SQL 注入攻擊）** 的威脅。

#### 什麼是 SQL Injection？

SQL Injection 是一種「隱碼攻擊」。攻擊者可以透過輸入特殊的字串，改變原本 SQL 的邏輯。

舉個例子，假設我們的登入查詢是這樣寫的：

```sql
SELECT * FROM MEMBER WHERE ID = '輸入的帳號' AND PWD = '輸入的密碼'
```

正常情況下，使用者輸入帳號 `hello` 和密碼 `hello`，SQL 會變成：

```sql
SELECT * FROM MEMBER WHERE ID = 'hello' AND PWD = 'hello'
```

但如果攻擊者在密碼欄位輸入 `' OR 1='1`，SQL 就會變成：

```sql
SELECT * FROM MEMBER WHERE ID = '' AND PWD = '' OR 1='1'
```

因為 `1='1'` 永遠為 true，這個查詢就會回傳所有資料，攻擊者就成功繞過了登入驗證！

所以，**我們在實務上幾乎不會使用 Statement**，而是使用接下來要介紹的 PreparedStatement。

### 方式二：PreparedStatement（推薦使用）

`PreparedStatement` 繼承自 `Statement`，它可以使用**參數化查詢**，是我們實務上最常用的方式。

```java
String sql = "SELECT * FROM MEMBER WHERE ID = ? AND PWD = ?";
PreparedStatement pstmt = conn.prepareStatement(sql);
pstmt.setString(1, userId);    // 設定第一個參數
pstmt.setString(2, password);  // 設定第二個參數
```

注意看，SQL 中會變動的部分我們用 `?` 來表示，然後透過 `setXxx()` 方法來設定參數值。參數的索引從 **1** 開始，不是從 0 開始喔！

#### PreparedStatement 的優點

**第一，效能較佳。** SQL 會預先編譯，如果要執行多次相同結構的查詢，只需要替換參數值就好。

**第二，可以防止 SQL Injection。** 因為參數值會被正確地跳脫處理，攻擊者無法透過輸入特殊字串來改變 SQL 的邏輯。

### 方式三：CallableStatement

`CallableStatement` 是用來呼叫資料庫的 **Stored Procedure（預儲程序）** 的。

```java
CallableStatement cstmt = conn.prepareCall("{call 程序名稱(?, ?)}");
```

Stored Procedure 是預先寫好並儲存在資料庫中的程序，優點是效能很好，缺點是彈性較差，而且需要針對不同資料庫做調整。

在一般的應用中，我們比較少用到 CallableStatement，所以這裡只做簡單介紹。

### 三種方式的比較

| 方式 | 適用場景 | 效能 | 安全性 |
|------|----------|------|--------|
| Statement | 靜態 SQL（幾乎不使用） | 差 | 差 |
| PreparedStatement | 動態 SQL（最常用） | 佳 | 佳 |
| CallableStatement | 呼叫 Stored Procedure | 最佳 | 佳 |

**結論：實務上請優先使用 PreparedStatement！**

---

## 第六章：執行 SQL 指令

SQL 指令準備好之後，接下來就是執行了。根據 SQL 的類型不同，執行的方法和回傳值也不一樣。

### 有資料回傳的查詢（SELECT）

如果是 SELECT 查詢，使用 `executeQuery()` 方法，回傳值是 `ResultSet` 物件：

```java
String sql = "SELECT * FROM MEMBER WHERE DEPT = ?";
PreparedStatement pstmt = conn.prepareStatement(sql);
pstmt.setString(1, "IT");

ResultSet rs = pstmt.executeQuery();
```

### 無資料回傳的操作（INSERT、UPDATE、DELETE）

如果是 INSERT、UPDATE、DELETE 等操作，使用 `executeUpdate()` 方法，回傳值是 `int`，代表受影響的資料筆數：

```java
String sql = "UPDATE MEMBER SET NAME = ? WHERE ID = ?";
PreparedStatement pstmt = conn.prepareStatement(sql);
pstmt.setString(1, "新名字");
pstmt.setString(2, "M001");

int affectedRows = pstmt.executeUpdate();
System.out.println("更新了 " + affectedRows + " 筆資料");
```

### 處理 ResultSet

當我們執行 SELECT 查詢後，會得到一個 `ResultSet` 物件。這個物件的結構有點像 `Iterator`，它有一個指標（cursor）指向目前的位置。

一開始，指標會在第一筆資料**之前**。我們需要呼叫 `next()` 方法來移動指標：

```java
while (rs.next()) {
    // rs.next() 會將指標移到下一筆資料
    // 如果有下一筆資料，回傳 true；如果沒有了，回傳 false
    
    String id = rs.getString("ID");        // 用欄位名稱取值
    String name = rs.getString("NAME");
    int age = rs.getInt("AGE");            // 也可以取得其他型別
    
    // 或者用欄位索引取值（從 1 開始）
    String id2 = rs.getString(1);
    
    System.out.println("ID: " + id + ", Name: " + name);
}
```

這裡要特別注意：

- `rs.next()` 同時做了「檢查是否有下一筆」和「移動到下一筆」兩件事
- 取值的時候，欄位索引是從 **1** 開始，不是 0
- 建議使用欄位名稱來取值，程式碼比較容易閱讀和維護

#### ResultSet 的運作原理

有一點要跟大家說明：`ResultSet` 物件實際上並不是把資料庫的所有資料都載入記憶體中。它建立的是與每一筆資料的**連結（Link）**，當指標移動到某一筆資料時，才會透過連結去取得該筆資料。

這樣的設計可以節省記憶體，特別是在處理大量資料的時候。

---

## 第七章：資源關閉

這是很多初學者容易忽略的一個步驟，但其實非常重要。

資料庫的連線是**有限的資源**。如果我們用完之後不關閉，連線就會一直被佔用。當連線數量達到上限時，新的請求就無法取得連線，系統就會出問題。

所以，程式執行完畢後，一定要記得關閉 `ResultSet`、`Statement` 和 `Connection`。

### 方式一：try-with-resources（推薦使用）

從 Java 7 開始，我們可以使用 **try-with-resources** 語法，它會自動幫我們關閉資源：

```java
String url = "jdbc:mysql://localhost:3306/mydb";
String user = "root";
String password = "password";

String sql = "SELECT * FROM MEMBER WHERE DEPT = ?";

try (Connection conn = DriverManager.getConnection(url, user, password);
     PreparedStatement pstmt = conn.prepareStatement(sql)) {
    
    pstmt.setString(1, "IT");
    
    try (ResultSet rs = pstmt.executeQuery()) {
        while (rs.next()) {
            System.out.println(rs.getString("NAME"));
        }
    }
    
} catch (SQLException e) {
    e.printStackTrace();
}
// 離開 try 區塊時，資源會自動關閉，不需要手動呼叫 close()
```

使用 try-with-resources 的條件是：物件必須實作 `AutoCloseable` 介面。`Connection`、`PreparedStatement`、`ResultSet` 都有實作這個介面，所以可以直接使用。

這是 **Java 17 推薦的寫法**，程式碼簡潔又安全。

### 方式二：傳統的 try-catch-finally

如果因為某些原因無法使用 try-with-resources，也可以用傳統的方式，在 `finally` 區塊中手動關閉資源：

```java
Connection conn = null;
PreparedStatement pstmt = null;
ResultSet rs = null;

try {
    conn = DriverManager.getConnection(url, user, password);
    pstmt = conn.prepareStatement(sql);
    pstmt.setString(1, "IT");
    rs = pstmt.executeQuery();
    
    while (rs.next()) {
        System.out.println(rs.getString("NAME"));
    }
    
} catch (SQLException e) {
    e.printStackTrace();
} finally {
    // 關閉資源的順序：由小到大（rs → pstmt → conn）
    try {
        if (rs != null) rs.close();
    } catch (SQLException e) {
        e.printStackTrace();
    }
    try {
        if (pstmt != null) pstmt.close();
    } catch (SQLException e) {
        e.printStackTrace();
    }
    try {
        if (conn != null) conn.close();
    } catch (SQLException e) {
        e.printStackTrace();
    }
}
```

使用這種方式要注意幾點：

1. 關閉前要先檢查是否為 `null`
2. 關閉的順序要**由小到大**：先關 ResultSet，再關 Statement，最後關 Connection
3. 每個 `close()` 都可能拋出例外，所以要分開處理

可以看到，傳統寫法非常冗長。所以只要可以的話，請優先使用 try-with-resources。

---

## 第八章：完整範例

最後，我們來看一個完整的範例，把前面學到的內容整合在一起：

```java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class JdbcDemo {
    
    // 資料庫連線資訊
    private static final String URL = "jdbc:mysql://localhost:3306/mydb";
    private static final String USER = "root";
    private static final String PASSWORD = "password";
    
    public static void main(String[] args) {
        // 查詢範例
        queryExample();
        
        // 新增範例
        insertExample();
    }
    
    /**
     * 查詢範例
     */
    private static void queryExample() {
        String sql = "SELECT ID, NAME, EMAIL FROM MEMBER WHERE DEPT = ?";
        
        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            // 設定參數
            pstmt.setString(1, "IT");
            
            // 執行查詢
            try (ResultSet rs = pstmt.executeQuery()) {
                System.out.println("=== 查詢結果 ===");
                while (rs.next()) {
                    String id = rs.getString("ID");
                    String name = rs.getString("NAME");
                    String email = rs.getString("EMAIL");
                    System.out.printf("ID: %s, Name: %s, Email: %s%n", id, name, email);
                }
            }
            
        } catch (SQLException e) {
            System.err.println("資料庫操作發生錯誤：" + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * 新增範例
     */
    private static void insertExample() {
        String sql = "INSERT INTO MEMBER (ID, NAME, EMAIL, DEPT) VALUES (?, ?, ?, ?)";
        
        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            // 設定參數
            pstmt.setString(1, "M001");
            pstmt.setString(2, "王小明");
            pstmt.setString(3, "ming@example.com");
            pstmt.setString(4, "IT");
            
            // 執行新增
            int affectedRows = pstmt.executeUpdate();
            System.out.println("成功新增 " + affectedRows + " 筆資料");
            
        } catch (SQLException e) {
            System.err.println("資料庫操作發生錯誤：" + e.getMessage());
            e.printStackTrace();
        }
    }
}
```

---

## 重點整理

1. **JDBC** 是 Java 連接資料庫的標準 API，讓我們可以用同一套程式碼操作不同的資料庫

2. **使用 Maven** 管理相依套件，不要再手動下載 JAR 檔了

3. JDBC 操作的四個步驟：取得連線 → 寫入 SQL → 執行 SQL → 關閉資源

4. Java 17 環境下，**Driver 會自動載入**，不需要再寫 `Class.forName()`

5. **優先使用 PreparedStatement**，可以防止 SQL Injection，效能也比較好

6. **務必關閉資源**，優先使用 **try-with-resources** 語法

7. 取值的欄位索引從 **1** 開始，不是 0

---

## 課後練習

### 練習一：QueryByPK

建立一個類別 `QueryByPK.java`，完成以下需求：

1. 使用 `PreparedStatement` 從 `STUDENT.CARS` 資料表查詢製造商為 **Toyota**，型號為 **R8** 的車款
2. 查出該筆資料的所有欄位，包裝成 `Map`
3. 取得 `Map` 的值，以 `StringBuilder` 串接
4. 依下列格式印出結果

**資料表欄位說明：**
- 製造商（MANUFACTURER）
- 型號（TYPE）
- 售價（PRICE）
- 底價（MIN_PRICE）

**預期輸出：**
```
製造商：Toyota，型號：R8，售價：$200.0，底價：$100.0
```

---

### 練習二：QueryByManufacturer

建立一個類別 `QueryByManufacturer.java`，完成以下需求：

1. 使用 `PreparedStatement` 從 `STUDENT.CARS` 資料表查詢製造商為 **Toyota** 的所有車輛
2. 查出所有欄位後，包裝成 `List<Map>`
3. 將查出的每一筆資料用 `StringBuilder` 串接，印出每一筆資料的製造商、型號、售價、底價，以及「售價高於底價」的差額

**預期輸出：**
```
製造商：Toyota，型號：A1，售價：500，底價：350，售價高於底價：150
製造商：Toyota，型號：B3，售價：650，底價：500，售價高於底價：150
製造商：Toyota，型號：R8，售價：200，底價：100，售價高於底價：100
製造商：Toyota，型號：R9，售價：1500，底價：1000，售價高於底價：500
```

---

## 第九章：JNDI 簡介

最後，我們來介紹一個在企業應用中很重要的概念：**JNDI**。

### 什麼是 JNDI？

JNDI 的全名是 **Java Naming and Directory Interface**，是 Java 提供的一個 API，主要用於存取命名和目錄服務。

聽起來有點抽象對吧？讓我用一個比喻來說明。

大家有沒有用過電話簿？當我們要打電話給某個人的時候，我們不需要記住他的電話號碼，只要在電話簿裡面用名字查詢，就可以找到對應的號碼。JNDI 就是類似的概念——我們可以用一個「名稱」來查詢對應的「資源」。

### 為什麼需要 JNDI？

在前面的範例中，我們把資料庫的連線資訊（URL、帳號、密碼）直接寫在程式碼裡面。這樣做有幾個問題：

**第一，安全性問題。** 把帳號密碼寫在程式碼中，如果程式碼外洩，資料庫的存取權限也跟著外洩了。

**第二，維護困難。** 如果資料庫的連線資訊改變了（例如換了伺服器、改了密碼），我們就要去修改程式碼，然後重新編譯、重新部署。

**第三，資源管理問題。** 一個伺服器底下可能運行多個 Web 專案，每個專案可能需要存取不同的資源，例如不同的資料庫。如果每個專案都各自管理連線，會很混亂。

### JNDI 如何解決這些問題？

在 Java EE（現在叫 Jakarta EE）的架構下，我們會這樣做：

1. 把資料庫的連線資訊設定在**伺服器**中，建立一個 **DataSource**
2. 給這個 DataSource 一個**名稱**（JNDI Name）
3. 程式中透過 JNDI 名稱來查詢並取得連線

這樣一來，程式碼裡面就不會出現任何敏感資訊，只有一個名稱而已。連線的細節都由伺服器管理，更安全也更容易維護。

### JNDI 的使用方式

以 Tomcat 伺服器為例，我們需要做兩件事：

**第一步：在伺服器設定 DataSource**

在 Tomcat 的 `context.xml` 或 `server.xml` 中設定資源：

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

**第二步：在程式中透過 JNDI 取得連線**

```java
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;
import java.sql.Connection;

public class JndiExample {
    
    public Connection getConnection() throws Exception {
        // 建立 JNDI 初始化上下文
        Context initContext = new InitialContext();
        
        // 查詢環境上下文
        Context envContext = (Context) initContext.lookup("java:/comp/env");
        
        // 用 JNDI 名稱取得 DataSource
        DataSource ds = (DataSource) envContext.lookup("jdbc/MyDB");
        
        // 從 DataSource 取得連線
        return ds.getConnection();
    }
}
```

可以看到，程式碼中完全沒有出現資料庫的 URL、帳號、密碼，只有一個 JNDI 名稱 `jdbc/MyDB`。

### JNDI 的好處

使用 JNDI 有以下幾個優點：

1. **安全性提升**：敏感資訊不會出現在程式碼中
2. **維護更容易**：連線資訊改變時，只需要修改伺服器設定，不需要改程式
3. **連線池管理**：DataSource 通常會內建連線池（Connection Pool），可以重複使用連線，效能更好
4. **統一管理**：所有資源都在伺服器端統一管理，方便運維

在實際的企業專案中，我們幾乎都會使用 JNDI 來管理資料庫連線，這是一個很重要的觀念，請大家一定要掌握。

---

## 重點整理

1. **JDBC** 是 Java 連接資料庫的標準 API，讓我們可以用同一套程式碼操作不同的資料庫

2. **使用 Maven** 管理相依套件，不要再手動下載 JAR 檔了

3. JDBC 操作的四個步驟：取得連線 → 寫入 SQL → 執行 SQL → 關閉資源

4. Java 17 環境下，**Driver 會自動載入**，不需要再寫 `Class.forName()`

5. **優先使用 PreparedStatement**，可以防止 SQL Injection，效能也比較好

6. **務必關閉資源**，優先使用 **try-with-resources** 語法

7. 取值的欄位索引從 **1** 開始，不是 0

8. **企業應用中使用 JNDI** 管理資料庫連線，更安全、更易維護

---