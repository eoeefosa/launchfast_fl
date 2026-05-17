import 'package:flutter/material.dart';
import 'package:campuschow/models/menu_item.dart';
import 'package:campuschow/widgets/home/menu_grouped_list.dart';

/// Fades the menu list in whenever the widget is first inserted (i.e. when
/// the store or category changes and this widget is re-keyed by the parent).
class AnimatedMenuList extends StatefulWidget {
  const AnimatedMenuList({
    super.key,
    required this.groupedItems,
    required this.accentColor,
    required this.onAdd,
    this.emptyMessage,
  });

  final Map<String, List<MenuItem>> groupedItems;
  final Color accentColor;
  final void Function(MenuItem) onAdd;
  final String? emptyMessage;

  @override
  State<AnimatedMenuList> createState() => _AnimatedMenuListState();
}

class _AnimatedMenuListState extends State<AnimatedMenuList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SliverFadeTransition is the sliver-aware equivalent of FadeTransition.
    // Using Opacity or FadeTransition here would require a RenderBox child.
    return SliverFadeTransition(
      opacity: _opacity,
      sliver: MenuGroupedList(
        groupedItems: widget.groupedItems,
        accentColor: widget.accentColor,
        onAdd: widget.onAdd,
        emptyMessage: widget.emptyMessage,
      ),
    );
  }
}
