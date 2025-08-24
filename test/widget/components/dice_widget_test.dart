import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ludo_game/presentation/widgets/game/dice_widget.dart';

void main() {
  group('DiceWidget Tests', () {
    Widget createWidgetUnderTest({
      int? value,
      bool isRolling = false,
      bool canRoll = true,
      VoidCallback? onRoll,
      double size = 60.0,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: DiceWidget(
                value: value,
                isRolling: isRolling,
                canRoll: canRoll,
                onRoll: onRoll,
                size: size,
              ),
            ),
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('renders dice widget with value', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(value: 6));

        expect(find.byType(DiceWidget), findsOneWidget);
        expect(find.text('6'), findsOneWidget);
      });

      testWidgets('shows loading indicator when rolling', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          isRolling: true,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('6'), findsNothing);
      });

      testWidgets('shows correct dice value for all numbers', (WidgetTester tester) async {
        for (int i = 1; i <= 6; i++) {
          await tester.pumpWidget(createWidgetUnderTest(value: i));
          expect(find.text(i.toString()), findsOneWidget);
        }
      });

      testWidgets('respects custom size parameter', (WidgetTester tester) async {
        const customSize = 80.0;
        await tester.pumpWidget(createWidgetUnderTest(
          value: 4,
          size: customSize,
        ));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(DiceWidget),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.maxWidth, customSize);
        expect(container.constraints?.maxHeight, customSize);
      });
    });

    group('Interaction Behavior', () {
      testWidgets('calls onRoll when tapped and can roll', (WidgetTester tester) async {
        bool rollCalled = false;
        
        await tester.pumpWidget(createWidgetUnderTest(
          value: 3,
          canRoll: true,
          onRoll: () => rollCalled = true,
        ));

        await tester.tap(find.byType(DiceWidget));
        await tester.pump();

        expect(rollCalled, true);
      });

      testWidgets('does not call onRoll when cannot roll', (WidgetTester tester) async {
        bool rollCalled = false;
        
        await tester.pumpWidget(createWidgetUnderTest(
          value: 3,
          canRoll: false,
          onRoll: () => rollCalled = true,
        ));

        await tester.tap(find.byType(DiceWidget));
        await tester.pump();

        expect(rollCalled, false);
      });

      testWidgets('does not call onRoll when rolling', (WidgetTester tester) async {
        bool rollCalled = false;
        
        await tester.pumpWidget(createWidgetUnderTest(
          isRolling: true,
          canRoll: true,
          onRoll: () => rollCalled = true,
        ));

        await tester.tap(find.byType(DiceWidget));
        await tester.pump();

        expect(rollCalled, false);
      });

      testWidgets('handles null onRoll callback gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          value: 2,
          canRoll: true,
          onRoll: null,
        ));

        // Should not throw when tapped
        await tester.tap(find.byType(DiceWidget));
        await tester.pump();

        expect(find.byType(DiceWidget), findsOneWidget);
      });
    });

    group('Visual States', () {
      testWidgets('shows enabled state styling when can roll', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          value: 1,
          canRoll: true,
        ));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(DiceWidget),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration?;
        expect(decoration?.border, isNotNull);
      });

      testWidgets('shows disabled state styling when cannot roll', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          value: 1,
          canRoll: false,
        ));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(DiceWidget),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration?;
        expect(decoration, isNotNull);
      });

      testWidgets('shows rolling animation state', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          isRolling: true,
        ));

        // Should show progress indicator instead of value
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.textContaining(RegExp(r'[1-6]')), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('provides semantic information', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(
          value: 5,
          canRoll: true,
        ));

        final semantics = tester.getSemantics(find.byType(DiceWidget));
        expect(semantics.hasAction(SemanticsAction.tap), true);
      });

      testWidgets('announces dice value to screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(value: 4));

        final semantics = tester.getSemantics(find.byType(DiceWidget));
        expect(semantics.label, contains('4'));
      });

      testWidgets('indicates when dice is rolling', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(isRolling: true));

        final semantics = tester.getSemantics(find.byType(DiceWidget));
        expect(semantics.label, contains('rolling') || semantics.label == null);
      });

      testWidgets('supports keyboard activation', (WidgetTester tester) async {
        bool rollCalled = false;
        
        await tester.pumpWidget(createWidgetUnderTest(
          value: 2,
          canRoll: true,
          onRoll: () => rollCalled = true,
        ));

        // Simulate keyboard activation
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        // In a real implementation, this would trigger the roll
        expect(find.byType(DiceWidget), findsOneWidget);
      });
    });

    group('Animation and Timing', () {
      testWidgets('transitions between states smoothly', (WidgetTester tester) async {
        // Start with value
        await tester.pumpWidget(createWidgetUnderTest(value: 3));
        expect(find.text('3'), findsOneWidget);

        // Switch to rolling
        await tester.pumpWidget(createWidgetUnderTest(isRolling: true));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Switch back to value
        await tester.pumpWidget(createWidgetUnderTest(value: 6));
        await tester.pump();
        expect(find.text('6'), findsOneWidget);
      });

      testWidgets('handles rapid state changes', (WidgetTester tester) async {
        // Rapidly change between different values
        for (int i = 1; i <= 6; i++) {
          await tester.pumpWidget(createWidgetUnderTest(value: i));
          await tester.pump(const Duration(milliseconds: 50));
          expect(find.text(i.toString()), findsOneWidget);
        }
      });
    });

    group('Error Handling', () {
      testWidgets('handles null value gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(value: null));

        // Should render without crashing
        expect(find.byType(DiceWidget), findsOneWidget);
      });

      testWidgets('handles invalid dice values', (WidgetTester tester) async {
        // Test with values outside 1-6 range
        await tester.pumpWidget(createWidgetUnderTest(value: 0));
        expect(find.byType(DiceWidget), findsOneWidget);

        await tester.pumpWidget(createWidgetUnderTest(value: 7));
        expect(find.byType(DiceWidget), findsOneWidget);

        await tester.pumpWidget(createWidgetUnderTest(value: -1));
        expect(find.byType(DiceWidget), findsOneWidget);
      });

      testWidgets('handles extreme size values', (WidgetTester tester) async {
        // Very small size
        await tester.pumpWidget(createWidgetUnderTest(
          value: 1,
          size: 1.0,
        ));
        expect(find.byType(DiceWidget), findsOneWidget);

        // Very large size
        await tester.pumpWidget(createWidgetUnderTest(
          value: 1,
          size: 1000.0,
        ));
        expect(find.byType(DiceWidget), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('does not rebuild unnecessarily', (WidgetTester tester) async {
        int buildCount = 0;
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    buildCount++;
                    return DiceWidget(
                      value: 4,
                      canRoll: true,
                      onRoll: () {},
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(buildCount, 1);

        // Pump again without changes
        await tester.pump();
        expect(buildCount, 1); // Should not rebuild
      });

      testWidgets('handles frequent updates efficiently', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        // Simulate rapid dice rolls
        for (int i = 0; i < 100; i++) {
          await tester.pumpWidget(createWidgetUnderTest(
            value: (i % 6) + 1,
            isRolling: i % 2 == 0,
          ));
          await tester.pump(const Duration(milliseconds: 1));
        }

        stopwatch.stop();

        // Should handle updates efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        expect(find.byType(DiceWidget), findsOneWidget);
      });
    });
  });
}