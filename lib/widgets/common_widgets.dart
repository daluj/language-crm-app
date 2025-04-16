import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Section header with optional action button
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final IconData? actionIcon;

  const SectionHeader({
    required this.title,
    this.onActionPressed,
    this.actionLabel,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onActionPressed != null)
            TextButton.icon(
              onPressed: onActionPressed,
              icon: Icon(actionIcon ?? Icons.add),
              label: Text(actionLabel ?? 'Add'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }
}

// Stat card for dashboard
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = color ?? primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 6), // Reduced padding
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8), // Smaller radius
                  ),
                  child: Icon(icon, color: cardColor, size: isSmallScreen ? 16 : 20), // Smaller icon
                ),
                SizedBox(width: isSmallScreen ? 4 : 6), // Smaller spacing
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: isSmallScreen ? 11 : null, // Smaller font
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 4 : 8), // Reduced spacing
            Flexible( // Make this flexible to prevent overflow
              child: Container(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 16 : 20, // Smaller font size
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Empty state placeholder
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyStateWidget({
    required this.message,
    this.icon = Icons.info_outline,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              if (onActionPressed != null) ...[  
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onActionPressed,
                  child: Text(actionLabel ?? 'Add New'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Status badge
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        break;
      case 'pending':
      case 'scheduled':
        backgroundColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        break;
      case 'cancelled':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 4 : 6,
        horizontal: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// Search field with clear button
class SearchField extends StatefulWidget {
  final String hint;
  final Function(String) onChanged;
  final TextEditingController? controller;

  const SearchField({
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  @override
  _SearchFieldState createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
      ),
      onChanged: widget.onChanged,
    );
  }
}

// Customizable date picker field
class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate == null
              ? 'Select date'
              : DateFormat('MMM d, yyyy').format(selectedDate!),
        ),
      ),
    );
  }
}

// Custom dropdown field
class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;
  final String hint;

  const CustomDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Select an option',
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label),
      hint: Text(hint),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}

// Confirmation dialog
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  return result ?? false;
}