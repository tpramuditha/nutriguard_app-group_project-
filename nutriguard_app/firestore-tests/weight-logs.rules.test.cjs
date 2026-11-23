
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
  orderBy,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  Timestamp,
} = require('firebase/firestore');

let testEnv;

const projectId = 'nutriguard-18dbd';
const ownerId = 'weight_test_owner';
const otherUserId = 'weight_test_other';

function weightPath(
  userId,
  weightLogId = 'weight_001',
) {
  return `users/${userId}/weightLogs/${weightLogId}`;
}

function validWeight(overrides = {}) {
  return {
    weightKg: 65.5,
    measuredAt: Timestamp.fromDate(
      new Date('2025-10-09T08:30:00Z'),
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

async function createOwnerWeight() {
  const reference = doc(
    ownerDb(),
    weightPath(ownerId),
  );

  await assertSucceeds(
    setDoc(reference, validWeight()),
  );

  return reference;
}

// --------------------------------------------------
// OWNER ACCESS TESTS
// --------------------------------------------------

test('owner can create a valid weight record', async () => {
  const reference = doc(
    ownerDb(),
    weightPath(ownerId),
  );

  await assertSucceeds(
    setDoc(reference, validWeight()),
  );
});

test('owner can read their weight record', async () => {
  const reference = await createOwnerWeight();

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  assert.equal(snapshot.exists(), true);
  assert.equal(snapshot.data().weightKg, 65.5);
});

test('owner can update weight measurement', async () => {
  const reference = await createOwnerWeight();

  await assertSucceeds(
    updateDoc(reference, {
      weightKg: 64.8,
    }),
  );

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  assert.equal(snapshot.data().weightKg, 64.8);
});

test('owner can delete weight record', async () => {
  const reference = await createOwnerWeight();

  await assertSucceeds(
    deleteDoc(reference),
  );

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  assert.equal(snapshot.exists(), false);
});

test('owner can query weight records by date range', async () => {
  await createOwnerWeight();

  const weightsCollection = collection(
    ownerDb(),
    `users/${ownerId}/weightLogs`,
  );

  const weightsQuery = query(
    weightsCollection,
    where(
      'measuredAt',
      '>=',
      Timestamp.fromDate(
        new Date('2025-10-01T00:00:00Z'),
      ),
    ),
    where(
      'measuredAt',
      '<',
      Timestamp.fromDate(
        new Date('2025-11-01T00:00:00Z'),
      ),
    ),
    orderBy('measuredAt', 'desc'),
  );

  const snapshot = await assertSucceeds(
    getDocs(weightsQuery),
  );

  assert.equal(snapshot.size, 1);
});

// --------------------------------------------------
// OTHER USER ACCESS TESTS
// --------------------------------------------------

test('another user cannot read owner weight', async () => {
  await createOwnerWeight();

  const reference = doc(
    otherUserDb(),
    weightPath(ownerId),
  );

  await assertFails(getDoc(reference));
});

test('another user cannot create owner weight', async () => {
  const reference = doc(
    otherUserDb(),
    weightPath(ownerId, 'weight_002'),
  );

  await assertFails(
    setDoc(reference, validWeight()),
  );
});

test('another user cannot update owner weight', async () => {
  await createOwnerWeight();

  const reference = doc(
    otherUserDb(),
    weightPath(ownerId),
  );

  await assertFails(
    updateDoc(reference, { weightKg: 70 }),
  );
});

test('another user cannot delete owner weight', async () => {
  await createOwnerWeight();

  const reference = doc(
    otherUserDb(),
    weightPath(ownerId),
  );

  await assertFails(deleteDoc(reference));
});

// --------------------------------------------------
// UNAUTHENTICATED ACCESS TESTS
// --------------------------------------------------

test('guest cannot read weight records', async () => {
  await createOwnerWeight();

  const reference = doc(
    guestDb(),
    weightPath(ownerId),
  );

  await assertFails(getDoc(reference));
});

test('guest cannot create weight records', async () => {
  const reference = doc(
    guestDb(),
    weightPath(ownerId),
  );

  await assertFails(
    setDoc(reference, validWeight()),
  );
});

// --------------------------------------------------
// DATA VALIDATION TESTS
// --------------------------------------------------

test('rejects weight below 2 kg', async () => {
  const reference = doc(
    ownerDb(),
    weightPath(ownerId),
  );

  await assertFails(
    setDoc(reference, validWeight({ weightKg: 1.5 })),
  );
});

test('rejects weight above 500 kg', async () => {
  const reference = doc(
    ownerDb(),
    weightPath(ownerId),
  );

  await assertFails(
    setDoc(reference, validWeight({ weightKg: 501 })),
  );
});

test('allows boundary weight of 2 kg', async () => {
  const reference = doc(
    ownerDb(),
    weightPath(ownerId),
  );

  await assertSucceeds(
    setDoc(reference, validWeight({ weightKg: 2 })),
  );
});

test('allows boundary weight of 500 kg', async () => {
  const reference = doc(
    ownerDb(),
    weightPath(ownerId),
  );

  await assertSucceeds(
    setDoc(reference, validWeight({ weightKg: 500 })),
  );
});

test('rejects missing required weight field', async () => {
  const reference = doc(
    ownerDb(),
    weightPath(ownerId),
  );

  const data = validWeight();
  delete data.weightKg;

  await assertFails(setDoc(reference, data));
});

test('rejects weight stored as text', async () => {
  const reference = doc(
    ownerDb(),
    weightPath(ownerId),
  );

  await assertFails(
    setDoc(reference, validWeight({ weightKg: '65.5' })),
  );
});

test('rejects future measurement dates', async () => {
  const reference = doc(
    ownerDb(),
    weightPath(ownerId),
  );

  const futureDate = new Date(
    Date.now() + 24 * 60 * 60 * 1000,
  );

  await assertFails(
    setDoc(
      reference,
      validWeight({
        measuredAt: Timestamp.fromDate(futureDate),
      }),
    ),
  );
});

test('rejects invalid measurement date type', async () => {
  const reference = doc(
    ownerDb(),
    weightPath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validWeight({ measuredAt: '2025-10-09' }),
    ),
  );
});

test('rejects unexpected document fields', async () => {
  const reference = doc(
    ownerDb(),
    weightPath(ownerId),
  );

  await assertFails(
    setDoc(
      reference,
      validWeight({ isAdmin: true }),
    ),
  );
});

test('rejects invalid update to existing record', async () => {
  const reference = await createOwnerWeight();

  await assertFails(
    updateDoc(reference, {
      weightKg: -10,
    }),
  );
});
