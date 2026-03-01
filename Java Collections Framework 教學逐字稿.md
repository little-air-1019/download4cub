# Java Collections Framework 教學逐字稿

> **預估時間**：Array 15分鐘、Collection 1.5小時、Map 45分鐘（不含練習）

---

## 開場（2分鐘）

我們要來學習 Java 最核心的資料結構工具——Java Collections Framework，簡稱 JCF。

在實際專案開發中，我們經常會需要處理「一堆資料」：一堆客戶、一堆訂單、一堆交易紀錄。JCF 就是 Java 提供給我們處理這些「一堆東西」的標準工具箱。它提供一系列資料結構的類別和介面集合，使用方式就像使用函式庫。

今天的課程分成三大部分：

1. **Array（陣列）**：最基礎的資料容器，了解它的限制才知道為什麼需要 Collection
2. **Collection 體系**：List、Set、Queue，處理「一堆元素」的主力工具
3. **Map 體系**：Key-Value 結構，查表、快取、統計的好幫手

好，我們直接開始。

---

## Part 1：Array 陣列（15分鐘）

### 為什麼要先講 Array？

在進入 Collection 之前，我們先快速複習 Array。不是因為 Array 有多複雜，而是要讓你們理解：**Array 的限制，就是 Collection 存在的理由**。

### Array 基本操作

先來看最基本的陣列操作，從初始化開始，初始化的方式可以分為靜態初始化和動態初始化：

- **靜態初始化**：適用於已知所有元素時，在宣告時就直接給值
- **動態初始化**：可以用在不知道有哪些元素時，先決定大小，之後再給值（沒有不指定長度的初始化方法）

接著是存取元素與長度屬性的方式，在存取的時候要注意的是：如果你的程式發生 `ArrayIndexOutOfBoundsException`，這代表你在存取不存在的 Index，例如：scores 陣列只有一個元素，但你試圖存取第三個元素。

在存取長度的部分，我們可以比較一下：

| 類型 | 取得長度的方式 |
|------|---------------|
| Array | `length` 是一個屬性 |
| String | `length()` 是一個回傳長度的方法 |
| Collection | `size()` 是回傳長度的方法 |

遍歷陣列時，如果是單純要讀取所有元素的情境，比起傳統 for 迴圈，會推薦大家使用 for-each 迴圈。

### Arrays 工具類

Java 提供了 `java.util.Arrays` 工具類，裡面有很多好用的靜態方法，這邊 demo 幾個給大家看：

1. **印出內容 `Arrays.toString()`**
   - 如果直接用 `print()`，你會印出記憶體位置
   - 因為直接列印一個物件時，它會自動呼叫該物件的 `.toString()` 方法，而 Object 預設行為是印出「型別 + 雜湊碼」的十六進位字串
   - 使用 `Arrays.toString(myArray)` 則會輸出陣列的實際內容

2. **自動排序 `Arrays.sort()`**
   - 如果你有一堆亂序的數字或字串，不需要自己寫冒泡排序法
   - 這個方法會直接對傳入的陣列進行「原地排序（In-place）」，預設是升冪排序（從小到大）
   - 它背後使用的是最佳化過的快速排序法（Dual-Pivot Quicksort），效率非常高

3. **快速找尋 `Arrays.binarySearch()`**
   - 當陣列很大時，用 for 迴圈一個個找太慢了
   - 這個方法使用「二元搜尋法」，能在極短時間內找到元素的索引值
   - ⚠️ **注意**：使用前陣列必須先經過排序，否則找出來的結果會是錯的

4. **內容比對 `Arrays.equals()`**
   - 在 Java 中，如果你用 `==` 比較兩個陣列，比的是「這兩個陣列是不是同一個記憶體位址」
   - 如果你想知道「兩個不同的陣列內容是否長得一模一樣」，就要用這個方法，它會逐一比對每個位置的元素

#### 沒有先 sort 就 binarySearch 會怎樣？

大家來動手寫一下程式做實驗吧！

- **未排序找 1**：回傳負數（明明陣列裡有）
  - 這最常見，明明數字在陣列裡，但因為搜尋邏輯跳過了它，最後回傳一個負值告訴你「沒找到」
- **未排序找 3**：找不到卻回傳正數索引（靈異現象）
  - 明明陣列裡有這個數，它卻跟你說找不到；或者它回傳了一個索引，但那個位置根本不是你要的數字
