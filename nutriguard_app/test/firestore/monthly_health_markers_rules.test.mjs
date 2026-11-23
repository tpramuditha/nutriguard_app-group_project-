
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
const monthId = '2026-11';

const validMarkers = {
  month: monthId,
  measurements: [
    { name: 'Total Cholesterol', value: 180, unit: 'mg/dL' },
    { name: 'Systolic Blood Pressure', value: 120, unit: 'mmHg' },
    { name: 'Diastolic Blood Pressure', value: 80, unit: 'mmHg' },
  ],
};

function markerRef(db, userId, id = monthId) {
  return doc(db, 'users', userId, 'monthlyHealthMarkers', id);
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

test('owner can create and read valid monthly markers', async () => {
  const db = userDb('alice');
  const ref = markerRef(db, 'alice');

  await assertSucceeds(setDoc(ref, validMarkers));

  const snapshot = await assertSucceeds(getDoc(ref));

  if (!snapshot.exists()) {
    throw new Error('Monthly markers were not created.');
  }
});

test('owner can update monthly markers', async () => {
  const db = userDb('alice');
  const ref = markerRef(db, 'alice');

  await setDoc(ref, validMarkers);

  await assertSucceeds(
    updateDoc(ref, {
      measurements: [
        ...validMarkers.measurements,
        { name: 'HDL Cholesterol', value: 55, unit: 'mg/dL' },
      ],
    }),
  );
});

test('owner can delete monthly markers', async () => {
  const db = userDb('alice');
  const ref = markerRef(db, 'alice');

  await setDoc(ref, validMarkers);

  await assertSucceeds(deleteDoc(ref));
});

test('another user cannot read monthly markers', async () => {
  await setDoc(
    markerRef(userDb('alice'), 'alice'),
    validMarkers,
  );

  await assertFails(
    getDoc(markerRef(userDb('bob'), 'alice')),
  );
});

test('another user cannot create monthly markers in another account', async () => {
  await assertFails(
    setDoc(
      markerRef(userDb('bob'), 'alice'),
      validMarkers,
    ),
  );
});

test('unauthenticated user cannot read monthly markers', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(getDoc(markerRef(db, 'alice')));
});

test('rejects an invalid month document ID', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      markerRef(db, 'alice', '2026-13'),
      { ...validMarkers, month: '2026-13' },
    ),
  );
});

test('rejects month field different from document ID', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      markerRef(db, 'alice'),
      { ...validMarkers, month: '2026-10' },
    ),
  );
});

test('rejects unsupported marker names', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      markerRef(db, 'alice'),
      {
        ...validMarkers,
        measurements: [
          { name: 'Unknown Marker', value: 100, unit: 'mg/dL' },
        ],
      },
    ),
  );
});

test('rejects incorrect blood pressure unit', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      markerRef(db, 'alice'),
      {
        ...validMarkers,
        measurements: [
          { name: 'Systolic Blood Pressure', value: 120, unit: 'mg/dL' },
          { name: 'Diastolic Blood Pressure', value: 80, unit: 'mmHg' },
        ],
      },
    ),
  );
});

test('rejects blood pressure without its matching measurement', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      markerRef(db, 'alice'),
      {
        ...validMarkers,
        measurements: [
          { name: 'Systolic Blood Pressure', value: 120, unit: 'mmHg' },
        ],
      },
    ),
  );
});

test('rejects duplicate marker names', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      markerRef(db, 'alice'),
      {
        ...validMarkers,
        measurements: [
          { name: 'Total Cholesterol', value: 180, unit: 'mg/dL' },
          { name: 'Total Cholesterol', value: 190, unit: 'mg/dL' },
        ],
      },
    ),
  );
});

test('rejects zero or negative marker values', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      markerRef(db, 'alice'),
      {
        ...validMarkers,
        measurements: [
          { name: 'Total Cholesterol', value: 0, unit: 'mg/dL' },
        ],
      },
    ),
  );
});

test('rejects more than seven measurements', async () => {
  const db = userDb('alice');

  const measurements = [
    'Total Cholesterol',
    'LDL Cholesterol',
    'HDL Cholesterol',
    'Triglycerides',
    'Fasting Blood Glucose',
    'Random Blood Glucose',
    'After Meal Blood Glucose',
    'Systolic Blood Pressure',
  ].map((name) => ({
    name,
    value: 100,
    unit: 'mg/dL',
  }));

  await assertFails(
    setDoc(
      markerRef(db, 'alice'),
      { month: monthId, measurements },
    ),
  );
});

test('rejects unexpected document fields', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      markerRef(db, 'alice'),
      { ...validMarkers, extraField: true },
    ),
  );
});
