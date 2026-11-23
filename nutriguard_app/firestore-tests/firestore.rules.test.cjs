
const { test, before, beforeEach, after } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

let testEnv;

const validReport = {
  reportType: 'Lipid Profile',
  reportName: 'Lipid Profile',
  reportDate: '2026-10-17T00:00:00.000',
  measurements: [
    {
      name: 'Total Cholesterol',
      value: 185,
      unit: 'mg/dL',
    },
  ],
};


const validMonthlyMarkers = {
  month: '2026-10',
  measurements: [
    {
      name: 'Total Cholesterol',
      value: 185,
      unit: 'mg/dL',
    },
    {
      name: 'Fasting Blood Glucose',
      value: 95,
      unit: 'mg/dL',
    },
    {
      name: 'Systolic Blood Pressure',
      value: 120,
      unit: 'mmHg',
    },
    {
      name: 'Diastolic Blood Pressure',
      value: 80,
      unit: 'mmHg',
    },
  ],
};


// Load the rules from the Flutter project root.
before(async () => {
  const rulesPath = path.join(
    __dirname,
    '..',
    'firestore.rules',
  );

  testEnv = await initializeTestEnvironment({
    projectId: 'nutriguard-18dbd',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(rulesPath, 'utf8'),
    },
  });
});

// Start each test with an empty local database.
beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

test('User A can create their own report', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const report = db.doc('users/userA/healthReports/report1');

  await assertSucceeds(report.set(validReport));
});

test('User A can read their own report', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const report = db.doc('users/userA/healthReports/report1');

  await assertSucceeds(report.get());
});

test('User A cannot read User B report', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const report = db.doc('users/userB/healthReports/report1');

  await assertFails(report.get());
});

test('User A cannot write User B report', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const report = db.doc('users/userB/healthReports/report1');

  await assertFails(report.set(validReport));
});

test('Signed-out users cannot read reports', async () => {
  const db = testEnv.unauthenticatedContext().firestore();

  const report = db.doc('users/userA/healthReports/report1');

  await assertFails(report.get());
});

test('Missing required fields are rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const report = db.doc('users/userA/healthReports/report1');

  await assertFails(
    report.set({
      reportName: 'Lipid Profile',
    }),
  );
});

test('Empty measurements are rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const report = db.doc('users/userA/healthReports/report1');

  await assertFails(
    report.set({
      ...validReport,
      measurements: [],
    }),
  );
});

test('Other collections remain inaccessible', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const document = db.doc('adminSettings/config');

  await assertFails(document.get());
});



test('Invalid measurement values are rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const report = db.doc(
    'users/userA/healthReports/invalidMeasurement'
  );

  await assertFails(
    report.set({
      ...validReport,
      measurements: [
        {
          name: 'Creatinine',
          value: 'hello',
          unit: 'mg/dL',
        },
      ],
    }),
  );
});



test('Invalid second measurement is rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const report = db.doc(
    'users/userA/healthReports/invalidSecondMeasurement'
  );

  await assertFails(
    report.set({
      ...validReport,
      measurements: [
        {
          name: 'Total Cholesterol',
          value: 185,
          unit: 'mg/dL',
        },
        {
          name: 'LDL Cholesterol',
          value: 'invalid',
          unit: 'mg/dL',
        },
      ],
    }),
  );
});

test('More than 10 measurements are rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const report = db.doc(
    'users/userA/healthReports/tooManyMeasurements'
  );

  const measurements = Array.from(
    { length: 11 },
    (_, index) => ({
      name: `Measurement ${index + 1}`,
      value: 10 + index,
      unit: 'mg/dL',
    }),
  );

  await assertFails(
    report.set({
      ...validReport,
      measurements,
    }),
  );
});


// ==============================================
// Monthly Health Marker Firestore Security Tests
// ==============================================

test('User A can create their own monthly markers', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertSucceeds(marker.set(validMonthlyMarkers));
});

test('User A can read their own monthly markers', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertSucceeds(marker.set(validMonthlyMarkers));
  await assertSucceeds(marker.get());
});

