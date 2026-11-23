
const {
  test,
  before,
  beforeEach,
  after,
} = require('node:test');

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
  deleteField,
  Timestamp,
} = require('firebase/firestore');

let testEnv;

const projectId = 'nutriguard-18dbd';
const userId = 'low_stock_test_user';

function itemPath(itemId = 'rice_001') {
  return `users/${userId}/pantryItems/${itemId}`;
}

function validItem(overrides = {}) {
  return {
    name: 'Rice',
    quantity: 2,
    unit: 'kg',
    category: 'Grains',
    expiryDate: null,
    createdAt: Timestamp.fromDate(
      new Date('2026-11-04T09:00:00Z'),
    ),
    ...overrides,
  };
}

function ownerDb() {
  return testEnv.authenticatedContext(userId).firestore();
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

test('allows a valid low-stock threshold', async () => {
  const reference = doc(ownerDb(), itemPath());

  await assertSucceeds(
    setDoc(
      reference,
      validItem({ lowStockThreshold: 5 }),
    ),
  );

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  if (snapshot.data().lowStockThreshold !== 5) {
    throw new Error('Threshold was not saved correctly.');
  }
});

test('allows older records without a threshold', async () => {
  const reference = doc(ownerDb(), itemPath());

  await assertSucceeds(
    setDoc(reference, validItem()),
  );
});

test('rejects a negative threshold', async () => {
  const reference = doc(ownerDb(), itemPath());

  await assertFails(
    setDoc(
      reference,
      validItem({ lowStockThreshold: -1 }),
    ),
  );
});

test('rejects a string threshold', async () => {
  const reference = doc(ownerDb(), itemPath());

  await assertFails(
    setDoc(
      reference,
      validItem({ lowStockThreshold: 'five' }),
    ),
  );
});

test('rejects thresholds greater than the maximum', async () => {
  const reference = doc(ownerDb(), itemPath());

  await assertFails(
    setDoc(
      reference,
      validItem({ lowStockThreshold: 1000001 }),
    ),
  );
});

test('allows the owner to update their threshold', async () => {
  const reference = doc(ownerDb(), itemPath());

  await assertSucceeds(
    setDoc(
      reference,
      validItem({ lowStockThreshold: 2 }),
    ),
  );

  await assertSucceeds(
    updateDoc(reference, {
      lowStockThreshold: 5,
    }),
  );

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  if (snapshot.data().lowStockThreshold !== 5) {
    throw new Error('Threshold update failed.');
  }
});

test('allows removing an existing threshold', async () => {
  const reference = doc(ownerDb(), itemPath());

  await assertSucceeds(
    setDoc(
      reference,
      validItem({ lowStockThreshold: 2 }),
    ),
  );

  await assertSucceeds(
    updateDoc(reference, {
      lowStockThreshold: deleteField(),
    }),
  );

  const snapshot = await assertSucceeds(
    getDoc(reference),
  );

  if ('lowStockThreshold' in snapshot.data()) {
    throw new Error('Threshold was not removed.');
  }
});