- **未排序找 5**：賽到（運氣好）
  - 剛好你要找的數字就在二元搜尋的第一個中點，或者搜尋路徑剛好沒被亂序干擾

### Array 的致命限制

好，現在來看 Array 最大的問題——**固定長度**：

- 直接看範例：如果你的購物車原本只有 3 格，想加入第 4 件商品，Array 會直接報錯
- 解法：手動擴容


---

## Part 2：Collection 體系（1.5 小時）

Collection 基本上就是物件的群組化。只要是物件都可以使用 `add(物件)` 方法加入 Collection 物件中。基本上會搭配泛型（Generics）使用，以規範該集合內的物件型別。

### 集合架構圖

這套架構主要由介面（Interface）定義行為規範，再由類別（Class）負責具體實作。

#### 核心結構：介面與繼承（Inheritance）

Java Collection Framework 的介面架構自上而下逐層定義資料結構的能力：

**頂層介面**

- `Iterable<E>`
  - 定義「可被迭代」的能力
  - 所有集合都能使用 `for-each` 迴圈

**集合總介面**

- `Collection<E>`
  - 所有集合的核心介面
  - 定義基本操作：`add()`, `remove()`, `size()`

**三大子介面**

| 介面 | 特性 | 範例 |
|------|------|------|
| `List<E>` | 有順序、可重複 | 排隊、座位列表 |
| `Queue<E>` | 先進先出（FIFO） | 排隊領餐 |
| `Set<E>` | 無順序、不可重複 | 學生名單、唯一 ID 集合 |

### 實作類別（Implementation）

#### List 家族

- **`ArrayList<E>`**
  - 底層：動態陣列
  - 搜尋快、插入刪除慢（中間異動需移動元素）

- **`LinkedList<E>`**
  - 底層：雙向鏈結串列
  - 增刪快、搜尋慢
  - 同時實作 `List` 與 `Deque` → 可當雙向佇列

- **`Vector<E>` / `Stack<E>`**
  - 早期類別（Legacy）
  - 執行緒安全但效能低
  - 現代開發多用 `ArrayList` 或 `Deque` 取代

#### Set 家族

- **`HashSet<E>`**
  - 搜尋效率最快
  - 不保證元素順序

- **`LinkedHashSet<E>`**
  - 保留插入順序
  - 效能接近 HashSet

- **`TreeSet<E>`**
  - 自然排序（如 A-Z、1-100）

### 繼承 vs 實作 的設計巧思

- **繼承（實線箭頭）** — 介面對介面
  - 例：`List extends Collection`
  - List 是一種更具體的 Collection

- **實作（虛線箭頭）** — 類別對介面
  - 例：`ArrayList implements List`
  - ArrayList 承諾遵守 List 介面的規範

### Iterable 介面

接下來，我們來看 Collection 介面繼承的 Iterable 介面。

`Iterable` 介面只有一個核心方法：`iterator()` 方法。任何實作 `Iterable` 的類別，都「保證」能提供一個 `Iterator`，而 `Iterator` 就是用來遍歷元素的工具。for-each 語法（增強 for 迴圈）的條件就是：物件必須實作 `Iterable` 介面。

**Iterator 的三個核心方法：**

1. `boolean hasNext()` - 還有沒有下一個元素？
2. `E next()` - 取得下一個元素（並移動游標）
3. `void remove()` - 移除剛剛 `next()` 回傳的元素

`Collection<E>` 繼承 `Iterable`，所以 `List`、`Set`、`Queue` 也繼承了 `Iterable`，使得它們的實作類別可以實作 `iterator()` 方法。`ArrayList` 能用 for-each 就是因為實作了 `Iterable`。

### Collection 的排序方法

對於 Collections 的內容排序，可以使用 `Collections` 提供的 `sort` 方法：

```java
Collections.sort(List 物件);
```

List 的內容物必須要實作（implements）`java.lang.Comparable`。Java 內建的類別（`String`, `Integer`, `Date` 等）已經實作了 `Comparable`，所以我們不需要自己寫實作，就能用 `sort()` 排序。

但針對自訂類別，我們就會需要自己設定這個類別的自然排序，設定的方法就是實作 `compareTo()` 方法。一個類別只能有一種自然排序。

