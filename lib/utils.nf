// lib/utils.nf
def sortByID(ch) {
    return ch
        .map { meta, f -> tuple(meta.id, f) }
        .toSortedList { a, b -> a[0] <=> b[0] }
        .map { pairs -> pairs.collect { it[1] } }
}
