"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.reminderHourBefore = exports.reminderDayBefore = exports.onBookingUpdated = exports.onBookingCreated = exports.processNotificationQueue = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
// ─── helpers ─────────────────────────────────────────────────────────────────
function formatDate(d) {
    const dt = d.toDate();
    const dd = String(dt.getDate()).padStart(2, "0");
    const mm = String(dt.getMonth() + 1).padStart(2, "0");
    return `${dd}.${mm}.${dt.getFullYear()}`;
}
/** Отправить пуш на все FCM-токены пользователя */
async function sendToUser(uid, title, body, data = {}) {
    const userDoc = await db.collection("users").doc(uid).get();
    const tokens = userDoc.data()?.fcm_tokens ?? [];
    if (!tokens.length)
        return;
    const results = await messaging.sendEachForMulticast({
        tokens,
        notification: { title, body },
        data,
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
    });
    // Удаляем протухшие токены
    const badTokens = [];
    results.responses.forEach((r, i) => {
        if (!r.success)
            badTokens.push(tokens[i]);
    });
    if (badTokens.length) {
        await db.collection("users").doc(uid).update({
            fcm_tokens: admin.firestore.FieldValue.arrayRemove(...badTokens),
        });
    }
}
/** owner_id ресторана */
async function getOwnerId(restaurantId) {
    const doc = await db.collection("restaurants").doc(restaurantId).get();
    return doc.data()?.owner_id ?? null;
}
// ─── 0. Обработка очереди уведомлений (пишет Dart-клиент) ────────────────────
//
// Dart сохраняет задачу в notification_queue/{docId}.
// Эта функция срабатывает при создании документа, читает FCM-токены юзера и шлёт пуш.
exports.processNotificationQueue = functions.firestore
    .document("notification_queue/{docId}")
    .onCreate(async (snap, ctx) => {
    const d = snap.data();
    if (d.sent)
        return;
    const uid = d.uid ?? "";
    const title = d.title ?? "";
    const body = d.body ?? "";
    const data = d.data ?? {};
    if (!uid || !title) {
        await snap.ref.update({ sent: true, error: "missing uid or title" });
        return;
    }
    try {
        await sendToUser(uid, title, body, data);
        await snap.ref.update({ sent: true, sent_at: admin.firestore.FieldValue.serverTimestamp() });
    }
    catch (e) {
        await snap.ref.update({ sent: true, error: String(e) });
    }
});
// ─── 1. Новая бронь от юзера → уведомить селлера ─────────────────────────────
exports.onBookingCreated = functions.firestore
    .document("bookings/{bookingId}")
    .onCreate(async (snap, ctx) => {
    const data = snap.data();
    // Ручная бронь селлера — молчим
    if (data.is_seller_booking === true)
        return;
    const restaurantId = data.restaurant_id ?? "";
    const sellerId = await getOwnerId(restaurantId);
    if (!sellerId)
        return;
    const dateStr = data.booking_date ? formatDate(data.booking_date) : "—";
    const start = data.start_time ?? "—";
    const end = data.end_time ?? "—";
    const name = data.name ?? "Гость";
    const guests = String(data.guests ?? "?");
    const restName = data.restaurant_name ?? restaurantId;
    await sendToUser(sellerId, `🆕 Новое бронирование — ${restName}`, `${name} · ${guests} гостей · ${dateStr} · ${start}–${end}`, { type: "new_booking", booking_id: ctx.params.bookingId, restaurant_id: restaurantId });
});
// ─── 2. Изменение брони от юзера → уведомить селлера ─────────────────────────
exports.onBookingUpdated = functions.firestore
    .document("bookings/{bookingId}")
    .onUpdate(async (change, ctx) => {
    const before = change.before.data();
    const after = change.after.data();
    // Ручная бронь или статусное обновление (только status/updated_at) — молчим
    if (after.is_seller_booking === true)
        return;
    const watchedFields = ["booking_date", "start_time", "end_time", "guests", "name", "phone"];
    const changed = watchedFields.filter((f) => {
        const a = before[f];
        const b = after[f];
        if (a instanceof admin.firestore.Timestamp && b instanceof admin.firestore.Timestamp) {
            return a.seconds !== b.seconds;
        }
        return String(a ?? "") !== String(b ?? "");
    });
    if (!changed.length)
        return; // изменились только статус/флаги — не нужно
    const restaurantId = after.restaurant_id ?? "";
    const sellerId = await getOwnerId(restaurantId);
    if (!sellerId)
        return;
    const dateStr = after.booking_date ? formatDate(after.booking_date) : "—";
    const start = after.start_time ?? "—";
    const end = after.end_time ?? "—";
    const name = after.name ?? "Гость";
    const restName = after.restaurant_name ?? restaurantId;
    const fieldLabels = {
        booking_date: "дата",
        start_time: "время начала",
        end_time: "время окончания",
        guests: "кол-во гостей",
        name: "имя",
        phone: "телефон",
    };
    const changedText = changed.map((f) => fieldLabels[f] ?? f).join(", ");
    await sendToUser(sellerId, `✏️ Изменение брони — ${restName}`, `${name} · ${dateStr} · ${start}–${end}\nИзменено: ${changedText}`, { type: "booking_updated", booking_id: ctx.params.bookingId, restaurant_id: restaurantId });
});
// ─── 3. Напоминание за день — каждый день в 09:00 UTC ────────────────────────
exports.reminderDayBefore = functions.pubsub
    .schedule("0 9 * * *")
    .timeZone("Asia/Almaty")
    .onRun(async () => {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 1);
    const snap = await db
        .collection("bookings")
        .where("booking_date", ">=", admin.firestore.Timestamp.fromDate(tomorrow))
        .where("booking_date", "<", admin.firestore.Timestamp.fromDate(dayAfter))
        .where("status", "in", ["pending", "confirmed"])
        .where("reminder_day_sent", "==", false)
        .get();
    const batch = db.batch();
    for (const doc of snap.docs) {
        const d = doc.data();
        const restaurantId = d.restaurant_id ?? "";
        const start = d.start_time ?? "—";
        const end = d.end_time ?? "—";
        const name = d.name ?? "Гость";
        const guests = String(d.guests ?? "?");
        const dateStr = d.booking_date ? formatDate(d.booking_date) : "—";
        // Название ресторана
        let restName = d.restaurant_name ?? "";
        if (!restName) {
            const restDoc = await db.collection("restaurants").doc(restaurantId).get();
            restName = restDoc.data()?.name ?? restaurantId;
        }
        const title = `📅 Завтра мероприятие — ${restName}`;
        const body = `${name} · ${guests} гостей · ${dateStr} · ${start}–${end}`;
        const data = { type: "reminder_day", booking_id: doc.id, restaurant_id: restaurantId };
        // Селлер
        const sellerId = await getOwnerId(restaurantId);
        if (sellerId)
            await sendToUser(sellerId, title, body, data);
        // Юзер (если есть и отличается от селлера)
        const userId = d.user_id ?? "";
        if (userId && userId !== sellerId) {
            await sendToUser(userId, title, body, data);
        }
        batch.update(doc.ref, { reminder_day_sent: true });
    }
    await batch.commit();
    functions.logger.info(`reminderDayBefore: processed ${snap.size} bookings`);
});
// ─── 4. Напоминание за час — каждые 15 минут ─────────────────────────────────
exports.reminderHourBefore = functions.pubsub
    .schedule("*/15 * * * *")
    .timeZone("Asia/Almaty")
    .onRun(async () => {
    const now = new Date();
    const startOfToday = new Date(now);
    startOfToday.setHours(0, 0, 0, 0);
    const startOfTomorrow = new Date(startOfToday);
    startOfTomorrow.setDate(startOfTomorrow.getDate() + 1);
    const snap = await db
        .collection("bookings")
        .where("booking_date", ">=", admin.firestore.Timestamp.fromDate(startOfToday))
        .where("booking_date", "<", admin.firestore.Timestamp.fromDate(startOfTomorrow))
        .where("status", "in", ["pending", "confirmed"])
        .where("reminder_hour_sent", "==", false)
        .get();
    const batch = db.batch();
    for (const doc of snap.docs) {
        const d = doc.data();
        // Вычисляем точное время начала брони
        const bookingDate = d.booking_date.toDate();
        const [hh, mm] = (d.start_time ?? "0:0").split(":").map(Number);
        const bookingStart = new Date(bookingDate);
        bookingStart.setHours(hh, mm, 0, 0);
        const minutesLeft = (bookingStart.getTime() - now.getTime()) / 60000;
        // Окно: 45–75 минут до начала
        if (minutesLeft < 45 || minutesLeft > 75)
            continue;
        const restaurantId = d.restaurant_id ?? "";
        const start = d.start_time ?? "—";
        const end = d.end_time ?? "—";
        const name = d.name ?? "Гость";
        const guests = String(d.guests ?? "?");
        const dateStr = d.booking_date ? formatDate(d.booking_date) : "—";
        let restName = d.restaurant_name ?? "";
        if (!restName) {
            const restDoc = await db.collection("restaurants").doc(restaurantId).get();
            restName = restDoc.data()?.name ?? restaurantId;
        }
        const title = `⏰ Через час мероприятие — ${restName}`;
        const body = `${name} · ${guests} гостей · ${dateStr} · ${start}–${end}`;
        const data = { type: "reminder_hour", booking_id: doc.id, restaurant_id: restaurantId };
        const sellerId = await getOwnerId(restaurantId);
        if (sellerId)
            await sendToUser(sellerId, title, body, data);
        const userId = d.user_id ?? "";
        if (userId && userId !== sellerId) {
            await sendToUser(userId, title, body, data);
        }
        batch.update(doc.ref, { reminder_hour_sent: true });
    }
    await batch.commit();
    functions.logger.info(`reminderHourBefore: processed within window`);
});
