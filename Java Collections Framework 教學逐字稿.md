# Java Collections Framework 教學逐字稿

> **講師備註**：本講義適用於資管系大四實習生，假設學員已具備 Java 基礎語法。教學重點聚焦於專案開發實務，而非演算法原理。
>
> **預估時間**：Array 15分鐘、Collection 1.5小時、Map 45分鐘（不含練習）

---

## 開場（2分鐘）

各位同學好，今天我們要來學習 Java 最核心的資料結構工具——Java Collections Framework，簡稱 JCF。

在實際專案開發中，你會發現大概有 80% 的時間都在處理「一堆資料」：一堆客戶、一堆訂單、一堆交易紀錄。JCF 就是 Java 提供給我們處理這些「一堆東西」的標準工具箱。

今天的課程分成三大部分：
1. **Array（陣列）**：最基礎的資料容器，了解它的限制才知道為什麼需要 Collection
2. **Collection 體系**：List、Set、Queue，處理「一堆元素」的主力工具
3. **Map 體系**：Key-Value 結構，查表、快取、統計的好幫手

好，我們直接開始。

---

# Part 1：Array 陣列（15分鐘）

## 1.1 為什麼要先講 Array？

在進入 Collection 之前，我們先快速複習 Array。不是因為 Array 有多複雜，而是要讓你們理解：**Array 的限制，就是 Collection 存在的理由**。

## 1.2 Array 基本操作

先來看最基本的陣列操作：

```java
public class ArrayBasics {
    public static void main(String[] args) {
        
        // ============================
        // 1. 陣列宣告與初始化
        // ============================
        
        // 方式一：宣告時就給值（靜態初始化）
        int[] scores = {85, 92, 78, 95, 88};
        
        // 方式二：先決定大小，之後再給值（動態初始化）
        String[] names = new String[3];
        names[0] = "Alice";
        names[1] = "Bob";
        names[2] = "Charlie";
        
        // ============================
        // 2. 存取元素
        // ============================
        
        // 用 index 取值，index 從 0 開始
        System.out.println("第一個分數：" + scores[0]);  // 85
        System.out.println("第三個名字：" + names[2]);   // Charlie
        
        // 修改元素
        scores[0] = 90;
        System.out.println("修改後：" + scores[0]);  // 90
        
        // ============================
        // 3. 陣列長度
        // ============================
        
        // 注意：是 .length 屬性，不是 .length() 方法！
        // 這是 Array 和 String 的差異，String 用 .length()
        System.out.println("分數陣列長度：" + scores.length);  // 5
        
        // ============================
        // 4. 遍歷陣列
        // ============================
        
        // 傳統 for 迴圈
        for (int i = 0; i < scores.length; i++) {
            System.out.println("Index " + i + ": " + scores[i]);
        }
        
        // 增強 for 迴圈（for-each）- 只是讀取時推薦用這個
        for (int score : scores) {
            System.out.println("分數：" + score);
        }
    }
}
```

這些應該都是你們學過的，我快速帶過。

## 1.3 Arrays 工具類

Java 提供了 `java.util.Arrays` 工具類，裡面有很多好用的靜態方法。在實務上，這些方法會幫你省很多事：

```java
import java.util.Arrays;

public class ArraysUtilityDemo {
    public static void main(String[] args) {
        
        int[] numbers = {3, 1, 4, 1, 5, 9, 2, 6};
        
        // ============================
        // 1. 印出陣列內容
        // ============================
        
        // 直接印陣列會得到奇怪的東西
        System.out.println(numbers);  // [I@6d06d69c（記憶體位址）
        
        // 用 Arrays.toString() 才能看到內容
        System.out.println(Arrays.toString(numbers));  // [3, 1, 4, 1, 5, 9, 2, 6]
        
        // ============================
        // 2. 排序
        // ============================
        
        Arrays.sort(numbers);
        System.out.println("排序後：" + Arrays.toString(numbers));  // [1, 1, 2, 3, 4, 5, 6, 9]
        
        // ============================
        // 3. 二分搜尋（必須先排序！）
        // ============================
        
        int index = Arrays.binarySearch(numbers, 5);
        System.out.println("5 的位置：" + index);  // 5
        
        // ============================
        // 4. 填充陣列
        // ============================
        
        int[] zeros = new int[5];
        Arrays.fill(zeros, 0);  // 全部填 0
        System.out.println(Arrays.toString(zeros));  // [0, 0, 0, 0, 0]
        
        // ============================
        // 5. 複製陣列
        // ============================
        
        int[] copy = Arrays.copyOf(numbers, numbers.length);
        int[] partial = Arrays.copyOf(numbers, 3);  // 只複製前 3 個
        System.out.println("部分複製：" + Arrays.toString(partial));  // [1, 1, 2]
        
        // ============================
        // 6. 比較陣列內容
        // ============================
        
        int[] a = {1, 2, 3};
        int[] b = {1, 2, 3};
        System.out.println(a == b);              // false（比較記憶體位址）
        System.out.println(Arrays.equals(a, b)); // true（比較內容）
    }
}
```

## 1.4 Array 的致命限制

好，現在來看 Array 最大的問題——**固定長度**：

```java
public class ArrayLimitations {
    public static void main(String[] args) {
        
        // ============================
        // 問題：Array 長度固定，無法動態增減
        // ============================
        
        String[] fruits = new String[3];
        fruits[0] = "Apple";
        fruits[1] = "Banana";
        fruits[2] = "Cherry";
        
        // 現在想加入第四個水果... 怎麼辦？
        // fruits[3] = "Durian";  // ArrayIndexOutOfBoundsException!
        
        // ============================
        // 傳統解法：手動擴容（超麻煩）
        // ============================
        
        // 1. 建立新陣列（更大的）
        String[] newFruits = new String[fruits.length + 1];
        
        // 2. 複製舊資料
        for (int i = 0; i < fruits.length; i++) {
            newFruits[i] = fruits[i];
        }
        
        // 3. 加入新元素
        newFruits[3] = "Durian";
        
        // 4. 指向新陣列
        fruits = newFruits;
        
        System.out.println(Arrays.toString(fruits));
        // [Apple, Banana, Cherry, Durian]
        
        // ============================
        // 其他限制
        // ============================
        
        // - 沒有內建的 add()、remove()、contains() 方法
        // - 想知道某元素是否存在？要自己寫迴圈
        // - 想刪除中間的元素？要自己處理後面元素的位移
        
        // 這就是為什麼我們需要 ArrayList...
    }
}
```

記住這個痛點：**每次要加元素，就要手動建新陣列、複製、替換**。這在實務上根本不可行。

所以 Java 提供了 Collection Framework，幫我們把這些髒活都封裝好了。

---

# Part 2：Collection 體系（1.5 小時）

## 2.1 進入 Collection 之前：兩個重要觀念

在正式進入 Collection 之前，我要先講兩個貫穿整個 JCF 的重要觀念。

### 觀念一：Auto Boxing / Unboxing（自動裝箱拆箱）

```java
import java.util.ArrayList;
import java.util.List;

public class AutoBoxingDemo {
    public static void main(String[] args) {
        
        // ============================
        // 為什麼需要 Auto Boxing？
        // ============================
        
        // Collection 只能存「物件」，不能存「基本型別」
        // List<int> numbers = new ArrayList<>();  // 編譯錯誤！
        
        // 必須使用包裝類別
        List<Integer> numbers = new ArrayList<>();
        
        // ============================
        // Auto Boxing：基本型別 → 包裝類別（自動）
        // ============================
        
        numbers.add(1);      // int → Integer（自動裝箱）
        numbers.add(2);
        numbers.add(3);
        // 等同於：numbers.add(Integer.valueOf(1));
        
        // ============================
        // Auto Unboxing：包裝類別 → 基本型別（自動）
        // ============================
        
        int first = numbers.get(0);  // Integer → int（自動拆箱）
        // 等同於：int first = numbers.get(0).intValue();
        
        // ============================
        // 對照表（背起來）
        // ============================
        // int     ↔ Integer
        // long    ↔ Long
        // double  ↔ Double
        // boolean ↔ Boolean
        // char    ↔ Character
        
        // ============================
        // 【陷阱】null 的 unboxing 會爆掉！
        // ============================
        
        List<Integer> list = new ArrayList<>();
        list.add(null);  // 可以加 null
        
        // int value = list.get(0);  // NullPointerException!
        // 因為 null 無法轉成 int
        
        // 安全做法
        Integer value = list.get(0);
        if (value != null) {
            int primitiveValue = value;
        }
        
        // ============================
        // 【陷阱】Integer 比較要用 equals()
        // ============================
        
        Integer a = 127;
        Integer b = 127;
        System.out.println(a == b);      // true（快取範圍內）
        
        Integer c = 128;
        Integer d = 128;
        System.out.println(c == d);      // false！（超出快取範圍）
        System.out.println(c.equals(d)); // true（正確做法）
        
        // 原因：Integer 會快取 -128 ~ 127 的值
        // 超過這個範圍，每次都是新物件
    }
}
```

