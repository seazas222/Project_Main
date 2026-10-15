const pool = require('../libs/db_pool');

module.exports = {
    createSlipReview: async ({ orderId, userId, amount, imagePath, reference }) => {
        const conn = await pool.getConnection();
        try {
            await conn.beginTransaction();
            const [orders] = await conn.query(
                'SELECT order_id, order_status FROM `order` WHERE order_id = ? AND user_id = ? FOR UPDATE',
                [orderId, userId]
            );
            if (!orders.length) throw new Error('ไม่พบออร์เดอร์ของบัญชีนี้');
            if (!['รอชำระเงิน', 'ชำระเงินไม่ผ่าน'].includes(orders[0].order_status)) {
                throw new Error('ออร์เดอร์นี้ยังส่งสลิปไม่ได้ หรือชำระเงินแล้ว');
            }
            const [items] = await conn.query(
                "SELECT quantity, price, food_status FROM order_detail WHERE order_id = ? FOR UPDATE",
                [orderId]
            );
            if (!items.length || items.some((item) => item.food_status !== 'ทำเสร็จแล้ว')) {
                throw new Error('ยังส่งสลิปไม่ได้จนกว่าอาหารทุกรายการจะทำเสร็จ');
            }
            const [pending] = await conn.query(
                'SELECT payment_id FROM payment WHERE order_id = ? AND payment_status_id = 3 LIMIT 1 FOR UPDATE',
                [orderId]
            );
            if (pending.length) throw new Error('มีสลิปที่รอตรวจสอบแล้ว');
            const actualAmount = items.reduce((sum, item) => sum + Number(item.quantity) * Number(item.price), 0);
            if (!Number.isFinite(actualAmount) || actualAmount <= 0 || Math.abs(actualAmount - Number(amount)) > 0.001) {
                throw new Error('ยอดชำระไม่ถูกต้อง กรุณาโหลดหน้าใหม่');
            }
            const [result] = await conn.query(
                `INSERT INTO payment
                    (preorder_id, order_id, user_id, payment_method_id, payment_status_id, amount, payment_image, payment_reference)
                 VALUES (NULL, ?, ?, 3, 3, ?, ?, ?)`,
                [orderId, userId, actualAmount, imagePath, reference || null]
            );
            await conn.query("UPDATE `order` SET order_status = 'รอตรวจสอบการชำระ' WHERE order_id = ?", [orderId]);
            await conn.commit();
            return result.insertId;
        } catch (error) {
            await conn.rollback();
            throw error;
        } finally {
            conn.release();
        }
    },

    reviewPayment: async ({ paymentId, reviewerId, approved }) => {
        const conn = await pool.getConnection();
        try {
            await conn.beginTransaction();
            const [rows] = await conn.query(
                'SELECT payment_id, order_id, payment_status_id FROM payment WHERE payment_id = ? FOR UPDATE',
                [paymentId]
            );
            if (!rows.length) throw new Error('ไม่พบรายการชำระเงิน');
            const payment = rows[0];
            if (Number(payment.payment_status_id) !== 3) throw new Error('รายการชำระเงินนี้ตรวจสอบไปแล้ว');
            if (payment.order_id) {
                const [orders] = await conn.query('SELECT order_id, order_status FROM `order` WHERE order_id = ? FOR UPDATE', [payment.order_id]);
                if (!orders.length || orders[0].order_status !== 'รอตรวจสอบการชำระ') throw new Error('สถานะออร์เดอร์ไม่ตรงกับการตรวจสอบสลิป');
            }
            await conn.query(
                `UPDATE payment SET payment_status_id = ?, reviewed_by = ?, reviewed_at = CURRENT_TIMESTAMP()
                 WHERE payment_id = ?`,
                [approved ? 1 : 2, reviewerId, paymentId]
            );
            if (approved && payment.order_id) {
                await conn.query(
                    "UPDATE `order` SET order_status = 'ชำระแล้ว', paid_at = CURRENT_TIMESTAMP() WHERE order_id = ?",
                    [payment.order_id]
                );
            } else if (!approved && payment.order_id) {
                await conn.query("UPDATE `order` SET order_status = 'ชำระเงินไม่ผ่าน' WHERE order_id = ?", [payment.order_id]);
            }
            await conn.commit();
            return payment;
        } catch (error) {
            await conn.rollback();
            throw error;
        } finally {
            conn.release();
        }
    },

    getPaymentForOrder: async (orderId) => {
        const [rows] = await pool.query(
            `SELECT p.payment_id, p.order_id, p.user_id, p.amount, p.payment_status_id,
                    ps.payment_status_name, p.payment_image, p.payment_reference,
                    p.payment_date, p.reviewed_at
             FROM payment p JOIN payment_status ps ON ps.payment_status_id = p.payment_status_id
             WHERE p.order_id = ? ORDER BY p.payment_id DESC LIMIT 1`,
            [orderId]
        );
        return rows[0] || null;
    },

    getAdminPayments: async () => {
        const [rows] = await pool.query(
            `SELECT p.payment_id, p.order_id, p.user_id, u.fullname, p.amount,
                    p.payment_status_id, ps.payment_status_name, p.payment_image,
                    p.payment_reference, p.payment_date
             FROM payment p JOIN \`user\` u ON u.user_id = p.user_id
             JOIN payment_status ps ON ps.payment_status_id = p.payment_status_id
             WHERE p.order_id IS NOT NULL ORDER BY p.payment_date DESC`
        );
        return rows;
    }
};
