import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgechef/models/recipe.dart';
import 'package:fridgechef/screens/home_screen.dart';
import 'package:fridgechef/screens/onboarding_screen.dart';
import 'package:fridgechef/screens/recipes_screen.dart';
import 'package:fridgechef/services/matcher.dart';
import 'package:fridgechef/state/app_state.dart';

AppState _stateWithRecipes() {
  final state = AppState();
  state.recipes = [
    const Recipe(
      id: 'dal-tadka',
      name: 'Dal Tadka',
      cuisine: 'North Indian',
      veg: true,
      prepMinutes: 10,
      cookMinutes: 25,
      difficulty: 'Easy',
      ingredients: [
        RecipeIngredient(name: 'toor dal', quantity: '1 cup'),
        RecipeIngredient(name: 'onion', quantity: '1'),
        RecipeIngredient(name: 'salt', quantity: 'to taste'),
      ],
      steps: ['Cook the dal.', 'Serve hot.'],
    ),
    const Recipe(
      id: 'egg-curry',
      name: 'Egg Curry',
      cuisine: 'North Indian',
      veg: false,
      prepMinutes: 10,
      cookMinutes: 25,
      difficulty: 'Easy',
      ingredients: [
        RecipeIngredient(name: 'egg', quantity: '4'),
        RecipeIngredient(name: 'onion', quantity: '2'),
        RecipeIngredient(name: 'salt', quantity: 'to taste'),
      ],
      steps: ['Boil the eggs.', 'Make the curry.'],
    ),
  ];
  state.recipesLoaded = true;
  return state;
}

void main() {
  testWidgets('onboarding explains both ways to add ingredients',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(onDone: () {}),
      ),
    );
    expect(find.text('FridgeChef'), findsOneWidget);
    expect(find.textContaining('Photograph your fridge'), findsOneWidget);
    expect(find.textContaining('Tick what you have'), findsOneWidget);
    expect(find.text('Start cooking'), findsOneWidget);
  });

  testWidgets('home screen shows fridge tab first and recipes tab lists '
      'recipes with match percentages', (tester) async {
    final state = _stateWithRecipes();
    state.addIngredients(['toor dal', 'onion']);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(state: state)),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Fridge'), findsWidgets);
    expect(find.textContaining('Toor Dal'), findsOneWidget);

    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();

    expect(find.text('Dal Tadka'), findsOneWidget);
    expect(find.text('Egg Curry'), findsOneWidget);
    // Dal Tadka: user has toor dal + onion = 100%; Egg Curry: 1 of 2 = 50%.
    expect(find.text('100% match'), findsOneWidget);
    expect(find.text('50% match'), findsOneWidget);
    expect(find.textContaining('Missing: egg'), findsOneWidget);
  });

  testWidgets('recipes screen search filters by name', (tester) async {
    final state = _stateWithRecipes();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RecipesScreen(state: state))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dal Tadka'), findsOneWidget);
    expect(find.text('Egg Curry'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'egg');
    await tester.pumpAndSettle();

    expect(find.text('Dal Tadka'), findsNothing);
    expect(find.text('Egg Curry'), findsOneWidget);
  });

  testWidgets('recipes screen veg filter hides non-veg recipes',
      (tester) async {
    final state = _stateWithRecipes();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RecipesScreen(state: state))),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<VegFilter>),
        matching: find.text('Veg'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dal Tadka'), findsOneWidget);
    expect(find.text('Egg Curry'), findsNothing);
  });
}
