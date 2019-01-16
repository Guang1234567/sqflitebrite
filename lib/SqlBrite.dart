part of sqflitebrite;

typedef T MapperFunction<T>(Map<String, dynamic> cursor);

class SqlBrite {
    static const Logger DEFAULT_LOGGER = Logger.defaultLogger();

    static const StreamTransformer<Query, Query> DEFAULT_QUERY_TRANSFORMER = const DefaultQueryTransformer();

    static BriteDatabase wrapDatabaseHelper(Database database,
                                            {Logger logger = DEFAULT_LOGGER, StreamTransformer<Query,
                                                    Query> queryTransformer = DEFAULT_QUERY_TRANSFORMER}) {
        return new BriteDatabase(database, DEFAULT_LOGGER, DEFAULT_QUERY_TRANSFORMER);
    }
}

abstract class Query {

    static StreamTransformer<Query, T> mapToOne<T>(MapperFunction<T> mapper) {
        return new QueryToOneOperator<T>(mapper, null);
    }

    static StreamTransformer<Query, T> mapToOneOrDefault<T>(MapperFunction<T> mapper, T defaultValue) {
        return new QueryToOneOperator<T>(mapper, defaultValue);
    }

    static StreamTransformer<Query, List<T>> mapToList<T>(MapperFunction<T> mapper) {
        return new QueryToListOperator<T>(mapper);
    }

    static StreamTransformer<Query, Optional<T>> mapToOptional<T>(MapperFunction<T> mapper) {
        return new QueryToOptionalOperator<T>(mapper);
    }

    static StreamTransformer<Query, T> asRows<T>(MapperFunction<T> mapper) {
        return new AsRowsOperator<T>(mapper);
    }

    Future<List<Map<String, dynamic>>> run();

    ///Limiting results or filtering will almost always be faster in the database as part of a query and should be preferred, where possible.
    ///
    /// {@code
    ///
    /// asyncExpand(q -> q.asRowsStream(Item.MAPPER).take(5).toList())
    ///
    /// or...
    ///
    /// asyncExpand(q -> q.asRowsStream(Item.MAPPER).filter(i -> i.isActive).toList())
    ///
    /// }
    Stream<T> asRowsStream<T>(MapperFunction<T> mapper) {
        return Stream.fromIterable([this]).transform(asRows(mapper));
    }
}

class DefaultQueryTransformer extends StreamTransformerBase<Query, Query> {

    const DefaultQueryTransformer();

    @override
    Stream<Query> bind(Stream<Query> upstream) {
        return upstream;
    }
}

abstract class Logger {
    void log(String message);

    const factory Logger.defaultLogger() = PrintLogger;
}

class PrintLogger implements Logger {

    const PrintLogger();

    @override
    void log(String message) {
        print("SqlBrite / " + message);
    }
}