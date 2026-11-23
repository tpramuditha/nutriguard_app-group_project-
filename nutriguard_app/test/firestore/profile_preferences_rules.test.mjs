
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
} from 'firebase/firestore';

let env;

const projectId = 'nutriguard-18dbd';

const validProfile = {
  dietaryRestrictions: ['Halal'],
  allergies: ['Peanuts', 'Shellfish'],
  unitSystem: 'Metric',
};

const validNotifications = {
  mealReminders: true,
  monthlyHealthMarkerReminders: true,
  aiSuggestionAlerts: false,
};

const validNutrition = {
  dailyCalorieTarget: 2000,
  goalType: 'Weight Loss',
};

function preferenceDoc(db, userId, preferenceId) {
  return doc(
    db,
    'users',
    userId,
    'preferences',
    preferenceId,
  );
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

// PROFILE PREFERENCES

test('owner can create and read valid profile preferences', async () => {
  const db = env.authenticatedContext('user-1').firestore();
  const ref = preferenceDoc(db, 'user-1', 'profile');

  await assertSucceeds(setDoc(ref, validProfile));

  const snapshot = await assertSucceeds(getDoc(ref));

  if (!snapshot.exists()) {
    throw new Error('Profile preferences document was not created.');
  }
});

test('owner can update profile preferences', async () => {
  const db = env.authenticatedContext('user-1').firestore();
  const ref = preferenceDoc(db, 'user-1', 'profile');

  await setDoc(ref, validProfile);

  await assertSucceeds(
    updateDoc(ref, {
      dietaryRestrictions: ['Vegetarian'],
      unitSystem: 'Imperial',
    }),
  );
});

test('another user cannot read profile preferences', async () => {
  const ownerDb = env.authenticatedContext('user-1').firestore();
  const otherDb = env.authenticatedContext('user-2').firestore();

  await setDoc(
    preferenceDoc(ownerDb, 'user-1', 'profile'),
    validProfile,
  );

  await assertFails(
    getDoc(preferenceDoc(otherDb, 'user-1', 'profile')),
  );
});

test('another user cannot overwrite profile preferences', async () => {
  const otherDb = env.authenticatedContext('user-2').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(otherDb, 'user-1', 'profile'),
      validProfile,
    ),
  );
});

test('unauthenticated user cannot read profile preferences', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(
    getDoc(preferenceDoc(db, 'user-1', 'profile')),
  );
});

test('unauthenticated user cannot create profile preferences', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'profile'),
      validProfile,
    ),
  );
});

test('rejects None combined with another dietary restriction', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'profile'),
      {
        ...validProfile,
        dietaryRestrictions: ['None', 'Vegan'],
      },
    ),
  );
});

test('rejects unknown dietary restrictions', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'profile'),
      {
        ...validProfile,
        dietaryRestrictions: ['Keto'],
      },
    ),
  );
});

test('rejects empty dietary restrictions', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'profile'),
      {
        ...validProfile,
        dietaryRestrictions: [],
      },
    ),
  );
});

test('rejects invalid unit system', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'profile'),
      {
        ...validProfile,
        unitSystem: 'Other',
      },
    ),
  );
});

test('rejects profile preferences with missing fields', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'profile'),
      {
        dietaryRestrictions: ['Halal'],
        allergies: ['Peanuts'],
      },
    ),
  );
});

test('rejects unexpected profile preference fields', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'profile'),
      {
        ...validProfile,
        extraField: true,
      },
    ),
  );
});

test('rejects more than 30 allergy entries', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'profile'),
      {
        ...validProfile,
        allergies: Array.from(
          { length: 31 },
          (_, index) => `Allergy ${index + 1}`,
        ),
      },
    ),
  );
});

// NOTIFICATION PREFERENCES

test('owner can create and read valid notification preferences', async () => {
  const db = env.authenticatedContext('user-1').firestore();
  const ref = preferenceDoc(db, 'user-1', 'notifications');

  await assertSucceeds(setDoc(ref, validNotifications));

  const snapshot = await assertSucceeds(getDoc(ref));

  if (!snapshot.exists()) {
    throw new Error('Notification preferences were not created.');
  }
});

test('owner can update notification preferences', async () => {
  const db = env.authenticatedContext('user-1').firestore();
  const ref = preferenceDoc(db, 'user-1', 'notifications');

  await setDoc(ref, validNotifications);

  await assertSucceeds(
    updateDoc(ref, {
      mealReminders: false,
    }),
  );
});

test('another user cannot read notification preferences', async () => {
  const ownerDb = env.authenticatedContext('user-1').firestore();
  const otherDb = env.authenticatedContext('user-2').firestore();

  await setDoc(
    preferenceDoc(ownerDb, 'user-1', 'notifications'),
    validNotifications,
  );

  await assertFails(
    getDoc(preferenceDoc(otherDb, 'user-1', 'notifications')),
  );
});

test('rejects notification preferences with non-boolean values', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'notifications'),
      {
        ...validNotifications,
        mealReminders: 'yes',
      },
    ),
  );
});

test('rejects notification preferences with missing fields', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'notifications'),
      {
        mealReminders: true,
      },
    ),
  );
});

test('rejects unexpected notification preference fields', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'notifications'),
      {
        ...validNotifications,
        extraField: true,
      },
    ),
  );
});

// EXISTING NUTRITION PREFERENCES

test('existing nutrition preferences still work', async () => {
  const db = env.authenticatedContext('user-1').firestore();
  const ref = preferenceDoc(db, 'user-1', 'nutrition');

  await assertSucceeds(setDoc(ref, validNutrition));
  await assertSucceeds(getDoc(ref));
});

test('rejects invalid nutrition preferences', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'nutrition'),
      {
        dailyCalorieTarget: -100,
        goalType: 'Weight Loss',
      },
    ),
  );
});

// GENERAL PREFERENCE SECURITY

test('rejects unknown preference document IDs', async () => {
  const db = env.authenticatedContext('user-1').firestore();

  await assertFails(
    setDoc(
      preferenceDoc(db, 'user-1', 'unknown'),
      { value: true },
    ),
  );
});

test('owner cannot delete profile preferences', async () => {
  const db = env.authenticatedContext('user-1').firestore();
  const ref = preferenceDoc(db, 'user-1', 'profile');

  await setDoc(ref, validProfile);

  await assertFails(deleteDoc(ref));
});

test('owner cannot delete notification preferences', async () => {
  const db = env.authenticatedContext('user-1').firestore();
  const ref = preferenceDoc(db, 'user-1', 'notifications');

  await setDoc(ref, validNotifications);

  await assertFails(deleteDoc(ref));
});
