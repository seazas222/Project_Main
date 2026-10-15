const ACTIVE_RESERVATION_STATUSES = [1, 4];
const OPENING_HOUR = 9;
const LAST_BOOKING_HOUR = 13;

function bangkokParts(date = new Date()) {
    const parts = new Intl.DateTimeFormat('en-GB', {
        timeZone: 'Asia/Bangkok', year: 'numeric', month: '2-digit', day: '2-digit',
        hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23'
    }).formatToParts(date);
    return Object.fromEntries(parts.map((part) => [part.type, part.value]));
}

function bangkokDateTime() {
    const p = bangkokParts();
    return { date: `${p.year}-${p.month}-${p.day}`, time: `${p.hour}:${p.minute}:${p.second}` };
}

function validateSlot(diningDate, diningTime, now = new Date()) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(String(diningDate))) return 'วันที่จองไม่ถูกต้อง';
    if (!/^\d{2}:\d{2}(?::00)?$/.test(String(diningTime))) return 'กรุณาระบุเวลาเป็น HH:mm';
    const hour = Number(String(diningTime).slice(0, 2));
    const minute = Number(String(diningTime).slice(3, 5));
    if (hour > 23 || minute > 59) return 'เวลาที่จองไม่ถูกต้อง';
    if (hour < OPENING_HOUR || hour > LAST_BOOKING_HOUR || (hour === LAST_BOOKING_HOUR && minute > 0)) {
        return 'ร้านเปิดรับจองเวลา 09:00–13:00 (ใช้โต๊ะได้ 1 ชั่วโมง)';
    }

    const requested = new Date(`${diningDate}T00:00:00Z`);
    if (Number.isNaN(requested.getTime()) || requested.toISOString().slice(0, 10) !== diningDate) return 'วันที่จองไม่ถูกต้อง';
    const today = bangkokParts(now);
    const todayText = `${today.year}-${today.month}-${today.day}`;
    const todayUtc = new Date(`${todayText}T00:00:00Z`);
    const difference = Math.round((requested.getTime() - todayUtc.getTime()) / 86400000);
    if (difference < 0 || difference > 2) return 'จองได้ตั้งแต่วันนี้ถึงอีก 2 วันเท่านั้น';
    if (requested.getUTCDay() === 0) return 'ร้านปิดทุกวันอาทิตย์';
    if (difference === 0) {
        const requestedStart = new Date(`${diningDate}T${String(diningTime).slice(0, 5)}:00+07:00`);
        if (requestedStart <= now) return 'ไม่สามารถจองเวลาที่ผ่านไปแล้วได้';
    }
    return null;
}

module.exports = { ACTIVE_RESERVATION_STATUSES, bangkokDateTime, validateSlot };
