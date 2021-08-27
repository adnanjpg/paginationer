/// when you want the next page
/// to load.
///
/// [ItemBased] seems better in all ways than
/// [ScrollBased], so we deprecated [ScrollBased],
/// and may it completely in the future if it does
/// not prove any benefit.
enum PaginationerType {
  /// The paginationer will load the next page when the user scrolls to the
  /// [maxScrollExtent] * [loadOn]
  @deprecated
  ScrollBased,

  /// The paginationer will load the next page when the user scrolls to the
  /// [loadOn]'th item
  ItemBased,
}
