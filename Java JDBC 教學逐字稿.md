# Java JDBC 教學逐字稿

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

## 資料庫交易（Transaction）

在前面的章節中，我們學會了如何對資料庫進行單一操作，像是新增一筆資料、查詢資料、或更新某個欄位的值。但在真實的商業應用中,很多時候我們需要執行一連串相關的操作，而這些操作必須被視為一個整體，要嘛全部成功，要嘛全部失敗，不能只完成一半。這就是資料庫交易的核心概念。

### 什麼是交易？

交易（Transaction）是一組資料庫操作的集合，這些操作被視為一個不可分割的單位。讓我們用一個生活化的例子來理解：假設你要從你的銀行帳戶匯款 5000 元給朋友，這個看似簡單的動作，在資料庫層面其實包含了至少兩個步驟。

第一步是從你的帳戶扣除 5000 元，第二步是在朋友的帳戶增加 5000 元。這兩個步驟必須被視為一個交易，也就是說，要嘛兩個步驟都成功完成，要嘛都不執行。想像一下如果沒有交易的保護會發生什麼事：系統執行完第一步，從你的帳戶扣了 5000 元，但就在這時候伺服器突然當機了，第二步還沒執行。更糟的是，因為 JDBC 預設是自動提交模式，第一步的扣款操作已經被確認寫入資料庫了，無法撤銷。結果就是你的錢不見了，但朋友也沒收到，這 5000 元就憑空消失了！這種情況是絕對不能接受的。

這裡我們可以用購物車結帳來比喻這兩種模式的差異。自動提交模式就像是每拿一個商品去櫃檯，店員就立刻刷一次卡扣一次錢，這樣非常麻煩而且容易出錯。如果你拿了五件商品，前三件已經扣款成功，但發現第四件缺貨，前面三件的錢已經扣了，想要全部退貨就很麻煩。而手動交易控制模式則像是把所有商品放進購物車，最後一次推到櫃檯說「我要買這些」，店員才開始結帳。如果中途發現錢不夠或某件商品缺貨，你可以直接整車推回去，你的錢包完全沒有任何變動。

交易的概念就是為了防止這種半途而廢的情況發生。當我們將這兩個步驟包裝成一個交易後，系統會確保：如果任何一個步驟出問題，所有已經執行的步驟都會被撤銷，兩個帳戶都會回到交易開始前的狀態，就像什麼事都沒發生過一樣。只有當所有步驟都成功執行後，這些改變才會真正被儲存到資料庫中。

### 交易的四大特性：ACID

為了確保資料的一致性和可靠性，資料庫交易必須滿足四個重要特性，我們用它們的英文首字母縮寫稱為 ACID。讓我們一個一個來理解這些特性。

第一個特性是原子性（Atomicity），這是交易最核心的特性。原子性的意思是，一個交易中的所有操作要嘛全部完成，要嘛全部不完成，不會有中間狀態。就像原子是物質不可再分割的最小單位一樣（雖然現代物理學告訴我們原子其實還可以再分割，但在化學反應中，原子確實是最小單位），交易也是資料庫操作中不可分割的最小單位。回到剛才匯款的例子，原子性保證了你不會出現「錢被扣了但對方沒收到」的情況。

第二個特性是一致性（Consistency），它確保資料庫從一個一致的狀態轉換到另一個一致的狀態。什麼是一致的狀態？簡單來說，就是所有的資料都符合預先定義的規則和約束條件。比如說，在匯款的例子中，所有帳戶的總金額應該保持不變，這就是一個一致性規則。如果你的帳戶扣了 5000 元，朋友的帳戶就必須增加 5000 元，總金額維持不變。如果因為某些原因無法維持這個規則，整個交易就會被撤銷。

第三個特性是隔離性（Isolation），它處理的是多個交易同時執行時的問題。在真實的系統中，可能有成千上萬個用戶同時在進行各種操作，這些操作會形成不同的交易同時執行。隔離性確保每個交易在執行過程中，看起來就像是整個資料庫只有它一個交易在執行一樣，不會受到其他交易的干擾。舉例來說，當你在查詢帳戶餘額時，另一個人正在轉帳給你，隔離性確保你要嘛看到轉帳前的餘額，要嘛看到轉帳後的餘額，不會看到一個中間的、不一致的狀態。這個特性會根據不同的隔離等級有不同的實作方式，這涉及到資料庫如何處理並發存取的問題，是一個很深入的主題。

