part of sqflitebrite;

abstract class BriteBatch {
    Future<List<dynamic>> commit({bool exclusive, bool noResult, bool continueOnError});

    void insert(String table, Map<String, dynamic> values,
                {String nullColumnHack, ConflictAlgorithm conflictAlgorithm});

    void delete(String table, {String where, List<dynamic> whereArgs});

    void update(String table, Map<String, dynamic> values,
                {String where,
                    List<dynamic> whereArgs,
                    ConflictAlgorithm conflictAlgorithm});

    void query(String table,
               {bool distinct,
                   List<String> columns,
                   String where,
                   List<dynamic> whereArgs,
                   String groupBy,
                   String having,
                   String orderBy,
                   int limit,
                   int offset});

    void execute(Set<String> tables, String sql, [List<dynamic> arguments]);

    void rawInsert(Set<String> tables, String sql, [List<dynamic> arguments]);

    void rawDelete(Set<String> tables, String sql, [List<dynamic> arguments]);

    void rawUpdate(Set<String> tables, String sql, [List<dynamic> arguments]);

    void rawQuery(Set<String> tables, String sql, [List<dynamic> arguments]);
}


class _BriteDatabaseBatch implements BriteBatch {
    final BriteDatabase _briteDatabase;

    final Batch _batch;

    final Set<String> _tables = new Set();

    _BriteDatabaseBatch(this._briteDatabase, this._batch);


    Future<List> commit({bool exclusive, bool noResult, bool continueOnError}) {
        return _batch.commit(exclusive: exclusive, noResult: noResult, continueOnError: continueOnError)
                .then((list) async {
            _briteDatabase._sendTableTrigger(_tables);
            return list;
        });
    }

    void insert(String table, Map<String, dynamic> values, {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) {
        _tables.add(table);
        _batch.insert(table, values, nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
    }

    void delete(String table, {String where, List whereArgs}) {
        _tables.add(table);
        return _batch.delete(table, where: where, whereArgs: whereArgs);
    }

    void update(String table, Map<String, dynamic>values, {String where, List whereArgs, ConflictAlgorithm conflictAlgorithm}) {
        _tables.add(table);
        _batch.update(table, values, where: where, whereArgs: whereArgs, conflictAlgorithm: conflictAlgorithm);
    }


    void query(String table, {bool distinct,
        List<String> columns, String where, List whereArgs, String groupBy, String having, String orderBy, int limit, int offset}) {
        _batch.query(table, distinct: distinct,
                             columns: columns,
                             where: where,
                             whereArgs: whereArgs,
                             groupBy: groupBy,
                             having: having,
                             orderBy: orderBy,
                             limit: limit,
                             offset: offset);
    }


    void execute(Set<String> tables, String sql, [List arguments]) {
        _tables.addAll(tables);
        _batch.execute(sql, arguments);
    }

    void rawDelete(Set<String> tables, String sql, [List arguments]) {
        _tables.addAll(tables);
        _batch.rawDelete(sql, arguments);
    }

    void rawInsert(Set<String> tables, String sql, [List arguments]) {
        _tables.addAll(tables);
        _batch.rawDelete(sql, arguments);
    }

    void rawQuery(Set<String> tables, String sql, [List arguments]) {
        _tables.addAll(tables);
        _batch.rawQuery(sql, arguments);
    }


    void rawUpdate(Set<String> tables, String sql, [List arguments]) {
        _tables.addAll(tables);
        _batch.rawUpdate(sql, arguments);
    }
}


class _BriteTransactionBatch implements BriteBatch {

    final BriteTransaction _transaction;

    final Batch _batch;

    _BriteTransactionBatch(this._transaction, this._batch);


    Future<List> commit({bool exclusive, bool noResult, bool continueOnError}) {
        return _batch.commit(exclusive: exclusive, noResult: noResult, continueOnError: continueOnError);
    }

    void insert(String table, Map<String, dynamic> values, {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) {
        _transaction._addTable(table);
        _batch.insert(table, values, nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
    }

    void delete(String table, {String where, List whereArgs}) {
        _transaction._addTable(table);
        return _batch.delete(table, where: where, whereArgs: whereArgs);
    }

    void update(String table, Map<String, dynamic>values, {String where, List whereArgs, ConflictAlgorithm conflictAlgorithm}) {
        _transaction._addTable(table);
        _batch.update(table, values, where: where, whereArgs: whereArgs, conflictAlgorithm: conflictAlgorithm);
    }


    void query(String table, {bool distinct,
        List<String> columns, String where, List whereArgs, String groupBy, String having, String orderBy, int limit, int offset}) {
        _batch.query(table, distinct: distinct,
                             columns: columns,
                             where: where,
                             whereArgs: whereArgs,
                             groupBy: groupBy,
                             having: having,
                             orderBy: orderBy,
                             limit: limit,
                             offset: offset);
    }


    void execute(Set<String> tables, String sql, [List arguments]) {
        _transaction._addTables(tables);
        _batch.execute(sql, arguments);
    }

    void rawDelete(Set<String> tables, String sql, [List arguments]) {
        _transaction._addTables(tables);
        _batch.rawDelete(sql, arguments);
    }

    void rawInsert(Set<String> tables, String sql, [List arguments]) {
        _transaction._addTables(tables);
        _batch.rawDelete(sql, arguments);
    }

    void rawQuery(Set<String> tables, String sql, [List arguments]) {
        _transaction._addTables(tables);
        _batch.rawQuery(sql, arguments);
    }


    void rawUpdate(Set<String> tables, String sql, [List arguments]) {
        _transaction._addTables(tables);
        _batch.rawUpdate(sql, arguments);
    }
}