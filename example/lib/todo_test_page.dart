import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflitebrite/sqflitebrite.dart';

import 'test_page.dart';

final String tableTodo = "todo";
final String columnId = "_id";
final String columnTitle = "title";
final String columnDone = "done";

class Todo {
    Todo();

    Todo.fromMap(Map map) {
        id = map[columnId] as int;
        title = map[columnTitle] as String;
        done = map[columnDone] == 1;
    }

    int id;
    String title;
    bool done;

    Map<String, dynamic> toMap() {
        var map = <String, dynamic>{
            columnTitle: title,
            columnDone: done == true ? 1 : 0
        };
        if (id != null) {
            map[columnId] = id;
        }
        return map;
    }
}

class TodoProvider {
    Database db;

    Future open(String path) async {
        db = await openDatabase(path, version: 1,
                                        onCreate: (Database db, int version) async {
                                            await db.execute('''
create table $tableTodo ( 
  $columnId integer primary key autoincrement, 
  $columnTitle text not null,
  $columnDone integer not null)
''');
                                        });
    }

    Future<Todo> insert(Todo todo) async {
        todo.id = await db.insert(tableTodo, todo.toMap());
        return todo;
    }

    Future<Todo> insertBrite(BriteDatabase db, Todo todo) async {
        todo.id = await db.insert(tableTodo, todo.toMap());
        return todo;
    }

    Future<Todo> insertBriteTranscation(BriteTransaction txn, Todo todo) async {
        todo.id = await txn.insert(tableTodo, todo.toMap());
        return todo;
    }

    Future<Todo> getTodo(int id) async {
        List<Map> maps = await db.query(tableTodo,
                                                columns: [columnId, columnDone, columnTitle],
                                                where: "$columnId = ?",
                                                whereArgs: [id]);
        if (maps.length > 0) {
            return Todo.fromMap(maps.first);
        }
        return null;
    }

    Future<int> delete(int id) async {
        return await db.delete(tableTodo, where: "$columnId = ?", whereArgs: [id]);
    }

    Future<int> update(Todo todo) async {
        return await db.update(tableTodo, todo.toMap(),
                                       where: "$columnId = ?", whereArgs: [todo.id]);
    }

    Future close() async => db.close();
}

