'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');

process.env.AUTH_TOKEN_SECRET = 'restaurant-app-node-tests-secret-at-least-32-bytes';

const { validateSlot } = require('../libs/booking_rules');
const { validMenuOptionGroups, resolveMenuSelections } = require('../libs/menu_options');
const { RESERVATION_REMINDERS, reminderWindow, reminderDeliveryKey, reminderBody } = require('../libs/reservation_reminders');
const userModel = require('../models/user');
const { issueToken, verifyToken, requireAuth } = require('../libs/auth_token');

const mondayMorning = new Date('2026-10-12T01:00:00.000Z'); // 08:00 in Bangkok
const saturdayMorning = new Date('2026-10-17T01:00:00.000Z'); // 08:00 in Bangkok

test('booking times enforce opening hours, Sundays, and the booking window', () => {
    assert.equal(validateSlot('2026-10-12', '09:00', mondayMorning), null);
    assert.equal(validateSlot('2026-10-18', '09:00', saturdayMorning), 'ร้านปิดทุกวันอาทิตย์');
    assert.match(validateSlot('2026-10-12', '08:00', mondayMorning), /09:00/);
    assert.match(validateSlot('2026-10-15', '09:00', mondayMorning), /อีก 2 วัน/);
    assert.equal(validateSlot('2026-10-12', '09:30', mondayMorning), null);
});

test('reservation reminders run once at 60 minutes, 10 minutes, and arrival time', () => {
    assert.deepEqual(RESERVATION_REMINDERS.map((item) => item.minutesBefore), [60, 10, 0]);
    assert.deepEqual(reminderWindow(60), { fromOffset: 59, toOffset: 60 });
    assert.deepEqual(reminderWindow(10), { fromOffset: 9, toOffset: 10 });
    assert.deepEqual(reminderWindow(0), { fromOffset: -1, toOffset: 0 });
    assert.equal(reminderDeliveryKey(12, 60), 'reservation-reminder:12:60m');
    assert.notEqual(reminderDeliveryKey(12, 60), reminderDeliveryKey(12, 10));
    assert.match(reminderBody({ dining_date: '2026-10-12', dining_time: '09:00' }, 60), /อีก 1 ชั่วโมง/);
    assert.match(reminderBody({ dining_date: '2026-10-12', dining_time: '09:00' }, 10), /อีก 10 นาที/);
});

test('menu choice validation accepts sold-out flags but rejects malformed or duplicate choices', () => {
    const valid = [{
        id: 'soup', name: 'น้ำซุป', required: true, max_select: 1,
        options: [
            { id: 'clear', name: 'ใส', extra_price: 0, available: true },
            { id: 'spicy', name: 'เผ็ด', extra_price: 5, available: false }
        ]
    }];
    assert.equal(validMenuOptionGroups(valid), true);
    assert.equal(validMenuOptionGroups([{ ...valid[0], options: [...valid[0].options, valid[0].options[0]] }]), false);
    assert.equal(validMenuOptionGroups([{ ...valid[0], options: [{ ...valid[0].options[0], available: 'false' }] }]), false);
});

test('menu order selection calculates extras and rejects sold-out choices', () => {
    const menu = { option_groups: [{
        id: 'protein', name: 'วัตถุดิบ', required: true, max_select: 1,
        options: [{ id: 'pork', name: 'หมู', extra_price: 10 }, { id: 'shrimp', name: 'กุ้ง', extra_price: 20, available: false }]
    }] };
    const selected = resolveMenuSelections(menu, [{ group_id: 'protein', option_id: 'pork' }]);
    assert.equal(selected.extraPrice, 10);
    assert.equal(selected.snapshot[0].option_name, 'หมู');
    assert.match(resolveMenuSelections(menu, [{ group_id: 'protein', option_id: 'shrimp' }]).error, /หมดแล้ว/);
    assert.match(resolveMenuSelections(menu, []).error, /กรุณาเลือก/);
});

test('signed tokens validate and tampered or expired tokens are rejected', () => {
    const token = issueToken({ user_id: 42, role_id: 2 });
    assert.equal(verifyToken(token).sub, 42);
    const [header, payload, signature] = token.split('.');
    const tampered = `${header}.${payload}.${signature.startsWith('a') ? 'b' : 'a'}${signature.slice(1)}`;
    assert.equal(verifyToken(tampered), null);

    const expiredPayload = Buffer.from(JSON.stringify({ sub: 42, exp: 1 })).toString('base64url');
    const input = `${header}.${expiredPayload}`;
    const expiredSignature = crypto.createHmac('sha256', process.env.AUTH_TOKEN_SECRET).update(input).digest('base64url');
    assert.equal(verifyToken(`${input}.${expiredSignature}`), null);
});

test('authenticated requests are rejected immediately when an account is suspended or deleted', async () => {
    const originalGetUserById = userModel.getUserById;
    const originalConsoleError = console.error;
    const token = issueToken({ user_id: 42, role_id: 1 });
    const response = () => ({ statusCode: 200, body: null, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } });
    try {
        userModel.getUserById = async () => ({ user_id: 42, role_id: 2, is_active: 1, is_deleted: 1 });
        const deletedResponse = response();
        await requireAuth({ headers: { authorization: `Bearer ${token}` } }, deletedResponse, () => assert.fail('deleted account passed authentication'));
        assert.equal(deletedResponse.statusCode, 403);

        userModel.getUserById = async () => ({ user_id: 42, role_id: 2, is_active: 0, is_deleted: 0 });
        const suspendedResponse = response();
        await requireAuth({ headers: { authorization: `Bearer ${token}` } }, suspendedResponse, () => assert.fail('suspended account passed authentication'));
        assert.equal(suspendedResponse.statusCode, 403);

        userModel.getUserById = async () => { throw new Error('database unavailable'); };
        const errorResponse = response();
        console.error = () => {};
        await requireAuth({ headers: { authorization: `Bearer ${token}` } }, errorResponse, () => assert.fail('authentication passed after database error'));
        console.error = originalConsoleError;
        assert.equal(errorResponse.statusCode, 500);

        userModel.getUserById = async () => ({ user_id: 42, role_id: 2, is_active: 1, is_deleted: 0 });
        const activeResponse = response();
        let nextCalled = false;
        const activeRequest = { headers: { authorization: `Bearer ${token}` } };
        await requireAuth(activeRequest, activeResponse, () => { nextCalled = true; });
        assert.equal(nextCalled, true);
        assert.equal(activeRequest.authUser.role_id, 2);
    } finally {
        console.error = originalConsoleError;
        userModel.getUserById = originalGetUserById;
    }
});
