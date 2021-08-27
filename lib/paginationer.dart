import 'package:flutter/material.dart';

/// The `emptyChildren` should be filled with
/// widgets that you want to appear when
/// there is not any data yet, or after
/// scrolling it will be added to the bottom
/// of the list until new data comes in;
///
/// The `future` parameter is simply a method that
/// gives you the current page and expects you to
/// send request and parse data into a
/// `List<Widget>` and return it;
///
/// The `paginationed` parameter
/// will be used in case some widget
/// is used twice, but one of them
/// is not paginationed. _for example
/// one in the main screen and the
/// other in some list screen_;
///
/// {@macro adam_flutter.paginationer.load_on}
///
/// pass your scroll controller in [controller]
/// argument to achieve pagination with
/// un-paginated above it.
/// example:
/// ```dart
/// ScrollController controller = ScrollController();
/// @override
/// Widget build(BuildContext context) {
///   return SingleChildScrollView(
///     controller: controller,
///     child: Column(
///       children: [
///         SomeWidget(),
///         Paginationer(
///           controller: controller,
///         ),
///       ],
///     ),
///   );
/// }
/// @override
/// void dispose() {
///  controller.dispose();
///  super.dispose();
/// }
/// ```
///
class Paginationer extends StatefulWidget {
  const Paginationer({
    required this.emptyChildren,
    required this.future,
    this.initialWidgets,
    this.paginationed = true,
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.loadOn = 0.8,
    this.key,
    this.controller,
  }) : assert(loadOn >= 0.0 && loadOn <= 1.0);

  /// will be inserted to the tree when
  /// we start loading, and will be removed
  /// when we finish loading.
  final List<Widget> emptyChildren;

  /// pre loaded widgets that will show above the
  /// Future data.
  ///
  /// NOTE: when you pass this variable,
  /// the current page will start from 2.
  final List<Widget>? initialWidgets;

  final Future<List<Widget>> Function(int currentPage) future;

  final Axis scrollDirection;

  /// if passed, the scroll control
  /// will be from parent, and thus
  /// load with un-paginated Widget
  /// above it.
  final ScrollController? controller;

  /// {@template adam_flutter.paginationer.load_on}
  /// the `loadOn` parameter indicates in what percentage
  /// of the screen the load will be triggered.
  /// {@endtemplate}
  ///
  /// between 0.0 and 1.0. default is 0.8.
  final double loadOn;

  /// wether to run the [future] methods,
  /// on reaching the scroll bound.
  final bool paginationed;

  final bool reverse;

  final bool shrinkWrap;

  final Key? key;
  @override
  _PaginationerState createState() => _PaginationerState();
}

class _PaginationerState extends State<Paginationer> {
  bool isNotEmpty(List? list) {
    return list != null && list.length > 0;
  }

  bool get hasChildren {
    return isNotEmpty(children);
  }

  bool get hasInitialChildren {
    return isNotEmpty(widget.initialWidgets);
  }

  bool get allEmpty => !hasChildren && !hasInitialChildren;

  bool isLoading = false;

  late bool noMoreData;
  late ScrollController controller;
  late int currentPage;

  List<Widget>? children = [];

  // manages adding and removing loading widgets.
  void load({required VoidCallback onEmpty}) async {
    // add loading widgets to the tree
    children?.addAll(widget.emptyChildren);

    // save current widget list size,
    // before adding more widgets.
    // this will be used later to remove
    // loading widgets.
    final childrenSize = children!.length;

    if (mounted) setState(() {});

    isLoading = true;

    final futureResult = (await widget.future(currentPage));

    if (isNotEmpty(futureResult)) {
      children?.addAll(futureResult);
      currentPage++;
    } else {
      onEmpty();
    }

    isLoading = false;

    // remove loading widgets.
    children?.removeRange(
        childrenSize - (widget.emptyChildren.length), childrenSize);

    if (mounted) setState(() {});
  }

  /// loads more data;
  Future loadMore() async {
    if (noMoreData == false && // if data is ended
            isLoading == false && // if currently loading other data
            (controller.offset >=
                controller.position.maxScrollExtent * widget.loadOn)
            // if we reached the `loadOn` percentage of the screen
            &&
            !controller.position.outOfRange // if we are not out of range

        ) {
      load(
        onEmpty: () {
          noMoreData = true;
        },
      );
    }
  }

  /// initializes data for the first load;
  initializeData() async {
    load(
      onEmpty: () {
        if (!hasInitialChildren) {
          children = null;
        }
      },
    );
  }

  @override
  void initState() {
    controller = widget.controller ?? ScrollController();

    noMoreData = !widget.paginationed;

    currentPage = 1;

    controller.addListener(loadMore);

    if (hasInitialChildren) {
      children = [];
      currentPage++;
    }

    initializeData();

    super.initState();
  }

  @override
  void dispose() {
    // do not dispose a controller
    // passed as an argument, or
    // it would result in chaotic
    // stuff!!
    if (widget.controller == null) controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget>? _e = allEmpty
        ? [Container()]
        : [
            if (hasInitialChildren) ...widget.initialWidgets!,
            if (hasChildren) ...children!,
          ];
    if (_e == null) return Container();
    return ListView.builder(
      reverse: widget.reverse,
      // force if parent is a scrollable widget.
      shrinkWrap: widget.controller != null || widget.shrinkWrap,
      // assert(!(controller != null && primary == true)
      primary: false,
      key: widget.key,
      itemCount: _e.length,
      scrollDirection: widget.scrollDirection,
      itemBuilder: (context, d) {
        return _e.elementAt(d);
      },
      // do not have a controller if parent does.
      controller: widget.controller == null ? controller : null,
    );
  }
}
