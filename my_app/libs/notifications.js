const pool = require('./db_pool');
const admin = require('./firebase_admin');
const {
    RESERVATION_REMINDERS,
    reminderWindow,
    reminderDeliveryKey,
    reminderBody
} = require('./reservation_reminders');

let messaging = null;
try {
    if (admin) messaging = admin.messaging();
} catch (error) {
    console.warn('Firebase Admin is not configured; notifications will be saved in-app only.');
}

async function notifyUser(userId, { type, title, body, relatedId = null }) {
    try {
        const [[preference]] = await pool.query(
            'SELECT notification_enabled FROM `user` WHERE user_id = ? LIMIT 1',
            [userId]
        );
        if (!preference) return null;
        const notificationsEnabled = Number(preference.notification_enabled) === 1;

        const [result] = await pool.query(
            `INSERT INTO customer_notification
                (user_id, notification_type, title, body, related_id, notifications_enabled)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [userId, type, title, body, relatedId, notificationsEnabled ? 1 : 0]
        );

        if (notificationsEnabled && messaging) {
            const [rows] = await pool.query(
                'SELECT fcm_token FROM push_device WHERE user_id = ?',
                [userId]
            );
            const tokens = rows.map((row) => row.fcm_token);
            if (tokens.length) {
                try {
                const sent = await messaging.sendEachForMulticast({
                    tokens,
                    notification: { title, body },
                    data: { type, related_id: String(relatedId || ''), notification_id: String(result.insertId) }
                });
                const invalidTokens = [];
                sent.responses.forEach((response, index) => {
                    if (!response.success && response.error &&
                        ['messaging/invalid-registration-token', 'messaging/registration-token-not-registered'].includes(response.error.code)) {
                        invalidTokens.push(tokens[index]);
                    }
                });
                if (invalidTokens.length) {
                    await pool.query('DELETE FROM push_device WHERE fcm_token IN (?)', [invalidTokens]);
                }
                } catch (error) {
                    console.error('Push notification send failed:', error.message);
                }
            }
        }
        return result.insertId;
    } catch (error) {
        // Notification delivery is best-effort and must never undo an order,
        // reservation, or status change that has already been saved.
        console.error('Notification could not be saved:', error.message);
        return null;
    }
}

function startReservationReminderWorker() {
    let running = false;
    const sendDueReminders = async () => {
        if (running) return;
        running = true;
        try {
            for (const reminder of RESERVATION_REMINDERS) {
                const { fromOffset, toOffset } = reminderWindow(reminder.minutesBefore);
                const now = '(UTC_TIMESTAMP() + INTERVAL 7 HOUR)';
                const fromTime = fromOffset < 0
                    ? `DATE_SUB(${now}, INTERVAL ${Math.abs(fromOffset)} MINUTE)`
                    : `DATE_ADD(${now}, INTERVAL ${fromOffset} MINUTE)`;
                const toTime = toOffset < 0
                    ? `DATE_SUB(${now}, INTERVAL ${Math.abs(toOffset)} MINUTE)`
                    : toOffset === 0
                        ? now
                        : `DATE_ADD(${now}, INTERVAL ${toOffset} MINUTE)`;
                const [rows] = await pool.query(
                    `SELECT r.reservation_id, r.user_id, r.dining_date, r.dining_time
                     FROM reservation r
                     WHERE r.statusreservation_id IN (1, 4)
                       AND TIMESTAMP(r.dining_date, r.dining_time) BETWEEN ${fromTime} AND ${toTime}`
                );
                for (const row of rows) {
                    const key = reminderDeliveryKey(row.reservation_id, reminder.minutesBefore);
                    const [claim] = await pool.query(
                        'INSERT IGNORE INTO notification_delivery (notification_key) VALUES (?)',
                        [key]
                    );
                    if (!claim.affectedRows) continue;
                    await notifyUser(row.user_id, {
                        type: reminder.type,
                        title: reminder.title,
                        body: reminderBody(row, reminder.minutesBefore),
                        relatedId: row.reservation_id
                    });
                }
            }
        } catch (error) {
            console.error('Reservation reminder worker error:', error.message);
        } finally {
            running = false;
        }
    };
    void sendDueReminders();
    return setInterval(sendDueReminders, 30 * 1000);
}

module.exports = { notifyUser, startReservationReminderWorker };
