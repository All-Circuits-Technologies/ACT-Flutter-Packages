// Copyright (c) 2020. BMS Circuits

import 'package:act_intl/src/utils/intl_file_utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';

/// The widget loads and display an asset file which contains translated text
///
/// The [textPath] given is the raw path without the language tag. Thanks to the
/// [context], the method will get the current language and try to load the file
/// with the right translation.
class TranslatedHtmlText extends StatefulWidget {
  final String textPath;
  final AlignmentGeometry alignment;

  /// Horizontal padding around the widget
  final double horizontalPadding;

  /// html body tag font size
  final FontSize bodyFontSize;

  /// html p tag font size
  final FontSize pFontSize;

  /// Default constructor
  ///
  /// [textPath] is an absolute path to the file
  TranslatedHtmlText({
    Key key,
    @required this.textPath,
    this.alignment = Alignment.center,
    this.horizontalPadding = 0,
    this.bodyFontSize,
    this.pFontSize,
  })  : assert(textPath != null),
        super(key: key);

  @override
  State createState() => _TranslatedHtmlTextState();
}

class _TranslatedHtmlTextState extends State<TranslatedHtmlText> {
  ScrollController _scrollController;

  /// The text got from file and already translated
  String _txtTranslated;
  bool _first;

  @override
  void initState() {
    _first = true;
    _scrollController = ScrollController();

    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load the translated text file to display in the page
  Future<void> loadTxtFile(BuildContext context) async {
    final translated = await IntlFileUtility.loadTransAssetFileText(
      context,
      widget.textPath,
    );

    if (mounted) {
      setState(() {
        _txtTranslated = translated;
      });
    } else {
      _txtTranslated = translated;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_first) {
      _first = false;
      loadTxtFile(context);
    }

    // TODO(brolandeau): The text scaling problem and the right overflow is currently fixing
    // TODO(brolandeau): in the flutter_html package: https://github.com/Sub6Resources/flutter_html/issues/308

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding,
      ),
      alignment: widget.alignment,
      child: (_txtTranslated == null)
          ? CircularProgressIndicator()
          : CupertinoScrollbar(
              controller: _scrollController,
              isAlwaysShown: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Html(
                  data: _txtTranslated,
                  style: {
                    "body": Style(
                      fontSize: widget.bodyFontSize,
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.all(0),
                      margin: EdgeInsets.all(0),
                    ),
                    "p": Style(
                      fontSize: widget.pFontSize,
                    ),
                  },
                ),
              ),
            ),
    );
  }
}