test('User A can update their own monthly markers', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertSucceeds(marker.set(validMonthlyMarkers));

  await assertSucceeds(
    marker.update({
      measurements: [
        {
          name: 'Total Cholesterol',
          value: 190,
          unit: 'mg/dL',
        },
      ],
    }),
  );
});

test('User A cannot read User B monthly markers', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userB/monthlyHealthMarkers/2026-10'
  );

  await assertFails(marker.get());
});

test('User A cannot write User B monthly markers', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userB/monthlyHealthMarkers/2026-10'
  );

  await assertFails(marker.set(validMonthlyMarkers));
});

test('Signed-out users cannot access monthly markers', async () => {
  const db = testEnv.unauthenticatedContext().firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertFails(marker.get());
  await assertFails(marker.set(validMonthlyMarkers));
});

test('Invalid month document ID is rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/October2026'
  );

  await assertFails(marker.set(validMonthlyMarkers));
});

test('Mismatched month and document ID are rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertFails(
    marker.set({
      ...validMonthlyMarkers,
      month: '2026-09',
    }),
  );
});

test('Empty monthly measurements are rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertFails(
    marker.set({
      ...validMonthlyMarkers,
      measurements: [],
    }),
  );
});

test('Invalid monthly measurement value is rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertFails(
    marker.set({
      ...validMonthlyMarkers,
      measurements: [
        {
          name: 'Total Cholesterol',
          value: -10,
          unit: 'mg/dL',
        },
      ],
    }),
  );
});

test('Incorrect blood pressure unit is rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertFails(
    marker.set({
      ...validMonthlyMarkers,
      measurements: [
        {
          name: 'Systolic Blood Pressure',
          value: 120,
          unit: 'mg/dL',
        },
      ],
    }),
  );
});

test('More than 7 monthly measurements are rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  const measurements = Array.from(
    { length: 8 },
    () => ({
      name: 'Total Cholesterol',
      value: 185,
      unit: 'mg/dL',
    }),
  );

  await assertFails(
    marker.set({
      ...validMonthlyMarkers,
      measurements,
    }),
  );
});

test('Unexpected monthly marker fields are rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertFails(
    marker.set({
      ...validMonthlyMarkers,
      unexpectedField: 'test',
    }),
  );
});


test('Duplicate monthly measurement names are rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertFails(
    marker.set({
      month: '2026-10',
      measurements: [
        {
          name: 'Total Cholesterol',
          value: 185,
          unit: 'mg/dL',
        },
        {
          name: 'Total Cholesterol',
          value: 190,
          unit: 'mg/dL',
        },
      ],
    }),
  );
});

test('Incomplete blood pressure pairs are rejected', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertFails(
    marker.set({
      month: '2026-10',
      measurements: [
        {
          name: 'Systolic Blood Pressure',
          value: 120,
          unit: 'mmHg',
        },
      ],
    }),
  );

  await assertFails(
    marker.set({
      month: '2026-10',
      measurements: [
        {
          name: 'Diastolic Blood Pressure',
          value: 80,
          unit: 'mmHg',
        },
      ],
    }),
  );
});


test('All seven monthly health markers can be saved together', async () => {
  const db = testEnv.authenticatedContext('userA').firestore();

  const marker = db.doc(
    'users/userA/monthlyHealthMarkers/2026-10'
  );

  await assertSucceeds(
    marker.set({
      month: '2026-10',
      measurements: [
        {
          name: 'Total Cholesterol',
          value: 185,
          unit: 'mg/dL',
        },
        {
          name: 'LDL Cholesterol',
          value: 110,
          unit: 'mg/dL',
        },
        {
          name: 'HDL Cholesterol',
          value: 55,
          unit: 'mg/dL',
        },
        {
          name: 'Triglycerides',
          value: 125,
          unit: 'mg/dL',
        },
        {
          name: 'Fasting Blood Glucose',
          value: 95,
          unit: 'mg/dL',
        },
        {
          name: 'Systolic Blood Pressure',
          value: 120,
          unit: 'mmHg',
        },
        {
          name: 'Diastolic Blood Pressure',
          value: 80,
          unit: 'mmHg',
        },
      ],
    }),
  );
});


