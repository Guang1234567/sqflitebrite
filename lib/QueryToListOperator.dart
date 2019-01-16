part of sqflitebrite;

class QueryToListOperator<T> extends StreamTransformerBase<Query, List<T>> {

    MapperFunction<T> _mapper;

    QueryToListOperator(this._mapper);

    @override
    Stream<List<T>> bind(Stream<Query> upstream) async* {
        await for (final q in upstream) {
            List<Map<String, dynamic>> items = await q.run();
            List<T> result = [];
            if (items != null) {
                items.forEach((item) {
                    if (item != null) {
                        result.add(_mapper(item));
                    }
                });
            }
            yield result;
        }
    }
}