這個觀念很重要：**Collection 裝的都是物件，基本型別會自動轉換**。要小心 null 和 == 的陷阱。

### 觀念二：Diamond 語法（菱形語法）

```java
import java.util.*;

public class DiamondSyntaxDemo {
    public static void main(String[] args) {
        
        // ============================
        // Java 7 之前（冗長寫法）
        // ============================
        
        List<String> oldStyle = new ArrayList<String>();
        Map<String, List<Integer>> oldMap = new HashMap<String, List<Integer>>();
        
        // ============================
        // Java 7+ Diamond 語法（推薦）
        // ============================
        
        // 右邊的泛型可以省略，編譯器會自動推斷
        List<String> newStyle = new ArrayList<>();
        Map<String, List<Integer>> newMap = new HashMap<>();
        
        // ============================
        // 為什麼叫 Diamond？
        // ============================
        
        // 因為 <> 長得像鑽石 💎
        // 所以又叫「菱形語法」
        
        // ============================
        // Java 10+ var 關鍵字（選讀）
        // ============================
        
        var list = new ArrayList<String>();  // 編譯器推斷 list 是 ArrayList<String>
        
        // 注意：var 只能用在區域變數，不能用在成員變數或參數
    }
}
```

好，有了這兩個觀念，我們正式進入 Collection。

## 2.2 Collection 架構總覽

先讓我們看一下整個 JCF 的架構圖：

```java
public class CollectionHierarchyOverview {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * Java Collections Framework 繼承體系
         * ============================================================
         *
         *                     Iterable<E>        ← 介面
         *                         │ (繼承)
         *                   Collection<E>        ← 介面
         *                  ╱      │      ╲ (繼承)
         *                 ╱       │       ╲
         *            List<E>   Set<E>   Queue<E>  ← 介面
         *               │         │         │
         *         ┌─────┴───┐   ┌─┴──┐      │ (實作)
         *         │         │   │    │      │
         *    ArrayList  LinkedList  HashSet TreeSet  LinkedList
         *      (類別)    (類別)    (類別)  (類別)    (類別)
         *
         * ============================================================
         * 注意：Map<K,V> 是獨立的，不屬於 Collection 體系！
         * ============================================================
         */
    }
}
```

### 介面繼承的目的：契約的傳遞

同學們可能會問：「為什麼 `Collection<E>` 要繼承 `Iterable<E>`？」

這是一個很好的問題。讓我用白話解釋：

```java
/*
 * ============================================================
 * 介面 = 契約（合約）
 * ============================================================
 *
 * 你可以把介面想成「保證書」或「合約」。
 *
 * Iterable<E> 這個介面只定義了一個方法：
 *     Iterator<E> iterator();
 *
 * 意思是：「任何實作 Iterable 的類別，都『保證』能被遍歷。」
 *
 * 當 Collection<E> 繼承 Iterable<E>，就等於說：
 * 「所有 Collection 都繼承了這個保證，所以都可以被遍歷。」
 *
 * 這個保證會一路傳下去：
 * List 繼承 Collection → List 也保證可遍歷
 * ArrayList 實作 List → ArrayList 也保證可遍歷
 *
 * 實際效果是什麼？就是你可以對所有集合使用 for-each：
 */

List<String> list = new ArrayList<>();
Set<String> set = new HashSet<>();

// 這兩個都能用 for-each，因為它們最終都繼承了 Iterable
for (String item : list) { }
for (String item : set) { }
```

### 實作的目的：履行契約

那「實作」又是什麼意思呢？

```java
/*
 * ============================================================
 * 實作 = 履行合約的具體方式
 * ============================================================
 *
 * List<E> 介面定義了很多方法（合約條款）：
 * - add(E e)     → 保證可以新增元素
 * - get(int i)   → 保證可以用索引取值
 * - remove(E e)  → 保證可以移除元素
 * - size()       → 保證可以知道大小
 * ... 還有很多
 *
 * 但介面只定義「要做什麼」，不管「怎麼做」。
 *
 * ArrayList 實作 List，就是在告訴 Java：
 * 「我 ArrayList 會履行 List 的所有合約，我會提供具體的實作方式。」
 *
 * ArrayList 選擇用「陣列」來實作這些方法
 * LinkedList 選擇用「鏈結串列」來實作這些方法
 *
 * 它們都履行了同一份合約，但具體做法不同，效能特性也不同。
 */
```

### 詳解 `List<String> list = new ArrayList<>();`

這行程式碼是 Java 最經典的寫法，我們來逐字拆解：

```java
public class PolymorphismDemo {
    public static void main(String[] args) {
        
        // ============================
        // 這行到底在做什麼？
        // ============================
        
        List<String> list = new ArrayList<>();
        
        /*
         * 拆解：
         * 
         * 左邊：List<String> list
         *   - 宣告一個變數叫 list
         *   - 這個變數的「宣告型別」是 List<String>
         *   - 意思是：「我只關心它是一個 List，能做 List 該做的事」
         *
         * 右邊：new ArrayList<>()
         *   - 實際建立一個 ArrayList 物件
         *   - 這個物件的「實際型別」是 ArrayList<String>
         *   - 這是真正在記憶體中存在的東西
         *
         * 整體：
         *   - 建立一個 ArrayList 物件，但用 List 型別的變數來參考它
         */
        
        // ============================
        // 這是多型嗎？是的！
        // ============================
        
        /*
         * 多型（Polymorphism）的定義：
         * 「父類別（或介面）的變數，可以指向子類別的物件」
         *
         * 在這裡：
         * - List 是介面（父）
         * - ArrayList 是實作類別（子）
         * - 所以 List<String> list = new ArrayList<>(); 就是多型
         */
        
        // ============================
        // list 的型別到底是什麼？
        // ============================
        
        /*
         * 這要分兩個層面來看：
         *
         * 1. 編譯時期型別（Compile-time Type）= List<String>
         *    - 編譯器只知道 list 是 List
         *    - 只能呼叫 List 介面定義的方法
         *
         * 2. 執行時期型別（Runtime Type）= ArrayList<String>
         *    - 程式執行時，JVM 知道它其實是 ArrayList
         *    - 實際執行的是 ArrayList 的方法實作
         */
        
        // 這個可以
        list.add("Hello");     // List 介面有定義 add()
        list.get(0);           // List 介面有定義 get()
        
        // 這個不行！
        // list.trimToSize();  // 編譯錯誤！List 沒有這個方法
        
        // trimToSize() 是 ArrayList 特有的方法
        // 如果真的要用，必須轉型：
        ((ArrayList<String>) list).trimToSize();  // 可以，但不推薦
        
        // ============================
        // 為什麼推薦這樣寫？
        // ============================
        
        /*
         * 好處 1：彈性
         * 如果之後想換成 LinkedList，只要改一個地方
         */
        List<String> list2 = new LinkedList<>();  // 只改這裡
        // 下面的程式碼都不用動
        
        /*
         * 好處 2：解耦
         * 方法參數用介面，呼叫端可以傳任何實作
         */
        printAll(new ArrayList<>());   // OK
        printAll(new LinkedList<>());  // OK
        
        /*
         * 好處 3：程式碼意圖更清楚
         * 「我只需要一個 List，不在乎具體是哪種」
         */
    }
    
    // 參數用 List（介面），不要用 ArrayList（實作）
    public static void printAll(List<String> items) {
        for (String item : items) {
            System.out.println(item);
        }
    }
}
```

**總結這個觀念**：
- `List<String> list = new ArrayList<>();` 是多型的經典應用
- `list` 的宣告型別是 `List<String>`，實際型別是 `ArrayList<String>`
- 推薦「宣告用介面，建立用實作」，這是 Java 的最佳實踐

## 2.3 List 介面：有序、可重複、有索引

List 是最常用的 Collection，它的特性是：
- **有序**：元素按加入順序排列
- **可重複**：同一個元素可以加入多次
- **有索引**：可以用 index 存取（像 Array）

```java
import java.util.*;

public class ListInterfaceDemo {
    public static void main(String[] args) {
        
        // ============================
        // List 基本操作
        // ============================
        
        List<String> fruits = new ArrayList<>();
        
        // 新增
        fruits.add("Apple");
        fruits.add("Banana");
        fruits.add("Cherry");
        fruits.add("Apple");  // 可以重複！
        
        System.out.println(fruits);  // [Apple, Banana, Cherry, Apple]
        
        // 用 index 存取
        System.out.println(fruits.get(0));  // Apple
        System.out.println(fruits.get(2));  // Cherry
        
        // 修改
        fruits.set(1, "Blueberry");
        System.out.println(fruits);  // [Apple, Blueberry, Cherry, Apple]
        
        // 插入到指定位置
        fruits.add(1, "Avocado");  // 插入到 index 1，後面的往後移
        System.out.println(fruits);  // [Apple, Avocado, Blueberry, Cherry, Apple]
        
        // 刪除
        fruits.remove("Apple");     // 移除第一個符合的元素
        System.out.println(fruits);  // [Avocado, Blueberry, Cherry, Apple]
        
        fruits.remove(0);           // 移除 index 0 的元素
        System.out.println(fruits);  // [Blueberry, Cherry, Apple]
        
        // 查詢
        System.out.println(fruits.contains("Cherry"));  // true
        System.out.println(fruits.indexOf("Cherry"));   // 1
        System.out.println(fruits.size());              // 3
        System.out.println(fruits.isEmpty());           // false
        
        // 清空
        fruits.clear();
        System.out.println(fruits.isEmpty());  // true
    }
}
```

