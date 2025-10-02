import 'package:flutter_test/flutter_test.dart';
import 'package:records/main.dart';

void main() {
 testWidgets('Splash screen shows brand title', (tester) async {
   await tester.pumpWidget(const RecordsApp());

   // Initial frame renders SplashScreen with "Records" title
   expect(find.text('Records'), findsOneWidget);

   // Let animations run a bit
   await tester.pump(const Duration(milliseconds: 500));
   expect(find.text('Records'), findsOneWidget);
 });
}
