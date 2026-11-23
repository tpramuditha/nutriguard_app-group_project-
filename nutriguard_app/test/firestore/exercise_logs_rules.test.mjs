
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

const validExercise = {
  exerciseName: 'Walking',
  exerciseType: 'Cardio',
  durationMinutes: 30,
  isCompleted: false,
  performedAt: Timestamp.fromDate(new Date('2026-11-16')),
};

function exerciseRef(db, userId, id = 'exercise-1') {
  return doc(db, 'users', userId, 'exerciseLogs', id);
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

test('owner can create and read valid exercise log', async () => {
  const db = userDb('alice');
  const ref = exerciseRef(db, 'alice');

  await assertSucceeds(setDoc(ref, validExercise));

  const snapshot = await assertSucceeds(getDoc(ref));

  if (!snapshot.exists()) {
    throw new Error('Exercise log was not created.');
  }
});

test('owner can update exercise log', async () => {
  const db = userDb('alice');
  const ref = exerciseRef(db, 'alice');

  await setDoc(ref, validExercise);

  await assertSucceeds(
    updateDoc(ref, {
      isCompleted: true,
    }),
  );
});

test('owner can delete exercise log', async () => {
  const db = userDb('alice');
  const ref = exerciseRef(db, 'alice');

  await setDoc(ref, validExercise);

  await assertSucceeds(deleteDoc(ref));
});

test('another user cannot read exercise log', async () => {
  await setDoc(
    exerciseRef(userDb('alice'), 'alice'),
    validExercise,
  );

  await assertFails(
    getDoc(exerciseRef(userDb('bob'), 'alice')),
  );
});

test('another user cannot create exercise log in another account', async () => {
  await assertFails(
    setDoc(
      exerciseRef(userDb('bob'), 'alice'),
      validExercise,
    ),
  );
});

test('unauthenticated user cannot read exercise log', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(
    getDoc(exerciseRef(db, 'alice')),
  );
});

test('unauthenticated user cannot create exercise log', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(
    setDoc(
      exerciseRef(db, 'alice'),
      validExercise,
    ),
  );
});

test('rejects missing required fields', async () => {
  const db = userDb('alice');
  const { exerciseName, ...invalid } = validExercise;

  await assertFails(
    setDoc(exerciseRef(db, 'alice'), invalid),
  );
});

test('rejects unexpected fields', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      exerciseRef(db, 'alice'),
      { ...validExercise, extraField: true },
    ),
  );
});

test('rejects empty exercise name', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      exerciseRef(db, 'alice'),
      { ...validExercise, exerciseName: '' },
    ),
  );
});

test('rejects whitespace-only exercise name', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      exerciseRef(db, 'alice'),
      { ...validExercise, exerciseName: '   ' },
    ),
  );
});

test('rejects invalid exercise type', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      exerciseRef(db, 'alice'),
      { ...validExercise, exerciseType: '' },
    ),
  );
});

test('rejects negative duration', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      exerciseRef(db, 'alice'),
      { ...validExercise, durationMinutes: -1 },
    ),
  );
});

test('rejects duration above 1440 minutes', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      exerciseRef(db, 'alice'),
      { ...validExercise, durationMinutes: 1441 },
    ),
  );
});

test('rejects non-integer duration', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      exerciseRef(db, 'alice'),
      { ...validExercise, durationMinutes: 30.5 },
    ),
  );
});

test('allows zero-minute duration', async () => {
  const db = userDb('alice');

  await assertSucceeds(
    setDoc(
      exerciseRef(db, 'alice'),
      { ...validExercise, durationMinutes: 0 },
    ),
  );
});

test('allows maximum duration of 1440 minutes', async () => {
  const db = userDb('alice');

  await assertSucceeds(
    setDoc(
      exerciseRef(db, 'alice'),
      { ...validExercise, durationMinutes: 1440 },
    ),
  );
});

test('rejects non-boolean completion status', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      exerciseRef(db, 'alice'),
      { ...validExercise, isCompleted: 'yes' },
    ),
  );
});

test('rejects non-timestamp performedAt', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      exerciseRef(db, 'alice'),
      { ...validExercise, performedAt: '2026-11-16' },
    ),
  );
});
