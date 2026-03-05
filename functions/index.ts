import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─── helpers ─────────────────────────────────────────────────────────────────

function formatDate(d: FirebaseFirestore.Timestamp): string {
  const dt = d.toDate();
  const dd = String(dt.getDate()).padStart(2, "0");
  const mm = String(dt.getMonth() + 1).padStart(2, "0");
  return `${dd}.${mm}.${dt.getFullYear()}`;
}

async function sendToUser(
  uid: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<void> {
  const userDoc = await db.collection("users").doc(uid).get();
  const tokens: string[] = userDoc.data()?.fcm_tokens ?? [];
  if (!tokens.length) return;

  const results = await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: {
      priority: "high",
      notification: {
        channelId: "bookings",
        priority: "high",
        defaultSound: true,
        visibility: "public",
      },
    },
    apns: {
      payload: { aps: { sound: "default", contentAvailable: true } },
      headers: { "apns-priority": "10" },
    },
    webpush: {
      notification: { title, body, icon: "/icons/Icon-192.png" },
      headers: { Urgency: "high" },
    },
  });

  const badTokens: string[] = [];
  results.responses.forEach((r, i) => {
    if (!r.success) badTokens.push(tokens[i]);
  });
  if (badTokens.length) {
    await db.collection("users").doc(uid).update({
      fcm_tokens: admin.firestore.FieldValue.arrayRemove(...badTokens),
    });
  }
}

async function getOwnerId(restaurantId: string): Promise<string | null> {
  const doc = await db.collection("restaurants").doc(restaurantId).get();
  return doc.data()?.owner_id ?? null;
}

async function getRestaurantName(restaurantId: string, fallback: string): Promise<string> {
  if (fallback) return fallback;
  const doc = await db.collection("restaurants").doc(restaurantId).get();
  return doc.data()?.name ?? restaurantId;
}

// ─── 1. Новая бронь от юзера → уведомить селлера ─────────────────────────────
// Dart больше НЕ пишет в notification_queue. Только этот триггер отправляет пуш.

export const onBookingCreated = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap, ctx) => {
    const d = snap.data();
    if (d.is_seller_booking === true) return;

    const restaurantId: string = d.restaurant_id ?? "";
    const sellerId = await getOwnerId(restaurantId);
    if (!sellerId) return;

    const restName = await getRestaurantName(restaurantId, d.restaurant_name ?? "");
    const dateStr = d.booking_date ? formatDate(d.booking_date) : "—";
    const name: string = d.name ?? "Гость";
    const guests: string = String(d.guests ?? "?");
    const phone: string = d.phone ?? "—";
    const start: string = d.start_time ?? "—";
    const end: string = d.end_time ?? "—";

    await sendToUser(
      sellerId,
      `🆕 Новое бронирование — ${restName}`,
      `${name} · ${guests} гостей · ${dateStr} · ${start}–${end}\n📞 ${phone}`,
      {
        type: "new_booking",
        booking_id: ctx.params.bookingId,
        restaurant_id: restaurantId,
      }
    );
  });

// ─── 2. Изменение брони от юзера → уведомить селлера ─────────────────────────

