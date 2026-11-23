
const { test, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  collection,
  query,
  where,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  Timestamp,
} = require('firebase/firestore');

let testEnv;

const projectId = 'nutriguard-18dbd';

const ownerId = 'exercise_test_owner';
const otherUserId = 'exercise_test_other';

function exercisePath(
  userId,
  exerciseId = 'exercise_001',
) {
  return `users/${userId}/exerciseLogs/${exerciseId}`;
}

function validExercise(overrides = {}) {
  return {
    exerciseName: 'Walking',
    exerciseType: 'Cardio',
    durationMinutes: 30,
    isCompleted: true,
    performedAt: Timestamp.fromDate(
      new Date('2026-11-09T08:30:00Z'),
    ),
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

async function createOwnerExercise() {
  const reference = doc(
    ownerDb(),
    exercisePath(ownerId),
  );

  await assertSucceeds(
    setDoc(reference, validExercise()),
  );

  return reference;
}

// --------------------------------------------------
// OWNER ACCESS TESTS
// --------------------------------------------------

test('owner can create a valid exercise', async () => {
  const reference = doc(
    ownerDb(),
    exercisePath(ownerId),
  );

  await assertSucceeds(
    setDoc(reference, validExercise()),
  );
});

test('owner can read their exercise', async () => {
  const reference = await createOwnerExercise();

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  assert.equal(snapshot.exists(), true);
  assert.equal(snapshot.data().exerciseName, 'Walking');
  assert.equal(snapshot.data().durationMinutes, 30);
  assert.equal(snapshot.data().isCompleted, true);
});

test('owner can update exercise completion', async () => {
  const reference = await createOwnerExercise();

  await assertSucceeds(
    updateDoc(reference, {
      isCompleted: false,
    }),
  );

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  assert.equal(snapshot.data().isCompleted, false);
});

test('owner can delete their exercise', async () => {
  const reference = await createOwnerExercise();

  await assertSucceeds(
    deleteDoc(reference),
  );

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  assert.equal(snapshot.exists(), false);
});

test('owner can query exercises by date', async () => {
  await createOwnerExercise();

  const exercisesCollection = collection(
    ownerDb(),
    `users/${ownerId}/exerciseLogs`,
  );

  const exercisesQuery = query(
    exercisesCollection,
    where(
      'performedAt',
      '>=',
      Timestamp.fromDate(
        new Date('2026-11-09T00:00:00Z'),
      ),
    ),
    where(
      'performedAt',
      '<',
      Timestamp.fromDate(
        new Date('2026-11-10T00:00:00Z'),
      ),
    ),
  );

  const snapshot = await assertSucceeds(
    getDocs(exercisesQuery),
  );

  assert.equal(snapshot.size, 1);
});

// --------------------------------------------------
// OTHER USER ACCESS TESTS
// --------------------------------------------------

test('another user cannot read owner exercise', async () => {
  await createOwnerExercise();

  const reference = doc(
    otherUserDb(),
    exercisePath(ownerId),
  );

  await assertFails(
    getDoc(reference),
  );
});

test('another user cannot create owner exercise', async () => {
  const reference = doc(
    otherUserDb(),
    exercisePath(ownerId, 'exercise_002'),
  );

  await assertFails(
    setDoc(reference, validExercise()),
  );
});

test('another user cannot update owner exercise', async () => {
  await createOwnerExercise();

  const reference = doc(
    otherUserDb(),
    exercisePath(ownerId),
  );

  await assertFails(
    updateDoc(reference, {
      isCompleted: false,
    }),
  );
});

test('another user cannot delete owner exercise', async () => {
  await createOwnerExercise();

  const reference = doc(
    otherUserDb(),
    exercisePath(ownerId),
  );

  await assertFails(
    deleteDoc(reference),
  );
});

// --------------------------------------------------
// UNAUTHENTICATED ACCESS TESTS
// --------------------------------------------------

test('guest cannot read exercise records', async () => {
  await createOwnerExercise();

  const reference = doc(
    guestDb(),
    exercisePath(ownerId),
  );

  await assertFails(
    getDoc(reference),
  );
});

test('guest cannot create exercise records', async () => {
  const reference = doc(
    guestDb(),
    exercisePath(ownerId),
  );

  await assertFails(
    setDoc(reference, validExercise()),
  );
});

// --------------------------------------------------
// DATA VALIDATION TESTS
// --------------------------------------------------

test('rejects negative exercise duration', async () => {
  const reference = doc(
    ownerDb(),
    exercisePath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validExercise({ durationMinutes: -10 }),
    ),
  );
});

test('rejects exercise duration above 1440 minutes', async () => {
  const reference = doc(
    ownerDb(),
    exercisePath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validExercise({ durationMinutes: 1500 }),
    ),
  );
});

test('rejects missing required fields', async () => {
  const reference = doc(
    ownerDb(),
    exercisePath(ownerId),
  );

  const exercise = validExercise();
  delete exercise.exerciseName;

  await assertFails(
    setDoc(reference, exercise),
  );
});

test('rejects invalid completion status', async () => {
  const reference = doc(
    ownerDb(),
    exercisePath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validExercise({ isCompleted: 'yes' }),
    ),
  );
});

test('rejects unexpected fields', async () => {
  const reference = doc(
    ownerDb(),
    exercisePath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validExercise({ isAdmin: true }),
    ),
  );
});

test('rejects blank exercise name', async () => {
  const reference = doc(
    ownerDb(),
    exercisePath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validExercise({ exerciseName: '   ' }),
    ),
  );
});

test('rejects invalid performedAt type', async () => {
  const reference = doc(
    ownerDb(),
    exercisePath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validExercise({ performedAt: '2026-11-09' }),
    ),
  );
});