## 2.4 ArrayList 深入：你最常用的好夥伴

```java
import java.util.*;

public class ArrayListDeepDive {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * ArrayList 底層原理（概念即可，不用背）
         * ============================================================
         *
         * ArrayList 底層就是一個 Object[] 陣列
         * 預設初始容量是 10
         * 當元素超過容量時，自動擴容為原來的 1.5 倍
         *
         * 所以它幫你解決了 Array 要手動擴容的問題！
         */
        
        // ============================
        // 建立方式
        // ============================
        
        // 方式一：空的 ArrayList
        List<String> list1 = new ArrayList<>();
        
        // 方式二：指定初始容量（如果你知道大概要放多少元素）
        List<String> list2 = new ArrayList<>(100);
        
        // 方式三：用現有的 Collection 建立
        List<String> list3 = new ArrayList<>(Arrays.asList("A", "B", "C"));
        
        // 方式四：Java 9+ 快速建立（不可修改的 List）
        List<String> immutable = List.of("X", "Y", "Z");
        // immutable.add("W");  // UnsupportedOperationException!
        
        // ============================
        // ArrayList 的效能特性（記住這個就好）
        // ============================
        
        /*
         * 操作          時間複雜度    說明
         * ─────────────────────────────────────
         * get(index)      O(1)      直接算位址，超快
         * add(element)    O(1)*     加到尾端，均攤 O(1)
         * add(index, e)   O(n)      要移動後面的元素
         * remove(index)   O(n)      要移動後面的元素
         * contains(o)     O(n)      要從頭找到尾
         * 
         * 結論：ArrayList 適合「頻繁讀取、較少增刪」的場景
         */
        
        // ============================
        // 實務小技巧
        // ============================
        
        // 如果要加入大量元素，先指定容量可以避免多次擴容
        List<Integer> bigList = new ArrayList<>(10000);
        for (int i = 0; i < 10000; i++) {
            bigList.add(i);
        }
        
        // 轉成 Array
        String[] array = list3.toArray(new String[0]);
        
        // Array 轉成 List（注意：這個 List 是固定大小的！）
        List<String> fixedList = Arrays.asList("A", "B", "C");
        // fixedList.add("D");  // UnsupportedOperationException!
        
        // 想要可修改的 List，要這樣包一層
        List<String> mutableList = new ArrayList<>(Arrays.asList("A", "B", "C"));
        mutableList.add("D");  // OK!
    }
}
```

## 2.5 LinkedList：特定場景的選擇

```java
import java.util.*;

public class LinkedListDemo {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * LinkedList vs ArrayList
         * ============================================================
         *
         * LinkedList 是「雙向鏈結串列」
         * 每個節點都有指向前一個和後一個節點的參考
         *
         * 效能比較：
         * 操作              ArrayList    LinkedList
         * ───────────────────────────────────────────
         * get(index)         O(1)         O(n)      ← ArrayList 大勝
         * add (尾端)          O(1)*        O(1)
         * add (頭端)          O(n)         O(1)      ← LinkedList 勝
         * remove (頭尾)       O(n)         O(1)      ← LinkedList 勝
         * remove (中間)       O(n)         O(n)
         *
         * 結論：
         * - 99% 的情況用 ArrayList 就對了
         * - 只有「頻繁在頭尾增刪」的場景才考慮 LinkedList
         */
        
        // LinkedList 同時實作了 List 和 Deque（雙端佇列）
        LinkedList<String> linkedList = new LinkedList<>();
        
        // List 的方法都有
        linkedList.add("B");
        linkedList.add("C");
        
        // 還有 Deque 的特有方法
        linkedList.addFirst("A");  // 加到頭
        linkedList.addLast("D");   // 加到尾
        
        System.out.println(linkedList);  // [A, B, C, D]
        
        System.out.println(linkedList.getFirst());  // A
        System.out.println(linkedList.getLast());   // D
        
        linkedList.removeFirst();
        linkedList.removeLast();
        System.out.println(linkedList);  // [B, C]
        
        // ============================
        // 實務建議
        // ============================
        
        // 除非你非常確定需要 LinkedList 的特性，否則用 ArrayList
        // 原因：現代 CPU 的快取機制，讓連續記憶體存取（ArrayList）更有優勢
    }
}
```

## 2.6 Set 介面：去重的最佳選擇

```java
import java.util.*;

public class SetInterfaceDemo {
    public static void main(String[] args) {
        
        /*
         * Set 的核心特性：
         * - 元素不可重複（唯一性）
         * - 沒有索引（不能用 get(index)）
         */
        
        Set<String> fruits = new HashSet<>();
        
        // 加入元素
        boolean added1 = fruits.add("Apple");   // true（成功加入）
        boolean added2 = fruits.add("Banana");  // true
        boolean added3 = fruits.add("Apple");   // false（已存在，加入失敗）
        
        System.out.println(fruits);   // [Apple, Banana]（順序可能不同）
        System.out.println(added1);   // true
        System.out.println(added3);   // false
        
        // 注意：HashSet 不保證順序！
        // 每次執行，印出的順序可能不同
        
        // ============================
        // Set 最常見的用途：去重
        // ============================
        
        List<String> listWithDuplicates = Arrays.asList(
            "Java", "Python", "Java", "JavaScript", "Python", "Go"
        );
        
        // 一行去重
        Set<String> uniqueLanguages = new HashSet<>(listWithDuplicates);
        System.out.println(uniqueLanguages);  // [Java, JavaScript, Go, Python]
        
        // 如果需要回傳 List
        List<String> uniqueList = new ArrayList<>(uniqueLanguages);
    }
}
```

## 2.7 HashSet 深入：equals 和 hashCode 的重要性

這是 Set 最重要的觀念，一定要理解。我們先從基礎觀念講起：

### 什麼是 hashCode？

```java
public class HashCodeExplained {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * hashCode 是什麼？
         * ============================================================
         *
         * hashCode 是每個 Java 物件都有的方法，定義在 Object 類別中。
         * 它會回傳一個 int 整數，代表這個物件的「雜湊碼」。
         *
         * 你可以把 hashCode 想成物件的「快速辨識碼」或「指紋」。
         * 
         * 重點：hashCode 不是 HashSet 的屬性！
         * 它是所有 Java 物件都有的方法（繼承自 Object）。
         */
        
        String s1 = "Hello";
        String s2 = "World";
        
        System.out.println(s1.hashCode());  // 69609650
        System.out.println(s2.hashCode());  // 83766130
        
        // 內容相同的字串，hashCode 也相同
        String s3 = "Hello";
        System.out.println(s1.hashCode() == s3.hashCode());  // true
        
        /*
         * HashSet 怎麼利用 hashCode？
         *
         * HashSet 內部有很多「桶子」（bucket）
         * 當你 add 一個元素時，HashSet 會：
         * 1. 計算元素的 hashCode
         * 2. 用 hashCode 決定放到哪個桶子
         * 3. 這樣查找時就能快速定位，不用掃描全部元素
         *
         * 這就是為什麼 HashSet 的查找是 O(1) 而不是 O(n)
         */
    }
}
```

### 什麼是 equals？預設行為 vs 覆寫後行為

```java
public class EqualsExplained {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * equals() 的預設行為（Object 類別）
         * ============================================================
         *
         * 如果沒有覆寫 equals()，它的行為和 == 一樣：
         * 比較兩個物件的「記憶體位址」是否相同。
         *
         * 只有當兩個變數指向「同一個物件」時，才回傳 true。
         */
        
        Object obj1 = new Object();
        Object obj2 = new Object();
        Object obj3 = obj1;  // obj3 指向和 obj1 相同的物件
        
        System.out.println(obj1.equals(obj2));  // false（不同物件）
        System.out.println(obj1.equals(obj3));  // true（同一個物件）
        System.out.println(obj1 == obj3);       // true（和 equals 行為相同）
        
        /*
         * ============================================================
         * equals() 覆寫後的行為（如 String, Integer）
         * ============================================================
         *
         * 許多類別會覆寫 equals()，改成比較「內容值」。
         * 這叫做 Value Equality（值相等）。
         */
        
        String str1 = new String("Hello");
        String str2 = new String("Hello");
        
        System.out.println(str1 == str2);       // false（不同物件）
        System.out.println(str1.equals(str2));  // true（內容相同）
        
        Integer num1 = new Integer(100);
        Integer num2 = new Integer(100);
        
        System.out.println(num1 == num2);       // false（不同物件）
        System.out.println(num1.equals(num2));  // true（值相同）
    }
}
```

### HashSet 如何判斷重複？

