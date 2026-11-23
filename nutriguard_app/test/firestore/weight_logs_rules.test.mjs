
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

const validWeight = {
  weightKg: 65.5,
  measuredAt: Timestamp.fromDate(new Date('2026-11-16T06:00:00Z')),
};

function weightRef(db, userId, id = 'weight-1') {
  return doc(db, 'users', userId, 'weightLogs', id);
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

test('owner can create and read valid weight log', async () => {
  const db = userDb('alice');
  const ref = weightRef(db, 'alice');

  await assertSucceeds(setDoc(ref, validWeight));

  const snapshot = await assertSucceeds(getDoc(ref));

  if (!snapshot.exists()) {
    throw new Error('Weight log was not created.');
  }
});

test('owner can update weight log', async () => {
  const db = userDb('alice');
  const ref = weightRef(db, 'alice');

  await setDoc(ref, validWeight);

  await assertSucceeds(
    updateDoc(ref, { weightKg: 66 }),
  );
});

test('owner can delete weight log', async () => {
  const db = userDb('alice');
  const ref = weightRef(db, 'alice');

  await setDoc(ref, validWeight);

  await assertSucceeds(deleteDoc(ref));
});

test('another user cannot read weight log', async () => {
  await setDoc(
    weightRef(userDb('alice'), 'alice'),
    validWeight,
  );

  await assertFails(
    getDoc(weightRef(userDb('bob'), 'alice')),
  );
});

test('another user cannot create weight log in another account', async () => {
  await assertFails(
    setDoc(
      weightRef(userDb('bob'), 'alice'),
      validWeight,
    ),
  );
});

test('unauthenticated user cannot read weight log', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(
    getDoc(weightRef(db, 'alice')),
  );
});

test('unauthenticated user cannot create weight log', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(
    setDoc(weightRef(db, 'alice'), validWeight),
  );
});

test('rejects missing required fields', async () => {
  const db = userDb('alice');
  const { measuredAt, ...invalid } = validWeight;

  await assertFails(
    setDoc(weightRef(db, 'alice'), invalid),
  );
});

test('rejects unexpected fields', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      weightRef(db, 'alice'),
      { ...validWeight, extraField: true },
    ),
  );
});

test('rejects weight below 2 kg', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      weightRef(db, 'alice'),
      { ...validWeight, weightKg: 1.9 },
    ),
  );
});

test('rejects weight above 500 kg', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      weightRef(db, 'alice'),
      { ...validWeight, weightKg: 501 },
    ),
  );
});

test('allows minimum weight of 2 kg', async () => {
  const db = userDb('alice');

  await assertSucceeds(
    setDoc(
      weightRef(db, 'alice'),
      { ...validWeight, weightKg: 2 },
    ),
  );
});

test('allows maximum weight of 500 kg', async () => {
  const db = userDb('alice');

  await assertSucceeds(
    setDoc(
      weightRef(db, 'alice'),
      { ...validWeight, weightKg: 500 },
    ),
  );
});

test('rejects non-numeric weight', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      weightRef(db, 'alice'),
      { ...validWeight, weightKg: '65.5' },
    ),
  );
});

test('rejects future measurement timestamp', async () => {
  const db = userDb('alice');

  const futureDate = Timestamp.fromDate(
    new Date(Date.now() + 24 * 60 * 60 * 1000),
  );

  await assertFails(
    setDoc(
      weightRef(db, 'alice'),
      { ...validWeight, measuredAt: futureDate },
    ),
  );
});

test('rejects non-timestamp measuredAt', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      weightRef(db, 'alice'),
      { ...validWeight, measuredAt: '2026-11-16' },
    ),
  );
});
