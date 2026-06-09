import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/all.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/entities/code_file.dart';

class CodeEditorView extends StatefulWidget {
  final CodeFile file;
  final ValueChanged<String> onChanged;

  const CodeEditorView({
    super.key,
    required this.file,
    required this.onChanged,
  });

  @override
  State<CodeEditorView> createState() => _CodeEditorViewState();
}

class _CodeEditorViewState extends State<CodeEditorView> {
  late CodeLineEditingController _controller;
  late CodeScrollController _scrollController;
  bool _showLineNumbers = true;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.file.content);
    _scrollController = CodeScrollController();
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(CodeEditorView old) {
    super.didUpdateWidget(old);
    if (old.file.id != widget.file.id) {
      _controller.removeListener(_onChanged);
      _controller.dispose();
      _controller = CodeLineEditingController.fromText(widget.file.content);
      _controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    widget.onChanged(_controller.text);
  }

  // Map FileLanguage → re_highlight mode
  dynamic _getHighlightMode() {
    switch (widget.file.language) {
      case FileLanguage.dart:        return builtinAllLanguages['dart'];
      case FileLanguage.python:      return builtinAllLanguages['python'];
      case FileLanguage.javascript:  return builtinAllLanguages['javascript'];
      case FileLanguage.typescript:  return builtinAllLanguages['typescript'];
      case FileLanguage.kotlin:      return builtinAllLanguages['kotlin'];
      case FileLanguage.swift:       return builtinAllLanguages['swift'];
      case FileLanguage.java:        return builtinAllLanguages['java'];
      case FileLanguage.cpp:         return builtinAllLanguages['cpp'];
      case FileLanguage.rust:        return builtinAllLanguages['rust'];
      case FileLanguage.go:          return builtinAllLanguages['go'];
      case FileLanguage.html:        return builtinAllLanguages['xml'];
      case FileLanguage.css:         return builtinAllLanguages['css'];
      case FileLanguage.json:        return builtinAllLanguages['json'];
      case FileLanguage.yaml:        return builtinAllLanguages['yaml'];
      case FileLanguage.bash:        return builtinAllLanguages['bash'];
      case FileLanguage.sql:         return builtinAllLanguages['sql'];
      default:                       return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlightMode = _getHighlightMode();

    return Container(
      color: AppColors.background,
      child: CodeEditor(
        controller: _controller,
        scrollController: _scrollController,
        style: CodeEditorStyle(
          fontSize:           AppTypography.code.fontSize ?? 14,
          fontFamily:         'JetBrainsMono',
          textColor:          AppColors.textPrimary,
          backgroundColor:    AppColors.background,
          selectionColor:     AppColors.primary.withOpacity(0.3),
          cursorColor:        AppColors.primary,
          lineNumberTextStyle: AppTypography.codeSmall.copyWith(
            color: AppColors.textDisabled,
          ),
          codeTheme: CodeHighlightTheme(
            languages: highlightMode != null
                ? {widget.file.language.name: CodeHighlightThemeMode(mode: highlightMode)}
                : {},
            theme: _acapCodeTheme,
          ),
        ),
        indicatorBuilder: _showLineNumbers
            ? (context, editingController, chunkController, notifier) {
                return Row(
                  children: [
                    DefaultCodeLineNumber(
                      controller: editingController,
                      notifier: notifier,
                      textStyle: AppTypography.codeSmall.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                    Container(
                      width: 1,
                      color: AppColors.outline,
                    ),
                  ],
                );
              }
            : null,
        gutterWidth:  _showLineNumbers ? 48 : 0,
        padding:      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hint:         const Text(''),
        shortcutsActivatorsBuilder: DefaultCodeShortcutsActivatorsBuilder(),
        shortcuts: [
          CodeShortcut(
            activators: [const SingleActivator(LogicalKeyboardKey.keyS, control: true)],
            handler: (controller) {
              // Save is handled by parent
              return false;
            },
          ),
        ],
      ),
    );
  }

  // ACAP syntax theme matching Material 3 dark design system
  static const _acapCodeTheme = {
    'root':     TextStyle(color: AppColors.textPrimary, backgroundColor: AppColors.background),
    'keyword':  TextStyle(color: AppColors.codeKeyword, fontWeight: FontWeight.w600),
    'string':   TextStyle(color: AppColors.codeString),
    'comment':  TextStyle(color: AppColors.codeComment, fontStyle: FontStyle.italic),
    'number':   TextStyle(color: AppColors.codeNumber),
    'function': TextStyle(color: AppColors.codeFunction),
    'class':    TextStyle(color: AppColors.codeType, fontWeight: FontWeight.w600),
    'type':     TextStyle(color: AppColors.codeType),
    'built_in': TextStyle(color: AppColors.tertiary),
    'literal':  TextStyle(color: AppColors.codeNumber),
    'meta':     TextStyle(color: AppColors.textSecondary),
    'tag':      TextStyle(color: AppColors.primary),
    'attr':     TextStyle(color: AppColors.codeFunction),
    'selector-id':    TextStyle(color: AppColors.codeType),
    'selector-class': TextStyle(color: AppColors.codeString),
  };
}