```java
import java.util.*;

public class HashSetDeepDive {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * HashSet 判斷「重複」的兩步驟
         * ============================================================
         *
         * 步驟 1：先比較 hashCode()
         *    - hashCode 不同 → 一定不重複，直接放入
         *    - hashCode 相同 → 可能重複，進入步驟 2
         *
         * 步驟 2：再比較 equals()
         *    - equals 回傳 true → 確定重複，不放入
         *    - equals 回傳 false → 不重複（只是 hashCode 碰巧相同），放入
         *
         * 所以：兩個物件要被視為「相同」，必須同時滿足：
         * 1. hashCode() 回傳值相同
         * 2. equals() 回傳 true
         */
        
        // ============================
        // Demo：自訂類別沒有覆寫 equals/hashCode
        // ============================
        
        Set<Student> studentSet = new HashSet<>();
        
        Student s1 = new Student("A001", "Alice");
        Student s2 = new Student("A001", "Alice");  // 學號姓名都相同
        
        studentSet.add(s1);
        studentSet.add(s2);
        
        // 沒有覆寫 equals/hashCode 的話...
        System.out.println(studentSet.size());  // 2！兩個都加進去了
        System.out.println(s1.equals(s2));      // false（用 Object 的 equals，比較記憶體位址）
        System.out.println(s1.hashCode());      // 例如：366712642
        System.out.println(s2.hashCode());      // 例如：1829164700（不同！）
        
        // ============================
        // Demo：覆寫 equals/hashCode 後
        // ============================
        
        Set<StudentCorrect> correctSet = new HashSet<>();
        
        StudentCorrect sc1 = new StudentCorrect("A001", "Alice");
        StudentCorrect sc2 = new StudentCorrect("A001", "Alice");
        
        correctSet.add(sc1);
        correctSet.add(sc2);
        
        System.out.println(correctSet.size());  // 1！被視為重複
        System.out.println(sc1.equals(sc2));    // true
        System.out.println(sc1.hashCode());     // 例如：62621
        System.out.println(sc2.hashCode());     // 例如：62621（相同！）
    }
}

// 沒有覆寫 equals/hashCode（錯誤示範）
class Student {
    private String id;
    private String name;
    
    public Student(String id, String name) {
        this.id = id;
        this.name = name;
    }
    // 沒有覆寫 equals 和 hashCode
    // 使用 Object 的預設實作：比較記憶體位址
}

// 正確覆寫 equals/hashCode
class StudentCorrect {
    private String id;
    private String name;
    
    public StudentCorrect(String id, String name) {
        this.id = id;
        this.name = name;
    }
    
    /*
     * 覆寫 equals：定義「怎樣算相同」
     * 這裡我們定義：學號相同就是同一個學生
     */
    @Override
    public boolean equals(Object o) {
        // 1. 如果是同一個物件，直接回傳 true
        if (this == o) return true;
        
        // 2. 如果是 null 或不同類別，回傳 false
        if (o == null || getClass() != o.getClass()) return false;
        
        // 3. 轉型後比較「我們關心的欄位」
        StudentCorrect that = (StudentCorrect) o;
        return Objects.equals(id, that.id);  // 用學號判斷
    }
    
    /*
     * 覆寫 hashCode：必須和 equals 一致！
     * 
     * 規則：如果 equals 回傳 true，hashCode 必須相同
     * 
     * 所以：equals 比較哪些欄位，hashCode 就用哪些欄位計算
     */
    @Override
    public int hashCode() {
        return Objects.hash(id);  // 用學號計算 hashCode
    }
}
```

**重點總結**：
1. `hashCode()` 和 `equals()` 是 Object 的方法，所有物件都有
2. 預設的 `equals()` 比較記憶體位址（和 `==` 相同）
3. 覆寫 `equals()` 可以改成比較內容值
4. **當你把自訂類別放進 `HashSet`（或當作 `HashMap` 的 key）時，一定要覆寫 `equals()` 和 `hashCode()`**
5. IDE（IntelliJ、Eclipse）都可以自動產生，善用它

## 2.8 TreeSet：有排序需求時使用

```java
import java.util.*;

public class TreeSetDemo {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * TreeSet 特性
         * ============================================================
         *
         * - 元素自動排序
         * - 底層是「紅黑樹」（Red-Black Tree）
         * - 元素必須可比較（實作 Comparable 或提供 Comparator）
         */
        
        /*
         * ============================================================
         * 什麼是紅黑樹？（簡單理解就好）
         * ============================================================
         *
         * 紅黑樹是一種「自平衡的二元搜尋樹」。
         * 
         * 你不需要知道它的詳細原理，只要知道：
         * 1. 它是一種樹狀結構，每個節點最多有兩個子節點
         * 2. 左邊的子節點比父節點小，右邊的比父節點大
         * 3. 「自平衡」代表它會自動調整，保持樹的高度平衡
         * 4. 因為平衡，所以查找、插入、刪除都是 O(log n)
         *
         * 對比：
         * - HashSet：用 hash table，查找 O(1)，但無序
         * - TreeSet：用紅黑樹，查找 O(log n)，但有序
         *
         * 實務上：
         * - 需要排序 → TreeSet
         * - 不需要排序 → HashSet（較快）
         */
        
        // ============================
        // 字串自動按字典序排序
        // ============================
        
        Set<String> treeSet = new TreeSet<>();
        treeSet.add("Banana");
        treeSet.add("Apple");
        treeSet.add("Cherry");
        
        System.out.println(treeSet);  // [Apple, Banana, Cherry]（已排序！）
        
        // ============================
        // 數字自動按大小排序
        // ============================
        
        Set<Integer> numberSet = new TreeSet<>();
        numberSet.add(5);
        numberSet.add(2);
        numberSet.add(8);
        numberSet.add(1);
        
        System.out.println(numberSet);  // [1, 2, 5, 8]
        
        // ============================
        // 自訂類別要能排序，必須實作 Comparable
        // ============================
        
        // 或者在建立 TreeSet 時提供 Comparator
        Set<StudentCorrect> studentTreeSet = new TreeSet<>(
            Comparator.comparing(s -> s.toString())
        );
    }
}
```

**選擇建議**：
- 只要去重，不在乎順序 → `HashSet`（最快）
- 需要維持插入順序 → `LinkedHashSet`
- 需要排序 → `TreeSet`

## 2.9 Queue 介面：先進先出

```java
import java.util.*;

public class QueueDemo {
    public static void main(String[] args) {
        
        /*
         * Queue 是先進先出（FIFO）的資料結構
         * 就像排隊一樣：先排的人先處理
         */
        
        Queue<String> queue = new LinkedList<>();
        
        // ============================
        // 兩組方法的差異（重要！）
        // ============================
        
        /*
         * 操作     會拋異常        回傳特殊值
         * ─────────────────────────────────────
         * 加入     add(e)         offer(e)      失敗時：exception vs false
         * 取出     remove()       poll()        空時：exception vs null
         * 查看     element()      peek()        空時：exception vs null
         *
         * 實務建議：用右邊那組（offer/poll/peek），比較安全
         */
        
        // 加入元素（入隊）
        queue.offer("First");
        queue.offer("Second");
        queue.offer("Third");
        
        System.out.println(queue);  // [First, Second, Third]
        
        // 查看頭部（不移除）
        System.out.println(queue.peek());  // First
        System.out.println(queue);         // [First, Second, Third]（還在）
        
        // 取出元素（出隊）
        System.out.println(queue.poll());  // First（被移除）
        System.out.println(queue);         // [Second, Third]
        
        // 空 Queue 的處理
        Queue<String> emptyQueue = new LinkedList<>();
        System.out.println(emptyQueue.poll());    // null（不會爆）
        System.out.println(emptyQueue.peek());    // null
        // emptyQueue.remove();  // NoSuchElementException!
    }
}
```

### Queue 的實務應用場景

讓我詳細說明 Queue 的三個常見應用：