第四個特性是持久性（Durability），它確保一旦交易被確認完成（我們稱為「提交」），這些改變就會永久保存在資料庫中，即使系統發生故障也不會丟失。比如說，當你看到「轉帳成功」的訊息後，即使下一秒銀行的伺服器就斷電了，你的這筆交易記錄也不會消失，等系統恢復後，你的朋友依然會看到那 5000 元已經在他的帳戶裡了。

### JDBC 中的交易控制

理解了交易的概念和特性後，讓我們來看看如何在 JDBC 中實際控制交易。這裡有一個很重要的觀念需要先釐清：JDBC 的 Connection 物件預設是自動提交模式，也就是 autoCommit 的值是 true。這代表什麼意思呢？當你執行任何一個 executeUpdate 方法時，無論是 INSERT、UPDATE 還是 DELETE，JDBC 驅動程式會立刻發送 COMMIT 指令給資料庫，讓這個操作立即生效。

這種預設行為對於單一操作來說很方便，但當我們需要將多個操作組成一個交易時就會造成問題。回到匯款的例子，如果我們使用預設的自動提交模式，執行完扣款的 UPDATE 語句後，這個扣款操作就已經被確認寫入資料庫了。假設在執行入帳的 UPDATE 語句時發生了錯誤，比如網路中斷或系統當機，因為扣款操作已經被提交了，我們無法撤銷它，錢就這樣憑空消失了。這就是為什麼我們需要手動控制交易。

控制交易主要使用 Connection 物件的三個方法。第一個是 setAutoCommit(false)，這個方法用來關閉自動提交模式，讓我們可以手動控制何時提交交易。第二個是 commit()，當所有操作都成功執行後，我們呼叫這個方法來提交交易，讓所有的改變真正寫入資料庫。第三個是 rollback()，如果在執行過程中發生任何錯誤，我們呼叫這個方法來回滾交易，撤銷所有已經執行的操作，讓資料庫回到交易開始前的狀態。

讓我們看一個完整的匯款範例來理解這些方法如何使用：

