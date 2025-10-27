import 'package:flutter/material.dart';

class CategoryCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final Function(String) onCategorySelected;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.name,
    required this.icon,
    required this.onCategorySelected,
    this.isSelected = false,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(CategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      setState(() {
        _isSelected = widget.isSelected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onCategorySelected(widget.name);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: _isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 32,
              color: _isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              widget.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
