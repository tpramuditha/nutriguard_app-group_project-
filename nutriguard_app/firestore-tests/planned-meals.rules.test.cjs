
const { test, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  getDocs,
} = require('firebase/firestore');

let testEnv;

const projectId = 'nutriguard-18dbd';

const ownerId = 'planner_test_owner';
const otherUserId = 'planner_test_other';

function mealPath(
  userId,
  mealId = 'meal_001',
) {
  return `users/${userId}/plannedMeals/${mealId}`;
}

function validMeal(overrides = {}) {
  return {
    id: 'meal_001',
    date: '2026-11-08',
    mealType: 'Lunch',
    recipeId: 'egg_fried_rice',
    servings: 2,
    ...overrides,
  };
}

function ownerDb() {
  return testEnv.authenticatedContext(ownerId).firestore();
}

function otherUserDb() {
  return testEnv.authenticatedContext(otherUserId).firestore();
}

function guestDb() {
  return testEnv.unauthenticatedContext().firestore();
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
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

async function createOwnerMeal() {
  const reference = doc(
    ownerDb(),
    mealPath(ownerId),
  );

  await assertSucceeds(
    setDoc(reference, validMeal()),
  );

  return reference;
}

// --------------------------------------------------
// OWNER ACCESS TESTS
// --------------------------------------------------

test('owner can create a valid planned meal', async () => {
  const reference = doc(
    ownerDb(),
    mealPath(ownerId),
  );

  await assertSucceeds(
    setDoc(reference, validMeal()),
  );
});

test('owner can read their planned meal', async () => {
  const reference = await createOwnerMeal();

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  assert.equal(snapshot.exists(), true);
  assert.equal(snapshot.data().recipeId, 'egg_fried_rice');
  assert.equal(snapshot.data().servings, 2);
});

test('owner can update planned servings', async () => {
  const reference = await createOwnerMeal();

  await assertSucceeds(
    updateDoc(reference, {
      servings: 3,
    }),
  );

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  assert.equal(snapshot.data().servings, 3);
});

test('owner can delete a planned meal', async () => {
  const reference = await createOwnerMeal();

  await assertSucceeds(
    deleteDoc(reference),
  );

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  assert.equal(snapshot.exists(), false);
});

test('owner can query meals by date', async () => {
  await createOwnerMeal();

  const mealsCollection = collection(
    ownerDb(),
    `users/${ownerId}/plannedMeals`,
  );

  const mealsQuery = query(
    mealsCollection,
    where('date', '==', '2026-11-08'),
  );

  const snapshot = await assertSucceeds(
    getDocs(mealsQuery),
  );

  assert.equal(snapshot.size, 1);
});

// --------------------------------------------------
// OTHER USER ACCESS TESTS
// --------------------------------------------------

test('another user cannot read owner meal', async () => {
  await createOwnerMeal();

  const reference = doc(
    otherUserDb(),
    mealPath(ownerId),
  );

  await assertFails(
    getDoc(reference),
  );
});

test('another user cannot create owner meal', async () => {
  const reference = doc(
    otherUserDb(),
    mealPath(ownerId, 'meal_002'),
  );

  await assertFails(
    setDoc(
      reference,
      validMeal({ id: 'meal_002' }),
    ),
  );
});

test('another user cannot update owner meal', async () => {
  await createOwnerMeal();

  const reference = doc(
    otherUserDb(),
    mealPath(ownerId),
  );

  await assertFails(
    updateDoc(reference, {
      servings: 5,
    }),
  );
});

test('another user cannot delete owner meal', async () => {
  await createOwnerMeal();

  const reference = doc(
    otherUserDb(),
    mealPath(ownerId),
  );

  await assertFails(
    deleteDoc(reference),
  );
});

// --------------------------------------------------
// UNAUTHENTICATED ACCESS TESTS
// --------------------------------------------------

test('guest cannot read planned meals', async () => {
  await createOwnerMeal();

  const reference = doc(
    guestDb(),
    mealPath(ownerId),
  );

  await assertFails(
    getDoc(reference),
  );
});

test('guest cannot create planned meals', async () => {
  const reference = doc(
    guestDb(),
    mealPath(ownerId),
  );

  await assertFails(
    setDoc(reference, validMeal()),
  );
});

// --------------------------------------------------
// VALIDATION TESTS
// --------------------------------------------------

test('rejects zero planned servings', async () => {
  const reference = doc(
    ownerDb(),
    mealPath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validMeal({ servings: 0 }),
    ),
  );
});

test('rejects invalid meal type', async () => {
  const reference = doc(
    ownerDb(),
    mealPath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validMeal({ mealType: 'Brunch' }),
    ),
  );
});

test('rejects unexpected fields', async () => {
  const reference = doc(
    ownerDb(),
    mealPath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validMeal({ admin: true }),
    ),
  );
});

test('rejects mismatched document ID', async () => {
  const reference = doc(
    ownerDb(),
    mealPath(ownerId, 'meal_002'),
  );

  await assertFails(
    setDoc(
      reference,
      validMeal({ id: 'meal_001' }),
    ),
  );
});

test('rejects invalid date format', async () => {
  const reference = doc(
    ownerDb(),
    mealPath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validMeal({ date: '08-11-2026' }),
    ),
  );
});
