# Java Collections Framework 完整指南：從 Array 到 Map 的選擇邏輯

> 這是一篇給 Java 初學者與想複習觀念的朋友看的文。我會試著把 Java Collections Framework（JCF）整個體系——從最基礎的 `Array`，到 `Collection`（`List` / `Set` / `Queue`），再到 `Map`——用比較直觀的方式串起來。如果內容有任何錯誤或可以補充的地方，歡迎在留言區指教。

## 前言

剛開始寫 Java 的時候，相信不少人都曾經對著 `ArrayList`、`HashMap`、`LinkedList` 這些名字感到頭痛——它們看起來都能裝東西，但到底差在哪裡？什麼時候該用哪一個？

JCF（Java Collections Framework）其實就是 Java 官方提供的「資料容器工具箱」。只要日常開發中需要處理「一堆資料」——例如一份使用者清單、一批待處理的任務、一份商品庫存——幾乎都會用到它。這篇開始，想用比較直觀的方式，把這套工具箱裡的各個容器整理一遍。

整篇文章我會分成三個部分：

1. **Array（陣列）**：最基礎的資料容器。先了解它的限制，才能體會 Collection 為什麼會被設計出來。
2. **Collection 體系**：`List`、`Set`、`Queue`——處理「一堆元素」的主力。
3. **Map 體系**：Key-Value 結構，做查表、快取、統計時不可或缺。

文章有點長，建議搭配 IDE 邊看邊試。

---

# Part 1：Array 陣列

## 一、為什麼要先講 Array？

不是因為 Array 本身有多複雜，而是因為——

> **Array 的限制，正是 Collection 存在的理由。**

理解了 Array 哪裡不夠用，後面再看 `ArrayList`、`LinkedList` 的時候，就會覺得「啊，原來是為了解決這個問題啊」，學起來會輕鬆很多。

## 二、Array 的基本操作

### 初始化的兩種方式

陣列的初始化大致分成兩種：

- **靜態初始化**：在宣告時就把所有元素填好，適合元素都已知的情境。
- **動態初始化**：先決定長度，之後再逐一填值，適合元素還不確定的情境。

需要注意的是，Java 的陣列**不能不指定長度就初始化**。長度一旦決定，就不能再改了——這點稍後會再回頭討論。

```java
// 靜態初始化
int[] scores = {90, 85, 78};

// 動態初始化
int[] scores = new int[3];
scores[0] = 90;
```

### 存取元素：小心 `ArrayIndexOutOfBoundsException`

如果你曾經看過這個錯誤訊息：

```
java.lang.ArrayIndexOutOfBoundsException: Index 3 out of bounds for length 3
```

它的意思是「你想存取的索引位置不存在」。例如陣列只有 3 個元素（索引 0、1、2），你卻試圖讀取 `scores[3]`，就會看到這個例外。

### 長度的取得方式：三種容器三種寫法

這是 Java 初學者常踩的小坑，順手整理一下：

| 類型 | 取得長度的寫法 | 是屬性還是方法？ |
|------|---------------|-----------------|
| Array | `length` | 屬性 |
| String | `length()` | 方法 |
| Collection | `size()` | 方法 |

寫久了會有肌肉記憶，但剛開始很容易把 `length` 寫成 `length()`、或反過來。

### 遍歷陣列：優先使用 for-each

如果只是單純要讀取所有元素，比起傳統的 `for (int i = 0; ...)`，我會建議優先使用 for-each：

```java
for (int score : scores) {
    System.out.println(score);
}
```

寫起來更乾淨，也比較不會出現索引算錯的問題。當然，如果你需要拿到「索引值」本身，那就還是得用傳統 for 迴圈。

## 三、`Arrays` 工具類：那些寫過 Java 都該認識的方法

`java.util.Arrays` 提供了一系列操作陣列的靜態方法。這邊挑幾個最常用的講一下。

### 1. `Arrays.toString()`：印出陣列內容

新手最常見的疑問之一：「為什麼我直接 `System.out.println(scores)` 印出來的是 `[I@1540e19d` 這種看不懂的東西？」

那是因為直接列印一個物件時，Java 會呼叫該物件的 `toString()` 方法，而陣列預設的 `toString()` 繼承自 `Object`，回傳的是「型別 + 雜湊碼」的十六進位字串，並不是內容。

想看真實內容的話，要用：

```java
System.out.println(Arrays.toString(scores));
// [90, 85, 78]
```

### 2. `Arrays.sort()`：原地排序

不用自己手刻排序演算法，呼叫一行就能搞定：

```java
Arrays.sort(scores);
```

這個方法會「就地」修改原本的陣列，預設是升冪排序。背後使用的是經過最佳化的 Dual-Pivot Quicksort，對於一般用途來說，效率已經非常足夠了。

### 3. `Arrays.binarySearch()`：二元搜尋

