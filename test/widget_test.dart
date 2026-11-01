import 'package:flutter_test/flutter_test.dart';
import 'package:towlink_app/main.dart';

void main() {
  testWidgets('TowLink Ghana booking screen loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TowLinkApp());

    // Verify the app branding is displayed.
    expect(find.text('TowLink Ghana'), findsOneWidget);

    // Verify the booking screen is displayed.
    expect(find.text('Request a tow truck'), findsOneWidget);
    expect(find.text('Your full name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Pickup location'), findsOneWidget);
    expect(find.text('Destination (optional)'), findsOneWidget);
    expect(find.text('Vehicle type'), findsOneWidget);
    expect(find.text('Describe the vehicle problem'), findsOneWidget);

    // Verify the customer can submit a towing request.
    expect(find.text('Request Tow Truck'), findsOneWidget);
  });
}
