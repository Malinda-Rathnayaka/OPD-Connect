import { readFile } from 'node:fs/promises';
import { before, after, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection, doc, getDoc, getDocs, setDoc, updateDoc, writeBatch,
  serverTimestamp, Timestamp, runTransaction, query, orderBy, limit,
} from 'firebase/firestore';

let env;
const contactRecord = {
  type: 'directory', title: 'Nimali Perera', detail: 'Reception coordinator',
  category: 'General OPD', contact: '011 269 1111', active: true, revision: 1,
};

for (const actorId of ['admin', 'super']) {
  test(`${actorId} can create read update and delete staff contacts and notices`, async () => {
    const db = env.authenticatedContext(actorId).firestore();
    for (const type of ['directory', 'notice']) {
      const ref = doc(db, 'staff_records', type);
      const data = type === 'directory' ? contactRecord : {
        ...contactRecord, type, title: 'Morning briefing', category: 'All staff', contact: '',
      };
      await assertSucceeds(setDoc(ref, data));
      assert.equal((await getDoc(ref)).data().revision, 1);
      await assertSucceeds(updateDoc(ref, { title: 'Updated record', revision: 2 }));
      await assertFails(updateDoc(ref, { title: 'Stale edit', revision: 2 }));
      const batch = writeBatch(db);
      batch.delete(ref);
      batch.set(doc(collection(db, 'staff_activity')), {
        title: 'Record deleted', detail: data.title, actor: 'Hospital Admin', actorId,
        recordId: type, recordType: type, operation: 'deleted', time: serverTimestamp(),
      });
      await assertSucceeds(batch.commit());
      assert.equal((await getDoc(ref)).exists(), false);
    }
  });
  test(`${actorId} can save department create update delete lists`, async () => {
    const db = env.authenticatedContext(actorId).firestore();
    const ref = doc(db, 'hospital_settings', 'default');
    for (const departments of [
      [{ id: 'lab', name: 'Laboratory', location: 'Block D', active: true }],
      [{ id: 'lab', name: 'Laboratory', location: 'Block E', active: true }], [],
    ]) await assertSucceeds(updateDoc(ref, {
      name: 'Test Hospital', address: 'Colombo 10', phone: '011 269 1111', departments,
    }));
    await assertFails(updateDoc(ref, { departments: 'invalid' }));
  });
}
for (const actorId of [null, 'support', 'patient', 'doctor', 'missing', 'inactive']) {
  test(`${actorId ?? 'anonymous'} cannot mutate staff CRUD records`, async () => {
    const db = actorId ? env.authenticatedContext(actorId).firestore() : env.unauthenticatedContext().firestore();
    await assertFails(setDoc(doc(db, 'staff_records', 'contact'), contactRecord));
    await assertFails(updateDoc(doc(db, 'hospital_settings', 'default'), {
      name: 'Test Hospital', address: 'Colombo 10', phone: '011 269 1111', departments: [],
    }));
    if (actorId === 'support') await assertSucceeds(getDocs(collection(db, 'staff_records')));
    else await assertFails(getDocs(collection(db, 'staff_records')));
  });
}
test('staff records reject role fields, invalid notices and forged operational audit actors', async () => {
  const db = env.authenticatedContext('admin').firestore();
  const ref = doc(db, 'staff_records', 'invalid');
  await assertFails(setDoc(ref, { ...contactRecord, staffRole: 'Super administrator' }));
  await assertFails(setDoc(ref, { ...contactRecord, type: 'notice', category: 'Unknown' }));
  await assertFails(setDoc(ref, { ...contactRecord, title: '', contact: 'x' }));
  await assertFails(setDoc(doc(collection(db, 'staff_activity')), {
    title: 'Record created', detail: 'Contact', actor: 'Impersonated', actorId: 'super',
    recordId: 'contact', recordType: 'directory', operation: 'created', time: serverTimestamp(),
  }));
});
const doctor = {
  role: 'doctor', name: 'Pending Doctor', email: 'doctor@example.test',
  isActive: true, isApproved: false, isVerified: false, registrationNumber: 'SLMC-1234',
};
const admin = {
  role: 'admin', name: 'Hospital Admin', isActive: true, isVerified: true,
  staffRole: 'Hospital administrator',
};
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-opd-connect',
    firestore: { host: '127.0.0.1', port: 8088,
      rules: await readFile(new URL('./firestore.verifications.rules', import.meta.url), 'utf8') },
  });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    const { staffRole, ...profileWithoutRole } = admin;
    for (const [id, data] of Object.entries({
      admin, super: { ...admin, staffRole: 'Super administrator' },
      support: { ...admin, staffRole: 'Support coordinator' },
      missing: profileWithoutRole, inactive: { ...admin, isActive: false },
      unverified: { ...admin, isVerified: false },
      patient: { role: 'patient', name: 'Patient', isActive: true, isVerified: true },
      doctor,
    })) await setDoc(doc(db, 'users', id), data);
    await setDoc(doc(db, 'hospital_settings', 'default'), { name: 'Hospital' });
  });
});

