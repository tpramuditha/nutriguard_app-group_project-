
import { readFileSync } from 'node:fs';
import { before, after, beforeEach, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

let env;

const projectId = 'nutriguard-18dbd';

const validMeal = {
  id: 'meal-1',
  date: '2026-11-16',
  mealType: 'Breakfast',
  recipeId: 'vegetable-omelette',
  servings: 2,
};

function mealRef(db, userId, id = 'meal-1') {
  return doc(db, 'users', userId, 'plannedMeals', id);
}

function userDb(uid) {
  return env.authenticatedContext(uid).firestore();
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: readFileSync('firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
});

after(async () => {
  if (env) await env.cleanup();
});

test('owner can create and read valid planned meal', async () => {
  const db = userDb('alice');
  const ref = mealRef(db, 'alice');

  await assertSucceeds(setDoc(ref, validMeal));

  const snapshot = await assertSucceeds(getDoc(ref));

  if (!snapshot.exists()) {
    throw new Error('Planned meal was not created.');
  }
});

test('owner can update planned meal', async () => {
  const db = userDb('alice');
  const ref = mealRef(db, 'alice');

  await setDoc(ref, validMeal);

  await assertSucceeds(
    updateDoc(ref, { servings: 3 }),
  );
});

test('owner can delete planned meal', async () => {
  const db = userDb('alice');
  const ref = mealRef(db, 'alice');

  await setDoc(ref, validMeal);

  await assertSucceeds(deleteDoc(ref));
});

test('another user cannot read planned meal', async () => {
  await setDoc(
    mealRef(userDb('alice'), 'alice'),
    validMeal,
  );

  await assertFails(
    getDoc(mealRef(userDb('bob'), 'alice')),
  );
});

test('another user cannot create meal in another account', async () => {
  await assertFails(
    setDoc(
      mealRef(userDb('bob'), 'alice'),
      validMeal,
    ),
  );
});

test('unauthenticated user cannot read planned meal', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(getDoc(mealRef(db, 'alice')));
});

test('rejects document ID different from meal ID', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      mealRef(db, 'alice', 'different-id'),
      validMeal,
    ),
  );
});

test('rejects invalid date format', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      mealRef(db, 'alice'),
      { ...validMeal, date: '16-11-2026' },
    ),
  );
});

test('rejects invalid month', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      mealRef(db, 'alice'),
      { ...validMeal, date: '2026-13-16' },
    ),
  );
});

test('rejects day greater than 31', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      mealRef(db, 'alice'),
      { ...validMeal, date: '2026-11-32' },
    ),
  );
});

test('checks current rule behavior for February 31', async () => {
  const db = userDb('alice');

  // The current Firestore rule checks the date format,
  // not whether the calendar date actually exists.
  await assertSucceeds(
    setDoc(
      mealRef(db, 'alice'),
      { ...validMeal, date: '2026-02-31' },
    ),
  );
});

test('rejects invalid meal type', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      mealRef(db, 'alice'),
      { ...validMeal, mealType: 'Brunch' },
    ),
  );
});

test('rejects empty recipe ID', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      mealRef(db, 'alice'),
      { ...validMeal, recipeId: '' },
    ),
  );
});

test('rejects invalid servings below 1', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      mealRef(db, 'alice'),
      { ...validMeal, servings: 0 },
    ),
  );
});

test('rejects servings above 20', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      mealRef(db, 'alice'),
      { ...validMeal, servings: 21 },
    ),
  );
});

test('rejects unexpected fields', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      mealRef(db, 'alice'),
      { ...validMeal, extraField: true },
    ),
  );
});
