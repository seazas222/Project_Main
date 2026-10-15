'use strict';

const RESERVATION_REMINDERS = Object.freeze([
    { minutesBefore: 60, title: 'เตือนการจองโต๊ะล่วงหน้า 1 ชั่วโมง', type: 'reservation_reminder_60m' },
    { minutesBefore: 10, title: 'เตือนการจองโต๊ะล่วงหน้า 10 นาที', type: 'reservation_reminder_10m' },
    { minutesBefore: 0, title: 'ถึงเวลาจองโต๊ะของคุณแล้ว', type: 'reservation_time' }
]);

function reminderWindow(minutesBefore) {
    if (!RESERVATION_REMINDERS.some((reminder) => reminder.minutesBefore === minutesBefore)) {
        throw new RangeError('Unsupported reservation reminder time');
    }
    return { fromOffset: minutesBefore - 1, toOffset: minutesBefore };
}

function reminderDeliveryKey(reservationId, minutesBefore) {
    if (minutesBefore === 0) return `reservation-start:${reservationId}`;
    return `reservation-reminder:${reservationId}:${minutesBefore}m`;
}

function reminderBody(row, minutesBefore) {
    const when = `วันที่ ${row.dining_date} เวลา ${row.dining_time}`;
    if (minutesBefore === 60) return `อีก 1 ชั่วโมงจะถึงเวลาจองโต๊ะ ${when}`;
    if (minutesBefore === 10) return `อีก 10 นาทีจะถึงเวลาจองโต๊ะ ${when}`;
    return `การจองโต๊ะ ${when} เริ่มแล้ว`;
}

module.exports = { RESERVATION_REMINDERS, reminderWindow, reminderDeliveryKey, reminderBody };
