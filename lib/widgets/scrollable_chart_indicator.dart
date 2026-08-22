import 'package:flutter/material.dart';

class ScrollableChartIndicator extends StatefulWidget {
  final Widget Function(BuildContext context, ScrollController controller) builder;

  const ScrollableChartIndicator({super.key, required this.builder});

  @override
  State<ScrollableChartIndicator> createState() => _ScrollableChartIndicatorState();
}

class _ScrollableChartIndicatorState extends State<ScrollableChartIndicator> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollability);
    // Agenda a verificação após a montagem completa da árvore de layout do gráfico
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollability());
  }

  void _checkScrollability() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    // Atualiza apenas se houver mudança de estado para evitar re-renders desnecessários
    final canLeft = currentScroll > 5;
    final canRight = currentScroll < maxScroll - 5 && maxScroll > 0;

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollability);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkScrollability();
        return false;
      },
      child: Stack(
        children: [
          // Constrói a árvore passando o controller configurado
          widget.builder(context, _scrollController),

          // Seta para Esquerda
          if (_canScrollLeft)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).cardColor.withValues(alpha: 0.95),
                        Theme.of(context).cardColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.chevron_left, size: 22, color: Colors.grey),
                ),
              ),
            ),

          // Seta para Direita
          if (_canScrollRight)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).cardColor.withValues(alpha: 0.0),
                        Theme.of(context).cardColor.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
