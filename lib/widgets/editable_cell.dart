import 'package:flutter/material.dart';

class EditableCell extends StatefulWidget {
  const EditableCell({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 120,
    this.textAlign = TextAlign.left,
    this.readOnly = false,
    this.isRequired = false,
    this.hasError = false,
    this.errorMessage,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final double width;
  final TextAlign textAlign;
  final bool readOnly;
  final bool isRequired;
  final bool hasError;
  final String? errorMessage;

  @override
  State<EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<EditableCell> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant EditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focusNode.hasFocus) return;
    _syncControllerText();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _syncControllerText();
    }
  }

  void _syncControllerText() {
    if (widget.value == _controller.text) return;
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invalid =
        widget.hasError ||
        (widget.isRequired && _controller.text.trim().isEmpty);

    final field = SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: widget.readOnly,
        textAlign: widget.textAlign,
        style: TextStyle(
          fontSize: 13,
          fontWeight: widget.readOnly ? FontWeight.w700 : FontWeight.w500,
          color: widget.readOnly
              ? const Color(0xFF334155)
              : const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 9,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: invalid
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFE1E7EF),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: invalid
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFE1E7EF),
            ),
          ),
        ),
        onChanged: widget.readOnly
            ? null
            : (value) {
                setState(() {});
                widget.onChanged(value);
              },
      ),
    );

    if (!invalid || widget.errorMessage == null) return field;

    return Tooltip(message: widget.errorMessage!, child: field);
  }
}
