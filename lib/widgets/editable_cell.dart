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
  TextEditingController? _controller;
  FocusNode? _focusNode;
  String _editStartValue = '';
  bool _editing = false;

  @override
  void didUpdateWidget(covariant EditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing || _controller == null || _focusNode?.hasFocus == true) {
      return;
    }
    _syncControllerText();
  }

  @override
  void dispose() {
    _disposeEditor();
    super.dispose();
  }

  void _beginEditing() {
    if (widget.readOnly || _editing) return;

    _editStartValue = widget.value;
    final controller = TextEditingController(text: widget.value);
    final focusNode = FocusNode();
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    focusNode.addListener(_handleFocusChanged);
    _controller = controller;
    _focusNode = focusNode;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) _focusNode?.requestFocus();
    });
  }

  void _handleFocusChanged() {
    if (_editing && _focusNode?.hasFocus == false) {
      _commit();
    }
  }

  void _syncControllerText() {
    final controller = _controller;
    if (controller == null || widget.value == controller.text) return;
    controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  void _commit() {
    if (!_editing) return;
    final value = _controller?.text ?? _editStartValue;
    final changed = value != _editStartValue;
    _disposeEditor();
    if (mounted) setState(() => _editing = false);
    if (changed) widget.onChanged(value);
  }

  void _disposeEditor() {
    _focusNode?.removeListener(_handleFocusChanged);
    _focusNode?.dispose();
    _controller?.dispose();
    _focusNode = null;
    _controller = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      final invalid =
          widget.hasError ||
          (widget.isRequired && widget.value.trim().isEmpty);
      final display = SizedBox(
        width: widget.width,
        height: 38,
        child: InkWell(
          onTap: widget.readOnly ? null : _beginEditing,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            alignment: widget.textAlign == TextAlign.right
                ? Alignment.centerRight
                : widget.textAlign == TextAlign.center
                ? Alignment.center
                : Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              color: widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
              border: Border.all(
                color: invalid
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFE1E7EF),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: widget.textAlign,
              style: TextStyle(
                fontSize: 13,
                fontWeight: widget.readOnly
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: widget.readOnly
                    ? const Color(0xFF334155)
                    : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      );

      if (!invalid || widget.errorMessage == null) return display;
      return Tooltip(message: widget.errorMessage!, child: display);
    }

    final invalid =
        widget.hasError ||
        (widget.isRequired && (_controller?.text.trim().isEmpty ?? true));

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
        onSubmitted: widget.readOnly ? null : (_) => _commit(),
      ),
    );

    if (!invalid || widget.errorMessage == null) return field;

    return Tooltip(message: widget.errorMessage!, child: field);
  }
}
