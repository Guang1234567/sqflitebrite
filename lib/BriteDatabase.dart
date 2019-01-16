part of sqflitebrite;

class BriteDatabase {
    final Database _database;

    final Logger _logger;

    final StreamTransformer<Query, Query> _queryTransformer;

    final Subject<Set<String>> _triggers = new PublishSubject();

    BriteTransaction _topTransaction;

    bool _logging = false;

    BriteDatabase(this._database, this._logger, this._queryTransformer);

    Future<void> close() {
        return _database.close();
    }

    BriteDatabase _sendTableTrigger(Set<String> tables) {
        if (_logging) {
            log("TRIGGER ${tables.toString()}");
        }
        _triggers.add(tables);
        return this;
    }

    BriteDatabase setLoggingEnabled(bool enabled) {
        _logging = enabled;
        return this;
    }

    BriteDatabase log(String message) {
        _logger.log(message);
        return this;
    }

    static String indentSql(String sql) {
        return sql.replaceAll("\n", "\n       ");
    }

    static String conflictString(ConflictAlgorithm conflictAlgorithm) {
        switch (conflictAlgorithm) {
            case ConflictAlgorithm.abort:
                return "abort";
            case ConflictAlgorithm.fail:
                return "fail";
            case ConflictAlgorithm.ignore:
                return "ignore";
            case ConflictAlgorithm.replace:
                return "replace";
            case ConflictAlgorithm.rollback:
                return "rollback";
            default:
                return "none";
        }
    }

    Future<T> _doBriteTransaction<T>(Transaction txn, Future<T> action(BriteTransaction briteTransaction)) async {
        BriteTransaction bt = beginBriteTransaction(txn);
        T result;
        try {
            result = await action(bt);
            bt._markSuccessful();
        } finally {
            endBriteTransaction();
        }
        return result;
    }

    Future<T> _supportNestedTranscation<T>(Future<T> action(BriteTransaction briteTransaction), {bool exclusive}) async {
        return await _doBriteTransaction(_topTransaction._transaction, action);
    }

    Future<T> transaction<T>(Future<T> action(BriteTransaction briteTransaction), {bool exclusive}) {
        if (_topTransaction != null) {
            /*throw new StateError("Cannot create nest transaction in transaction. "
                                         + "Use query() for a query inside a transaction.");*/
            return _supportNestedTranscation(action, exclusive: exclusive);
        }

        return _database.transaction((txn) async {
            return await _doBriteTransaction(txn, action);
        }, exclusive: exclusive);
    }

    BriteTransaction beginBriteTransaction(Transaction txn) {
        BriteTransaction bt = new BriteTransaction._(txn, _topTransaction, this);
        _topTransaction = bt;
        if (_logging) {
            log("TXN BEGIN ${bt.toString()}");
        }
        return bt._onBegin();
    }

    BriteTransaction endBriteTransaction() {
        BriteTransaction bt = _topTransaction;
        if (bt == null) {
            throw new StateError("Not in transaction.");
        }

        BriteTransaction newTop = bt._parent;
        _topTransaction = newTop;
        if (_logging) {
            log("TXN END ${bt.toString()}");
        }
        if (bt._isSuccessfull && _topTransaction == null) {
            _sendTableTrigger(bt._getTables());
        }
        return bt._onEnd();
    }

    BriteBatch batch() {
        return new _BriteDatabaseBatch(this, _database.batch());
    }

    void _ensureNotInTransaction() {
        if (_topTransaction != null) {
            throw new StateError("Cannot subscribe to observable query in a transaction.");
        }
    }

    QueryObservable _createQuery(_DatabaseQuery query) {
        if (_topTransaction != null) {
            throw new StateError("Cannot create observable query in transaction. "
                                         + "Use query() for a query inside a transaction.");
        }

        Observable<Query> ob = _triggers
                .where(query.test) // DatabaseQuery filters triggers to on tables we care about.
                .map(query.convert) // DatabaseQuery maps to itself to save an allocation.
                .startWith(query) //
        //.observeOn(scheduler)
                .transform(_queryTransformer) // Apply the user's query transformer.
                .doOnListen(_ensureNotInTransaction);
        //.doOnSubscribe(ensureNotInTransaction)
        //.to(QueryObservable.QUERY_OBSERVABLE);

        return QueryObservable.QUERY_OBSERVABLE(ob);
    }

    QueryObservable createQuery({String table = "", Iterable<String> tables = const[], String sql = "", List<dynamic> args = const[]}) {
        if (table != null && table.isEmpty) {
            tables = tables.toSet()
                ..add(table);
        }
        return _createQuery(new _DatabaseQuery(this, tables, sql, args));
    }

