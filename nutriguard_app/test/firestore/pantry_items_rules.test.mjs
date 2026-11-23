
import { readFileSync } from 'node:fs';
import { before, after, beforeEach, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

import {
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  Timestamp,
} from 'firebase/firestore';

let env;

const projectId = 'nutriguard-18dbd';

const validPantryItem = {
  name: 'Rice',
  quantity: 5,
  unit: 'kg',
  category: 'Grains',
  expiryDate: Timestamp.fromDate(new Date('2027-06-30')),
  createdAt: Timestamp.fromDate(new Date('2026-11-16')),
};

function pantryRef(db, userId, id = 'item-1') {
  return doc(db, 'users', userId, 'pantryItems', id);
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

test('owner can create and read valid pantry item', async () => {
  const db = userDb('alice');
  const ref = pantryRef(db, 'alice');

  await assertSucceeds(setDoc(ref, validPantryItem));

  const snapshot = await assertSucceeds(getDoc(ref));

  if (!snapshot.exists()) {
    throw new Error('Pantry item was not created.');
  }
});

test('owner can update pantry item without changing createdAt', async () => {
  const db = userDb('alice');
  const ref = pantryRef(db, 'alice');

  await setDoc(ref, validPantryItem);

  await assertSucceeds(
    updateDoc(ref, {
      quantity: 3,
    }),
  );
});

test('owner can delete pantry item', async () => {
  const db = userDb('alice');
  const ref = pantryRef(db, 'alice');

  await setDoc(ref, validPantryItem);

  await assertSucceeds(deleteDoc(ref));
});

test('another user cannot read pantry item', async () => {
  await setDoc(
    pantryRef(userDb('alice'), 'alice'),
    validPantryItem,
  );

  await assertFails(
    getDoc(pantryRef(userDb('bob'), 'alice')),
  );
});

test('another user cannot create pantry item in another account', async () => {
  await assertFails(
    setDoc(
      pantryRef(userDb('bob'), 'alice'),
      validPantryItem,
    ),
  );
});

test('unauthenticated user cannot read pantry item', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(getDoc(pantryRef(db, 'alice')));
});

test('unauthenticated user cannot create pantry item', async () => {
  const db = env.unauthenticatedContext().firestore();

  await assertFails(
    setDoc(pantryRef(db, 'alice'), validPantryItem),
  );
});

test('rejects missing required fields', async () => {
  const db = userDb('alice');
  const { name, ...invalid } = validPantryItem;

  await assertFails(
    setDoc(pantryRef(db, 'alice'), invalid),
  );
});

test('rejects unexpected fields', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      pantryRef(db, 'alice'),
      { ...validPantryItem, extraField: true },
    ),
  );
});

test('rejects empty item name', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      pantryRef(db, 'alice'),
      { ...validPantryItem, name: '' },
    ),
  );
});

test('rejects whitespace-only item name', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      pantryRef(db, 'alice'),
      { ...validPantryItem, name: '   ' },
    ),
  );
});

test('rejects zero quantity', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      pantryRef(db, 'alice'),
      { ...validPantryItem, quantity: 0 },
    ),
  );
});

test('rejects negative quantity', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      pantryRef(db, 'alice'),
      { ...validPantryItem, quantity: -1 },
    ),
  );
});

test('rejects invalid expiry date type', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      pantryRef(db, 'alice'),
      { ...validPantryItem, expiryDate: '2027-06-30' },
    ),
  );
});

test('allows null expiry date', async () => {
  const db = userDb('alice');

  await assertSucceeds(
    setDoc(
      pantryRef(db, 'alice'),
      { ...validPantryItem, expiryDate: null },
    ),
  );
});

test('allows optional low stock threshold', async () => {
  const db = userDb('alice');

  await assertSucceeds(
    setDoc(
      pantryRef(db, 'alice'),
      { ...validPantryItem, lowStockThreshold: 2 },
    ),
  );
});

test('allows removing optional low stock threshold', async () => {
  const db = userDb('alice');
  const ref = pantryRef(db, 'alice');

  await setDoc(ref, {
    ...validPantryItem,
    lowStockThreshold: 2,
  });

  await assertSucceeds(
    updateDoc(ref, {
      lowStockThreshold: deleteField(),
    }),
  );
});

test('rejects negative low stock threshold', async () => {
  const db = userDb('alice');

  await assertFails(
    setDoc(
      pantryRef(db, 'alice'),
      { ...validPantryItem, lowStockThreshold: -1 },
    ),
  );
});

test('rejects update that changes createdAt', async () => {
  const db = userDb('alice');
  const ref = pantryRef(db, 'alice');

  await setDoc(ref, validPantryItem);

  await assertFails(
    updateDoc(ref, {
      createdAt: Timestamp.now(),
    }),
  );
});
