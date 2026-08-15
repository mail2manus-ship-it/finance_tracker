import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_finance_tracker/presentation/widgets/common/amount_field.dart';

void main() {
  Widget wrap(TextEditingController controller, GlobalKey<FormState> formKey) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: AmountField(controller: controller, accentColor: Colors.red),
        ),
      ),
    );
  }

  testWidgets('shows the default currency symbol as a prefix', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(wrap(controller, formKey));

    expect(find.text('₹ '), findsOneWidget);
  });

  testWidgets('rejects more than 2 decimal places via input formatter', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(wrap(controller, formKey));

    await tester.enterText(find.byType(TextFormField), '12.999');
    await tester.pump();

    // The RegExp input formatter should truncate to 2 decimal places.
    expect(controller.text, '12.99');
  });

  testWidgets('validator fails on empty submit and passes with a valid amount', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(wrap(controller, formKey));

    expect(formKey.currentState!.validate(), isFalse);

    await tester.enterText(find.byType(TextFormField), '250');
    await tester.pump();

    expect(formKey.currentState!.validate(), isTrue);
  });
}
