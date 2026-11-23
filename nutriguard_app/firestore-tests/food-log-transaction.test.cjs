
const { test, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');

const {
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  collection,
  getDoc,
  getDocs,
  runTransaction,
  Timestamp,
} = require('firebase/firestore');

const fs = require('node:fs');

let testEnv;

const projectId = 'demo-nutriguard-transactions';
const userId = 'transaction-test-owner';

function validFoodLog(name = 'Rice and Dhal Curry') {
  return {
    foodId: 'manual-test-001',
    foodName: name,
    brand: null,
    source: 'Manual Entry',
    grams: 100,
    mealType: 'Breakfast',
    calories: 150,
    protein: 10,
    carbs: 20,
    fat: 5,
    loggedAt: Timestamp.fromDate(
      new Date('2026-11-02T09:00:00Z')
    ),
  };
}

function foodLogRef(context, submissionId) {
  return doc(
    context.firestore(),
    'users',
    userId,
    'foodLogs',
    submissionId
  );
}

// JavaScript equivalent of the Dart repository's
// transaction-based duplicate-save logic.
async function saveFoodLog(context, submissionId, data) {
  const reference = foodLogRef(context, submissionId);

  await runTransaction(context.firestore(), async (transaction) => {
    const snapshot = await transaction.get(reference);

    if (snapshot.exists()) {
      const existing = snapshot.data();

      for (const field of Object.keys(data)) {
        const oldValue = existing[field];
        const newValue = data[field];

        if (
          oldValue instanceof Timestamp &&
          newValue instanceof Timestamp
        ) {
          if (!oldValue.isEqual(newValue)) {
            throw new Error('Conflicting submission');
          }
        } else if (oldValue !== newValue) {
          throw new Error('Conflicting submission');
        }
      }

      // Existing identical submission: no write.
      return;
    }

    transaction.set(reference, data);
  });

  return submissionId;
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync('firestore.rules', 'utf8'),
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

test('transaction creates a new food log', async () => {
  const owner = testEnv.authenticatedContext(userId);

  const id = await saveFoodLog(
    owner,
    'submission-001',
    validFoodLog()
  );

  const snapshot = await getDoc(
    foodLogRef(owner, id)
  );

  assert.equal(id, 'submission-001');
  assert.equal(snapshot.exists(), true);
  assert.equal(
    snapshot.data().foodName,
    'Rice and Dhal Curry'
  );
});

test('retry with identical data does not create a duplicate', async () => {
  const owner = testEnv.authenticatedContext(userId);

  await saveFoodLog(
    owner,
    'submission-001',
    validFoodLog()
  );

  const retryId = await saveFoodLog(
    owner,
    'submission-001',
    validFoodLog()
  );

  const logs = await getDocs(
    collection(
      owner.firestore(),
      'users',
      userId,
      'foodLogs'
    )
  );

  assert.equal(retryId, 'submission-001');
  assert.equal(logs.size, 1);
});

test('conflicting retry is rejected without overwriting', async () => {
  const owner = testEnv.authenticatedContext(userId);

  await saveFoodLog(
    owner,
    'submission-001',
    validFoodLog()
  );

  await assert.rejects(
    saveFoodLog(
      owner,
      'submission-001',
      validFoodLog('Chicken Kottu')
    ),
    /Conflicting submission/
  );

  const snapshot = await getDoc(
    foodLogRef(owner, 'submission-001')
  );

  assert.equal(
    snapshot.data().foodName,
    'Rice and Dhal Curry'
  );
});

test('different submission IDs create separate logs', async () => {
  const owner = testEnv.authenticatedContext(userId);

  await saveFoodLog(
    owner,
    'submission-001',
    validFoodLog()
  );

  await saveFoodLog(
    owner,
    'submission-002',
    validFoodLog()
  );

  const logs = await getDocs(
    collection(
      owner.firestore(),
      'users',
      userId,
      'foodLogs'
    )
  );

  assert.equal(logs.size, 2);
});
