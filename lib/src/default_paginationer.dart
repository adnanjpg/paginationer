import 'package:flutter/material.dart';
import 'package:paginationer/src/extensions.dart';
import 'paginationer_type.dart';

///
/// The `future` parameter is simply a method that
/// gives you the current page and expects you to
/// send request and parse data into a
/// `List<Widget>` and return it;
///
/// {@template adam_flutter.paginationer.description}
/// The `emptyChildren` should be filled with
/// widgets that you want to appear when
/// there is not any data yet, or after
/// scrolling it will be added to the bottom
/// of the list until new data comes in;
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
/// {@endtemplate}
class Paginationer extends StatefulWidget {
  const Paginationer({
    required this.emptyChildren,
    required this.future,
    this.initialWidgets,
    this.paginationed = true,
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.loadOn,
    this.key,
    this.controller,
    this.primary,
    // keep it this way for now, to not break anything.
    this.type = PaginationerType.ScrollBased,
  }) : assert(type == PaginationerType.ScrollBased
            ? (loadOn == null || loadOn >= 0.0 && loadOn <= 1.0)
            : true);

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
  /// if (type == PaginationerType.ScrollBased),
  /// the `loadOn` parameter indicates in what percentage
  /// of the screen the load will be triggered.
  /// {@endtemplate}
  ///
  ///
  /// the value should be
  /// between 0.0 and 1.0. default is 0.8.
  final double? loadOn;

  /// wether to run the [future] methods,
  /// on reaching the scroll bound.
  final bool paginationed;

  final bool reverse;

  final bool shrinkWrap;

  final Key? key;

  final PaginationerType type;

  final bool? primary;

  @override
  State<Paginationer> createState() {
    if (type == PaginationerType.ScrollBased) {
      return _ScrollBased();
    } else {
      return _ItemBased();
    }
  }
}

bool _isNotEmpty(List? list) {
  return list != null && list.length > 0;
}

class _ScrollBased extends State<Paginationer> {
  bool get hasChildren {
    return _isNotEmpty(children);
  }

  bool get hasInitialChildren {
    return _isNotEmpty(widget.initialWidgets);
  }

  bool get allEmpty => !hasChildren && !hasInitialChildren;

  bool isLoading = false;
  bool hasLoadingItems = false;

  late bool noMoreData;
  late ScrollController controller;
  late int currentPage;

  List<Widget>? children = [];

  // manages adding and removing loading widgets.
  void load({required VoidCallback onEmpty}) async {
    if (isLoading == true) return;

    if (!hasLoadingItems) {
      // add loading widgets to the tree
      children?.addAll(widget.emptyChildren);
      hasLoadingItems = true;
    }

    await safeSetState(() {});

    isLoading = true;

    final futureResult = (await widget.future(currentPage));

    isLoading = false;

    if (children?.isNotEmpty == true && hasLoadingItems) {
      // remove loading widgets.
      children!.removeRange(
        children!.length - widget.emptyChildren.length,
        children!.length,
      );
      hasLoadingItems = false;
    }

    if (_isNotEmpty(futureResult)) {
      children?.addAll(futureResult);
      currentPage++;
    } else {
      onEmpty();
    }

    await safeSetState(() {});
  }

  /// loads more data;
  Future loadMore() async {
    if (noMoreData == false && // if data is ended
            isLoading == false && // if currently loading other data
            (controller.offset >=
                controller.position.maxScrollExtent * (widget.loadOn ?? .8))
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
    final List<Widget>? widgets = allEmpty
        ? [Container()]
        : [
            if (hasInitialChildren) ...widget.initialWidgets!,
            if (hasChildren) ...children!,
          ];
    if (widgets == null) return Container();
    return ListView.builder(
      reverse: widget.reverse,
      // force if parent is a scrollable widget.
      shrinkWrap: widget.controller != null || widget.shrinkWrap,
      // assert(!(controller != null && primary == true)
      primary: widget.primary ?? false,
      key: widget.key,
      itemCount: widgets.length,
      scrollDirection: widget.scrollDirection,
      itemBuilder: (context, index) {
        return widgets.elementAt(index);
      },
      // do not have a controller if parent does.
      controller: widget.controller == null ? controller : null,
    );
  }
}

class _ItemBased extends State<Paginationer> {
  bool get hasChildren {
    return _isNotEmpty(children);
  }

  bool get hasInitialChildren {
    return _isNotEmpty(widget.initialWidgets);
  }

  bool get allEmpty => !hasChildren && !hasInitialChildren;

  bool isLoading = false;
  bool hasLoadingItems = false;

  late bool noMoreData;
  late int currentPage;

  List<Widget>? children = [];

  // manages adding and removing loading widgets.
  void load({required VoidCallback onEmpty}) async {
    if (isLoading == true) return;

    if (!hasLoadingItems) {
      // add loading widgets to the tree
      children?.addAll(widget.emptyChildren);
      hasLoadingItems = true;
    }

    await safeSetState(() {});

    isLoading = true;

    final futureResult = (await widget.future(currentPage));

    isLoading = false;

    if (children?.isNotEmpty == true && hasLoadingItems) {
      // remove loading widgets.
      children!.removeRange(
        children!.length - widget.emptyChildren.length,
        children!.length,
      );
      hasLoadingItems = false;
    }

    if (_isNotEmpty(futureResult)) {
      children?.addAll(futureResult);
      currentPage++;
    } else {
      onEmpty();
    }

    await safeSetState(() {});
  }

  /// loads more data;
  Future loadMore() async {
    if (noMoreData == false && // if data is ended
            isLoading == false // if currently loading other data

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
    noMoreData = !widget.paginationed;

    currentPage = 1;

    if (hasInitialChildren) {
      children = [];
      currentPage++;
    }

    initializeData();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget>? widgets = allEmpty
        ? [Container()]
        : [
            if (hasInitialChildren) ...widget.initialWidgets!,
            if (hasChildren) ...children!,
          ];
    if (widgets == null) return Container();
    return ListView.builder(
      reverse: widget.reverse,
      // force if parent is a scrollable widget.
      shrinkWrap: widget.controller != null || widget.shrinkWrap,
      key: widget.key,
      primary: widget.primary,
      itemCount: widgets.length,
      scrollDirection: widget.scrollDirection,
      itemBuilder: (context, index) {
        if (index == widgets.length - 1) {
          loadMore();
        }
        return widgets.elementAt(index);
      },
    );
  }
}
