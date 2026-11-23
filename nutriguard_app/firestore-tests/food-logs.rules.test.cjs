
const { test, before, beforeEach, after } = require('node:test');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  deleteDoc,
  Timestamp,
} = require('firebase/firestore');

const fs = require('node:fs');

let testEnv;

const projectId = 'demo-nutriguard-foodlogs';

const ownerId = 'food-owner';
const otherUserId = 'another-user';

function validFoodLog() {
  return {
    foodId: '123456',
    foodName: 'Test Oats',
    brand: 'Example Brand',
    source: 'Open Food Facts',
    grams: 150,
    mealType: 'Breakfast',
    calories: 570,
    protein: 19.5,
    carbs: 100.5,
    fat: 10.5,
    loggedAt: Timestamp.fromDate(
      new Date('2026-10-20T08:00:00Z')
    ),
  };
}

function foodLogRef(context, userId, logId = 'test-log') {
  return doc(
    context.firestore(),
    'users',
    userId,
    'foodLogs',
    logId
  );
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync('firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

test('owner can create a valid food log', async () => {
  const owner = testEnv.authenticatedContext(ownerId);

  await assertSucceeds(
    setDoc(foodLogRef(owner, ownerId), validFoodLog())
  );
});

test('owner can read their food log', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      foodLogRef(context, ownerId),
      validFoodLog()
    );
  });

  const owner = testEnv.authenticatedContext(ownerId);

  await assertSucceeds(
    getDoc(foodLogRef(owner, ownerId))
  );
});

test('another user cannot read the food log', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      foodLogRef(context, ownerId),
      validFoodLog()
    );
  });

  const otherUser =
      testEnv.authenticatedContext(otherUserId);

  await assertFails(
    getDoc(foodLogRef(otherUser, ownerId))
  );
});

test('unauthenticated user cannot create food logs', async () => {
  const guest = testEnv.unauthenticatedContext();

  await assertFails(
    setDoc(foodLogRef(guest, ownerId), validFoodLog())
  );
});

test('negative calories are rejected', async () => {
  const owner = testEnv.authenticatedContext(ownerId);

  const invalidLog = {
    ...validFoodLog(),
    calories: -100,
  };

  await assertFails(
    setDoc(foodLogRef(owner, ownerId), invalidLog)
  );
});

test('zero grams are rejected', async () => {
  const owner = testEnv.authenticatedContext(ownerId);

  const invalidLog = {
    ...validFoodLog(),
    grams: 0,
  };

  await assertFails(
    setDoc(foodLogRef(owner, ownerId), invalidLog)
  );
});

test('invalid meal types are rejected', async () => {
  const owner = testEnv.authenticatedContext(ownerId);

  const invalidLog = {
    ...validFoodLog(),
    mealType: 'Midnight Meal',
  };

  await assertFails(
    setDoc(foodLogRef(owner, ownerId), invalidLog)
  );
});

test('missing required fields are rejected', async () => {
  const owner = testEnv.authenticatedContext(ownerId);

  const invalidLog = validFoodLog();
  delete invalidLog.protein;

  await assertFails(
    setDoc(foodLogRef(owner, ownerId), invalidLog)
  );
});

test('owner cannot update existing food logs', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      foodLogRef(context, ownerId),
      validFoodLog()
    );
  });

  const owner = testEnv.authenticatedContext(ownerId);

  await assertFails(
    updateDoc(foodLogRef(owner, ownerId), {
      grams: 200,
    })
  );
});

test('owner can delete their food log', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      foodLogRef(context, ownerId),
      validFoodLog()
    );
  });

  const owner = testEnv.authenticatedContext(ownerId);

  await assertSucceeds(
    deleteDoc(foodLogRef(owner, ownerId))
  );
});

test('another user cannot delete the food log', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      foodLogRef(context, ownerId),
      validFoodLog()
    );
  });

  const otherUser =
      testEnv.authenticatedContext(otherUserId);

  await assertFails(
    deleteDoc(foodLogRef(otherUser, ownerId))
  );
});