class TodoTestPage extends TestPage {
    TodoTestPage() : super("Todo example") {
        test("open", () async {
            // await Sqflite.devSetDebugModeOn(true);
            String path = await initDeleteDb("simple_todo_open.db");
            TodoProvider todoProvider = TodoProvider();
            await todoProvider.open(path);

            await todoProvider.close();
            //await Sqflite.setDebugModeOn(false);
        });

        test("insert/query/update/delete", () async {
            // await Sqflite.devSetDebugModeOn();
            String path = await initDeleteDb("simple_todo.db");
            TodoProvider todoProvider = TodoProvider();
            await todoProvider.open(path);

            Todo todo = Todo()
                ..title = "test";
            await todoProvider.insert(todo);
            expect(todo.id, 1);

            expect(await todoProvider.getTodo(0), null);
            todo = await todoProvider.getTodo(1);
            expect(todo.id, 1);
            expect(todo.title, "test");
            expect(todo.done, false);

            todo.done = true;
            expect(await todoProvider.update(todo), 1);
            todo = await todoProvider.getTodo(1);
            expect(todo.id, 1);
            expect(todo.title, "test");
            expect(todo.done, true);

            expect(await todoProvider.delete(0), 0);
            expect(await todoProvider.delete(1), 1);
            expect(await todoProvider.getTodo(1), null);

            await todoProvider.close();
            //await Sqflite.setDebugModeOn(false);
        });


        //  如何写单元测试: https://github.com/dart-lang/test/blob/master/pkgs/test/README.md


        test("sqlbrite_createQuery", () async {
            String path = await initDeleteDb("simple_todo_sqlbrite.db");
            TodoProvider todoProvider = TodoProvider();
            await todoProvider.open(path);

            Todo todo = Todo()
                ..title = "test";
            Database db = todoProvider.db;
            BriteDatabase briteDb = SqlBrite.wrapDatabaseHelper(db).setLoggingEnabled(true);


            briteDb.createQuery(
                    tables: [tableTodo],
                    sql: "SELECT * FROM $tableTodo WHERE $columnId=?",
                    args: [1])
                    .mapToOne((cursor) {
                return Todo.fromMap(cursor);
            }).listen((item) async {
                await briteDb.close();
                expect(item.id, 1);
            }, onError: (e) {

            }, onDone: () async {
                await briteDb.close();
            });

            await todoProvider.insertBrite(briteDb, todo);
            expect(todo.id, 1);
        });

        test("sqlbrite_createQuery_2", () async {
            String path = await initDeleteDb("simple_todo_sqlbrite_createQuery_2.db");
            TodoProvider todoProvider = TodoProvider();
            await todoProvider.open(path);

            Database db = todoProvider.db;
            BriteDatabase briteDb = SqlBrite.wrapDatabaseHelper(db).setLoggingEnabled(true);


            int fiveInsert = 5;
            int counter = 0;
            QueryObservable queryobj = briteDb.createQuery(
                    tables: [tableTodo],
                    sql: "SELECT * FROM $tableTodo");

            Observable<Todo> singleTodoObj = queryobj.mapToOne((cursor) {
                return Todo.fromMap(cursor);
            }).share();

            singleTodoObj.listen((item) async {
                counter++;
                if (counter == fiveInsert + 1) {
                    await briteDb.close();
                    expect(fiveInsert + 1, counter); // + 1的原因, createQuery 创建的事件源在被订阅时,会发出一个事件.
                }
            }, onDone: () async {
                await briteDb.close();
            });

            for (int i = 0; i < fiveInsert; i++) {
                Todo todo = Todo()
                    ..title = "test_$i";
                await todoProvider.insertBrite(briteDb, todo);
            }
        });

        test("sqlbrite_transaction", () async {
            String path = await initDeleteDb("simple_todo_sqlbrite_transaction.db");
            TodoProvider todoProvider = TodoProvider();
            await todoProvider.open(path);

            Database db = todoProvider.db;
            BriteDatabase briteDb = SqlBrite.wrapDatabaseHelper(db).setLoggingEnabled(true);


            int fiveInsert = 5;
            int counter = 0;
            QueryObservable queryobj = briteDb.createQuery(
                    tables: [tableTodo],
                    sql: "SELECT * FROM $tableTodo");

            Observable<Todo> singleTodoObj = queryobj.mapToOne((cursor) {
                return Todo.fromMap(cursor);
            }).share();

            singleTodoObj.listen((item) async {
                counter++;
                if (counter == 1 + 1) {
                    print("onData: briteDb.close()");
                    await briteDb.close();
                    expect(1 + 1, counter); // + 1的原因, createQuery 创建的事件源在被订阅时,会发出一个事件.
                }
            }, onDone: () async {
                print("onDone: briteDb.close()");
                await briteDb.close();
            });


            briteDb.transaction((txn) async {
                List<Todo> result = [];
                for (int i = 0; i < fiveInsert; i++) {
                    Todo todo = Todo()
                        ..title = "test_$i";
                    result.add(await todoProvider.insertBriteTranscation(txn, todo));
                }
                return result;
            });
        });

        test("sqlbrite_nest_transaction", () async {
            String path = await initDeleteDb("simple_todo_sqlbrite_nest_transaction.db");
            TodoProvider todoProvider = TodoProvider();
            await todoProvider.open(path);

            Database db = todoProvider.db;
            BriteDatabase briteDb = SqlBrite.wrapDatabaseHelper(db).setLoggingEnabled(true);


            int fiveInsert = 5;
            int counter = 0;
            QueryObservable queryobj = briteDb.createQuery(
                    tables: [tableTodo],
                    sql: "SELECT * FROM $tableTodo WHERE $columnTitle='test_nest_transaction'");

            Observable<Todo> singleTodoObj = queryobj.mapToOne((cursor) {
                return Todo.fromMap(cursor);
            }).share();

            singleTodoObj.listen((item) async {
                expect(item.title, "test_nest_transaction");

                counter++;
                if (counter == 1 + 1) {
                    await briteDb.close();
                }
            }, onDone: () async {
                await briteDb.close();
            });


            await briteDb.transaction((txn) async {
                List<Todo> result = [];

                Todo todo = Todo()
                    ..title = "test_outter_transaction";
                await todoProvider.insertBriteTranscation(txn, todo);

                // support nest transaction
                await briteDb.transaction((txn) async {
                    Todo todo = Todo()
                        ..title = "test_nest_transaction";
                    result.add(await todoProvider.insertBriteTranscation(txn, todo));
                });


                return result;
            });
        });
    }
}
