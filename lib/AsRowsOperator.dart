part of sqflitebrite;

class AsRowsOperator<T> extends StreamTransformerBase<Query, T> {

    MapperFunction<T> _mapper;

    AsRowsOperator(this._mapper);

    @override
    Stream<T> bind(Stream<Query> upstream) async* {
        await for (final q in upstream) {
            List<Map<String, dynamic>> items = await q.run();
            for (final item in items) {
                if (item != null) {
                    yield _mapper(item);
                }
            }
        }
    }
}