function decision(db, actorId = 'admin', { approve = true, changes = {}, auditChanges = {}, withAudit = true } = {}) {
  const auditRef = doc(collection(db, 'staff_activity'));
  const reason = approve ? '' : 'Credentials could not be confirmed';
  const data = {
    isApproved: approve, isVerified: approve,
    approvalStatus: approve ? 'approved' : 'rejected',
    reviewNote: approve ? 'Identity and credentials reviewed by Hospital Admin' : `Rejected: ${reason}`,
    reviewedBy: actorId, reviewedAt: serverTimestamp(), reviewActivityId: auditRef.id,
    identityChecked: approve, credentialsChecked: approve, reviewReason: reason, ...changes,
  };
  const audit = {
    title: approve ? 'Doctor registration approved' : 'Doctor registration rejected',
    detail: `Pending Doctor · ${approve ? 'Identity and credentials checked' : reason}`,
    actor: 'Hospital Admin', actorId, targetId: 'doctor',
    decision: data.approvalStatus, reason: data.reviewReason, time: serverTimestamp(), ...auditChanges,
  };
  return { data, audit, auditRef, withAudit };
}
function commit(db, actorId = 'admin', options) {
  const request = decision(db, actorId, options);
  const batch = writeBatch(db);
  batch.update(doc(db, 'users', 'doctor'), request.data);
  if (request.withAudit) batch.set(request.auditRef, request.audit);
  return batch.commit();
}

