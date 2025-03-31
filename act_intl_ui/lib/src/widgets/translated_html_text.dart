// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_intl/act_intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// The widget loads and display an asset file which contains translated text
///
/// The [textPath] given is the raw path without the language tag. Thanks to the
/// context, the method will get the current language and try to load the file
/// with the right translation.
class TranslatedHtmlText extends StatefulWidget {
  /// This is the path of the HTML text to translate
  final String textPath;

  /// This is the alignment of the translated HTML text
  final AlignmentGeometry alignment;

  /// Horizontal padding around the widget
  final double horizontalPadding;

  /// html body tag font size
  final FontSize? bodyFontSize;

  /// html p tag font size
  final FontSize? pFontSize;

  /// Default constructor
  ///
  /// [textPath] is an absolute path to the file
  const TranslatedHtmlText({
    super.key,
    required this.textPath,
    this.alignment = Alignment.center,
    this.horizontalPadding = 0,
    this.bodyFontSize,
    this.pFontSize,
  });

  @override
  State createState() => _TranslatedHtmlTextState();
}

/// This is the state of [TranslatedHtmlText]
class _TranslatedHtmlTextState extends State<TranslatedHtmlText> {
  /// The text retrieved from file and already translated
  late ScrollController _scrollController;

  /// This is used to load the text at the first build
  late bool _first;

  /// This is the retrieved translated text
  String? _txtTranslated;

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
        ) ??
        "Cannot find a proper translation";

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
      unawaited(loadTxtFile(context));
    }

    /* TODO(brolandeau): The text scaling problem and the right overflow is currently fixing
                         in the flutter_html package:
                         https://github.com/Sub6Resources/flutter_html/issues/308
     */

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding,
      ),
      alignment: widget.alignment,
      child: (_txtTranslated == null)
          ? const CircularProgressIndicator()
          : CupertinoScrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Html(
                  data: _txtTranslated,
                  style: {
                    "body": Style(
                      fontSize: widget.bodyFontSize,
                      width:
                          Width(MediaQuery.of(context).size.width - (widget.horizontalPadding * 2)),
                      padding: HtmlPaddings.zero,
                      margin: Margins.zero,
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
