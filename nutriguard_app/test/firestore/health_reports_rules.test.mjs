
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

const validReport = {
  reportType: 'Blood Test',
  reportName: 'Annual Blood Report',
  reportDate: '2026-11-16',
  measurements: [
    { name: 'Total Cholesterol', value: 180, unit: 'mg/dL' },
    { name: 'Blood Glucose', value: 95, unit: 'mg/dL' },
  ],
};

function reportRef(db, userId, reportId = 'report-1') {
  return doc(db, 'users', userId, 'healthReports', reportId);
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

test('owner can create and read a valid health report', async () => {
  const db = userDb('alice');
  const ref = reportRef(db, 'alice');

  await assertSucceeds(setDoc(ref, validReport));

  const snapshot = await assertSucceeds(getDoc(ref));

  if (!snapshot.exists()) {
    throw new Error('Health report was not created.');
  }
});

test('owner can update a valid health report', async () => {
  const db = userDb('alice');
  const ref = reportRef(db, 'alice');

  await setDoc(ref, validReport);

  await assertSucceeds(
    updateDoc(ref, { reportName: 'Updated Blood Report' }),
  );
});

test('owner can delete a health report', async () => {
  const db = userDb('alice');
  const ref = reportRef(db, 'alice');

  await setDoc(ref, validReport);

  await assertSucceeds(deleteDoc(ref));
});

test('another user cannot read a health report', async () => {
  await setDoc(
    reportRef(userDb('alice'), 'alice'),
    validReport,
  );

  await assertFails(
    getDoc(reportRef(userDb('bob'), 'alice')),
  );
});

test('another user cannot create a report in another account', async () => {
  await assertFails(
    setDoc(
      reportRef(userDb('bob'), 'alice'),
      validReport,
    ),
  );
});

test('unauthenticated user cannot read a health report', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(getDoc(reportRef(db, 'alice')));
});

test('unauthenticated user cannot create a health report', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(
    setDoc(reportRef(db, 'alice'), validReport),
  );
});

test('rejects missing required report fields', async () => {
  const db = userDb('alice');

  const { reportName, ...invalidReport } = validReport;

  await assertFails(
    setDoc(reportRef(db, 'alice'), invalidReport),
  );
});

test('rejects unexpected report fields', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      reportRef(db, 'alice'),
      { ...validReport, extraField: true },
    ),
  );
});

test('rejects empty report name', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      reportRef(db, 'alice'),
      { ...validReport, reportName: '' },
    ),
  );
});

test('rejects report type exceeding 100 characters', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      reportRef(db, 'alice'),
      { ...validReport, reportType: 'A'.repeat(101) },
    ),
  );
});

test('rejects report name exceeding 150 characters', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      reportRef(db, 'alice'),
      { ...validReport, reportName: 'A'.repeat(151) },
    ),
  );
});

test('rejects empty measurements list', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      reportRef(db, 'alice'),
      { ...validReport, measurements: [] },
    ),
  );
});

test('rejects more than 10 measurements', async () => {
  const db = userDb('alice');

  const measurements = Array.from(
    { length: 11 },
    (_, index) => ({
      name: `Measurement ${index}`,
      value: 10,
      unit: 'mg/dL',
    }),
  );

  await assertFails(
    setDoc(
      reportRef(db, 'alice'),
      { ...validReport, measurements },
    ),
  );
});

test('rejects a measurement with missing fields', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      reportRef(db, 'alice'),
      {
        ...validReport,
        measurements: [
          { name: 'Cholesterol', value: 180 },
        ],
      },
    ),
  );
});

test('rejects a measurement with an invalid value type', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      reportRef(db, 'alice'),
      {
        ...validReport,
        measurements: [
          { name: 'Cholesterol', value: '180', unit: 'mg/dL' },
        ],
      },
    ),
  );
});

test('rejects unexpected measurement fields', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      reportRef(db, 'alice'),
      {
        ...validReport,
        measurements: [
          {
            name: 'Cholesterol',
            value: 180,
            unit: 'mg/dL',
            extra: true,
          },
        ],
      },
    ),
  );
});
