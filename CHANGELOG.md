## 0.0.51

- Fixed error no table exist

## 0.0.50

- Minor

## 0.0.49

- Minor

## 0.0.48

- Minor

## 0.0.47

- Minor

## 0.0.45

- Method renames back.

## 0.0.44

### Changes:

- Added functionality to automatically remove non-existent columns from the database schema during insert and update operations.
  - Example:
    ```dart
    List<String> existingColumns = await getTableColumns(tableName, db: db);
    var map = item.toMap();
    map.removeWhere((key, value) => !existingColumns.contains(key));
    ```
- Method renames to match functionality.

## 0.0.43

- Minor

## 0.0.42

- Minor

## 0.0.41

- Added search across multiple columns. `var items = await db.searchColumns(Strongs(), columnNames, query);`

## 0.0.40

- Github repository updated

## 0.0.39

- Minor

## 0.0.38

- Fixed not compile

## 0.0.36

- Added ISQLiteItemExtended & SQLiteItemBatch

## 0.0.35

- Added `toJoinString()` method to `ISQLiteItem`.
  - This method returns a string combining from sample `title` and `value` fields using the `|` delimiter.
  - Example: `'${title ?? ""}|${value ?? ""}'`.

## 0.0.34

- Removed `SQLiteConnection.formatDateWithSeconds(Date? date)`

## 0.0.33

- Added `SQLiteConnection.formatDateWithSeconds(Date? date)`
- Output: `Dec-12-2024-10:38:35 AM`
- Can be used to compare the `date_updated` between the server's `date_updated` and the local `date_updated` to detect any changes that have been pushed.

## 0.0.32

- fixed toListWhereValuesAre() return empty

## 0.0.31

- Readme updated.

## 0.0.30

- Reversed the changelog order.

## 0.0.29

- Added toListWhereValuesAre()
- Added getBatch()

## 0.0.28

- Added getFirstItem()

## 0.0.27

- InsertAll fixed

## 0.0.26

- InsertAll updated

## 0.0.25

- Added doc

## 0.0.24

- Added toListWhere

## 0.0.23

- Added backup and paginate

## 0.0.22

- Added wereSingle. for single query

## 0.0.14

- Added some documentation code.

## 0.0.9

- Added multiple items.

## 0.0.1

- Release sample.