```java
Connection conn = null;

try {
    // 建立資料庫連線
    conn = DriverManager.getConnection(url, username, password);
    
    // 關閉自動提交，開始手動控制交易
    // 從這一刻起，所有的 SQL 操作都不會立即生效
    conn.setAutoCommit(false);
    
    // 第一步：從 A 帳戶扣款 5000 元
    // 這個 UPDATE 會被執行，但不會立即 COMMIT
    String deductSql = "UPDATE ACCOUNT SET BALANCE = BALANCE - ? WHERE ACCOUNT_ID = ?";
    try (PreparedStatement deductStmt = conn.prepareStatement(deductSql)) {
        deductStmt.setDouble(1, 5000);
        deductStmt.setString(2, "A123");
        deductStmt.executeUpdate();
    }
    
    // 這裡可能發生各種問題：網路中斷、系統錯誤等等
    // 如果發生錯誤，會跳到 catch 區塊執行 rollback
    
    // 第二步：在 B 帳戶增加 5000 元
    // 同樣地，這個 UPDATE 也不會立即生效
    String addSql = "UPDATE ACCOUNT SET BALANCE = BALANCE + ? WHERE ACCOUNT_ID = ?";
    try (PreparedStatement addStmt = conn.prepareStatement(addSql)) {
        addStmt.setDouble(1, 5000);
        addStmt.setString(2, "B456");
        addStmt.executeUpdate();
    }
    
    // 所有操作都成功，一次性提交所有變更
    // 只有這一刻，扣款和入帳才真正被寫入資料庫
    conn.commit();
    System.out.println("轉帳成功！");
    
} catch (SQLException e) {
    // 發生錯誤時，回滾所有操作
    // 無論前面執行了幾個 SQL，全部撤銷
    if (conn != null) {
        try {
            conn.rollback();
            System.out.println("轉帳失敗，已回滾所有操作");
        } catch (SQLException ex) {
            ex.printStackTrace();
        }
    }
    e.printStackTrace();
    
} finally {
    // 關閉連線前，記得恢復自動提交模式
    // 因為這個連線物件可能會被連線池回收後給其他程式使用
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

讓我們仔細理解這段程式碼的運作流程，以及一個常見的疑問：當我們執行了 SQL 語句但還沒 commit 時，這些操作到底發生了什麼事？資料是暫存在 Java 程式裡嗎？

答案是：不是。這是一個很常見的誤解。當你執行 executeUpdate 或 executeQuery 時，這些 SQL 指令已經被發送到資料庫伺服器了，並不是暫存在你的 Java 程式碼裡。資料庫會將這些變更記錄在它內部的 Undo Log（回滾日誌）和記憶體緩衝區中。此時，這些變更對目前這個 Connection 是可見的，也就是說，如果你在同一個交易中再次查詢 A 帳戶的餘額，你會看到已經扣款後的餘額。但是，這些變更對其他連線是不可見的，其他人查詢 A 帳戶時，看到的還是扣款前的餘額。這就是隔離性在發揮作用。

只有當你呼叫 commit() 時，資料庫才會將這些變更真正「落盤」，寫入永久儲存區，並且對所有連線公開。如果你呼叫 rollback()，或是連線異常中斷，資料庫會利用剛才記錄的 Undo Log 將資料還原到交易開始前的狀態。

這裡還有一個值得思考的問題：如果我們在一個交易中執行了一連串的操作，比如先 INSERT 一筆資料，再 DELETE 一筆資料，最後才 COMMIT，資料庫會如何處理這些操作呢？它會不會聰明到發現「先加一再減一，結果等於沒變」，就直接跳過這些操作？

答案是不會。資料庫會依照你發送 SQL 的順序，逐筆執行每一個操作。當你執行 INSERT 時，資料庫會在內部記錄一筆新增，並可能鎖定相關的資源。接著執行 DELETE 時，資料庫再記錄一筆刪除。最後呼叫 COMMIT 時，資料庫會將上述一連串的變更記錄一次性轉為永久生效。

為什麼要這樣做呢？因為這樣才能確保原子性。想像一下，如果資料庫真的會做「最佳化」，先不執行 INSERT 而是等到最後看整體效果，那麼在執行過程中如果有其他交易需要查詢這筆資料，就會產生不一致的狀態。而且，如果在執行到一半時發生錯誤，你只要一個 rollback()，前面的新增和刪除都會像沒發生過一樣，不會留下殘缺的資料。這種按順序執行並保持可回滾的設計，才是確保資料完整性的關鍵。

### 為什麼交易這麼重要？

你可能會想，既然 JDBC 預設就是自動提交，為什麼還要學習手動控制交易呢？原因很簡單：在真實的商業應用中，絕大多數有意義的操作都不是單一的 SQL 語句就能完成的。除了匯款這個例子，還有很多情境需要交易的保護。

比如說，在電商系統中，當用戶下訂單時，需要同時執行好幾個操作：扣減商品庫存、建立訂單記錄、扣除用戶帳戶餘額、產生出貨單等等。這些操作必須全部成功才算是一筆完整的訂單，如果只完成了一部分，就會造成資料不一致的問題。想像一下，如果庫存已經扣了，但訂單記錄卻因為系統錯誤沒有建立成功，商品就這樣憑空消失了，這會造成庫存管理的混亂。

再比如，在醫療系統中，醫生開立處方時，需要同時更新病患的病歷記錄、藥品庫存、醫療費用等多個資料表。如果沒有交易的保護，可能會出現「藥品已經扣庫存了，但處方記錄卻沒有建立」這種嚴重的資料不一致問題，這在醫療環境中可能造成嚴重的後果。

交易的概念是資料庫系統最重要的特性之一，它讓我們能夠在複雜的商業邏輯中，確保資料的一致性和可靠性。當你未來進入 Spring Boot 的學習時，你會發現框架提供了更簡潔的方式來管理交易，例如使用 @Transactional 註解，你只需要在方法上加上這個註解，Spring 就會自動幫你處理 setAutoCommit(false)、commit() 和 rollback() 這些細節。但其底層的原理和我們這裡學習的 JDBC 交易控制是完全一樣的。理解了這些基礎概念，你就能更深刻地理解為什麼我們需要這些機制，以及如何正確地使用它們。即使未來使用了高階的框架，當遇到交易相關的問題時，你也能夠追根究底，知道問題出在哪個環節。

---

### 交易練習

#### 1. ACCOUNT 資料表建立語句

```sql
-- 建立帳戶資料表
create table ACCOUNT (
    ACCOUNT_ID varchar2(20) primary key,
    ACCOUNT_NAME varchar2(100) not null,
    BALANCE number(15, 2) default 0 not null,
    ACCOUNT_TYPE varchar2(20) not null,
    STATUS varchar2(20) default 'ACTIVE' not null,
    CREATED_DATE date default sysdate not null,
    LAST_UPDATED date default sysdate not null,
    constraint chk_balance check (BALANCE >= 0),
    constraint chk_account_type check (ACCOUNT_TYPE in ('SAVINGS', 'CHECKING', 'CREDIT')),
    constraint chk_status check (STATUS in ('ACTIVE', 'SUSPENDED', 'CLOSED'))
);

