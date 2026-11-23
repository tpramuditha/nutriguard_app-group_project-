
import { readFileSync } from 'node:fs';
import {
  before,
  after,
  beforeEach,
  test,
} from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
} from 'firebase/firestore';

let env;

const projectId = 'nutriguard-18dbd';
const weekId = '2026-11-09';

function planPath(userId) {
  return `users/${userId}/weeklyExercisePlans/${weekId}`;
}

function validPlan() {
  const exerciseIds = [
    'walking',
    'gentle_stretching',
    'chair_exercises',
    'easy_cycling',
    'mobility_routine',
    'walking',
  ];

  return {
    weekStart: weekId,
    goal: 'generalFitness',
    activityLevel: 'beginner',
    preference: 'any',
    days: Array.from({ length: 7 }, (_, index) => ({
      weekday: index + 1,
      exerciseId: index === 6 ? null : exerciseIds[index],
    })),
  };
}

function userDb(uid) {
  return env.authenticatedContext(uid).firestore();
}

function userRef(uid, ownerId = uid) {
  return doc(userDb(uid), planPath(ownerId));
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
  if (env) {
    await env.cleanup();
  }
});

test('owner can create and read a valid plan', async () => {
  const ref = userRef('alice');

  await assertSucceeds(setDoc(ref, validPlan()));

  const snapshot = await assertSucceeds(getDoc(ref));

  if (!snapshot.exists()) {
    throw new Error('Saved plan was not found');
  }
});

test('owner can update a valid plan', async () => {
  const ref = userRef('alice');

  await assertSucceeds(setDoc(ref, validPlan()));

  await assertSucceeds(
    updateDoc(ref, { goal: 'buildConsistency' }),
  );
});

test('owner can delete their plan', async () => {
  const ref = userRef('alice');

  await assertSucceeds(setDoc(ref, validPlan()));
  await assertSucceeds(deleteDoc(ref));
});

test('another user cannot read the plan', async () => {
  await assertSucceeds(
    setDoc(userRef('alice'), validPlan()),
  );

  await assertFails(
    getDoc(userRef('bob', 'alice')),
  );
});

test('another user cannot overwrite the plan', async () => {
  await assertSucceeds(
    setDoc(userRef('alice'), validPlan()),
  );

  await assertFails(
    setDoc(userRef('bob', 'alice'), validPlan()),
  );
});

test('unauthenticated user cannot read a plan', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(
    getDoc(doc(db, planPath('alice'))),
  );
});

test('rejects incorrect weekStart', async () => {
  const plan = validPlan();
  plan.weekStart = '2026-11-10';

  await assertFails(
    setDoc(userRef('alice'), plan),
  );
});

test('rejects invalid weekday sequence', async () => {
  const plan = validPlan();
  plan.days[0].weekday = 3;

  await assertFails(
    setDoc(userRef('alice'), plan),
  );
});

test('rejects exercise on Sunday rest day', async () => {
  const plan = validPlan();
  plan.days[6].exerciseId = 'walking';

  await assertFails(
    setDoc(userRef('alice'), plan),
  );
});

test('rejects unknown exercise ID', async () => {
  const plan = validPlan();
  plan.days[0].exerciseId = 'invalid_exercise';

  await assertFails(
    setDoc(userRef('alice'), plan),
  );
});

test('rejects unexpected document fields', async () => {
  const plan = validPlan();
  plan.adminAccess = true;

  await assertFails(
    setDoc(userRef('alice'), plan),
  );
});

test('rejects unknown activity level', async () => {
  const plan = validPlan();
  plan.activityLevel = 'expert';

  await assertFails(
    setDoc(userRef('alice'), plan),
  );
});

test('rejects moderate exercise for beginners', async () => {
  const plan = validPlan();
  plan.days[0].exerciseId = 'brisk_walking';

  await assertFails(
    setDoc(userRef('alice'), plan),
  );
});

test('allows moderate exercise for intermediate users', async () => {
  const plan = validPlan();
  plan.activityLevel = 'intermediate';
  plan.days[0].exerciseId = 'brisk_walking';

  await assertSucceeds(
    setDoc(userRef('alice'), plan),
  );
});

test('rejects unexpected fields inside a day', async () => {
  const plan = validPlan();
  plan.days[0].durationMinutes = 500;

  await assertFails(
    setDoc(userRef('alice'), plan),
  );
});
