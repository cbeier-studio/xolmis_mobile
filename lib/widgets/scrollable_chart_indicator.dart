import 'package:flutter/material.dart';

class ScrollableChartIndicator extends StatefulWidget {
  final Widget child;

  const ScrollableChartIndicator({super.key, required this.child});

  @override
  State<ScrollableChartIndicator> createState() => _ScrollableChartIndicatorState();
}

class _ScrollableChartIndicatorState extends State<ScrollableChartIndicator> {
  late final ScrollController _scrollController;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_checkScrollability);
    // Verifica o estado inicial após a renderização
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollability());
  }

  void _checkScrollability() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    setState(() {
      _canScrollLeft = currentScroll > 5;
      _canScrollRight = currentScroll < maxScroll - 5 && maxScroll > 0;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollability);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Injeta o ScrollController no gráfico
        PrimaryScrollController(
          controller: _scrollController,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _checkScrollability();
              return false;
            },
            child: widget.child,
          ),
        ),

        // Indicador de rolagem para a esquerda
        if (_canScrollLeft)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).cardColor.withValues(alpha: 0.9),
                      Theme.of(context).cardColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: const Icon(Icons.chevron_left, size: 20, color: Colors.grey),
              ),
            ),
          ),

        // Indicador de rolagem para a direita
        if (_canScrollRight)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).cardColor.withValues(alpha: 0.0),
                      Theme.of(context).cardColor.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }
}
