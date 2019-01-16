# sqflitebrite

**sqlfiltebrite** is a dart lang implement of [square/sqlbrite](https://github.com/square/sqlbrite) that base on [tekartik/sqflite](https://github.com/tekartik/sqflite).

## Getting Started

1) Read the [sqflite's ReadMe](https://github.com/tekartik/sqflite)

2) Read the [sqlbrite's ReadMe](https://github.com/square/sqlbrite)

3) See [example](https://github.com/Guang1234567/sqflitebrite/blob/cb5819934eab1a1354e8be8c5817ad2badf2c41c/example/lib/todo_test_page.dart#L140-L297).

   
## different point

**sqlfiltebrite**  support **`nested transation`** that not supported by [tekartik/sqflite (Issue#146)](https://github.com/tekartik/sqflite/issues/146#issuecomment-454585698).

**`nested transation`** in **sqlfiltebrite** is a **simulation of the nest transaction** that not a real one.

How works? See Example.