當陣列很大時，用 for 迴圈一個一個比對相對慢，二元搜尋可以大幅縮短查找時間：

```java
int index = Arrays.binarySearch(scores, 85);
```

⚠️ **但有一個前提**：陣列必須先排序，否則結果完全不可信。這點稍後會用一個小實驗示範。

### 4. `Arrays.equals()`：比較內容是否相同

在 Java 中，`==` 比較的是「兩個變數是否指向同一個記憶體位址」，所以下面這段程式碼會印出 `false`：

```java
int[] a = {1, 2, 3};
int[] b = {1, 2, 3};
System.out.println(a == b);  // false
```

如果想比較「內容是否相同」，要改用：

```java
Arrays.equals(a, b);  // true
```

### 沒先 sort 就 binarySearch 會發生什麼事？

這個我覺得很值得自己動手實驗一次，比看文字描述記得更牢。試試看下面三種情境：

```java
int[] arr = {5, 2, 8, 1, 3};  // 未排序

System.out.println(Arrays.binarySearch(arr, 1));  // 明明有 1，卻可能回傳負數
System.out.println(Arrays.binarySearch(arr, 3));  // 找不到卻回傳了索引
System.out.println(Arrays.binarySearch(arr, 5));  // 剛好賽到，回傳正確索引
```

執行結果通常會讓你覺得「靈異」：

- **找 1**：明明存在，卻被告知「找不到」，回傳負數。
- **找 3**：可能回傳一個索引，但那個位置存的根本不是 3。
- **找 5**：因為 5 剛好就在二元搜尋的第一個中點，碰巧找到了。

這個實驗的目的不是要你記得「會出現哪些奇怪結果」，而是要建立一個直覺：**未排序的資料用二元搜尋，結果是不可預測的**。在實務上踩到這個坑，Debug 起來會相當痛苦。

## 四、Array 的致命限制：固定長度

到目前為止，Array 看起來都還不錯——能存東西、能排序、能搜尋。但它有一個致命的限制：

> **長度一旦決定，就不能再改了。**

舉個例子，假設你有一個購物車陣列，初始化時只開了 3 格：

```java
String[] cart = new String[3];
cart[0] = "牛奶";
cart[1] = "麵包";
cart[2] = "雞蛋";

cart[3] = "蘋果";  // 💥 ArrayIndexOutOfBoundsException
```

當你想加入第 4 件商品時，程式直接炸了。

那怎麼辦呢？傳統的解法是「手動擴容」：開一個更大的新陣列，把舊資料複製過去。但這麼基本的需求每次都要自己處理，實在太麻煩——也正是因為這樣，Java 才設計了 `ArrayList`、`LinkedList` 這些能「動態調整大小」的容器。

接下來就要進入主菜了。

## Part 1 小結

1. 初始化分靜態跟動態兩種，但**長度都必須在建立時決定**。
2. `length`、`length()`、`size()` 三種寫法，分別對應 Array、String、Collection。
3. `Arrays` 工具類提供了 `toString`、`sort`、`binarySearch`、`equals` 等好用的靜態方法。
4. `binarySearch` 使用前一定要先 `sort`，否則結果不可信。
5. Array 最大的限制是**長度固定**——而這正是 Collection 存在的理由。

---

# Part 2：Collection 體系

`Collection` 簡單講就是「一群物件的容器」。只要是物件，都能用 `add(物件)` 把它丟進來。實務上幾乎一定會搭配泛型（Generics）使用，這樣可以在編譯時期就限定「這個容器只能放某種型別」。

## 一、整個架構先看一眼

JCF 的設計非常 OOP——**介面（Interface）負責定義「要會做什麼」，類別（Class）負責決定「具體怎麼做」**。

### 介面層：由上往下逐步具體化

- **`Iterable<E>`**（最頂層）
  - 定義「可以被迭代」這件事。
  - 所有實作它的容器，都能用 `for-each` 迴圈。
- **`Collection<E>`**
  - 所有集合的核心介面。
  - 定義基本操作：`add()`、`remove()`、`size()` 等。
- **三大子介面**

| 介面 | 特性 | 生活化的例子 |
|------|------|------|
| `List<E>` | 有順序、可重複 | 排隊名單、座位表 |
| `Queue<E>` | 先進先出（FIFO） | 排隊領餐 |
| `Set<E>` | 無順序、不可重複 | 唯一 ID 集合、去重後的標籤 |

### 實作類別：選你需要的

**List 家族**

- `ArrayList<E>`：底層是動態陣列。查找快、中間插入刪除慢。**日常 80% 場景的預設選擇**。
- `LinkedList<E>`：底層是雙向鏈結串列。頭尾增刪快、隨機存取慢。同時實作 `List` 與 `Deque`，可以當雙向佇列用。
- `Vector<E>` / `Stack<E>`：早期類別（Legacy）。執行緒安全但效能差，現代開發幾乎不會用，需要安全集合會用 `Collections.synchronizedXxx` 或 `java.util.concurrent` 套件下的類別取代。