> 我們現在就切到編譯器去寫一個自訂類別看看
> Override `compareTo()`，印出來之後發現印出的是記憶體位址，所以可以再 Override `toString()`

實作 `compareTo()` 可以讓我們的自訂類別有內建的自然排序。接著我們來看怎麼外部定義客製排序。外部是指在排序時才提供比較邏輯，而不是直接把邏輯定義在類別裡，所以可以有很多種不同的排序方式。

> 我們再切回編譯器

#### 練習

- Employees 再多加 `age` 和 `gender`
- 自然排序用 `age`
- 外部排序先用 `gender` 再用 `age`

### 進入 Collection 之前：兩個重要觀念

我們直接看程式碼（切到編譯器看）

- **觀念一**：AUTO BOXING / UNBOXING
- **觀念二**：Diamond 語法（菱形語法）

### List 介面

`List<E>` 介面定義了很多方法（合約條款）：

- `add(E e)` → 保證可以新增元素
- `get(int i)` → 保證可以用索引取值
- `remove(E e)` → 保證可以移除元素
- `size()` → 保證可以知道大小
- ... 還有很多

但介面只定義「要做什麼」，不管「怎麼做」。

`ArrayList` 實作 `List`，就是在告訴 Java：「我 ArrayList 會履行 List 的所有合約，我會提供具體的實作方式。」

- `ArrayList` 選擇用「陣列」來實作這些方法
- `LinkedList` 選擇用「鏈結串列」來實作這些方法

它們都履行了同一份合約，但具體做法不同，效能特性也不同。

#### 詳解 `List<String> list = new ArrayList<>();`

進編譯器裡，我們來宣告一個 list。

**拆解：**

**左邊：`List<String> list`**
- 宣告一個變數叫 `list`
- 這個變數的「宣告型別」是 `List<String>`
- 意思是：「我只關心它是一個 List，能做 List 該做的事」

**右邊：`new ArrayList<>()`**
- 實際建立一個 `ArrayList` 物件
- 這個物件的「實際型別」是 `ArrayList<String>`
- 這是真正在記憶體中存在的東西

**整體：**
- 建立一個 `ArrayList` 物件，但用 `List` 型別的變數來參考它

#### 這是多型嗎？是的！

多型（Polymorphism）的定義：「父類別（或介面）的變數，可以指向子類別的物件」

在這裡：
- `List` 是介面（父）
- `ArrayList` 是實作類別（子）
- 所以 `List<String> list = new ArrayList<>();` 就是多型

#### list 的型別到底是什麼？

這要分兩個層面來看：

1. **編譯時期型別（Compile-time Type）= `List<String>`**
   - 編譯器只知道 `list` 是 `List`
   - 只能呼叫 `List` 介面定義的方法

2. **執行時期型別（Runtime Type）= `ArrayList<String>`**
   - 程式執行時，JVM 知道它其實是 `ArrayList`
   - 實際執行的是 `ArrayList` 的方法實作

**總結這個觀念**：

- `List<String> list = new ArrayList<>();` 是多型的經典應用
- `list` 的宣告型別是 `List<String>`，實際型別是 `ArrayList<String>`
- 推薦「宣告用介面，建立用實作」，這是 Java 的最佳實踐

### ArrayList vs. LinkedList

我們剛剛為了解說 List，一直拿 `ArrayList` 來舉例，現在來詳細介紹 `ArrayList` 和 `LinkedList`。

#### ArrayList — 連續記憶體結構，會自動擴容

| 操作 | 時間複雜度 | 說明 |
|------|-----------|------|
| `get(index)` | O(1) | 記憶體中的陣列是連續的。電腦只要知道「起點」和「編號（索引）」，就能直接計算出那個位置的地址。就像一排編好號的置物櫃，你只要知道編號是 5，手伸過去直接打開就好，不必從 1 開始數。 |
| `add(e)` 尾端 | 均攤 O(1) | 平常尾端有空位，直接放進去就好。但當陣列「滿了」，它會自動搬家到一個兩倍大的新空間。雖然「搬家」那一次很累，但因為很久才搬一次，把那個成本分攤到每一次的插入，平均下來還是接近常數時間。就像買票，大部分人直接進場很快；偶爾票賣完了要加開大場地會慢一點，但整體效率還是很高。 |
| `add(idx, e)` 中間 | O(n) | 陣列要求元素必須「排排坐」，中間不能有空隙。如果你要在中間插隊，後面所有的人都必須往後退一格。你要在排隊隊伍的中間塞入一個人，後面的 100 個人都得向後挪一步。插隊的位置越前面，搬動的人就越多。 |
| `contains(obj)` | O(n) | 陣列本身並不知道裡面住了誰。要找某個特定的東西，只能從頭開始一個一個比對，直到找到或看完為止。就像在一班學生中找「裴真率」，你不知道他坐哪，只能從第一排第一個開始問：「你是裴真率嗎？」，最壞的情況要問遍全班 n 個人。 |

