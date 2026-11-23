
const { test, before, beforeEach, after } = require('node:test');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  deleteDoc,
} = require('firebase/firestore');

const fs = require('node:fs');

let testEnv;

const projectId = 'demo-nutriguard-nutrition-goals';
const ownerId = 'nutrition-owner';
const otherUserId = 'another-user';

function validGoal() {
  return {
    dailyCalorieTarget: 2000,
    goalType: 'Maintain Weight',
  };
}

function goalRef(context, userId, preferenceId = 'nutrition') {
  return doc(
    context.firestore(),
    'users',
    userId,
    'preferences',
    preferenceId
  );
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

test('owner can create a valid nutrition goal', async () => {
  const owner = testEnv.authenticatedContext(ownerId);

  await assertSucceeds(
    setDoc(goalRef(owner, ownerId), validGoal())
  );
});

test('owner can read their nutrition goal', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      goalRef(context, ownerId),
      validGoal()
    );
  });

  const owner = testEnv.authenticatedContext(ownerId);

  await assertSucceeds(
    getDoc(goalRef(owner, ownerId))
  );
});

test('owner can update their nutrition goal', async () => {
  const owner = testEnv.authenticatedContext(ownerId);

  await assertSucceeds(
    setDoc(goalRef(owner, ownerId), validGoal())
  );

  await assertSucceeds(
    updateDoc(goalRef(owner, ownerId), {
      dailyCalorieTarget: 1800,
      goalType: 'Weight Loss',
    })
  );
});

test('another user cannot read nutrition goal', async () => {
  const otherUser = testEnv.authenticatedContext(otherUserId);

  await assertFails(
    getDoc(goalRef(otherUser, ownerId))
  );
});

test('another user cannot modify nutrition goal', async () => {
  const otherUser = testEnv.authenticatedContext(otherUserId);

  await assertFails(
    setDoc(goalRef(otherUser, ownerId), validGoal())
  );
});

test('unauthenticated user cannot create nutrition goal', async () => {
  const guest = testEnv.unauthenticatedContext();

  await assertFails(
    setDoc(goalRef(guest, ownerId), validGoal())
  );
});

test('invalid calorie target is rejected', async () => {
  const owner = testEnv.authenticatedContext(ownerId);

  await assertFails(
    setDoc(goalRef(owner, ownerId), {
      dailyCalorieTarget: -100,
      goalType: 'Maintain Weight',
    })
  );

  await assertFails(
    setDoc(goalRef(owner, ownerId), {
      dailyCalorieTarget: 10001,
      goalType: 'Maintain Weight',
    })
  );
});

test('invalid goal type is rejected', async () => {
  const owner = testEnv.authenticatedContext(ownerId);

  await assertFails(
    setDoc(goalRef(owner, ownerId), {
      dailyCalorieTarget: 2000,
      goalType: 'Invalid Goal',
    })
  );
});

test('owner cannot delete nutrition goal', async () => {
  const owner = testEnv.authenticatedContext(ownerId);

  await assertSucceeds(
    setDoc(goalRef(owner, ownerId), validGoal())
  );

  await assertFails(
    deleteDoc(goalRef(owner, ownerId))
  );
});

test('other preference documents are inaccessible', async () => {
  const owner = testEnv.authenticatedContext(ownerId);

  await assertFails(
    setDoc(
      goalRef(owner, ownerId, 'other-preference'),
      validGoal()
    )
  );

  await assertFails(
    getDoc(goalRef(owner, ownerId, 'other-preference'))
  );
});
