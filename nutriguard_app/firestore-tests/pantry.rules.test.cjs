
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
  Timestamp,
} = require('firebase/firestore');

let testEnv;

const projectId = 'nutriguard-18dbd';

const ownerId = 'pantry_test_owner';
const otherUserId = 'pantry_test_other';

function pantryPath(userId, itemId = 'item_001') {
  return `users/${userId}/pantryItems/${itemId}`;
}

function validItem(overrides = {}) {
  return {
    name: 'Eggs',
    quantity: 6,
    unit: 'pcs',
    category: 'Protein',
    expiryDate: Timestamp.fromDate(
      new Date('2026-11-10T00:00:00Z'),
    ),
    createdAt: Timestamp.fromDate(
      new Date('2026-11-04T09:00:00Z'),
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

test('owner can create a valid pantry item', async () => {
  const reference = doc(ownerDb(), pantryPath(ownerId));

  await assertSucceeds(
    setDoc(reference, validItem()),
  );
});

test('owner can read their pantry item', async () => {
  const reference = doc(ownerDb(), pantryPath(ownerId));

  await assertSucceeds(
    setDoc(reference, validItem()),
  );

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  assert.equal(snapshot.data().name, 'Eggs');
});

test('another user cannot read pantry data', async () => {
  const reference = doc(
    otherUserDb(),
    pantryPath(ownerId),
  );

  await assertFails(getDoc(reference));
});

test('another user cannot create pantry data', async () => {
  const reference = doc(
    otherUserDb(),
    pantryPath(ownerId),
  );

  await assertFails(
    setDoc(reference, validItem()),
  );
});

test('unauthenticated user cannot read pantry', async () => {
  const reference = doc(
    guestDb(),
    pantryPath(ownerId),
  );

  await assertFails(getDoc(reference));
});

test('rejects negative quantities', async () => {
  const reference = doc(ownerDb(), pantryPath(ownerId));

  await assertFails(
    setDoc(
      reference,
      validItem({ quantity: -5 }),
    ),
  );
});

test('rejects zero quantity', async () => {
  const reference = doc(ownerDb(), pantryPath(ownerId));

  await assertFails(
    setDoc(
      reference,
      validItem({ quantity: 0 }),
    ),
  );
});

test('rejects empty ingredient names', async () => {
  const reference = doc(ownerDb(), pantryPath(ownerId));

  await assertFails(
    setDoc(
      reference,
      validItem({ name: '   ' }),
    ),
  );
});

test('rejects unexpected fields', async () => {
  const reference = doc(ownerDb(), pantryPath(ownerId));

  await assertFails(
    setDoc(
      reference,
      validItem({ admin: true }),
    ),
  );
});

test('accepts an item without an expiry date', async () => {
  const reference = doc(ownerDb(), pantryPath(ownerId));

  await assertSucceeds(
    setDoc(
      reference,
      validItem({ expiryDate: null }),
    ),
  );
});

test('owner can update ingredient quantity', async () => {
  const reference = doc(ownerDb(), pantryPath(ownerId));

  await assertSucceeds(
    setDoc(reference, validItem()),
  );

  await assertSucceeds(
    updateDoc(reference, { quantity: 12 }),
  );
});

test('owner cannot change createdAt', async () => {
  const reference = doc(ownerDb(), pantryPath(ownerId));

  await assertSucceeds(
    setDoc(reference, validItem()),
  );

  await assertFails(
    updateDoc(reference, {
      createdAt: Timestamp.fromDate(
        new Date('2026-11-05T09:00:00Z'),
      ),
    }),
  );
});

test('owner can delete their pantry item', async () => {
  const reference = doc(ownerDb(), pantryPath(ownerId));

  await assertSucceeds(
    setDoc(reference, validItem()),
  );

  await assertSucceeds(
    deleteDoc(reference),
  );
});

test('another user cannot delete pantry item', async () => {
  const ownerReference = doc(
    ownerDb(),
    pantryPath(ownerId),
  );

  await assertSucceeds(
    setDoc(ownerReference, validItem()),
  );

  const otherReference = doc(
    otherUserDb(),
    pantryPath(ownerId),
  );

  await assertFails(
    deleteDoc(otherReference),
  );
});