#### LinkedList

`LinkedList` 不使用連續陣列，而是每個元素（Node）都知道自己的前一個與下一個是誰。

> 實務小技巧可以看編譯器
> 
> [練習題：ArrayList vs. LinkedList](/Eh0fAfvQTjSqWi6vASEhVg)


### Set 介面：去重的最佳選擇

- 元素不可重複（唯一性）
- 沒有索引（不能用 `get(index)`）

**實務應用：一行去重（Deduplication）**

> 直接看編譯器

### Set 如何比較相同性？

#### 什麼是 hashCode？

`hashCode` 是每個 Java 物件都有的方法，定義在 `Object` 類別中。它會回傳一個 `int` 整數，代表這個物件的「雜湊碼」。

你可以把 `hashCode` 想成物件的「快速辨識碼」或「指紋」。

> ⚠️ **重點**：`hashCode` 不是 `HashSet` 的屬性！它是所有 Java 物件都有的方法（繼承自 Object）。

> （去看編譯器）

**HashSet 怎麼利用 hashCode？**

`HashSet` 內部有很多「桶子」（bucket）。當你 `add` 一個元素時，`HashSet` 會：

1. 計算元素的 `hashCode`
2. 用 `hashCode` 決定放到哪個桶子
3. 這樣查找時就能快速定位，不用掃描全部元素

這就是為什麼 `HashSet` 的查找是 O(1) 而不是 O(n)。

#### 什麼是 equals？預設行為 vs 覆寫後行為

**`equals()` 的預設行為（Object 類別）**

如果沒有覆寫 `equals()`，它的行為和 `==` 一樣：比較兩個物件的「記憶體位址」是否相同。只有當兩個變數指向「同一個物件」時，才回傳 `true`。

**`equals()` 覆寫後的行為（如 String, Integer）**

許多類別會覆寫 `equals()`，改成比較「內容值」。這叫做 Value Equality（值相等）。

> （去看編譯器）

#### HashSet 如何判斷重複？

`HashSet` 判斷「重複」的兩步驟：

| 步驟 | 說明 | 結果 |
|------|------|------|
| **步驟 1** | 先比較 `hashCode()` | hashCode 不同 → 一定不重複，直接放入<br>hashCode 相同 → 可能重複，進入步驟 2 |
| **步驟 2** | 再比較 `equals()` | equals 回傳 true → 確定重複，不放入<br>equals 回傳 false → 不重複（只是 hashCode 碰巧相同），放入 |

所以：兩個物件要被視為「相同」，必須同時滿足：

1. `hashCode()` 回傳值相同
2. `equals()` 回傳 true

**重點總結**：

1. `hashCode()` 和 `equals()` 是 `Object` 的方法，所有物件都有
2. 預設的 `equals()` 比較記憶體位址（和 `==` 相同）
3. 覆寫 `equals()` 可以改成比較內容值
4. **當你把自訂類別放進 `HashSet`（或當作 `HashMap` 的 key）時，一定要覆寫 `equals()` 和 `hashCode()`**
5. IDE（IntelliJ、Eclipse）都可以自動產生，善用它

### TreeSet：有排序需求時使用

**TreeSet 特性**：

- 元素自動排序
- 底層是「紅黑樹」（Red-Black Tree）
- 元素必須可比較（實作 `Comparable` 或提供 `Comparator`）

**什麼是紅黑樹？（簡單理解就好）**

紅黑樹是一種「自平衡的二元搜尋樹」。你不需要知道它的詳細原理，只要知道：

1. 它是一種樹狀結構，每個節點最多有兩個子節點
2. 左邊的子節點比父節點小，右邊的比父節點大
3. 「自平衡」代表它會自動調整，保持樹的高度平衡
4. 因為平衡，所以查找、插入、刪除都是 O(log n)

