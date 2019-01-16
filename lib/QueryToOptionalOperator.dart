part of sqflitebrite;

class QueryToOptionalOperator<T> extends StreamTransformerBase<Query, Optional<T>> {

    MapperFunction<T> _mapper;

    QueryToOptionalOperator(this._mapper);

    @override
    Stream<Optional<T>> bind(Stream<Query> upstream) async* {
        await for (final q in upstream) {
            List<Map<String, dynamic>> items = await q.run();
            for (final item in items) {
                if (item != null) {
                    yield Optional.fromNullable(_mapper(item));
                }
            }
        }
    }
}