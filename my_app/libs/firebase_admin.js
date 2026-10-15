let admin = null;
try {
    admin = require('firebase-admin');
    if (!admin.apps.length) admin.initializeApp();
} catch (_) {}

module.exports = admin;
