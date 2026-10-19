/// Strips embedded CSS and decodes HTML entities from WooCommerce / supplier HTML.
abstract final class ProductContentSanitizer {
  static final RegExp _styleTag =
      RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false);
  static final RegExp _scriptTag =
      RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false);
  static final RegExp _htmlComment = RegExp(r'<!--[\s\S]*?-->');
  static final RegExp _inlineStyle =
      RegExp(r'\sstyle="[^"]*"', caseSensitive: false);
  static final RegExp _detailDecorateBlock = RegExp(
    r'#detail_decorate_root[\s\S]*?(?=(?:<[/a-zA-Z])|$)',
    caseSensitive: false,
  );
  static final RegExp _cssRuleBlock = RegExp(
    r'(?:[#.][\w-]+(?:\s+|[,>+~]\s*)?)+\{[^{}]*\}',
    dotAll: true,
  );
  static final RegExp _braceBlock = RegExp(r'\{[^{}]*\}', dotAll: true);
  static final RegExp _cssPropertyLine = RegExp(
    r'^\s*[\w-]+\s*:\s*[^;\n]+;\s*$',
    multiLine: true,
  );

  static String decodeEntities(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }

  static String sanitizePlainText(String text) {
    return decodeEntities(text).trim();
  }

  static String sanitizeHtml(String html) {
    if (html.isEmpty) return html;

    var s = decodeEntities(html);
    s = s.replaceAll(_styleTag, '');
    s = s.replaceAll(_scriptTag, '');
    s = s.replaceAll(_htmlComment, '');
    s = s.replaceAll(_inlineStyle, '');
    s = s.replaceAll(_detailDecorateBlock, '');
    s = _stripCssRuleBlocks(s);
    s = s.replaceAll(_cssPropertyLine, '');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  static String _stripCssRuleBlocks(String input) {
    var s = input;

    for (var pass = 0; pass < 8; pass++) {
      final before = s;
      s = s.replaceAll(_cssRuleBlock, '');
      s = s.replaceAllMapped(_braceBlock, (match) {
        final inner = match.group(0)!;
        final body = inner.substring(1, inner.length - 1);
        return _looksLikeCssBlock(body) ? '' : match.group(0)!;
      });
      if (s == before) break;
    }

    return s;
  }

  static bool _looksLikeCssBlock(String inner) {
    final trimmed = inner.trim();
    if (trimmed.isEmpty || !trimmed.contains(':')) return false;

    final declarations =
        trimmed.split(';').where((part) => part.trim().contains(':')).toList();
    if (declarations.isEmpty) return false;

    if (declarations.length >= 2 && trimmed.contains(';')) return true;

    return RegExp(
      r'\b(?:font-family|font-size|font-weight|margin|padding|border|display|width|height|color|background|line-height|box-sizing|overflow|position|top|left|right|bottom)\s*:',
      caseSensitive: false,
    ).hasMatch(trimmed);
  }
}