**Set 家族**

- `HashSet<E>`：搜尋最快，不保證順序。
- `LinkedHashSet<E>`：保留插入順序，效能接近 `HashSet`。
- `TreeSet<E>`：自動排序（自然排序或自訂排序）。

### 繼承 vs 實作 的設計巧思

看 UML 圖時你會注意到兩種箭頭：

- **實線箭頭（繼承）**：介面對介面。例：`List extends Collection`，代表 `List` 是「更具體的 `Collection`」。
- **虛線箭頭（實作）**：類別對介面。例：`ArrayList implements List`，代表「我 `ArrayList` 承諾會履行 `List` 的所有規範」。

簡單說：**介面定義合約，類別負責履約**。

## 二、`Iterable`：為什麼 `Collection` 能用 for-each？

`Iterable` 是整個架構最上層的介面，它只規定一件事——「我必須能回傳一個 `Iterator`」。

```java
public interface Iterable<T> {
    Iterator<T> iterator();
}
```

`Iterator` 是真正用來「逐一拜訪元素」的工具，核心三個方法：

1. `boolean hasNext()`：還有下一個嗎？
2. `E next()`：給我下一個（並把游標往前推）。
3. `void remove()`：把剛剛 `next()` 回傳的那個元素移掉。

for-each 之所以能用，就是因為這個介面。Java 編譯器看到 for-each 時，會自動幫你把它改寫成呼叫 `iterator()` 的版本。

```java
List<String> list = List.of("A", "B", "C");

// for-each 寫法
for (String s : list) {
    System.out.println(s);
}

// 編譯器其實是這樣處理的
Iterator<String> it = list.iterator();
while (it.hasNext()) {
    System.out.println(it.next());
}
```

### 一個踩坑點：遍歷時刪除元素

很多人初學時會這樣寫：

```java
for (String s : list) {
    if (s.equals("B")) {
        list.remove(s);  // 💥 ConcurrentModificationException
    }
}
```

這會丟出 `ConcurrentModificationException`——「邊走邊改」是大忌。正確做法是用 `Iterator.remove()`：

```java
Iterator<String> it = list.iterator();
while (it.hasNext()) {
    if (it.next().equals("B")) {
        it.remove();
    }
}
```

或者用更乾淨的 Java 8 寫法：

```java
list.removeIf(s -> s.equals("B"));
```

## 三、`Collections.sort()` 與自訂排序

`Collections`（注意有 s）這個工具類別，提供了很多操作 `List` 的靜態方法，其中最常用的就是 `sort`。

```java
Collections.sort(list);
```

這行能跑的前提是——**`list` 裡的元素必須實作 `Comparable` 介面**。Java 內建的 `String`、`Integer`、`LocalDate` 都已經實作了，所以可以直接用。

### 自訂類別的「自然排序」：實作 `Comparable`

假設我們有一個 `Employee` 類別，想讓它預設按 `age` 排序：

```java
public class Employee implements Comparable<Employee> {
    private String name;
    private int age;
    private String gender;

    // 建構子、getter 省略...

    @Override
    public int compareTo(Employee other) {
        return Integer.compare(this.age, other.age);
    }

    @Override
    public String toString() {
        return name + "(" + age + ")";
    }
}
```

`compareTo()` 的回傳規則：

- 回傳負數：自己比對方小（排前面）
- 回傳零：兩者相等
- 回傳正數：自己比對方大（排後面）

要注意的是——**一個類別只能有一種自然排序**。如果今天要先按性別排、再按年齡排怎麼辦？這時候就要靠 `Comparator`。

### 外部排序：使用 `Comparator`

`Comparator` 是「臨時抱佛腳」的排序工具——不需要修改類別本身，需要哪種排序就在外面提供：

```java
List<Employee> employees = new ArrayList<>(List.of(
    new Employee("裴真率", 25, "F"),
    new Employee("朴莉莉", 23, "F"),
    new Employee("吳海嫄", 26, "F")
));

// 先按 gender，再按 age
Comparator<Employee> byGenderThenAge = Comparator
    .comparing(Employee::getGender)
    .thenComparingInt(Employee::getAge);

employees.sort(byGenderThenAge);
```

這套 Lambda + method reference 的組合是 Java 8 之後的標準寫法，可讀性比早期的 anonymous class 高得多。

> 小提示：實務上我會把 `Comparable` 用在「最常用、最直覺」的那個排序（例如 `Employee` 大家最常需要按年齡排），其他需求都用 `Comparator` 處理。

## 四、進入 List 之前：兩個必懂的小觀念

### 觀念一：Auto Boxing / Unboxing

