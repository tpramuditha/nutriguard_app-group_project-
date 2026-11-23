
const { test, before, beforeEach, after } = require("node:test");
const assert = require("node:assert/strict");

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const {
  collection,
  doc,
  setDoc,
  getDoc,
  getDocs,
  Timestamp,
} = require("firebase/firestore");

const fs = require("node:fs");

let testEnv;

const projectId = "demo-nutriguard-idempotency";
const userId = "test-food-owner";

function validFoodLog(name = "Rice and Dhal Curry") {
  return {
    foodId: "manual-test-001",
    foodName: name,
    brand: null,
    source: "Manual Entry",
    grams: 100,
    mealType: "Breakfast",
    calories: 150,
    protein: 10,
    carbs: 20,
    fat: 5,
    loggedAt: Timestamp.fromDate(
      new Date("2026-11-02T08:00:00Z")
    ),
  };
}

function foodLogRef(context, submissionId) {
  return doc(
    context.firestore(),
    "users",
    userId,
    "foodLogs",
    submissionId
  );
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: fs.readFileSync("firestore.rules", "utf8"),
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

test("first submission creates a food log", async () => {
  const owner = testEnv.authenticatedContext(userId);
  const ref = foodLogRef(owner, "submission-001");

  await assertSucceeds(
    setDoc(ref, validFoodLog())
  );

  const snapshot = await getDoc(ref);

  assert.equal(snapshot.exists(), true);
  assert.equal(
    snapshot.data().foodName,
    "Rice and Dhal Curry"
  );
});

test("retry with same ID cannot overwrite existing log", async () => {
  const owner = testEnv.authenticatedContext(userId);
  const ref = foodLogRef(owner, "submission-001");

  await assertSucceeds(
    setDoc(ref, validFoodLog())
  );

  // This second set() becomes an UPDATE.
  // Current security rules should reject it.
  await assertFails(
    setDoc(ref, validFoodLog("Changed Food"))
  );

  // Verify that the original record remains unchanged.
  const snapshot = await getDoc(ref);

  assert.equal(
    snapshot.data().foodName,
    "Rice and Dhal Curry"
  );

  // There should still be just one document.
  const logs = await getDocs(
    collection(
      owner.firestore(),
      "users",
      userId,
      "foodLogs"
    )
  );

  assert.equal(logs.size, 1);
});

test("different submission IDs create separate logs", async () => {
  const owner = testEnv.authenticatedContext(userId);

  await assertSucceeds(
    setDoc(
      foodLogRef(owner, "submission-001"),
      validFoodLog()
    )
  );

  await assertSucceeds(
    setDoc(
      foodLogRef(owner, "submission-002"),
      validFoodLog()
    )
  );

  const logs = await getDocs(
    collection(
      owner.firestore(),
      "users",
      userId,
      "foodLogs"
    )
  );

  assert.equal(logs.size, 2);
});
