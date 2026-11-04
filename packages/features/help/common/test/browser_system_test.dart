import 'package:help_common/help_common.dart';
import 'package:test/test.dart';

void main() {
  test('names the browser and the system', () {
    expect(
      browserSystem(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36',
      ),
      'Chrome 141 · macOS',
    );
    expect(
      browserSystem(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 '
        'Mobile/15E148 Safari/604.1',
      ),
      'Safari 26 · iOS 18',
    );
    expect(
      browserSystem(
        'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/113.0.5672.136 Mobile Safari/537.36',
      ),
      'Chrome 113 · Android 14',
    );
    expect(
      browserSystem(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:144.0) Gecko/20100101 '
        'Firefox/144.0',
      ),
      'Firefox 144 · Windows',
    );
  });

  test('tells Edge from the Chrome it is built on', () {
    expect(
      browserSystem(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0',
      ),
      'Edge 141 · Windows',
    );
  });

  test('says web when it knows nothing', () {
    expect(browserSystem(''), 'web');
  });
}