Collection 只能裝物件（Object），不能直接裝 `int`、`double` 這種基本型別。但實務上我們又會寫：

```java
List<Integer> nums = new ArrayList<>();
nums.add(1);          // 自動把 int 1 包成 Integer
int n = nums.get(0);  // 自動把 Integer 拆成 int
```

這就叫做 Auto Boxing（裝箱）與 Unboxing（拆箱），是 Java 5 之後的語法糖。寫起來很方便，但要小心一個坑：**頻繁的 boxing 會產生效能成本**。如果你在熱迴圈裡瘋狂操作 `List<Integer>`，效能會比 `int[]` 差不少。

### 觀念二：Diamond 語法

```java
// 早期寫法（Java 6 以前）
List<String> list = new ArrayList<String>();

// Diamond 語法（Java 7+）
List<String> list = new ArrayList<>();
```

右邊的型別參數可以省略，編譯器會自動推斷。看起來簡單，但意外有很多人不知道這個叫做 Diamond Operator。

## 五、`List<String> list = new ArrayList<>();` 在搞什麼？

這行幾乎每個 Java 教材都會寫，但很多人寫了很久還是不太理解——**為什麼左邊要寫 `List`，右邊卻是 `new ArrayList`？**

### 拆解這行程式碼

- **左邊 `List<String> list`**：宣告一個變數 `list`，型別寫成 `List<String>`。意思是「我只把它當成一個 `List` 使用，能呼叫 `List` 規範裡的方法就好」。
- **右邊 `new ArrayList<>()`**：實際 new 出來的物件是 `ArrayList<String>`，這才是真正在記憶體裡存在的東西。

### 這就是多型（Polymorphism）

多型的定義是「父類別/介面的變數，可以指向子類別/實作類別的物件」。在這裡：

- `List` 是介面（父）
- `ArrayList` 是實作類別（子）
- 所以 `List<String> list = new ArrayList<>();` 就是多型的經典應用。

### 一個變數有兩種型別

| 層面 | 型別 | 影響 |
|------|------|------|
| 編譯時期型別 | `List<String>` | 編譯器只允許你呼叫 `List` 介面定義的方法 |
| 執行時期型別 | `ArrayList<String>` | JVM 知道實際是 `ArrayList`，會執行 `ArrayList` 的實作 |

### 為什麼要這樣寫？「宣告用介面，建立用實作」

這是 Java 圈非常推崇的習慣，原因是——**讓你的程式碼對未來的變化更有彈性**。

```java
// 宣告用介面
List<String> list = new ArrayList<>();

// 哪一天想換成 LinkedList
List<String> list = new LinkedList<>();
// 其他使用 list 的程式碼完全不用改，因為都只依賴 List 介面
```

如果你一開始就寫死 `ArrayList<String> list = new ArrayList<>();`，那後續所有用到 `list` 的方法簽章、回傳值都會被綁死。

## 六、`ArrayList` vs `LinkedList`：到底差在哪？

它們都實作 `List` 介面，從 API 用起來幾乎一樣。差別在「底層資料結構」，而這決定了它們的效能特性。

### `ArrayList`：連續記憶體、會自動擴容

| 操作 | 時間複雜度 | 直白的解釋 |
|------|-----------|------|
| `get(index)` | O(1) | 陣列在記憶體裡是連續的，只要知道起點和索引就能直接算出位置。就像一排編了號的置物櫃，知道編號 5，手伸過去就能直接打開。 |
| `add(e)` 尾端 | 均攤 O(1) | 平常尾端有空位就直接放。當陣列滿了，會搬家到一個兩倍大的新空間。搬家那次很累，但很久才搬一次，平均下來還是常數時間。 |
| `add(idx, e)` 中間 | O(n) | 陣列要求「排排坐、中間不能空」，你在中間插一個，後面所有元素都得往後挪一格。 |
| `contains(obj)` | O(n) | 陣列不知道自己裡面住了誰，只能從頭一個一個比對。就像在班上找「裴真率」，你不知道她坐哪，只能從第一排第一個開始問：「妳是裴真率嗎？」 |

### `LinkedList`：每個節點知道前後鄰居

`LinkedList` 不用連續陣列，而是用一個個 Node 串起來，每個 Node 都知道自己的前一個和下一個是誰。

| 操作 | 時間複雜度 | 直白的解釋 |
|------|-----------|------|
| `get(index)` | O(n) | 沒有索引概念，要從頭（或尾）一個一個走過去。 |
| `add` / `remove` 頭尾 | O(1) | 改幾個指標就好，不用搬家。 |
| 中間 `add` / `remove` | O(n) 找位置 + O(1) 操作 | 找到位置那段慢，找到之後改指標很快。 |

### 實務上怎麼選？

老實說，**90% 以上的情境我都用 `ArrayList`**。原因是：