```java
import java.util.*;

public class QueueUseCases {
    
    /*
     * ============================================================
     * 應用一：訊息佇列 / 任務佇列
     * ============================================================
     *
     * 想像你是銀行的叫號系統：
     * - 客戶進來 → 抽號碼牌（offer 加入佇列）
     * - 櫃檯空出來 → 叫下一號（poll 取出處理）
     *
     * 這確保「先來的先服務」，不會有人插隊。
     *
     * 實務應用：
     * - 印表機工作排程：多人同時列印，按順序處理
     * - 客服系統：客戶來電排隊等待
     * - 非同步任務：把任務丟進佇列，背景程式慢慢處理
     */
    
    public static void demo1_TaskQueue() {
        Queue<String> printJobs = new LinkedList<>();
        
        // 使用者送出列印工作
        printJobs.offer("文件A.pdf");
        printJobs.offer("報告B.docx");
        printJobs.offer("圖片C.jpg");
        
        // 印表機依序處理
        while (!printJobs.isEmpty()) {
            String job = printJobs.poll();
            System.out.println("正在列印：" + job);
        }
    }
    
    /*
     * ============================================================
     * 應用二：BFS（廣度優先搜尋）
     * ============================================================
     *
     * 這是演算法中的經典應用。簡單來說：
     *
     * 想像你在找某個人，你會先問身邊的朋友，
     * 如果朋友都不知道，再問朋友的朋友。
     * 這就是「一層一層往外擴散」的搜尋方式。
     *
     * Queue 在這裡的角色：
     * - 把「待拜訪的人」放進 Queue
     * - 每次從 Queue 取出一個人來問
     * - 如果他不是目標，就把他的朋友加進 Queue
     * - 重複直到找到或 Queue 空了
     *
     * 實務應用：
     * - 社群網站的「你可能認識的人」
     * - 地圖導航的最短路徑
     * - 網路爬蟲的網頁探索
     */
    
    public static void demo2_BFS() {
        // 簡化範例：找出從 A 到其他點的最短距離
        // 假設有個簡單的關係圖：A -> B, A -> C, B -> D
        
        Queue<String> toVisit = new LinkedList<>();
        Set<String> visited = new HashSet<>();
        
        toVisit.offer("A");  // 從 A 開始
        
        while (!toVisit.isEmpty()) {
            String current = toVisit.poll();
            if (visited.contains(current)) continue;
            
            visited.add(current);
            System.out.println("拜訪：" + current);
            
            // 把鄰居加入待拜訪（這裡簡化處理）
            if (current.equals("A")) {
                toVisit.offer("B");
                toVisit.offer("C");
            } else if (current.equals("B")) {
                toVisit.offer("D");
            }
        }
        // 輸出：拜訪：A → 拜訪：B → 拜訪：C → 拜訪：D
    }
    
    /*
     * ============================================================
     * 應用三：生產者-消費者模式
     * ============================================================
     *
     * 這是多執行緒程式設計的經典模式。
     *
     * 想像一個漢堡店：
     * - 廚師（生產者）：一直做漢堡，做好放到出餐檯
     * - 外送員（消費者）：從出餐檯拿漢堡去送
     *
     * 出餐檯就是 Queue：
     * - 廚師做好漢堡 → offer 到 Queue
     * - 外送員來拿 → poll 從 Queue
     *
     * 好處：
     * - 廚師和外送員可以各做各的，不用等對方
     * - 如果外送員比較慢，漢堡可以先堆在出餐檯
     * - 如果廚師比較慢，外送員就等一下
     *
     * 實務應用：
     * - 日誌系統：程式產生日誌（生產者），背景寫入檔案（消費者）
     * - 訂單處理：使用者下單（生產者），系統處理訂單（消費者）
     *
     * 注意：實際多執行緒環境要用 BlockingQueue，不是普通的 Queue
     */
    
    public static void demo3_ProducerConsumer() {
        Queue<String> orderQueue = new LinkedList<>();
        
        // 模擬：使用者下單（生產者）
        orderQueue.offer("訂單001：漢堡");
        orderQueue.offer("訂單002：薯條");
        orderQueue.offer("訂單003：可樂");
        
        // 模擬：系統處理訂單（消費者）
        while (!orderQueue.isEmpty()) {
            String order = orderQueue.poll();
            System.out.println("處理中：" + order);
        }
    }
    
    public static void main(String[] args) {
        System.out.println("=== 任務佇列 Demo ===");
        demo1_TaskQueue();
        
        System.out.println("\n=== BFS Demo ===");
        demo2_BFS();
        
        System.out.println("\n=== 生產者-消費者 Demo ===");
        demo3_ProducerConsumer();
    }
}
```

## 2.10 Iterator 深入：為什麼 Collection 可以被遍歷？

在講 Iterator 的使用之前，我們先來理解「為什麼 Collection 可以用 for-each 遍歷」。

### Collection 能被遍歷的原因：Iterable 介面

```java
import java.util.*;

public class IterableExplained {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * 為什麼所有 Collection 都可以用 for-each？
         * ============================================================
         *
         * 答案在繼承體系裡：
         *
         *     Iterable<E>          ← 定義了 iterator() 方法
         *         │
         *   Collection<E>          ← 繼承 Iterable
         *     ╱   │   ╲
         *  List  Set  Queue        ← 也繼承了 Iterable
         *    │
         * ArrayList                ← 實作 iterator() 方法
         *
         * Iterable 介面只有一個核心方法：
         *     Iterator<E> iterator();
         *
         * 任何實作 Iterable 的類別，都「保證」能提供一個 Iterator，
         * 而 Iterator 就是用來遍歷元素的工具。
         *
         * for-each 語法（增強 for 迴圈）的條件就是：
         * 物件必須實作 Iterable 介面。
         */
        
        List<String> list = new ArrayList<>();
        list.add("A");
        list.add("B");
        list.add("C");
        
        // for-each 能用，是因為 ArrayList 實作了 Iterable
        for (String item : list) {
            System.out.println(item);
        }
        
        // 編譯器會把上面的 for-each 轉換成：
        Iterator<String> it = list.iterator();  // 這就是 Iterable 定義的方法
        while (it.hasNext()) {
            String item = it.next();
            System.out.println(item);
        }
        
        /*
         * ============================================================
         * Iterator 的三個核心方法
         * ============================================================
         *
         * 1. boolean hasNext() - 還有沒有下一個元素？
         * 2. E next()          - 取得下一個元素（並移動游標）
         * 3. void remove()     - 移除剛剛 next() 回傳的元素
         */
    }
}
```

### Iterator 的正確使用方式

這是一個常見的面試題，也是實務上容易踩的坑：

```java
import java.util.*;

public class IteratorDeepDive {
    public static void main(String[] args) {
        
        List<String> fruits = new ArrayList<>(
            Arrays.asList("Apple", "Banana", "Cherry", "Date", "Elderberry")
        );
        
        // ============================
        // 錯誤示範：在 for-each 中直接 remove
        // ============================
        
        /*
        // 這樣寫會爆 ConcurrentModificationException！
        for (String fruit : fruits) {
            if (fruit.startsWith("B")) {
                fruits.remove(fruit);  // 危險！
            }
        }
        */
        
        /*
         * 為什麼會爆？
         *
         * for-each 背後其實是用 Iterator。
         * 當你用 list.remove() 直接修改集合時，
         * Iterator 會發現「集合被別人改了」，
         * 就會拋出 ConcurrentModificationException。
         *
         * 這是一種「Fail-Fast」機制，用來防止在遍歷時的不一致狀態。
         */
        
        // ============================
        // 正確做法一：使用 Iterator.remove()
        // ============================
        
        Iterator<String> iterator = fruits.iterator();
        while (iterator.hasNext()) {
            String fruit = iterator.next();
            if (fruit.startsWith("B") || fruit.startsWith("D")) {
                iterator.remove();  // 用 Iterator 的 remove()，安全！
            }
        }
        System.out.println(fruits);  // [Apple, Cherry, Elderberry]
        
        // ============================
        // 正確做法二：使用 removeIf()（Java 8+，推薦）
        // ============================
        
        fruits = new ArrayList<>(
            Arrays.asList("Apple", "Banana", "Cherry", "Date", "Elderberry")
        );
        
        fruits.removeIf(fruit -> fruit.startsWith("B") || fruit.startsWith("D"));
        System.out.println(fruits);  // [Apple, Cherry, Elderberry]
        
        // ============================
        // 正確做法三：倒著遍歷（傳統 for 迴圈）
        // ============================
        
        fruits = new ArrayList<>(
            Arrays.asList("Apple", "Banana", "Cherry", "Date", "Elderberry")
        );
        
        for (int i = fruits.size() - 1; i >= 0; i--) {
            if (fruits.get(i).startsWith("B") || fruits.get(i).startsWith("D")) {
                fruits.remove(i);
            }
        }
        System.out.println(fruits);  // [Apple, Cherry, Elderberry]
    }
}
```

**記住**：遍歷 Collection 時要刪除元素，用 `Iterator.remove()` 或 `removeIf()`，絕對不要在 for-each 中直接呼叫 `list.remove()`。

## 2.11 Comparable 與 Comparator：排序的兩種方式

### 誰會需要 Comparable 與 Comparator？

```java
import java.util.*;

public class WhoNeedsComparable {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * 誰會需要 Comparable 和 Comparator？
         * ============================================================
         *
         * 簡單來說：當你想對「一堆東西」排序時。
         *
         * Java 內建的類別（String, Integer, Date 等）已經實作了 Comparable，
         * 所以你可以直接排序：
         */
        
        List<String> names = Arrays.asList("Charlie", "Alice", "Bob");
        Collections.sort(names);
        System.out.println(names);  // [Alice, Bob, Charlie]
        
        List<Integer> numbers = Arrays.asList(3, 1, 4, 1, 5);
        Collections.sort(numbers);
        System.out.println(numbers);  // [1, 1, 3, 4, 5]
        
        /*
         * 但是「自訂類別」怎麼辦？
         * Java 怎麼知道 Employee 該怎麼排？按姓名？按薪水？按年資？
         *
         * 這時候你就需要告訴 Java「怎麼比較」，有兩種方式：
         *
         * 1. Comparable（類別內建的「自然排序」）
         *    - 在類別裡面實作 compareTo() 方法
         *    - 一個類別只能有一種自然排序
         *
         * 2. Comparator（外部定義的「客製排序」）
         *    - 在排序時才提供比較邏輯
         *    - 可以有很多種不同的排序方式
         */
    }
}
```

