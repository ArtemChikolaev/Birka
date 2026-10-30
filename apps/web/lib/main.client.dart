import 'package:birka_web/main.client.options.dart';
import 'package:jaspr/client.dart';

void main() {
  Jaspr.initializeApp(options: defaultClientOptions);
  runApp(const ClientApp());
}