1. 現代 CPU 的快取對「連續記憶體」非常友善，`ArrayList` 在實際 benchmark 上往往比 `LinkedList` 快得多——即使理論上 `LinkedList` 在頭尾操作有優勢。
2. `LinkedList` 的每個 Node 都要額外存兩個指標，記憶體開銷不小。

只有在「明確知道會頻繁在頭尾增刪、而且資料量很大」時，才會考慮 `LinkedList`（或者更精準地說，用 `ArrayDeque`）。

## 七、`Set`：去重的最佳武器

`Set` 的兩個特性：

- **元素不可重複**（同樣的東西放兩次，第二次會被忽略）
- **沒有索引概念**（不能用 `get(0)` 取第一個）

最經典的應用就是「一行去重」：

```java
List<String> raw = List.of("apple", "banana", "apple", "cherry", "banana");
Set<String> unique = new HashSet<>(raw);
System.out.println(unique);  // [banana, cherry, apple]（順序不保證）
```

### `Set` 如何判斷「兩個物件是同一個」？

這是新手最容易出問題的地方。答案是——**靠 `hashCode()` 和 `equals()` 兩個方法搭配判斷**。

### 先理解 `hashCode`

`hashCode()` 是 `Object` 類別的方法，每個 Java 物件都有。它回傳一個 `int`，可以想成這個物件的「指紋」或「快速辨識碼」。

> ⚠️ 重點：`hashCode` 不是 `HashSet` 的屬性，而是**所有 Java 物件都有的方法**。`HashSet` 只是利用了它而已。

`HashSet` 內部有很多「桶子（bucket）」。當你 `add` 一個元素時，它會：

1. 算元素的 `hashCode`。
2. 用 `hashCode` 決定要丟進哪個桶子。
3. 之後要查找時，同樣算 hash 直接定位到桶子，不用掃描全部元素。

這就是為什麼 `HashSet.contains()` 的平均複雜度是 O(1)。

### 再理解 `equals`

`equals()` 也是 `Object` 的方法，**預設行為跟 `==` 一樣**：比較記憶體位址。

```java
String a = new String("hello");
String b = new String("hello");
System.out.println(a == b);       // false（不同記憶體位址）
System.out.println(a.equals(b));  // true（String 有覆寫 equals）
```

像 `String`、`Integer` 這些常用類別都覆寫了 `equals()`，改成比較「值」是否相同。但**你自己寫的類別，預設還是比較記憶體位址**。

### `HashSet` 判斷重複的兩步驟

| 步驟 | 做什麼 | 結果 |
|------|------|------|
| 1 | 比較 `hashCode()` | hashCode 不同 → 一定不重複，直接放入<br>hashCode 相同 → 可能重複，進入步驟 2 |
| 2 | 比較 `equals()` | 回傳 true → 確定重複，不放入<br>回傳 false → 只是 hash 碰巧相同，仍然放入 |

所以「同時滿足 `hashCode` 相同且 `equals` 為 true」才算重複。

### 自訂類別的踩坑示範

```java
public class User {
    private String name;
    private int age;
    // 建構子、getter 省略
}

Set<User> users = new HashSet<>();
users.add(new User("裴真率", 25));
users.add(new User("裴真率", 25));  // 沒覆寫 equals/hashCode

System.out.println(users.size());  // 2，因為記憶體位址不同
```

兩個內容完全一樣的 `User`，因為沒覆寫 `equals` 和 `hashCode`，被當成兩個不同的人。修正方式：

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof User user)) return false;
    return age == user.age && Objects.equals(name, user.name);
}

@Override
public int hashCode() {
    return Objects.hash(name, age);
}
```

IDE（IntelliJ、Eclipse）都有「Generate equals() and hashCode()」的功能，**請務必善用**，不要自己手刻。

### 一個我自己常提醒的口訣

> **自訂類別要放進 `HashSet`、或當 `HashMap` 的 key 時，一定要同時覆寫 `equals` 和 `hashCode`。**

只覆寫其中一個會產生很詭異的 bug，這點背起來就對了。

## 八、`TreeSet`：有排序需求時使用

`TreeSet` 的特性：

- 元素**自動排序**
- 底層是「紅黑樹（Red-Black Tree）」
- 元素必須可比較（實作 `Comparable` 或建立時提供 `Comparator`）

### 紅黑樹是什麼？

不用真的去背紅黑樹的演算法，只需要知道：

1. 它是一種「自平衡的二元搜尋樹」。
2. 左子節點 < 父節點 < 右子節點。
3. 「自平衡」表示它會自動旋轉、調整，避免長成一條線（變成 O(n)）。
4. 所有操作（查找、插入、刪除）都是 **O(log n)**。

### `HashSet` vs `TreeSet`

| 類型 | 底層結構 | 查找複雜度 | 順序 |
|------|---------|-----------|------|
| `HashSet` | hash table | O(1) | 無序 |
| `TreeSet` | 紅黑樹 | O(log n) | 自動排序 |

### `Set` 三兄弟怎麼挑？

- 只要去重，不在乎順序 → `HashSet`（最快）
- 需要維持「插入順序」 → `LinkedHashSet`
- 需要排序 → `TreeSet`

## 九、`Queue`：先進先出

`Queue` 就是排隊——先進來的人先被服務。它的方法有兩組，新手常搞混：

| 操作 | 失敗時拋 Exception | 失敗時回傳特殊值 |
|------|---------|-----------|
| 加入 | `add(e)` | `offer(e)` |
| 取出 | `remove()` | `poll()` |
| 查看（不取出） | `element()` | `peek()` |

實務上**建議用右邊那組**（`offer` / `poll` / `peek`），因為錯誤處理用「回傳值」比 try-catch 乾淨多了。

```java
Queue<String> queue = new LinkedList<>();
queue.offer("任務 A");
queue.offer("任務 B");

