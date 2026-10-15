function tlv(tag, value) {
    const text = String(value);
    return `${tag}${String(text.length).padStart(2, '0')}${text}`;
}

function crc16(input) {
    let crc = 0xffff;
    for (const char of input) {
        crc ^= char.charCodeAt(0) << 8;
        for (let i = 0; i < 8; i += 1) {
            crc = (crc & 0x8000) ? ((crc << 1) ^ 0x1021) : (crc << 1);
            crc &= 0xffff;
        }
    }
    return crc.toString(16).toUpperCase().padStart(4, '0');
}

function makePromptPayPayload(promptPayId, amount) {
    const id = String(promptPayId || '').replace(/[\s-]/g, '');
    const numericAmount = Number(amount);
    if (!(/^(0\d{9}|\d{13})$/.test(id))) throw new Error('ตั้งค่า PROMPTPAY_ID เป็นเบอร์โทรไทย 10 หลักที่ขึ้นต้นด้วย 0 หรือเลขประจำตัว 13 หลัก');
    if (!Number.isFinite(numericAmount) || numericAmount <= 0) throw new Error('ยอดชำระไม่ถูกต้อง');

    let proxyTag;
    let proxyValue;
    if (id.length === 10) {
        proxyTag = '01';
        proxyValue = `0066${id.slice(1)}`;
    } else {
        proxyTag = '02';
        proxyValue = id;
    }
    const merchantAccount = tlv('00', 'A000000677010111') + tlv(proxyTag, proxyValue);
    let payload = tlv('00', '01') + tlv('01', '12') + tlv('29', merchantAccount) + tlv('53', '764') + tlv('54', numericAmount.toFixed(2)) + tlv('58', 'TH') + '6304';
    payload += crc16(payload);
    return payload;
}

module.exports = { makePromptPayPayload };