for (const actorId of ['admin', 'super']) {
  test(`${actorId} reads the complete accounts query and approves with an atomic audit`, async () => {
    const db = env.authenticatedContext(actorId).firestore();
    await assertSucceeds(getDocs(collection(db, 'users')));
    await assertSucceeds(getDoc(doc(db, 'hospital_settings', 'default')));
    await assertSucceeds(commit(db, actorId));
    const data = (await getDoc(doc(db, 'users', 'doctor'))).data();
    const audit = (await getDoc(doc(db, 'staff_activity', data.reviewActivityId))).data();
    assert.equal(data.reviewedBy, actorId);
    assert.equal(audit.actorId, actorId);
    assert.equal(audit.decision, 'approved');
    assert.ok(data.reviewedAt instanceof Timestamp);
    assert.equal(data.reviewedAt.toMillis(), audit.time.toMillis());
    await assertFails(commit(db, actorId, { approve: false }));
  });
}
test('administrator rejects with reason and the same server timestamp in the activity log', async () => {
  const db = env.authenticatedContext('admin').firestore();
  await assertSucceeds(commit(db, 'admin', { approve: false }));
  const data = (await getDoc(doc(db, 'users', 'doctor'))).data();
  assert.equal(data.isApproved, false);
  const audit = (await getDoc(doc(db, 'staff_activity', data.reviewActivityId))).data();
  assert.equal(audit.reason, 'Credentials could not be confirmed');
  assert.equal(data.reviewedAt.toMillis(), audit.time.toMillis());
  await assertFails(commit(db));
});
for (const actorId of [null, 'patient', 'doctor', 'missing', 'inactive', 'unverified', 'stranger']) {
  test(`${actorId ?? 'anonymous'} cannot query registrations or save reviews`, async () => {
    const db = actorId ? env.authenticatedContext(actorId).firestore() : env.unauthenticatedContext().firestore();
    await assertFails(getDocs(collection(db, 'users')));
    await assertFails(getDoc(doc(db, 'users', 'admin')));
    await assertFails(getDocs(collection(db, 'staff_activity')));
    await assertFails(commit(db, actorId ?? 'anonymous'));
  });
}
test('support can read but cannot approve or promote themselves', async () => {
  const db = env.authenticatedContext('support').firestore();
  await assertSucceeds(getDocs(collection(db, 'users')));
  await assertFails(commit(db, 'support'));
  await assertFails(updateDoc(doc(db, 'users', 'support'), { staffRole: 'Super administrator' }));
});
for (const actorId of ['admin', 'super', 'support']) {
  test(`${actorId} reads users, staff, pending doctors, departments, and the ordered activity query`, async () => {
    await env.withSecurityRulesDisabled(async context => {
      await setDoc(doc(context.firestore(), 'hospital_settings', 'default'), {
        name: 'Test Hospital', departments: [{ id: 'opd', name: 'OPD', location: 'Block A', active: true }],
      });
      await setDoc(doc(context.firestore(), 'staff_activity', 'existing'), {
        title: 'Existing decision', detail: 'Saved review', actor: 'Hospital Admin',
        actorId: 'admin', time: Timestamp.fromMillis(1000),
      });
    });
    const db = env.authenticatedContext(actorId).firestore();
    const users = await assertSucceeds(getDocs(collection(db, 'users')));
    assert.ok(users.docs.some(record => record.data().role === 'admin'));
    assert.ok(users.docs.some(record => record.data().role === 'doctor' && !record.data().isApproved));
    const hospital = await assertSucceeds(getDoc(doc(db, 'hospital_settings', 'default')));
    assert.equal(hospital.data().departments[0].name, 'OPD');
    const activity = await assertSucceeds(getDocs(query(collection(db, 'staff_activity'), orderBy('time', 'desc'), limit(80))));
    assert.equal(activity.size, 1);
  });
}
test('the observed missing-role profile can read itself but no hospital administration data', async () => {
  const db = env.authenticatedContext('missing').firestore();
  const ownProfile = await assertSucceeds(getDoc(doc(db, 'users', 'missing')));
  assert.equal(ownProfile.data().role, 'admin');
  assert.equal(ownProfile.data().staffRole, undefined);
  await assertFails(getDocs(collection(db, 'users')));
  await assertFails(getDoc(doc(db, 'hospital_settings', 'default')));
  await assertFails(getDocs(query(collection(db, 'staff_activity'), orderBy('time', 'desc'), limit(80))));
});
test('doctor can read their own profile but cannot approve it or promote themselves', async () => {
  const db = env.authenticatedContext('doctor').firestore();
  await assertSucceeds(getDoc(doc(db, 'users', 'doctor')));
  await assertFails(updateDoc(doc(db, 'users', 'doctor'), { isApproved: true, isVerified: true }));
  await assertFails(updateDoc(doc(db, 'users', 'doctor'), { role: 'admin', staffRole: 'Hospital administrator' }));
});
for (const checks of [[false, false], [true, false], [false, true]]) {
  test(`approval with checks ${checks} is denied`, async () => {
    await assertFails(commit(env.authenticatedContext('admin').firestore(), 'admin', {
      changes: { identityChecked: checks[0], credentialsChecked: checks[1] },
    }));
  });
}
for (const reason of ['', 'short', '        ', ' padded reason ']) {
  test(`rejection with invalid reason ${JSON.stringify(reason)} is denied`, async () => {
    await assertFails(commit(env.authenticatedContext('admin').firestore(), 'admin', {
      approve: false, changes: { reviewReason: reason },
    }));
  });
}
test('a review without an audit and an audit without a review are denied', async () => {
  const db = env.authenticatedContext('admin').firestore();
  await assertFails(commit(db, 'admin', { withAudit: false }));
  const { audit, auditRef } = decision(db);
  await assertFails(setDoc(auditRef, audit));
  assert.equal((await getDoc(doc(db, 'users', 'doctor'))).data().isApproved, false);
});
test('forged actor, target, decision, reason, timestamp and privilege changes are denied atomically', async () => {
  const db = env.authenticatedContext('admin').firestore();
  for (const options of [
    { changes: { reviewedBy: 'super' } },
    { changes: { reviewedAt: Timestamp.fromMillis(1) } },
    { changes: { staffRole: 'Super administrator' } },
    { changes: { role: 'admin' } },
    { changes: { isActive: false } },
    { changes: { isVerified: false } },
    { auditChanges: { actorId: 'super' } },
    { auditChanges: { actor: 'Another Admin' } },
    { auditChanges: { targetId: 'patient' } },
    { auditChanges: { decision: 'rejected' } },
    { auditChanges: { reason: 'Forged reason' } },
    { auditChanges: { time: Timestamp.fromMillis(1) } },
  ]) await assertFails(commit(db, 'admin', options));
  assert.equal((await getDoc(doc(db, 'users', 'doctor'))).data().isApproved, false);
  assert.equal((await getDocs(collection(db, 'staff_activity'))).size, 0);
});
test('legacy pending doctors without approval fields remain reviewable; inactive doctors do not', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'users', 'doctor'), { role: 'doctor', name: 'Legacy Doctor' });
  });
  const db = env.authenticatedContext('admin').firestore();
  await assertSucceeds(commit(db));
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'users', 'doctor'), { ...doctor, isActive: false });
  });
  await assertFails(commit(db));
});
test('two server transactions produce exactly one decision and one audit', async () => {
  const review = async actorId => {
    const db = env.authenticatedContext(actorId).firestore();
    const request = decision(db, actorId);
    return runTransaction(db, async transaction => {
      const ref = doc(db, 'users', 'doctor');
      const snapshot = await transaction.get(ref);
      if (snapshot.data().isApproved || snapshot.data().approvalStatus === 'rejected') {
        throw Error('No longer pending');
      }
      transaction.update(ref, request.data);
      transaction.set(request.auditRef, request.audit);
    });
  };
  const results = await Promise.allSettled([review('admin'), review('super')]);
  assert.equal(results.filter(result => result.status === 'fulfilled').length, 1);
  const db = env.authenticatedContext('admin').firestore();
  assert.equal((await getDocs(collection(db, 'staff_activity'))).size, 1);
});
for (const role of ['patient', 'doctor']) {
  test(`verified email self-registration stores ${role} in users/{uid} safely`, async () => {
    const db = env.authenticatedContext('new', { email: 'new@example.test', email_verified: true }).firestore();
    await assertSucceeds(setDoc(doc(db, 'users', 'new'), {
      email: 'new@example.test', name: 'New User', phone: '+94 77 123 4567', role,
      isActive: true, isApproved: role === 'patient', isVerified: role === 'patient',
      createdAt: serverTimestamp(), ...(role === 'doctor' ? { registrationNumber: 'SLMC-5678', department: 'OPD' } : {}),
    }));
  });
}
test('registration cannot overwrite a profile, self-provision admin access or preapprove a doctor', async () => {
  const db = env.authenticatedContext('new', { email: 'new@example.test', email_verified: true }).firestore();
  const base = { email: 'new@example.test', name: 'New User', phone: '', role: 'doctor',
    isActive: true, isApproved: false, isVerified: false, createdAt: serverTimestamp() };
  for (const changes of [{ role: 'admin' }, { staffRole: 'Hospital administrator' },
    { isApproved: true, isVerified: true }, { reviewedBy: 'admin' }]) {
    await assertFails(setDoc(doc(db, 'users', 'new'), { ...base, ...changes }));
  }
  await assertFails(setDoc(doc(db, 'users', 'doctor'), base));
});
