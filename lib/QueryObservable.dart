part of sqflitebrite;

class QueryObservable extends Observable<Query> {

    static final QueryObservable Function(Observable<Query> upstream) QUERY_OBSERVABLE = (upstream) {
        return new QueryObservable(upstream);
    };

    QueryObservable(Stream<Query> upstream) : super(upstream);

    Observable<T> mapToOne<T>(MapperFunction<T> mapper) {
        return this.transform(Query.mapToOne(mapper));
    }

    Observable<T> mapToOneOrDefault<T>(MapperFunction<T> mapper, T defaultValue) {
        return this.transform(Query.mapToOneOrDefault(mapper, defaultValue));
    }

    Observable<List<T>> mapToList<T>(MapperFunction<T> mapper) {
        return this.transform(Query.mapToList(mapper));
    }

    Observable<Optional<T>> mapToOptional<T>(MapperFunction<T> mapper) {
        return this.transform(Query.mapToOptional(mapper));
    }

    Observable<T> asRows<T>(MapperFunction<T> mapper) {
        return this.transform(Query.asRows(mapper));
    }
}