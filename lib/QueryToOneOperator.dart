part of sqflitebrite;

class QueryToOneOperator<T> extends StreamTransformerBase<Query, T> {

    MapperFunction<T> _mapper;

    T _defaultValue;

    QueryToOneOperator(this._mapper, this._defaultValue);

    @override
    Stream<T> bind(Stream<Query> upstream) async* {
        await for (final q in upstream) {
            List<Map<String, dynamic>> items = await q.run();
            if (items != null && items.isNotEmpty) {
                if (items.first != null) {
                    yield _mapper(items.first);
                } else {
                    yield _defaultValue;
                }
            } else {
                yield _defaultValue;
            }
        }
    }
}