while (!queue.isEmpty()) {
    String task = queue.poll();
    System.out.println("處理：" + task);
}
```

### 常見應用場景

- **任務佇列**：背景處理待辦工作。
- **BFS（廣度優先搜尋）**：圖論演算法的標配。
- **生產者-消費者模式**：執行緒之間的資料傳遞（通常會用 `BlockingQueue`）。

## 十、處理 null 與空集合：`CollectionUtils`

實務上有個很常見的 bug 來源——「拿到一個 List，沒檢查 null 就直接 `.size()`」，然後 NullPointerException。

兩個常用工具類可以省掉手動檢查：

- **Apache Commons Collections** 的 `org.apache.commons.collections4.CollectionUtils`
- **Spring** 的 `org.springframework.util.CollectionUtils`

兩者功能略有差異：

| 功能 | Apache | Spring |
|------|--------|--------|
| `isEmpty()` | ✓ | ✓ |
| `isNotEmpty()` | ✓ | ✗（要自己反向寫） |
| `size()` null safe | ✓ | ✗ |
| `emptyIfNull()` | ✓ | ✗ |
| 集合運算（交/聯/差集） | ✓ | ✗ |
| `containsAny()` | ✓ | ✓ |
| `containsAll()` | ✓ | ✗ |

選擇建議：

- 專案本來就有 Spring → 用 Spring 的，簡單夠用。
- 需要豐富的集合操作 → 用 Apache。
- 兩個都沒有 → 自己寫一個小工具方法也行。

### 三個實務習慣

1. **方法回傳 Collection 時，回傳空集合而不是 null**（`Collections.emptyList()` 或直接 `new ArrayList<>()`）。
2. **接收外部傳來的 Collection 時，先用 `isEmpty()` 判斷**。
3. **養成「拿到 Collection 先想會不會 null」的反射動作**。

## Part 2 小結

1. `Iterable` 是讓 for-each 能跑的關鍵，遍歷時要刪除請用 `Iterator.remove()` 或 `removeIf()`。
2. **宣告用介面、建立用實作**是 Java 最常見的最佳實踐（`List<String> list = new ArrayList<>();`）。
3. `ArrayList` 適合大多數情境；`LinkedList` 只在頻繁頭尾增刪時才考慮。
4. `Set` 靠 `hashCode` + `equals` 判斷重複，自訂類別**必須**同時覆寫兩者。
5. `TreeSet` 用紅黑樹維持排序，O(log n)。
6. `Queue` 用 `offer` / `poll` / `peek` 比較安全。
7. 處理空集合用 `CollectionUtils`，回傳值優先用空集合而不是 null。

---

# Part 3：Map 體系

## 一、Map 不是 Collection

開頭先澄清一個常見誤解：

> **`Map` 並沒有繼承 `Collection`。** 它和 `Collection` 是 JCF 裡並列的兩大體系。

不過 `Map` 一樣屬於 JCF 的一部分，而且**是日常開發中最常用的資料結構之一**，重要程度甚至超過 `List`。

`Map` 的核心是「Key-Value（鍵值對）」結構。每一組 key/value 在 Java 裡叫做 `Entry`：

```java
Map<String, Integer> ages = new HashMap<>();
ages.put("裴真率", 25);

// 取得所有 Entry
for (Map.Entry<String, Integer> entry : ages.entrySet()) {
    System.out.println(entry.getKey() + " -> " + entry.getValue());
}
```

## 二、`Map` 的基本操作

```java
Map<String, Integer> stock = new HashMap<>();

// 新增 / 更新
stock.put("apple", 100);
stock.put("banana", 50);
stock.put("apple", 80);  // 覆蓋舊值

// 取值
Integer apples = stock.get("apple");        // 80
Integer none = stock.get("grape");          // null
Integer fallback = stock.getOrDefault("grape", 0);  // 0