### Comparable：類別內建的自然排序

```java
import java.util.*;

public class ComparableDemo {
    public static void main(String[] args) {
        
        List<Employee> employees = new ArrayList<>();
        employees.add(new Employee("Alice", "HR", 50000));
        employees.add(new Employee("Bob", "IT", 60000));
        employees.add(new Employee("Charlie", "HR", 55000));
        
        // Employee 實作了 Comparable，定義了預設按薪資排序
        Collections.sort(employees);
        
        System.out.println("按薪資排序（Comparable）：");
        employees.forEach(System.out::println);
        // Alice (HR, 50000)
        // Charlie (HR, 55000)
        // Bob (IT, 60000)
    }
}

class Employee implements Comparable<Employee> {
    private String name;
    private String department;
    private double salary;
    
    public Employee(String name, String department, double salary) {
        this.name = name;
        this.department = department;
        this.salary = salary;
    }
    
    /*
     * compareTo 的回傳值規則：
     * - 負數：this 排在 other 前面（this < other）
     * - 零：相等
     * - 正數：this 排在 other 後面（this > other）
     *
     * 記憶技巧：想像成 this - other 的結果
     */
    @Override
    public int compareTo(Employee other) {
        return Double.compare(this.salary, other.salary);  // 按薪資升序
    }
    
    // Getters
    public String getName() { return name; }
    public String getDepartment() { return department; }
    public double getSalary() { return salary; }
    
    @Override
    public String toString() {
        return String.format("%s (%s, %.0f)", name, department, salary);
    }
}
```

### Comparator：外部定義的客製排序

```java
import java.util.*;

public class ComparatorDemo {
    public static void main(String[] args) {
        
        List<Employee> employees = new ArrayList<>();
        employees.add(new Employee("Alice", "HR", 50000));
        employees.add(new Employee("Bob", "IT", 60000));
        employees.add(new Employee("Charlie", "HR", 55000));
        employees.add(new Employee("David", "IT", 60000));
        
        // ============================
        // Comparator：外部定義排序規則
        // ============================
        
        // 按名字排序
        Collections.sort(employees, Comparator.comparing(Employee::getName));
        System.out.println("按名字：");
        employees.forEach(System.out::println);
        
        // 按部門排序
        employees.sort(Comparator.comparing(Employee::getDepartment));
        System.out.println("\n按部門：");
        employees.forEach(System.out::println);
        
        // ============================
        // 多欄位排序（超實用！）
        // ============================
        
        // 先按部門，再按薪資降序
        employees.sort(
            Comparator.comparing(Employee::getDepartment)
                      .thenComparing(Employee::getSalary, Comparator.reverseOrder())
        );
        System.out.println("\n先按部門，再按薪資降序：");
        employees.forEach(System.out::println);
        
        // ============================
        // 【小技巧】Java 8+ Lambda 寫法（超常用！）
        // ============================
        
        /*
         * 在現代 Java (8+) 開發中，若需要臨時變更排序規則，
         * 最常用的方式是 Comparator + Lambda。
         *
         * 好處：不需要去改類別，直接在排序時定義規則。
         */
        
        // 直接用 Lambda
        employees.sort((e1, e2) -> e1.getName().compareTo(e2.getName()));
        
        // 或用 Comparator.comparing()（更清楚）
        employees.sort(Comparator.comparing(Employee::getName));
        
        // 降序
        employees.sort(Comparator.comparing(Employee::getSalary).reversed());
        
        // 多欄位
        employees.sort(
            Comparator.comparing(Employee::getDepartment)
                      .thenComparing(Employee::getName)
        );
        
        // ============================
        // 處理 null 值
        // ============================
        
        // null 排最後
        Comparator<Employee> nullSafe = Comparator.comparing(
            Employee::getName, 
            Comparator.nullsLast(Comparator.naturalOrder())
        );
    }
}
```

**Comparable vs Comparator 比較**：

| 面向 | Comparable | Comparator |
|------|-----------|------------|
| 位置 | 類別內部實作 | 外部定義 |
| 數量 | 一個類別只能有一種 | 可以有多種 |
| 方法 | `compareTo(T o)` | `compare(T o1, T o2)` |
| 適用 | 定義「預設」排序 | 定義「客製」排序 |
| 修改類別 | 需要 | 不需要 |

**實務建議**：
- 如果排序規則是「這個類別本來就該這樣排」→ 用 Comparable
- 如果排序規則是「臨時需要」或「有多種排法」→ 用 Comparator + Lambda

## 2.12 空值與空集合判斷

這是寫程式時很容易忽略但又很重要的細節：

```java
import java.util.*;

public class NullAndEmptyChecks {
    public static void main(String[] args) {
        
        // ============================
        // null vs empty 的差異
        // ============================
        
        List<String> nullList = null;                    // 沒有指向任何物件
        List<String> emptyList = new ArrayList<>();      // 有物件，但沒有元素
        List<String> nonEmpty = Arrays.asList("A");      // 有物件，有元素
        
        // ============================
        // 原生判斷方式
        // ============================
        
        // 安全的判斷方式：先檢查 null，再檢查 empty
        if (nonEmpty != null && !nonEmpty.isEmpty()) {
            System.out.println("List 有內容");
        }
        
        // 危險寫法
        // if (nullList.isEmpty()) { }  // NullPointerException!
    }
}
```

### CollectionUtils 工具類比較：Apache vs Spring

在實務開發中，常會使用工具類來簡化 null 和 empty 的判斷。有兩個常見的選擇：

```java
import java.util.*;
// import org.apache.commons.collections4.CollectionUtils;  // Apache
// import org.springframework.util.CollectionUtils;          // Spring

public class CollectionUtilsComparison {
    public static void main(String[] args) {
        
        List<String> nullList = null;
        List<String> emptyList = new ArrayList<>();
        List<String> nonEmpty = Arrays.asList("A", "B");
        
        /*
         * ============================================================
         * Apache Commons Collections 的 CollectionUtils
         * ============================================================
         *
         * Maven 依賴：
         * <dependency>
         *     <groupId>org.apache.commons</groupId>
         *     <artifactId>commons-collections4</artifactId>
         *     <version>4.4</version>
         * </dependency>
         *
         * 特色：功能非常豐富，是一個「專門處理集合」的工具庫
         */
        
        // org.apache.commons.collections4.CollectionUtils
        
        // 基本判斷
        // CollectionUtils.isEmpty(nullList);      // true
        // CollectionUtils.isEmpty(emptyList);     // true
        // CollectionUtils.isEmpty(nonEmpty);      // false
        // CollectionUtils.isNotEmpty(nonEmpty);   // true
        
        // null 安全的 size
        // CollectionUtils.size(nullList);         // 0（不會爆）
        
        // null 轉空集合
        // CollectionUtils.emptyIfNull(nullList);  // 回傳空 List 而非 null
        
        // 集合操作（Apache 特有）
        // CollectionUtils.union(list1, list2);        // 聯集
        // CollectionUtils.intersection(list1, list2); // 交集
        // CollectionUtils.subtract(list1, list2);     // 差集
        // CollectionUtils.isEqualCollection(l1, l2);  // 比較（不管順序）
        
        /*
         * ============================================================
         * Spring Framework 的 CollectionUtils
         * ============================================================
         *
         * Maven 依賴：
         * <dependency>
         *     <groupId>org.springframework</groupId>
         *     <artifactId>spring-core</artifactId>
         *     <version>6.1.3</version>
         * </dependency>
         *
         * 特色：功能較簡單，但如果專案已經用 Spring，不用額外加依賴
         */
        
        // org.springframework.util.CollectionUtils
        
        // 基本判斷
        // CollectionUtils.isEmpty(nullList);      // true
        // CollectionUtils.isEmpty(emptyList);     // true
        // CollectionUtils.isEmpty(nonEmpty);      // false
        
        // 注意：Spring 的沒有 isNotEmpty()！要自己寫 !isEmpty()
        
        /*
         * ============================================================
         * 比較表
         * ============================================================
         *
         * 功能                    Apache              Spring
         * ───────────────────────────────────────────────────────
         * isEmpty()               ✓                   ✓
         * isNotEmpty()            ✓                   ✗
         * size() null safe        ✓                   ✗
         * emptyIfNull()           ✓                   ✗
         * 集合運算(交/聯/差集)     ✓                   ✗
         * containsAny()           ✓                   ✓
         * containsAll()           ✓                   ✗
         *
         * 結論：
         * - 專案已有 Spring → 用 Spring 的，簡單夠用
         * - 需要豐富的集合操作 → 用 Apache 的
         * - 兩者都沒有 → 自己寫一個簡單的工具方法
         */
    }
    
    // ============================
    // 如果不想引入外部依賴，自己寫一個
    // ============================
    
    public static boolean isEmpty(Collection<?> collection) {
        return collection == null || collection.isEmpty();
    }
    
    public static boolean isNotEmpty(Collection<?> collection) {
        return !isEmpty(collection);
    }
}
```

