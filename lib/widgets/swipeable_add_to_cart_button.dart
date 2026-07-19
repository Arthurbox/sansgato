import 'package:flutter/material.dart';

class SwipeableAddToCartButton extends StatefulWidget {
  final Future<bool> Function() onSwipe;
  final bool isDark;
  final bool isAdded;

  const SwipeableAddToCartButton({
    super.key,
    required this.onSwipe,
    this.isDark = false,
    this.isAdded = false,
  });

  @override
  State<SwipeableAddToCartButton> createState() => _SwipeableAddToCartButtonState();
}

class _SwipeableAddToCartButtonState extends State<SwipeableAddToCartButton> {
  double _swipePosition = 0.0;
  int _swipeState = 0; // 0: initial, 1: loading, 2: success

  @override
  void didUpdateWidget(SwipeableAddToCartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // On ne force plus l'état en fonction de isAdded
    // isAdded sert juste pour le style visuel
  }

  void _handleSwipe(DragUpdateDetails details, double maxWidth) {
    if (_swipeState != 0) return;
    setState(() {
      _swipePosition += details.delta.dx;
      if (_swipePosition < 0) _swipePosition = 0;
      if (_swipePosition > maxWidth - 44) _swipePosition = maxWidth - 44;
    });
  }

  void _handleSwipeEnd(DragEndDetails details, double maxWidth) async {
    if (_swipeState != 0) return;
    if (_swipePosition > (maxWidth - 44) * 0.6) {
      setState(() {
        _swipePosition = maxWidth - 44;
        _swipeState = 1;
      });
      final success = await widget.onSwipe();
      if (mounted) {
        if (success) {
          setState(() { _swipeState = 2; });
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              setState(() {
                _swipeState = 0;
                _swipePosition = 0;
              });
            }
          });
        } else {
          setState(() {
            _swipeState = 0;
            _swipePosition = 0;
          });
        }
      }
    } else {
      setState(() {
        _swipePosition = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isInitial = _swipeState == 0;
        final isLoading = _swipeState == 1;
        final isSuccess = _swipeState == 2;
        
        final buttonWidth = isInitial ? maxWidth : 44.0;
        final bgColorContainer = isSuccess 
            ? const Color(0xFF00A9C1) 
            : (widget.isDark ? Colors.grey.shade800 : Colors.grey.shade100);

        return Align(
          alignment: Alignment.centerRight,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: buttonWidth,
            height: 44,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: bgColorContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: isInitial 
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: _swipePosition + 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A9C1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                      OverflowBox(
                        maxWidth: maxWidth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: maxWidth < 130 ? 6 : 12),
                            Text(
                              maxWidth < 130 ? 'Ajouter' : 'Glisser pour ajouter',
                              style: TextStyle(
                                color: widget.isDark ? Colors.white : Colors.grey.shade800, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 10
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_double_arrow_right, color: widget.isDark ? Colors.white54 : Colors.grey.shade400, size: 14),
                          ],
                        ),
                      ),
                      Positioned(
                        left: _swipePosition,
                        child: GestureDetector(
                          onPanUpdate: (details) => _handleSwipe(details, maxWidth),
                          onPanEnd: (details) => _handleSwipeEnd(details, maxWidth),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: widget.isAdded ? const Color(0xFF00A9C1) : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(2, 0))
                              ]
                            ),
                            child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check, color: Colors.white, size: 24),
                  ),
          ),
        );
      },
    );
  }
}