    Future<int> insert(String table, Map<String, dynamic> values, {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) {
        if (_logging) {
            log("INSERT\n  table: $table\n  values: $values\n  nullColumnHack: $nullColumnHack\n  conflictAlgorithm: ${BriteDatabase.conflictString(
                    conflictAlgorithm)}");
        }

        return _database.insert(table, values, nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm)
                .then((rowId) async {
            if (rowId != -1) {
                _sendTableTrigger(new Set()..add(table));
            }
            return rowId;
        });
    }

    Future<int> delete(String table, {String where, List whereArgs}) {
        if (_logging) {
            log("DELETE\n  table: $table\n  whereClause: $where\n  whereArgs: $whereArgs");
        }

        return _database.delete(table, where: where, whereArgs: whereArgs)
                .then((rows) async {
            if (rows > 0) {
                _sendTableTrigger(new Set()..add(table));
            }
            return rows;
        });
    }

    Future<int> update(String table, Map<String, dynamic> values, {String where, List whereArgs, ConflictAlgorithm conflictAlgorithm}) {
        if (_logging) {
            log(
                    "UPDATE\n  table: $table\n  values: $values\n  whereClause: $where\n  whereArgs: $whereArgs\n  conflictAlgorithm: ${BriteDatabase
                            .conflictString(conflictAlgorithm)}");
        }

        return _database.update(table, values, where: where, whereArgs: whereArgs, conflictAlgorithm: conflictAlgorithm)
                .then((rows) async {
            if (rows > 0) {
                _sendTableTrigger(new Set()..add(table));
            }
            return rows;
        });
    }

    Future<List<Map<String, dynamic>>> query(String table, {bool distinct, List<
            String> columns, String where, List whereArgs, String groupBy, String having, String orderBy, int limit, int offset}) {
        if (_logging) {
            log(
                    "QUERY\n  table: $table\n  distinct: $distinct\n  columns: $columns\n  whereClause: $where\n  whereArgs: $whereArgs\n  groupBy: $groupBy\n  having: $having\n  orderBy: $orderBy\n  limit: $limit\n  offset: $offset\n");
        }

        return _database.query(
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
        if (_logging) {
            log("EXECUTE\n  tables: $tables\n  sql: ${BriteDatabase.indentSql(sql)}\n  args: $arguments");
        }

        return _database.execute(sql, arguments)
                .then((_) async {
            _sendTableTrigger(tables);
            return;
        });
    }

    @override
    Future<int> rawInsert(Set<String> tables, String sql, [List arguments]) {
        if (_logging) {
            log("RAW_INSERT\n  tables: $tables\n  sql: ${BriteDatabase.indentSql(sql)}\n  args: $arguments");
        }

        return _database.rawInsert(sql, arguments)
                .then((rowId) async {
            if (rowId != -1) {
                _sendTableTrigger(tables);
            }
            return rowId;
        });
    }

    @override
    Future<int> rawDelete(Set<String> tables, String sql, [List arguments]) {
        if (_logging) {
            log("RAW_DELETE\n  tables: $tables\n  sql: ${BriteDatabase.indentSql(sql)}\n  args: $arguments");
        }

        return _database.rawDelete(sql, arguments)
                .then((rows) async {
            if (rows > 0) {
                _sendTableTrigger(tables);
            }
            return rows;
        });
    }

    @override
    Future<int> rawUpdate(Set<String> tables, String sql, [List arguments]) {
        if (_logging) {
            log("RAW_UPDATE\n  tables: $tables\n  sql: ${BriteDatabase.indentSql(sql)}\n  args: $arguments");
        }

        return _database.rawUpdate(sql, arguments)
                .then((rows) async {
            if (rows > 0) {
                _sendTableTrigger(tables);
            }
            return rows;
        });
    }

    @override
    Future<List<Map<String, dynamic>>> rawQuery(String sql, [List arguments]) {
        if (_logging) {
            log("RAW_QUERY\n  sql: ${BriteDatabase.indentSql(sql)}\n  args: $arguments");
        }

        return _database.rawQuery(sql, arguments);
    }
}


class _DatabaseQuery extends Query {

    final BriteDatabase _briteDatabase;

    final Iterable<String> _tables;

    final String _sql;

    final List<dynamic> _arguments;

    _DatabaseQuery(this._briteDatabase, this._tables, this._sql,
                   [this._arguments]);

    @override
    Future<List<Map<String, dynamic>>> run() {
        if (_briteDatabase._topTransaction != null) {
            throw new StateError("Cannot execute observable query in a transaction.");
        }

        if (_briteDatabase._logging) {
            _briteDatabase.log("CREATE_QUERY\n  tables: $_tables\n  sql: ${BriteDatabase.indentSql(_sql)}\n  args: $_arguments");
        }

        Future<List<Map<String, dynamic>>> cursor = _briteDatabase.rawQuery(_sql, _arguments);

        return cursor;
    }

    bool test(Set<String> tables) {
        for (String table in _tables) {
            if (tables.contains(table)) {
                return true;
            }
        }
        return false;
    }

    Query convert(Set<String> tables) {
        return this;
    }
}