export const onBookingUpdated = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, ctx) => {
    const before = change.before.data();
    const after = change.after.data();

    if (after.is_seller_booking === true) return;

    const watchedFields = [
      "booking_date", "start_time", "end_time",
      "guests", "name", "phone",
    ];
    const changed = watchedFields.filter((f) => {
      const a = before[f];
      const b = after[f];
      if (
        a instanceof admin.firestore.Timestamp &&
        b instanceof admin.firestore.Timestamp
      ) {
        return a.seconds !== b.seconds;
      }
      return String(a ?? "") !== String(b ?? "");
    });
    if (!changed.length) return;

    const restaurantId: string = after.restaurant_id ?? "";
    const sellerId = await getOwnerId(restaurantId);
    if (!sellerId) return;

    const restName = await getRestaurantName(restaurantId, after.restaurant_name ?? "");
    const dateStr = after.booking_date ? formatDate(after.booking_date) : "—";
    const name: string = after.name ?? "Гость";
    const guests: string = String(after.guests ?? "?");
    const phone: string = after.phone ?? "—";
    const start: string = after.start_time ?? "—";
    const end: string = after.end_time ?? "—";

    const fieldLabels: Record<string, string> = {
      booking_date: "дата",
      start_time: "время начала",
      end_time: "время окончания",
      guests: "кол-во гостей",
      name: "имя",
      phone: "телефон",
    };
    const changedText = changed.map((f) => fieldLabels[f] ?? f).join(", ");

    await sendToUser(
      sellerId,
      `✏️ Изменение брони — ${restName}`,
      `${name} · ${guests} гостей · ${dateStr} · ${start}–${end}\n📞 ${phone}\nИзменено: ${changedText}`,
      {
        type: "booking_updated",
        booking_id: ctx.params.bookingId,
        restaurant_id: restaurantId,
      }
    );
  });

// ─── 3. Напоминание за день — 09:00 по Алматы ────────────────────────────────

export const reminderDayBefore = functions.pubsub
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
      const restaurantId: string = d.restaurant_id ?? "";
      const name: string = d.name ?? "Гость";
      const guests: string = String(d.guests ?? "?");
      const phone: string = d.phone ?? "—";
      const start: string = d.start_time ?? "—";
      const end: string = d.end_time ?? "—";
      const dateStr = d.booking_date ? formatDate(d.booking_date) : "—";
      const restName = await getRestaurantName(restaurantId, d.restaurant_name ?? "");

      const title = `📅 Завтра мероприятие — ${restName}`;
      const body = `${name} · ${guests} гостей · ${dateStr} · ${start}–${end}\n📞 ${phone}`;
      const data = { type: "reminder_day", booking_id: doc.id, restaurant_id: restaurantId };

      const sellerId = await getOwnerId(restaurantId);
      if (sellerId) await sendToUser(sellerId, title, body, data);

      const userId: string = d.user_id ?? "";
      if (userId && userId !== sellerId) {
        await sendToUser(userId, title, body, data);
      }
      batch.update(doc.ref, { reminder_day_sent: true });
    }
    await batch.commit();
    functions.logger.info(`reminderDayBefore: processed ${snap.size} bookings`);
  });

// ─── 4. Напоминание за час — каждые 15 минут ─────────────────────────────────

export const reminderHourBefore = functions.pubsub
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
      const bookingDate: Date = (d.booking_date as admin.firestore.Timestamp).toDate();
      const [hh, mm] = (d.start_time as string ?? "0:0").split(":").map(Number);
      const bookingStart = new Date(bookingDate);
      bookingStart.setHours(hh, mm, 0, 0);

      const minutesLeft = (bookingStart.getTime() - now.getTime()) / 60000;
      if (minutesLeft < 45 || minutesLeft > 75) continue;

      const restaurantId: string = d.restaurant_id ?? "";
      const name: string = d.name ?? "Гость";
      const guests: string = String(d.guests ?? "?");
      const phone: string = d.phone ?? "—";
      const start: string = d.start_time ?? "—";
      const end: string = d.end_time ?? "—";
      const dateStr = d.booking_date ? formatDate(d.booking_date) : "—";
      const restName = await getRestaurantName(restaurantId, d.restaurant_name ?? "");

      const title = `⏰ Через час мероприятие — ${restName}`;
      const body = `${name} · ${guests} гостей · ${dateStr} · ${start}–${end}\n📞 ${phone}`;
      const data = { type: "reminder_hour", booking_id: doc.id, restaurant_id: restaurantId };

      const sellerId = await getOwnerId(restaurantId);
      if (sellerId) await sendToUser(sellerId, title, body, data);

      const userId: string = d.user_id ?? "";
      if (userId && userId !== sellerId) {
        await sendToUser(userId, title, body, data);
      }
      batch.update(doc.ref, { reminder_hour_sent: true });
    }
    await batch.commit();
    functions.logger.info(`reminderHourBefore: processed within window`);
  });