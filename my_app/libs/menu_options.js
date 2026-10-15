'use strict';

function validMenuOptionGroups(groups) {
    if (!Array.isArray(groups)) return false;
    const groupIds = new Set();
    for (const group of groups) {
        if (!group || typeof group.id !== 'string' || !group.id.trim() || groupIds.has(group.id) ||
            typeof group.name !== 'string' || !group.name.trim() ||
            !Number.isInteger(Number(group.max_select)) || Number(group.max_select) < 1 || Number(group.max_select) > 5 ||
            !Array.isArray(group.options)) return false;
        groupIds.add(group.id);
        if (group.required !== false && group.options.length === 0) return false;
        const optionIds = new Set();
        for (const option of group.options) {
            if (!option || typeof option.id !== 'string' || !option.id.trim() || optionIds.has(option.id) ||
                typeof option.name !== 'string' || !option.name.trim() ||
                !Number.isFinite(Number(option.extra_price)) || Number(option.extra_price) < 0 ||
                (option.available != null && typeof option.available !== 'boolean') ||
                (option.sold_out != null && typeof option.sold_out !== 'boolean')) return false;
            optionIds.add(option.id);
        }
    }
    return true;
}

function resolveMenuSelections(menu, selections) {
    if (!Array.isArray(selections)) return { error: 'ตัวเลือกเมนูไม่ถูกต้อง' };
    const groups = Array.isArray(menu?.option_groups) ? menu.option_groups : [];
    const chosenByGroup = new Map();
    const snapshot = [];
    for (const selected of selections) {
        if (!selected || typeof selected !== 'object') return { error: 'ตัวเลือกเมนูไม่ถูกต้อง' };
        const group = groups.find((item) => String(item.id) === String(selected.group_id));
        const option = group?.options?.find((item) => String(item.id) === String(selected.option_id));
        if (!group || !option) return { error: 'ตัวเลือกนี้ไม่มีในเมนูแล้ว กรุณาเปิดเมนูและเลือกใหม่' };
        if (option.available === false || option.sold_out === true) return { error: `ตัวเลือก "${option.name}" หมดแล้ว กรุณาเลือกอย่างอื่น` };
        const groupId = String(group.id);
        const chosen = chosenByGroup.get(groupId) || [];
        if (chosen.some((item) => String(item.id) === String(option.id))) return { error: 'เลือกตัวเลือกซ้ำกัน' };
        chosen.push(option);
        chosenByGroup.set(groupId, chosen);
        const extraPrice = Number(option.extra_price);
        if (!Number.isFinite(extraPrice) || extraPrice < 0) return { error: 'ราคาตัวเลือกเมนูไม่ถูกต้อง' };
        snapshot.push({ group_id: groupId, group_name: String(group.name), option_id: String(option.id), option_name: String(option.name), extra_price: extraPrice });
    }
    for (const group of groups) {
        const chosen = chosenByGroup.get(String(group.id)) || [];
        const maxSelect = Number(group.max_select);
        if (group.required !== false && chosen.length === 0) return { error: `กรุณาเลือก${group.name}` };
        if (!Number.isInteger(maxSelect) || maxSelect < 1 || chosen.length > maxSelect) return { error: `หัวข้อ${group.name}เลือกได้ไม่เกิน ${maxSelect || 1} รายการ` };
    }
    return { snapshot, extraPrice: snapshot.reduce((sum, item) => sum + item.extra_price, 0) };
}

module.exports = { validMenuOptionGroups, resolveMenuSelections };