### 最佳實踐

```java
import java.util.*;

public class BestPractices {
    
    // ============================
    // 方法回傳值：回傳空集合而非 null
    // ============================
    
    // 不好的做法：可能回傳 null
    public List<String> findUsers_bad(String keyword) {
        // ... 查詢邏輯 ...
        // 沒找到時回傳 null
        return null;  // 不好！
    }
    
    // 好的做法：回傳空集合
    public List<String> findUsers_good(String keyword) {
        List<String> result = new ArrayList<>();
        // ... 查詢邏輯 ...
        // 沒找到就回傳空的 result
        return result;  // 好！
        
        // 或者用 Collections.emptyList()（不可變的空 List）
        // return Collections.emptyList();
    }
    
    public static void main(String[] args) {
        BestPractices demo = new BestPractices();
        
        // 好的做法讓呼叫端可以安心使用，不用擔心 NPE
        for (String user : demo.findUsers_good("test")) {
            // 安全！就算是空集合，for-each 也不會爆
            System.out.println(user);
        }
    }
}
```

**實務建議**：
1. 方法回傳 Collection 時，回傳空集合而非 null
2. 使用 `CollectionUtils.isEmpty()` 或自己封裝類似的方法
3. 養成習慣：拿到 Collection 時，先想「這會不會是 null？」

## 2.13 Collections 工具類

最後來看 `java.util.Collections` 這個工具類：

```java
import java.util.*;

public class CollectionsUtilityDemo {
    public static void main(String[] args) {
        
        List<Integer> numbers = new ArrayList<>(Arrays.asList(3, 1, 4, 1, 5, 9, 2, 6));
        
        // ============================
        // 排序相關
        // ============================
        
        Collections.sort(numbers);  // 升序排序
        System.out.println(numbers);  // [1, 1, 2, 3, 4, 5, 6, 9]
        
        Collections.reverse(numbers);  // 反轉
        System.out.println(numbers);  // [9, 6, 5, 4, 3, 2, 1, 1]
        
        Collections.shuffle(numbers);  // 隨機打亂
        System.out.println(numbers);  // [隨機順序]
        
        // ============================
        // 搜尋（必須先排序！）
        // ============================
        
        Collections.sort(numbers);
        int index = Collections.binarySearch(numbers, 5);
        System.out.println("5 的位置：" + index);
        
        // ============================
        // 極值
        // ============================
        
        System.out.println("最大值：" + Collections.max(numbers));
        System.out.println("最小值：" + Collections.min(numbers));
        
        // ============================
        // 不可修改的集合（防禦性程式設計）
        // ============================
        
        List<String> original = new ArrayList<>(Arrays.asList("A", "B", "C"));
        List<String> unmodifiable = Collections.unmodifiableList(original);
        
        // unmodifiable.add("D");  // UnsupportedOperationException!
        
        // 注意：Java 9+ 更推薦用 List.of()
        List<String> immutable = List.of("X", "Y", "Z");
        
        // ============================
        // 執行緒安全的集合
        // ============================
        
        List<String> syncList = Collections.synchronizedList(new ArrayList<>());
        // 但更推薦用 java.util.concurrent 下的類別，如 CopyOnWriteArrayList
        
        // ============================
        // 特殊用途
        // ============================
        
        List<String> empty = Collections.emptyList();       // 不可變的空 List
        List<String> single = Collections.singletonList("Only");  // 只有一個元素的不可變 List
        List<String> nCopies = Collections.nCopies(5, "X");  // 5 個 "X"
        System.out.println(nCopies);  // [X, X, X, X, X]
    }
}
```

---

# Part 3：Map 體系（45 分鐘）

## 3.1 Map 不是 Collection！

首先要澄清一個常見誤解：

```java
public class MapIsNotCollection {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * Map 不繼承 Collection！
         * ============================================================
         *
         * Collection 存放的是「單一元素」
         * Map 存放的是「鍵值對」（Key-Value pair）
         *
         * 它們是平行的兩個體系：
         *
         *    Iterable
         *        │
         *   Collection        Map
         *   ╱   │   ╲        ╱   │   ╲
         * List Set Queue  HashMap TreeMap ...
         *
         */
        
        // 雖然不是 Collection，但 Map 是 JCF 的一部分
        // 而且是最常用的資料結構之一！
    }
}
```

## 3.2 Map 介面基本操作

```java
import java.util.*;

public class MapInterfaceDemo {
    public static void main(String[] args) {
        
        Map<String, Integer> scores = new HashMap<>();
        
        // ============================
        // 新增與更新
        // ============================
        
        // put：新增或更新
        scores.put("Alice", 85);
        scores.put("Bob", 92);
        scores.put("Charlie", 78);
        
        System.out.println(scores);  // {Alice=85, Bob=92, Charlie=78}（順序可能不同）
        
        // 更新（key 已存在）
        scores.put("Alice", 90);  // Alice 的分數更新為 90
        
        // put 會回傳舊值（如果 key 存在）
        Integer oldValue = scores.put("Bob", 95);
        System.out.println("Bob 的舊分數：" + oldValue);  // 92
        
        // putIfAbsent：只在 key 不存在時才加入
        scores.putIfAbsent("Alice", 100);  // Alice 已存在，不會更新
        scores.putIfAbsent("David", 88);   // David 不存在，會加入
        System.out.println(scores);
        
        // ============================
        // 查詢
        // ============================
        
        // get：取得 value（key 不存在回傳 null）
        Integer aliceScore = scores.get("Alice");
        Integer unknownScore = scores.get("Unknown");
        System.out.println("Alice: " + aliceScore);    // 90
        System.out.println("Unknown: " + unknownScore);  // null
        
        // getOrDefault：key 不存在時回傳預設值（推薦）
        int score = scores.getOrDefault("Unknown", 0);
        System.out.println("Unknown (with default): " + score);  // 0
        
        // containsKey / containsValue
        System.out.println(scores.containsKey("Alice"));    // true
        System.out.println(scores.containsValue(90));       // true
        
        // ============================
        // 刪除
        // ============================
        
        scores.remove("David");
        System.out.println(scores);
        
        // remove 也可以同時檢查 key 和 value
        boolean removed = scores.remove("Alice", 90);  // 只有 Alice=90 時才刪除
        System.out.println("Removed: " + removed);
        
        // ============================
        // 其他
        // ============================
        
        System.out.println("Size: " + scores.size());
        System.out.println("Is empty: " + scores.isEmpty());
        
        // keySet, values, entrySet（待會講遍歷時會用到）
        Set<String> keys = scores.keySet();
        Collection<Integer> values = scores.values();
        Set<Map.Entry<String, Integer>> entries = scores.entrySet();
    }
}
```

## 3.3 HashMap 深入

```java
import java.util.*;

public class HashMapDeepDive {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * HashMap 核心特性
         * ============================================================
         *
         * 1. 基於 hash table 實作
         * 2. key 的 hashCode() 決定存放位置
         * 3. 允許 null key（只能有一個）和 null value
         * 4. 不保證順序（遍歷順序可能和插入順序不同）
         * 5. 非執行緒安全
         *
         * 效能：
         * - get / put / remove：平均 O(1)
         */
        
        Map<String, String> map = new HashMap<>();
        
        // 允許 null key 和 null value
        map.put(null, "null key's value");
        map.put("key", null);
        System.out.println(map.get(null));  // null key's value
        
        // ============================
        // 自訂類別當 key 時，必須覆寫 equals 和 hashCode
        // ============================
        
        // 和 HashSet 一樣的道理
        // 請參考前面 HashSet 的說明
        
        // ============================
        // LinkedHashMap：保持插入順序
        // ============================
        
        Map<String, Integer> linkedMap = new LinkedHashMap<>();
        linkedMap.put("C", 3);
        linkedMap.put("A", 1);
        linkedMap.put("B", 2);
        
        System.out.println("LinkedHashMap: " + linkedMap);  // {C=3, A=1, B=2}（維持插入順序）
        
        // ============================
        // Java 8+ 的好用方法
        // ============================
        
        Map<String, Integer> countMap = new HashMap<>();
        
        // 計數器模式（超常用！）
        String[] words = {"apple", "banana", "apple", "cherry", "banana", "apple"};
        
        // 傳統寫法（囉嗦）
        for (String word : words) {
            if (countMap.containsKey(word)) {
                countMap.put(word, countMap.get(word) + 1);
            } else {
                countMap.put(word, 1);
            }
        }
        
        // Java 8+ 寫法（推薦）
        countMap.clear();
        for (String word : words) {
            countMap.merge(word, 1, Integer::sum);
        }
        System.out.println(countMap);  // {apple=3, banana=2, cherry=1}
        
        // getOrDefault 也很好用
        countMap.clear();
        for (String word : words) {
            countMap.put(word, countMap.getOrDefault(word, 0) + 1);
        }
        
        // computeIfAbsent：key 不存在時才計算
        Map<String, List<String>> groupMap = new HashMap<>();
        
        // 傳統寫法
        if (!groupMap.containsKey("fruits")) {
            groupMap.put("fruits", new ArrayList<>());
        }
        groupMap.get("fruits").add("apple");
        
        // Java 8+ 寫法
        groupMap.computeIfAbsent("vegetables", k -> new ArrayList<>()).add("carrot");
    }
}
```

