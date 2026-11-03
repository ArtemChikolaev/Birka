/// [text] as a search compares it: trimmed, in lower case and with ё as е,
/// so that neither case nor ё decides what is found.
String searchKey(String text) => text.trim().toLowerCase().replaceAll('ё', 'е');