// 判斷存在
boolean hasApple = stock.containsKey("apple");

// 移除
stock.remove("banana");

// 大小
int size = stock.size();
```

`getOrDefault` 在實務上非常好用——拿不到 key 時不用自己寫 if-else 處理 null。

## 三、`Map` 的三種遍歷方式

```java
// 1. 只關心 key
for (String name : ages.keySet()) {
    System.out.println(name);
}

// 2. 只關心 value
for (Integer age : ages.values()) {
    System.out.println(age);
}

// 3. key 和 value 都要（最常用）
for (Map.Entry<String, Integer> entry : ages.entrySet()) {
    System.out.println(entry.getKey() + ": " + entry.getValue());
}

// 4. Java 8 forEach + Lambda
ages.forEach((name, age) -> System.out.println(name + ": " + age));
```

如果同時需要 key 和 value，**請用 `entrySet()`**，不要寫成「先 `keySet()`、再對每個 key 呼叫 `get()`」——後者會多做一次 hash 查找，沒必要的成本。

## 四、為什麼要用泛型？

在 Java 5 之前，`Map` 只能存 `Object`：

```java
Map map = new HashMap();
map.put("key1", "hello");
map.put("key2", 123);

String value = (String) map.get("key1");  // 要手動轉型
String wrong = (String) map.get("key2");  // 💥 ClassCastException at runtime
```

兩個痛點：

1. **每次拿出來都要強制轉型**。
2. **錯誤發生在執行期**，編譯時抓不到。

引入泛型後，這些問題在編譯時期就被擋下：

```java
Map<String, Integer> ages = new HashMap<>();
ages.put("裴真率", 25);
ages.put("朴莉莉", "23");  // ❌ 編譯就報錯
```

## 五、`Map` 的三個主要實作

| 類型 | 特性 |
|------|------|
| **`HashMap`** | 最基礎、最常用。**沒有順序保證**。 |
| **`LinkedHashMap`** | 繼承自 `HashMap`，但保留**插入順序**。 |
| **`TreeMap`** | 根據 key 自動**排序**，底層紅黑樹。 |

### `HashMap`

- 基於 hash table。
- key 的 `hashCode()` 決定它存到哪個桶子。
- 允許一個 null key、多個 null value。
- 遍歷順序不保證（可能跟插入順序不同，也可能不同 JDK 版本不一樣）。
- **自訂類別當 key 時，務必覆寫 `equals` 和 `hashCode`**（跟 `HashSet` 一樣的道理）。

### `LinkedHashMap` 與 `TreeMap`

| 類型 | 順序 | 適用場景 |
|------|------|------|
| `LinkedHashMap` | 插入順序 | 需要「先進先出」的快取、保留輸入順序的設定檔 |
| `TreeMap` | key 自然排序 | 需要按 key 排序遍歷、做範圍查詢（`subMap`、`headMap`） |

## 六、`Map` 的四個經典實務應用

這節的範例都很實用，建議自己跑一次。

### 應用 1：詞頻統計

```java
String[] words = {"apple", "banana", "apple", "cherry", "banana", "apple"};
Map<String, Integer> count = new HashMap<>();

for (String w : words) {
    count.merge(w, 1, Integer::sum);
}

System.out.println(count);  // {banana=2, apple=3, cherry=1}
```

`merge` 的邏輯：

- 如果 key 不存在 → 放入新的 value（這裡是 1）。
- 如果 key 已存在 → 用第三個參數（`BiFunction`）計算新值。

執行追蹤：

- 第一次遇到 `"apple"`：map 裡沒有 → 放入 `apple=1`。
- 第二次遇到 `"apple"`：已存在（舊值 1）→ 執行 `Integer::sum(1, 1)` = 2 → 更新成 `apple=2`。
- ……以此類推。

### 應用 2：資料分組

把員工按部門分組：

```java
List<Employee> employees = List.of(
    new Employee("朴莉莉", "RD"),
    new Employee("吳海嫄", "HR"),
    new Employee("薛侖娥", "RD"),
    new Employee("裴真率", "HR"),
    new Employee("金智友", "Sales"),
    new Employee("張圭珍", "RD")
);