**對比**：

| 類型 | 底層結構 | 查找複雜度 | 順序 |
|------|---------|-----------|------|
| HashSet | hash table | O(1) | 無序 |
| TreeSet | 紅黑樹 | O(log n) | 有序 |

**實務上**：

- 需要排序 → `TreeSet`
- 不需要排序 → `HashSet`（較快）

**選擇建議**：

- 只要去重，不在乎順序 → `HashSet`（最快）
- 需要維持插入順序 → `LinkedHashSet`
- 需要排序 → `TreeSet`

### Queue 介面：先進先出

有兩組方法，建議用右邊那組：

| 操作 | 會拋異常 | 回傳特殊值 | 差異 |
|------|---------|-----------|------|
| 加入 | `add(e)` | `offer(e)` | 失敗時：exception vs false |
| 取出 | `remove()` | `poll()` | 空時：exception vs null |
| 查看 | `element()` | `peek()` | 空時：exception vs null |

> （看編譯器）

#### Queue 的實務應用場景

Queue 的三個常見應用，有空再看編譯器。

### CollectionUtils 工具類處理空值

在實務開發中，常會使用工具類來簡化 null 和 empty 的判斷。有兩個常見的選擇：

> （細節看編譯器）

**比較表**：

| 功能 | Apache | Spring |
|------|--------|--------|
| `isEmpty()` | ✓ | ✓ |
| `isNotEmpty()` | ✓ | ✗ |
| `size()` null safe | ✓ | ✗ |
| `emptyIfNull()` | ✓ | ✗ |
| 集合運算（交/聯/差集） | ✓ | ✗ |
| `containsAny()` | ✓ | ✓ |
| `containsAll()` | ✓ | ✗ |

**結論**：

- 專案已有 Spring → 用 Spring 的，簡單夠用
- 需要豐富的集合操作 → 用 Apache 的
- 兩者都沒有 → 自己寫一個簡單的工具方法

**實務建議**：

1. 方法回傳 Collection 時，回傳空集合而非 null
2. 使用 `CollectionUtils.isEmpty()` 或自己封裝類似的方法
3. 養成習慣：拿到 Collection 時，先想「這會不會是 null？」

---

## Part 3：Map 體系（45 分鐘）

### Map 不是 Collection！

首先要澄清一個常見誤解：

> **Map 不繼承 Collection**，它們是平行的兩個體系。雖然不是 Collection，但 Map 是 JCF 的一部分，而且是最常用的資料結構之一！

在 Java 的 Map 中，每一組 key 和 value，定義為 `Entry`：

- 如何取得 Entry？→ `map.entrySet();` 取得裝有所有 Entry 的 Set
- 每一筆 Entry 可以用 `getKey()` 和 `getValue()` 方法分別拿到 key 與 value

### Map 介面基本操作

> 直接看編譯器

### Map 的遍歷方式

> 直接看編譯器

### Map 支援泛型的寫法以規範 key 與 value 的型別

在沒有泛型的年代，Map 只能存放 `Object`。這會產生兩個主要痛點：

1. **必須手動轉型**：拿出來的東西都是 Object，你得自己記住它是什麼，並強行轉型（Casting）
2. **執行時期的錯誤（Runtime Crash）**：因為什麼都能塞進去，如果不小心把「字串」塞進了預期放「數字」的 Map，編譯時不會報錯，但程式執行到一半會因為轉型失敗而崩潰（`ClassCastException`）

**現在使用泛型（Generics）的寫法**：

透過 `<K, V>` 的語法，我們可以在宣告時就「規範」這張地圖的 Key 與 Value 分別是什麼型別。

### Map 的架構圖 & 種類

| 類型 | 說明 |
|------|------|
| **HashMap** | 最基礎的 Map，也最常用，不具順序性 |
| **LinkedHashMap** | HashMap 的子類別，實作順序性 |
| **TreeMap** | 具有順序性，根據 Map 的 key 做自然排序 |

### HashMap

- 基於 hash table 實作
- key 的 `hashCode()` 決定存放位置
- 允許 null key（只能有一個）和 null value
- 不保證順序（遍歷順序可能和插入順序不同）
- 自訂類別當 key 時，必須覆寫 `equals` 和 `hashCode`（和 HashSet 一樣的道理）

### LinkedHashMap vs. TreeMap

