part of sqflitebrite;

class BriteTransaction {

    final BriteTransaction _parent;

    final Transaction _transaction;

    final BriteDatabase _briteDatabase;

    final Set<String> _tables = new Set();

    bool _successfull = false;


    BriteTransaction._(this._transaction, this._parent, this._briteDatabase);

    @override
    String toString() {
        //package:sqflitebrite/BriteTransaction.dart/BriteTransaction
        return _parent == null
                ? "BriteTransaction@${hashCode.toRadixString(16)} {}"
                : "BriteTransaction@{${hashCode.toRadixString(16)}, parent: ${_parent.toString()}}";
    }


    BriteTransaction _onBegin() {
        _successfull = false;
        return this;
    }


    BriteTransaction _onEnd() {
        if (_successfull) {}
        return this;
    }


    BriteTransaction _markSuccessful() {
        _successfull = true;
        return this;
    }


    bool get _isSuccessfull {
        return _successfull;
    }


    BriteTransaction _addTables(Iterable<String> tables) {
        _tables.addAll(tables);
        return this;
    }


    BriteTransaction _addTable(String table) {
        _tables.add(table);
        return this;
    }


    Iterable<String> _getTables() {
        return _tables;
    }


    BriteBatch batch() {
        return new _BriteTransactionBatch(this, _transaction.batch());
    }


    Future<int> insert(String table, Map<String, dynamic> values, {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) {
        if (_briteDatabase._logging) {
            _briteDatabase.log("INSERT\n  table: $table\n  values: $values\n  nullColumnHack: $nullColumnHack\n  conflictAlgorithm: ${BriteDatabase
                    .conflictString(conflictAlgorithm)}");
        }

        return _transaction.insert(table, values, nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm)
                .then((rowId) async {
            if (rowId != -1) {
                _addTable(table);
            }
            return rowId;
        });
    }


    Future<int> delete(String table, {String where, List whereArgs}) {
        if (_briteDatabase._logging) {
            _briteDatabase.log("DELETE\n  table: $table\n  whereClause: $where\n  whereArgs: $whereArgs");
        }

        return _transaction.delete(table, where: where, whereArgs: whereArgs)
                .then((rows) async {
            if (rows > 0) {
                _addTable(table);
            }
            return rows;
        });
    }


    Future<int> update(String table, Map<String, dynamic> values, {String where, List whereArgs, ConflictAlgorithm conflictAlgorithm}) {
        if (_briteDatabase._logging) {
            _briteDatabase.log(
                    "UPDATE\n  table: $table\n  values: $values\n  whereClause: $where\n  whereArgs: $whereArgs\n  conflictAlgorithm: ${BriteDatabase
                            .conflictString(conflictAlgorithm)}");
        }

        return _transaction.update(table, values, where: where, whereArgs: whereArgs, conflictAlgorithm: conflictAlgorithm)
                .then((rows) async {
            if (rows > 0) {
                _addTable(table);
            }
            return rows;
        });
    }


    Future<List<Map<String, dynamic>>> query(String table, {bool distinct, List<
            String> columns, String where, List whereArgs, String groupBy, String having, String orderBy, int limit, int offset}) {
        if (_briteDatabase._logging) {
            _briteDatabase.log(
                    "QUERY\n  table: $table\n  distinct: $distinct\n  columns: $columns\n  whereClause: $where\n  whereArgs: $whereArgs\n  groupBy: $groupBy\n  having: $having\n  orderBy: $orderBy\n  limit: $limit\n  offset: $offset\n");
        }

        return _transaction.query(
                table,
                distinct: distinct,
                columns: columns,
                where: where,
                whereArgs: whereArgs,
                groupBy: groupBy,
                having: having,
                orderBy: orderBy,
                limit: limit,
                offset: offset);
    }


    Future<void> execute(Set<String> tables, String sql, [List arguments]) {
        if (_briteDatabase._logging) {
            _briteDatabase.log("EXECUTE\n  tables: $tables\n  sql: ${BriteDatabase.indentSql(sql)}\n  args: $arguments");
        }

        return _transaction.execute(sql, arguments)
                .then((_) async {
            _addTables(tables);
            return;
        });
    }


    Future<int> rawInsert(Set<String> tables, String sql, [List arguments]) {
        if (_briteDatabase._logging) {
            _briteDatabase.log("RAW_INSERT\n  tables: $tables\n  sql: ${BriteDatabase.indentSql(sql)}\n  args: $arguments");
        }

        return _transaction.rawInsert(sql, arguments)
                .then((rowId) async {
            if (rowId != -1) {
                _addTables(tables);
            }
            return rowId;
        });
    }


    Future<int> rawDelete(Set<String> tables, String sql, [List arguments]) {
        if (_briteDatabase._logging) {
            _briteDatabase.log("RAW_DELETE\n  tables: $tables\n  sql: ${BriteDatabase.indentSql(sql)}\n  args: $arguments");
        }

        return _transaction.rawDelete(sql, arguments)
                .then((rows) async {
            if (rows > 0) {
                _addTables(tables);
            }
            return rows;
        });
    }


    Future<int> rawUpdate(Set<String> tables, String sql, [List arguments]) {
        if (_briteDatabase._logging) {
            _briteDatabase.log("RAW_UPDATE\n  tables: $tables\n  sql: ${BriteDatabase.indentSql(sql)}\n  args: $arguments");
        }

        return _transaction.rawUpdate(sql, arguments)
                .then((rows) async {
            if (rows > 0) {
                _addTables(tables);
            }
            return rows;
        });
    }


    Future<List<Map<String, dynamic>>> rawQuery(String sql, [List arguments]) {
        if (_briteDatabase._logging) {
            _briteDatabase.log("RAW_QUERY\n  sql: ${BriteDatabase.indentSql(sql)}\n  args: $arguments");
        }

        return _transaction.rawQuery(sql, arguments);
    }
}