Map<String, List<Employee>> byDepartment = new HashMap<>();
for (Employee emp : employees) {
    byDepartment
        .computeIfAbsent(emp.getDepartment(), k -> new ArrayList<>())
        .add(emp);
}
```

`computeIfAbsent` 這行是靈魂，拆解來看：

1. **檢查**：先看 map 裡有沒有這個 key（例如 `"HR"`）對應的 List？
2. **如果沒有（Absent）**：執行 lambda `k -> new ArrayList<>()` 建立新 List，並放進 map。
3. **如果已經有**：直接把那個 List 拿出來。
4. 最後在拿到的 List 上呼叫 `.add(emp)`。

如果不用 `computeIfAbsent`，自己寫會變成：

```java
List<Employee> list = byDepartment.get(emp.getDepartment());
if (list == null) {
    list = new ArrayList<>();
    byDepartment.put(emp.getDepartment(), list);
}
list.add(emp);
```

差很多吧？這也是為什麼我很推薦熟悉 Java 8 之後加進來的 `merge` / `computeIfAbsent` / `compute` / `putIfAbsent` 這幾個方法。

> 補充：如果你用過 Stream API，這個情境其實一行 `Collectors.groupingBy` 就解決了。但底層概念還是 `computeIfAbsent`。

### 應用 3：快取機制

```java
Map<String, User> cache = new HashMap<>();

User user = cache.computeIfAbsent("user123", id -> {
    System.out.println("從資料庫載入 " + id);
    return loadFromDatabase(id);  // 假設是個昂貴的操作
});
```

執行流程：

**第一次呼叫**：

1. `computeIfAbsent("user123", ...)` 發現 key 不存在。
2. 執行 lambda → 印出「從資料庫載入...」→ 回傳資料。
3. Map 把回傳的資料存起來。
4. **結果**：慢慢載入，並存入快取。

**第二次呼叫**：

1. `computeIfAbsent("user123", ...)` 發現 key 已存在。
2. **lambda 完全不會被執行**（不會印訊息，不會敲 DB）。
3. 直接回傳上次存好的資料。
4. **結果**：極速命中。

這個模式在實務上叫做 **memoization（記憶化）**，是最簡單的快取實作。要注意的是 `HashMap` 不是執行緒安全的，多執行緒環境請改用 `ConcurrentHashMap`。

### 應用 4：建立反向索引

假設原本資料是「ID → 姓名」，但你常常需要用「姓名找 ID」，那就建一個反向索引：

```java
Map<Integer, String> idToName = Map.of(
    1, "裴真率",
    2, "朴莉莉",
    3, "吳海嫄"
);

Map<String, Integer> nameToId = new HashMap<>();
idToName.forEach((id, name) -> nameToId.put(name, id));

System.out.println(nameToId.get("裴真率"));  // 1
```

當你發現某個欄位被頻繁拿來查找，就可以考慮用反向索引把查找成本從 O(n) 降到 O(1)。

## Part 3 小結

1. `Map` 不是 `Collection`，但同屬 JCF，重要性極高。
2. 同時需要 key 和 value 時用 `entrySet()`，不要先 `keySet()` 再 `get()`。
3. `HashMap`（無序）、`LinkedHashMap`（插入順序）、`TreeMap`（key 排序）三選一。
4. 自訂類別當 key → 同樣要覆寫 `equals` 和 `hashCode`。
5. 熟悉 `merge`、`computeIfAbsent`、`getOrDefault` 這幾個方法，會讓你的 Map 程式碼乾淨非常多。

---

# 總結：怎麼選對的容器？

寫到這裡，重點觀念都鋪完了。最後給一張**選擇流程圖**——遇到「我該用什麼容器」的時候，照著走通常不會錯：

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
│                   └─ 是 → Queue（可用 LinkedList 或 ArrayDeque 實作）
```

## 重點觀念總覽

1. **Array 的限制** 催生了 Collection Framework。
2. **宣告用介面，建立用實作**：`List<String> list = new ArrayList<>();` 是多型的經典應用。
3. **Auto Boxing**：Collection 只能存物件，基本型別會自動轉換，但要注意效能成本。
4. **`equals` / `hashCode`**：自訂類別放進 `HashSet` 或當 `HashMap` 的 key 時必須同時覆寫。
5. **`Iterable` 介面**：所有 Collection 都能被 for-each 遍歷的根本原因。
6. **遍歷時刪除元素**：用 `Iterator.remove()` 或 `removeIf()`，不要在 for-each 裡直接 remove。
7. **排序**：`Comparable` 定義自然排序，`Comparator` 定義臨時客製排序（推薦用 Lambda 寫法）。
8. **空值判斷**：拿到 Collection 先檢查 null，可以用 `CollectionUtils`。
9. **Map 同時要 key 跟 value**：用 `entrySet()`。
10. **`merge` / `computeIfAbsent`**：詞頻、分組、快取的神兵利器，熟悉了會大幅改善程式碼可讀性。

---

## 下一篇預告

JCF 是 Java 的「資料容器」基本功，把這套用熟之後，下一個會直接影響程式碼品質的就是 **Exception（例外處理）** 了。下一篇我打算寫：

- Checked Exception vs Unchecked Exception 的差異
- `try-catch-finally` 與 `try-with-resources`
- 自訂例外的時機與設計原則
- 實務上常見的 anti-pattern（吞例外、過度 catch 等）

如果文章有任何錯誤或可以補充的地方，歡迎留言指教。

我們下一篇見。