-- 插入測試資料
insert into ACCOUNT (ACCOUNT_ID, ACCOUNT_NAME, BALANCE, ACCOUNT_TYPE, STATUS) 
values ('A123', '張小明', 10000.00, 'SAVINGS', 'ACTIVE');

insert into ACCOUNT (ACCOUNT_ID, ACCOUNT_NAME, BALANCE, ACCOUNT_TYPE, STATUS) 
values ('B456', '李小華', 5000.00, 'CHECKING', 'ACTIVE');

insert into ACCOUNT (ACCOUNT_ID, ACCOUNT_NAME, BALANCE, ACCOUNT_TYPE, STATUS) 
values ('C789', '王大同', 15000.00, 'SAVINGS', 'ACTIVE');

insert into ACCOUNT (ACCOUNT_ID, ACCOUNT_NAME, BALANCE, ACCOUNT_TYPE, STATUS) 
values ('D012', '陳美玲', 3000.00, 'CHECKING', 'ACTIVE');

insert into ACCOUNT (ACCOUNT_ID, ACCOUNT_NAME, BALANCE, ACCOUNT_TYPE, STATUS) 
values ('E345', '林志豪', 8000.00, 'SAVINGS', 'SUSPENDED');

commit;
```

### 練習題一：基本轉帳交易

#### 題目描述
建立一個類別 `TransferMoney.java`，實作帳戶間的轉帳功能。完成以下需求：

1. 從帳戶 A123（張小明）轉帳 3000 元到帳戶 B456（李小華）
2. 使用交易控制，確保轉帳的原子性
3. 轉帳前先檢查來源帳戶餘額是否足夠，如果不足則拋出例外並回滾
4. 轉帳前檢查來源帳戶和目標帳戶的狀態是否都是 'ACTIVE'，如果不是則拋出例外並回滾
5. 轉帳成功後更新兩個帳戶的 LAST_UPDATED 欄位為當前時間
6. 印出轉帳結果：成功則顯示兩個帳戶轉帳後的餘額，失敗則顯示失敗原因

#### 參考答案

```java
import java.sql.*;

public class TransferMoney {
    
    private static final String URL = "jdbc:oracle:thin:@localhost:1521:ORCL";
    private static final String USERNAME = "STUDENT";
    private static final String PASSWORD = "student123";
    
    public static void main(String[] args) {
        String fromAccountId = "A123";
        String toAccountId = "B456";
        double amount = 3000.00;
        
        transferMoney(fromAccountId, toAccountId, amount);
    }
    
