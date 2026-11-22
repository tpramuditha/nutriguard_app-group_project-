import '../models/recipe_model.dart';

class RecipeCatalog {
  const RecipeCatalog._();

  // Initial local recipe catalog.
  //
  // Ingredient quantities are for the entire recipe.
  // Rice quantities refer to uncooked rice.
  //
  // Nutrition figures are illustrative estimates,
  // NOT medically validated values.
  // They should not be treated as precise nutrition data.

  static const List<RecipeModel> recipes = [
    RecipeModel(
      id: 'egg_fried_rice',
      name: 'Egg Fried Rice',
      description: 'A quick rice dish with eggs and vegetables.',
      preparationMinutes: 10,
      cookingMinutes: 15,
      servings: 2,
      calories: 420,
      protein: 15,
      carbs: 58,
      fat: 14,
      ingredients: [
        RecipeIngredient(name: 'Rice', quantity: 150, unit: 'g'),
        RecipeIngredient(name: 'Eggs', quantity: 2, unit: 'pcs'),
        RecipeIngredient(name: 'Carrots', quantity: 80, unit: 'g'),
        RecipeIngredient(name: 'Onions', quantity: 50, unit: 'g'),
        RecipeIngredient(name: 'Oil', quantity: 15, unit: 'ml'),
      ],
      instructions: [
        'Cook the rice according to package instructions.',
        'Wash and chop the carrots and onions.',
        'Heat oil in a pan and cook the vegetables.',
        'Add the eggs and cook until fully set.',
        'Add the cooked rice and stir everything together.',
        'Serve hot.',
      ],
    ),

    RecipeModel(
      id: 'vegetable_omelette',
      name: 'Vegetable Omelette',
      description: 'A simple omelette with fresh vegetables.',
      preparationMinutes: 5,
      cookingMinutes: 10,
      servings: 1,
      calories: 260,
      protein: 15,
      carbs: 8,
      fat: 19,
      ingredients: [
        RecipeIngredient(name: 'Eggs', quantity: 2, unit: 'pcs'),
        RecipeIngredient(name: 'Tomatoes', quantity: 60, unit: 'g'),
        RecipeIngredient(name: 'Onions', quantity: 40, unit: 'g'),
        RecipeIngredient(name: 'Oil', quantity: 10, unit: 'ml'),
      ],
      instructions: [
        'Wash and chop the tomatoes and onions.',
        'Crack the eggs into a bowl and beat well.',
        'Mix the vegetables into the eggs.',
        'Heat oil in a non-stick frying pan.',
        'Pour in the egg mixture.',
        'Cook until the eggs are fully set.',
        'Serve warm.',
      ],
    ),

    RecipeModel(
      id: 'rice_and_dhal',
      name: 'Rice and Dhal Curry',
      description: 'A simple rice meal with red lentil curry.',
      preparationMinutes: 10,
      cookingMinutes: 25,
      servings: 2,
      calories: 450,
      protein: 17,
      carbs: 78,
      fat: 8,
      ingredients: [
        RecipeIngredient(name: 'Rice', quantity: 150, unit: 'g'),
        RecipeIngredient(name: 'Red Lentils', quantity: 120, unit: 'g'),
        RecipeIngredient(name: 'Onions', quantity: 50, unit: 'g'),
        RecipeIngredient(name: 'Coconut Milk', quantity: 100, unit: 'ml'),
      ],
      instructions: [
        'Wash the rice and cook it according to '
            'package instructions.',
        'Rinse the red lentils thoroughly.',
        'Place lentils and chopped onions in a pot.',
        'Add enough water to cook the lentils.',
        'Simmer until the lentils are tender.',
        'Add coconut milk and continue cooking gently.',
        'Serve the dhal curry with the cooked rice.',
      ],
    ),

    RecipeModel(
      id: 'vegetable_stir_fry',
      name: 'Vegetable Stir-Fry',
      description: 'A colorful vegetable dish that is easy to prepare.',
      preparationMinutes: 10,
      cookingMinutes: 10,
      servings: 2,
      calories: 160,
      protein: 5,
      carbs: 17,
      fat: 9,
      ingredients: [
        RecipeIngredient(name: 'Carrots', quantity: 100, unit: 'g'),
        RecipeIngredient(name: 'Beans', quantity: 100, unit: 'g'),
        RecipeIngredient(name: 'Broccoli', quantity: 100, unit: 'g'),
        RecipeIngredient(name: 'Oil', quantity: 15, unit: 'ml'),
      ],
      instructions: [
        'Wash all vegetables thoroughly.',
        'Cut the carrots, beans, and broccoli '
            'into small pieces.',
        'Heat oil in a frying pan.',
        'Add the vegetables.',
        'Stir-fry until cooked and tender-crisp.',
        'Serve warm.',
      ],
    ),

    RecipeModel(
      id: 'boiled_eggs',
      name: 'Boiled Eggs',
      description: 'An easy protein-rich snack.',
      preparationMinutes: 2,
      cookingMinutes: 12,
      servings: 1,
      calories: 155,
      protein: 13,
      carbs: 1,
      fat: 11,
      ingredients: [RecipeIngredient(name: 'Eggs', quantity: 2, unit: 'pcs')],
      instructions: [
        'Place the eggs in a saucepan.',
        'Add enough water to cover the eggs.',
        'Bring the water to a boil.',
        'Cook until the eggs are fully cooked.',
        'Cool the eggs under clean running water.',
        'Peel and serve.',
      ],
    ),
  ];

  static List<RecipeModel> getAllRecipes() {
    return List<RecipeModel>.unmodifiable(recipes);
  }

  static RecipeModel? getRecipeById(String id) {
    for (final recipe in recipes) {
      if (recipe.id == id) {
        return recipe;
      }
    }

    return null;
  }
}