## 3.4 TreeMap：有排序的 Map

```java
import java.util.*;

public class TreeMapDemo {
    public static void main(String[] args) {
        
        /*
         * TreeMap 特性：
         * - Key 自動排序（自然順序或 Comparator）
         * - 底層是紅黑樹
         * - 不允許 null key（會 NullPointerException）
         * - get/put/remove：O(log n)
         */
        
        Map<String, Integer> treeMap = new TreeMap<>();
        treeMap.put("Charlie", 78);
        treeMap.put("Alice", 85);
        treeMap.put("Bob", 92);
        
        System.out.println(treeMap);  // {Alice=85, Bob=92, Charlie=78}（按 key 排序）
        
        // ============================
        // TreeMap 特有的方法
        // ============================
        
        TreeMap<Integer, String> scoreMap = new TreeMap<>();
        scoreMap.put(60, "及格");
        scoreMap.put(70, "普通");
        scoreMap.put(80, "良好");
        scoreMap.put(90, "優秀");
        
        System.out.println("第一個：" + scoreMap.firstEntry());  // 60=及格
        System.out.println("最後一個：" + scoreMap.lastEntry());  // 90=優秀
        
        // 找出 <= 75 的最大 key
        System.out.println("floorEntry(75): " + scoreMap.floorEntry(75));  // 70=普通
        
        // 找出 >= 75 的最小 key
        System.out.println("ceilingEntry(75): " + scoreMap.ceilingEntry(75));  // 80=良好
        
        // 取得子 Map
        System.out.println("headMap(80): " + scoreMap.headMap(80));  // {60=及格, 70=普通}
        System.out.println("tailMap(80): " + scoreMap.tailMap(80));  // {80=良好, 90=優秀}
    }
}
```

## 3.5 ConcurrentHashMap 簡介

```java
import java.util.concurrent.*;

public class ConcurrentHashMapIntro {
    public static void main(String[] args) {
        
        /*
         * ============================================================
         * 為什麼需要 ConcurrentHashMap？
         * ============================================================
         *
         * HashMap 不是執行緒安全的！
         * 多執行緒同時修改 HashMap，可能導致：
         * - 資料遺失
         * - 無限迴圈
         * - 其他詭異問題
         *
         * 解決方案：
         * 1. Collections.synchronizedMap()（效能差）
         * 2. ConcurrentHashMap（推薦）
         */
        
        ConcurrentHashMap<String, Integer> concurrentMap = new ConcurrentHashMap<>();
        
        // 基本操作和 HashMap 一樣
        concurrentMap.put("A", 1);
        concurrentMap.put("B", 2);
        System.out.println(concurrentMap.get("A"));  // 1
        
        // ============================
        // 重要差異：不允許 null！
        // ============================
        
        // concurrentMap.put(null, 1);  // NullPointerException!
        // concurrentMap.put("C", null);  // NullPointerException!
        
        // ============================
        // 原子操作（超重要）
        // ============================
        
        // putIfAbsent：只在 key 不存在時才放入
        concurrentMap.putIfAbsent("A", 100);  // A 已存在，不會更新
        
        // computeIfAbsent：只在 key 不存在時才計算並放入
        concurrentMap.computeIfAbsent("C", key -> {
            System.out.println("Computing value for " + key);
            return 3;
        });
        
        // 這些方法是「原子」的，多執行緒環境下不會有問題
        
        /*
         * 什麼時候用？
         * - 多執行緒環境下共享的 Map
         * - 快取（Cache）
         * - 計數器
         */
    }
}
```

## 3.6 Map 的遍歷方式

```java
import java.util.*;

public class MapIterationDemo {
    public static void main(String[] args) {
        
        Map<String, Integer> scores = new HashMap<>();
        scores.put("Alice", 85);
        scores.put("Bob", 92);
        scores.put("Charlie", 78);
        
        // ============================
        // 方式一：遍歷 keySet（只需要 key 時）
        // ============================
        
        System.out.println("=== 遍歷 keySet ===");
        for (String name : scores.keySet()) {
            System.out.println(name + ": " + scores.get(name));
        }
        
        // ============================
        // 方式二：遍歷 entrySet（推薦！同時需要 key 和 value 時）
        // ============================
        
        System.out.println("\n=== 遍歷 entrySet ===");
        for (Map.Entry<String, Integer> entry : scores.entrySet()) {
            System.out.println(entry.getKey() + ": " + entry.getValue());
        }
        
        // ============================
        // 方式三：forEach + Lambda（Java 8+，最簡潔）
        // ============================
        
        System.out.println("\n=== forEach + Lambda ===");
        scores.forEach((name, score) -> {
            System.out.println(name + ": " + score);
        });
        
        // ============================
        // 方式四：只遍歷 values（只需要 value 時）
        // ============================
        
        System.out.println("\n=== 遍歷 values ===");
        for (Integer score : scores.values()) {
            System.out.println(score);
        }
        
        // ============================
        // 效能比較
        // ============================
        
        /*
         * 需要 key 和 value → entrySet()（最快，只遍歷一次）
         * 只需要 key        → keySet()
         * 只需要 value      → values()
         *
         * 不推薦：用 keySet 遍歷後再 get()（多了一次查找）
         */
    }
}
```

## 3.7 Map 實務應用

```java
import java.util.*;

public class MapPracticalUsage {
    public static void main(String[] args) {
        
        // ============================
        // 應用一：統計次數（超常用！）
        // ============================
        
        String text = "apple banana apple cherry banana apple";
        String[] words = text.split(" ");
        
        Map<String, Integer> wordCount = new HashMap<>();
        for (String word : words) {
            wordCount.merge(word, 1, Integer::sum);
        }
        System.out.println("詞頻統計：" + wordCount);
        // {apple=3, banana=2, cherry=1}
        
        // ============================
        // 應用二：分組（Group By）
        // ============================
        
        List<Employee> employees = Arrays.asList(
            new Employee("Alice", "HR", 50000),
            new Employee("Bob", "IT", 60000),
            new Employee("Charlie", "HR", 55000),
            new Employee("David", "IT", 65000)
        );
        
        // 按部門分組
        Map<String, List<Employee>> byDepartment = new HashMap<>();
        for (Employee emp : employees) {
            byDepartment.computeIfAbsent(emp.getDepartment(), k -> new ArrayList<>())
                        .add(emp);
        }
        System.out.println("按部門分組：" + byDepartment);
        
        // ============================
        // 應用三：快取（Cache）
        // ============================
        
        Map<String, String> cache = new HashMap<>();
        
        String userId = "user123";
        String userData = cache.computeIfAbsent(userId, id -> {
            // 這個 Lambda 只在 cache 沒有資料時才執行
            System.out.println("從資料庫載入 " + id + " 的資料...");
            return "User Data for " + id;
        });
        System.out.println(userData);
        
        // 第二次呼叫，直接從 cache 取得
        userData = cache.computeIfAbsent(userId, id -> {
            System.out.println("不會印出這行，因為 cache 已有資料");
            return "xxx";
        });
        System.out.println(userData);
        
        // ============================
        // 應用四：反向查找（建立反向索引）
        // ============================
        
        Map<String, String> idToName = new HashMap<>();
        idToName.put("A001", "Alice");
        idToName.put("A002", "Bob");
        idToName.put("A003", "Charlie");
        
        // 建立反向 Map
        Map<String, String> nameToId = new HashMap<>();
        for (Map.Entry<String, String> entry : idToName.entrySet()) {
            nameToId.put(entry.getValue(), entry.getKey());
        }
        System.out.println("Name to ID: " + nameToId);
        // {Alice=A001, Bob=A002, Charlie=A003}
    }
}
```

---

# 總結與 Q&A

## Collection 選擇指南

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

## 重點回顧

1. **Array 的限制**催生了 Collection Framework
2. **宣告用介面，建立用實作**：`List<String> list = new ArrayList<>();` 是多型的應用
3. **Auto Boxing**：Collection 只能存物件，基本型別會自動轉換
4. **equals/hashCode**：自訂類別放入 HashSet 或當 HashMap 的 key 時必須覆寫
5. **Collection 能被遍歷**：因為繼承了 Iterable 介面
6. **遍歷時刪除**：用 `Iterator.remove()` 或 `removeIf()`
7. **排序**：Comparable 定義預設排序，Comparator 定義客製排序（推薦用 Lambda）
8. **空值判斷**：養成先檢查 null 再操作的習慣，可用 CollectionUtils 工具類
9. **Map 遍歷**：需要 key 和 value 時用 `entrySet()`

好，今天的 Java Collections Framework 就講到這裡。接下來我們進入練習時間，請打開練習題檔案...

---

> **講師備註**：此處結束理論教學，進入練習時間。建議搭配 spec 中的練習題讓學員實作。