    public static void transferMoney(String fromAccountId, String toAccountId, double amount) {
        Connection conn = null;
        
        try {
            // 建立連線
            conn = DriverManager.getConnection(URL, USERNAME, PASSWORD);
            
            // 關閉自動提交
            conn.setAutoCommit(false);
            
            // 檢查來源帳戶狀態和餘額
            String checkSql = "select BALANCE, STATUS, ACCOUNT_NAME from ACCOUNT where ACCOUNT_ID = ?";
            double fromBalance = 0;
            String fromName = "";
            String toName = "";
            
            try (PreparedStatement checkStmt = conn.prepareStatement(checkSql)) {
                // 檢查來源帳戶
                checkStmt.setString(1, fromAccountId);
                try (ResultSet rs = checkStmt.executeQuery()) {
                    if (rs.next()) {
                        fromBalance = rs.getDouble("BALANCE");
                        String status = rs.getString("STATUS");
                        fromName = rs.getString("ACCOUNT_NAME");
                        
                        if (!"ACTIVE".equals(status)) {
                            throw new SQLException("來源帳戶狀態不是 ACTIVE，無法轉帳");
                        }
                        
                        if (fromBalance < amount) {
                            throw new SQLException("來源帳戶餘額不足，目前餘額：" + fromBalance + "，轉帳金額：" + amount);
                        }
                    } else {
                        throw new SQLException("找不到來源帳戶：" + fromAccountId);
                    }
                }
                
                // 檢查目標帳戶
                checkStmt.setString(1, toAccountId);
                try (ResultSet rs = checkStmt.executeQuery()) {
                    if (rs.next()) {
                        String status = rs.getString("STATUS");
                        toName = rs.getString("ACCOUNT_NAME");
                        
                        if (!"ACTIVE".equals(status)) {
                            throw new SQLException("目標帳戶狀態不是 ACTIVE，無法轉帳");
                        }
                    } else {
                        throw new SQLException("找不到目標帳戶：" + toAccountId);
                    }
                }
            }
            
            // 執行轉帳：扣款
            String deductSql = "update ACCOUNT set BALANCE = BALANCE - ?, LAST_UPDATED = sysdate where ACCOUNT_ID = ?";
            try (PreparedStatement deductStmt = conn.prepareStatement(deductSql)) {
                deductStmt.setDouble(1, amount);
                deductStmt.setString(2, fromAccountId);
                deductStmt.executeUpdate();
            }
            
            // 執行轉帳：入帳
            String addSql = "update ACCOUNT set BALANCE = BALANCE + ?, LAST_UPDATED = sysdate where ACCOUNT_ID = ?";
            try (PreparedStatement addStmt = conn.prepareStatement(addSql)) {
                addStmt.setDouble(1, amount);
                addStmt.setString(2, toAccountId);
                addStmt.executeUpdate();
            }
            
            // 提交交易
            conn.commit();
            
            // 查詢並顯示轉帳後的餘額
            String querySql = "select BALANCE from ACCOUNT where ACCOUNT_ID = ?";
            try (PreparedStatement queryStmt = conn.prepareStatement(querySql)) {
                queryStmt.setString(1, fromAccountId);
                try (ResultSet rs = queryStmt.executeQuery()) {
                    if (rs.next()) {
                        System.out.println("轉帳成功！");
                        System.out.println(fromName + "（" + fromAccountId + "）轉帳後餘額：$" + rs.getDouble("BALANCE"));
                    }
                }
                
                queryStmt.setString(1, toAccountId);
                try (ResultSet rs = queryStmt.executeQuery()) {
                    if (rs.next()) {
                        System.out.println(toName + "（" + toAccountId + "）轉帳後餘額：$" + rs.getDouble("BALANCE"));
                    }
                }
            }
            
        } catch (SQLException e) {
            // 發生錯誤時回滾
            System.out.println("轉帳失敗：" + e.getMessage());
            if (conn != null) {
                try {
                    conn.rollback();
                    System.out.println("已回滾所有操作");
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            
        } finally {
            // 恢復自動提交並關閉連線
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
```

更現代的寫法（減少巢狀try-catch）
```java
public static void transferMoney(String fromAccountId, String toAccountId, double amount) {
    
    try (Connection conn = DriverManager.getConnection(URL, USERNAME, PASSWORD)) {
        
        try {
            // 關閉自動提交
            conn.setAutoCommit(false);
            
            // 檢查帳戶狀態和餘額...
            
            // 執行扣款...
            
            // 執行入帳...
            
            // 提交交易
            conn.commit();
            System.out.println("轉帳成功！");
            
        } catch (SQLException e) {
            // 發生錯誤時回滾（此時連線還未關閉）
            conn.rollback();
            System.out.println("轉帳失敗，已回滾所有操作：" + e.getMessage());
            throw e;  // 重新拋出，讓外層處理
        }
        
    } catch (SQLException e) {
        // 最終的例外處理
        e.printStackTrace();
    }
    // Connection 在這裡自動關閉
}
```

---

### 練習題二：批次轉帳交易

#### 題目描述
建立一個類別 `BatchTransfer.java`，實作批次轉帳功能。完成以下需求：

1. 帳戶 C789（王大同）要同時轉帳給多個人：
   - 轉帳 2000 元給 A123（張小明）
   - 轉帳 3000 元給 B456（李小華）
   - 轉帳 1500 元給 D012（陳美玲）
2. 使用交易控制，確保所有轉帳要嘛全部成功，要嘛全部失敗
3. 轉帳前檢查來源帳戶（C789）的總餘額是否足夠支付所有轉帳（2000 + 3000 + 1500 = 6500）
4. 轉帳前檢查所有相關帳戶的狀態都是 'ACTIVE'
5. 建立一個轉帳記錄列表，使用 List 或陣列儲存每筆轉帳的資訊（目標帳戶、金額）
6. 使用迴圈批次執行所有轉帳操作
7. 所有轉帳完成後更新所有帳戶的 LAST_UPDATED 欄位
8. 印出轉帳結果：成功則顯示每筆轉帳的明細和最終餘額，失敗則顯示失敗原因

#### 參考答案

```java
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class BatchTransfer {
    
    private static final String URL = "jdbc:oracle:thin:@localhost:1521:ORCL";
    private static final String USERNAME = "STUDENT";
    private static final String PASSWORD = "student123";
    
    // 轉帳記錄的內部類別
    static class TransferRecord {
        String toAccountId;
        double amount;
        
        TransferRecord(String toAccountId, double amount) {
            this.toAccountId = toAccountId;
            this.amount = amount;
        }
    }
    
    public static void main(String[] args) {
        String fromAccountId = "C789";
        
        // 建立轉帳列表
        List<TransferRecord> transfers = new ArrayList<>();
        transfers.add(new TransferRecord("A123", 2000.00));
        transfers.add(new TransferRecord("B456", 3000.00));
        transfers.add(new TransferRecord("D012", 1500.00));
        
        batchTransfer(fromAccountId, transfers);
    }
    
    public static void batchTransfer(String fromAccountId, List<TransferRecord> transfers) {
        Connection conn = null;
        
        try {
            // 建立連線
            conn = DriverManager.getConnection(URL, USERNAME, PASSWORD);
            
            // 關閉自動提交
            conn.setAutoCommit(false);
            
            // 計算總轉帳金額
            double totalAmount = 0;
            for (TransferRecord record : transfers) {
                totalAmount += record.amount;
            }
            
            // 檢查來源帳戶狀態和餘額
            String checkSql = "select BALANCE, STATUS, ACCOUNT_NAME from ACCOUNT where ACCOUNT_ID = ?";
            double fromBalance = 0;
            String fromName = "";
            
            try (PreparedStatement checkStmt = conn.prepareStatement(checkSql)) {
                // 檢查來源帳戶
                checkStmt.setString(1, fromAccountId);
                try (ResultSet rs = checkStmt.executeQuery()) {
                    if (rs.next()) {
                        fromBalance = rs.getDouble("BALANCE");
                        String status = rs.getString("STATUS");
                        fromName = rs.getString("ACCOUNT_NAME");
                        
                        if (!"ACTIVE".equals(status)) {
                            throw new SQLException("來源帳戶狀態不是 ACTIVE，無法轉帳");
                        }
                        
                        if (fromBalance < totalAmount) {
                            throw new SQLException("來源帳戶餘額不足，目前餘額：" + fromBalance + 
                                                 "，總轉帳金額：" + totalAmount);
                        }
                    } else {
                        throw new SQLException("找不到來源帳戶：" + fromAccountId);
                    }
                }
                
                // 檢查所有目標帳戶
                for (TransferRecord record : transfers) {
                    checkStmt.setString(1, record.toAccountId);
                    try (ResultSet rs = checkStmt.executeQuery()) {
                        if (rs.next()) {
                            String status = rs.getString("STATUS");
                            
                            if (!"ACTIVE".equals(status)) {
                                throw new SQLException("目標帳戶 " + record.toAccountId + 
                                                     " 狀態不是 ACTIVE，無法轉帳");
                            }
                        } else {
                            throw new SQLException("找不到目標帳戶：" + record.toAccountId);
                        }
                    }
                }
            }
            
            // 執行來源帳戶扣款
            String deductSql = "update ACCOUNT set BALANCE = BALANCE - ?, LAST_UPDATED = sysdate where ACCOUNT_ID = ?";
            try (PreparedStatement deductStmt = conn.prepareStatement(deductSql)) {
                deductStmt.setDouble(1, totalAmount);
                deductStmt.setString(2, fromAccountId);
                deductStmt.executeUpdate();
            }
            
            // 批次執行所有目標帳戶入帳
            String addSql = "update ACCOUNT set BALANCE = BALANCE + ?, LAST_UPDATED = sysdate where ACCOUNT_ID = ?";
            try (PreparedStatement addStmt = conn.prepareStatement(addSql)) {
                for (TransferRecord record : transfers) {
                    addStmt.setDouble(1, record.amount);
                    addStmt.setString(2, record.toAccountId);
                    addStmt.executeUpdate();
                }
            }
            
            // 提交交易
            conn.commit();
            
            // 顯示轉帳結果
            System.out.println("批次轉帳成功！");
            System.out.println("================================");
            System.out.println("來源帳戶：" + fromName + "（" + fromAccountId + "）");
            System.out.println("轉帳明細：");
            
            String querySql = "select ACCOUNT_NAME, BALANCE from ACCOUNT where ACCOUNT_ID = ?";
            try (PreparedStatement queryStmt = conn.prepareStatement(querySql)) {
                for (TransferRecord record : transfers) {
                    queryStmt.setString(1, record.toAccountId);
                    try (ResultSet rs = queryStmt.executeQuery()) {
                        if (rs.next()) {
                            System.out.println("  → " + rs.getString("ACCOUNT_NAME") + 
                                             "（" + record.toAccountId + "）：$" + record.amount +
                                             "，轉帳後餘額：$" + rs.getDouble("BALANCE"));
                        }
                    }
                }
                
                // 顯示來源帳戶最終餘額
                queryStmt.setString(1, fromAccountId);
                try (ResultSet rs = queryStmt.executeQuery()) {
                    if (rs.next()) {
                        System.out.println("--------------------------------");
                        System.out.println("總轉帳金額：$" + totalAmount);
                        System.out.println(fromName + " 最終餘額：$" + rs.getDouble("BALANCE"));
                    }
                }
            }
            
        } catch (SQLException e) {
            // 發生錯誤時回滾
            System.out.println("批次轉帳失敗：" + e.getMessage());
            if (conn != null) {
                try {
                    conn.rollback();
                    System.out.println("已回滾所有操作");
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            
        } finally {
            // 恢復自動提交並關閉連線
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
```

#### 預期輸出結果

```
批次轉帳成功！
================================
來源帳戶：王大同（C789）
轉帳明細：
  → 張小明（A123）：$2000.0，轉帳後餘額：$12000.0
  → 李小華（B456）：$3000.0，轉帳後餘額：$8000.0
  → 陳美玲（D012）：$1500.0，轉帳後餘額：$4500.0
--------------------------------
總轉帳金額：$6500.0
王大同 最終餘額：$8500.0
```

---

這兩個練習題涵蓋了交易控制的核心概念：

**練習題一**著重於：
- 基本的交易控制流程（setAutoCommit、commit、rollback）
- 業務邏輯驗證（餘額檢查、狀態檢查）
- 錯誤處理和回滾機制

**練習題二**著重於：
- 批次操作的交易管理
- 複雜業務邏輯（多筆轉帳）
- 使用資料結構組織轉帳資訊
- 迴圈中的 SQL 執行

這兩個練習可以讓學生深入理解交易的原子性和一致性特性。