| 類型 | 特性 |
|------|------|
| **LinkedHashMap** | 保持插入順序 |
| **TreeMap** | 根據 Map 的 key 做自然排序 |

### Map 實務應用

> 直接看編譯器

#### 1. 詞頻統計

這段程式碼會遍歷 `words` 陣列，動作如下：

- **遇到第一個 "apple"**：
  - `wordCount` 裡還沒有 apple
  - 動作：直接把 "apple" 放進去，值設為 1

- **遇到第二個 "apple"**：
  - `wordCount` 發現 apple 已經在裡面了（舊的值是 1）
  - 動作：執行 `Integer::sum`，把舊的 1 加上新的 1，更新為 2

- 以此類推...

#### 2. 資料分組

這行程式碼是分組邏輯的靈魂：

```java
byDepartment.computeIfAbsent(emp.getDepartment(), k -> new ArrayList<>()).add(emp);
```

我們可以把它拆解來看：

1. **檢查**：先看看 `byDepartment` 這張地圖裡，有沒有這個部門（例如 "HR"）的 List？
2. **如果沒有（Absent）**：立刻幫我新建一個 List，並把它放進 Map 裡
3. **如果已經有**：就直接把那個 List 拿來放

#### 3. 快取機制

> 去快取找 userId，如果找不到，就執行 `{...}` 裡面的昂貴運算（如讀取資料庫），並把結果存進快取；如果找到了，就直接給我，別去跑後面的程式碼。

**程式執行過程拆解**：

**第一回合：快取是空的**

1. 呼叫 `computeIfAbsent("user123", ...)`
2. Map 發現沒有這個 Key
3. 執行 Lambda 區塊：印出「從資料庫載入...」，回傳資料
4. Map 把回傳的資料存起來
5. **結果**：慢速載入，並存入快取

**第二回合：快取已有資料**

1. 再次呼叫 `computeIfAbsent("user123", ...)`
2. Map 發現「喔！user123 已經在裡面了」
3. 跳過 Lambda 區塊：裡面的程式碼完全不會被執行（所以不會印出訊息，也不會去敲資料庫）
4. 直接回傳上次存好的資料
5. **結果**：極速回傳

#### 4. 建立反向索引

將「ID 對應姓名」轉換為「姓名對應 ID」，加速特定欄位查找。

> [練習題：HashMap](/3V6unBvJTiu3m2YVjy3CWw)

---

## 總結與 Q&A

### Collection 選擇指南

```
需要存放一堆元素嗎？
│
├─ 需要 key-value 結構嗎？
│   │
│   ├─ 是 → Map
│   │       ├─ 需要排序 → TreeMap
│   │       ├─ 需要執行緒安全 → ConcurrentHashMap
│   │       ├─ 需要維持插入順序 → LinkedHashMap
│   │       └─ 其他 → HashMap（預設選擇）
│   │
│   └─ 否 → Collection
│           │
│           ├─ 允許重複嗎？
│           │   │
│           │   ├─ 是 → List
│           │   │       ├─ 頻繁在頭尾增刪 → LinkedList
│           │   │       └─ 其他 → ArrayList（預設選擇）
│           │   │
│           │   └─ 否 → Set
│           │           ├─ 需要排序 → TreeSet
│           │           ├─ 需要維持插入順序 → LinkedHashSet
│           │           └─ 其他 → HashSet（預設選擇）
│           │
│           └─ 需要 FIFO 嗎？
│                   └─ 是 → Queue（用 LinkedList 實作）
```

### 重點回顧

1. **Array 的限制**催生了 Collection Framework
2. **宣告用介面，建立用實作**：`List<String> list = new ArrayList<>();` 是多型的應用
3. **Auto Boxing**：Collection 只能存物件，基本型別會自動轉換
4. **equals/hashCode**：自訂類別放入 HashSet 或當 HashMap 的 key 時必須覆寫
5. **Collection 能被遍歷**：因為繼承了 Iterable 介面
6. **遍歷時刪除**：用 `Iterator.remove()` 或 `removeIf()`
7. **排序**：`Comparable` 定義預設排序，`Comparator` 定義客製排序（推薦用 Lambda）
8. **空值判斷**：養成先檢查 null 再操作的習慣，可用 CollectionUtils 工具類
9. **Map 遍歷**：需要 key 和 value 時用 `entrySet()`


---