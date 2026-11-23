
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
  Timestamp,
} from 'firebase/firestore';

let env;

const projectId = 'nutriguard-18dbd';

const validFoodLog = {
  foodId: 'food-001',
  foodName: 'Rice and Curry',
  brand: null,
  source: 'AI',
  grams: 200,
  mealType: 'Lunch',
  calories: 350,
  protein: 12,
  carbs: 55,
  fat: 8,
  loggedAt: Timestamp.now(),
};

function foodRef(db, userId, id = 'food-1') {
  return doc(db, 'users', userId, 'foodLogs', id);
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

test('owner can create and read valid food log', async () => {
  const db = userDb('alice');
  const ref = foodRef(db, 'alice');

  await assertSucceeds(setDoc(ref, validFoodLog));

  const snapshot = await assertSucceeds(getDoc(ref));

  if (!snapshot.exists()) {
    throw new Error('Food log was not created.');
  }
});

test('owner can delete food log', async () => {
  const db = userDb('alice');
  const ref = foodRef(db, 'alice');

  await setDoc(ref, validFoodLog);

  await assertSucceeds(deleteDoc(ref));
});

test('owner cannot update existing food log', async () => {
  const db = userDb('alice');
  const ref = foodRef(db, 'alice');

  await setDoc(ref, validFoodLog);

  await assertFails(
    updateDoc(ref, { calories: 400 }),
  );
});

test('another user cannot read food log', async () => {
  await setDoc(
    foodRef(userDb('alice'), 'alice'),
    validFoodLog,
  );

  await assertFails(
    getDoc(foodRef(userDb('bob'), 'alice')),
  );
});

test('another user cannot create food log in another account', async () => {
  await assertFails(
    setDoc(
      foodRef(userDb('bob'), 'alice'),
      validFoodLog,
    ),
  );
});

test('unauthenticated user cannot read food log', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(getDoc(foodRef(db, 'alice')));
});

test('unauthenticated user cannot create food log', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(
    setDoc(foodRef(db, 'alice'), validFoodLog),
  );
});

test('rejects missing required fields', async () => {
  const db = userDb('alice');
  const { foodName, ...invalid } = validFoodLog;

  await assertFails(
    setDoc(foodRef(db, 'alice'), invalid),
  );
});

test('rejects unexpected fields', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      foodRef(db, 'alice'),
      { ...validFoodLog, extraField: true },
    ),
  );
});

test('rejects invalid meal type', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      foodRef(db, 'alice'),
      { ...validFoodLog, mealType: 'Brunch' },
    ),
  );
});

test('rejects zero or negative portion weight', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      foodRef(db, 'alice'),
      { ...validFoodLog, grams: 0 },
    ),
  );
});

test('rejects portion weight exceeding 5000 grams', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      foodRef(db, 'alice'),
      { ...validFoodLog, grams: 5001 },
    ),
  );
});

test('rejects negative calories', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      foodRef(db, 'alice'),
      { ...validFoodLog, calories: -1 },
    ),
  );
});

test('rejects non-timestamp loggedAt', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      foodRef(db, 'alice'),
      { ...validFoodLog, loggedAt: '2026-11-16' },
    ),
  );
});

test('allows null brand', async () => {
  const db = userDb('alice');

  await assertSucceeds(
    setDoc(
      foodRef(db, 'alice'),
      { ...validFoodLog, brand: null },
    ),
  );
});

test('allows valid string brand', async () => {
  const db = userDb('alice');

  await assertSucceeds(
    setDoc(
      foodRef(db, 'alice'),
      { ...validFoodLog, brand: 'Example Brand' },
    ),
  );
});
