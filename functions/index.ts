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
  return doc.data()?.name ?? "Ресторан";
}

// ─── helpers: работа с датами по UTC+5 ───────────────────────────────────────

const UTC_PLUS_5_OFFSET_MS = 5 * 60 * 60 * 1000; // UTC+5 в миллисекундах

/**
 * Возвращает текущее время в UTC+5 как объект Date.
 * UTC-методы этого Date вернут значения, соответствующие UTC+5.
 */
function nowUtcPlus5(): Date {
  return new Date(Date.now() + UTC_PLUS_5_OFFSET_MS);
}

/**
 * Получает UTC timestamp для полуночи в UTC+5 на указанный день.
 * @param utcPlus5Now - текущее время в UTC+5 (результат nowUtcPlus5())
 * @param daysOffset - смещение в днях (0 = сегодня, 1 = завтра)
 */
function getUtcMidnightForUtcPlus5Day(utcPlus5Now: Date, daysOffset: number): Date {
  // Создаём дату в UTC+5
  const d = new Date(utcPlus5Now);
  d.setUTCDate(d.getUTCDate() + daysOffset);
  d.setUTCHours(0, 0, 0, 0);
  // Конвертируем полночь UTC+5 обратно в UTC
  return new Date(d.getTime() - UTC_PLUS_5_OFFSET_MS);
}

/**
 * Вычисляет точный UTC момент начала бронирования.
 * 
 * ВАЖНО: booking_date в Firestore хранится как UTC timestamp,
 * но представляет дату в UTC+5. Например, если бронирование на 15 марта,
 * то booking_date = 14 марта 19:00 UTC (что соответствует 15 марта 00:00 UTC+5).
 * 
 * @param bookingDateTs - Timestamp даты бронирования из Firestore
 * @param startTime - Время начала в формате "HH:mm" (в UTC+5)
 * @returns UTC Date момента начала бронирования
 */
function getBookingStartTimeUtc(
  bookingDateTs: admin.firestore.Timestamp,
  startTime: string
): Date {
  const [hours, minutes] = (startTime ?? "0:0").split(":").map(Number);
  
  // booking_date хранит UTC timestamp, соответствующий полуночи UTC+5
  // Чтобы получить полночь в UTC+5, добавляем смещение
  const bookingDateUtc = bookingDateTs.toDate().getTime();
  
  // Добавляем время начала (часы и минуты в UTC+5)
  // startTime уже в UTC+5, поэтому просто добавляем к booking_date
  const startTimeMs = (hours * 60 + minutes) * 60 * 1000;
  
  return new Date(bookingDateUtc + startTimeMs);
}

// ─── 1. Новая бронь от юзера → уведомить селлера ─────────────────────────────

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
        restaurant_id: restaurantId,
      }
    );
  });

// ─── 3. Напоминание за день — 09:00 по UTC+5 ─────────────────────────────────

export const reminderDayBefore = functions.pubsub
  .schedule("0 4 * * *") // 04:00 UTC = 09:00 UTC+5
  .timeZone("UTC")
  .onRun(async () => {
    const now = nowUtcPlus5();
    functions.logger.info(`reminderDayBefore: starting at UTC+5 time: ${now.toISOString()}`);
    
    // Завтра 00:00 — послезавтра 00:00 по UTC+5, переведённые в UTC для Firestore
    const tomorrowUtc = getUtcMidnightForUtcPlus5Day(now, 1);
    const dayAfterUtc = getUtcMidnightForUtcPlus5Day(now, 2);
    
    functions.logger.info(`reminderDayBefore: searching bookings between ${tomorrowUtc.toISOString()} and ${dayAfterUtc.toISOString()}`);

    // Запрашиваем оба случая: поле == false И поле отсутствует (null).
    // Firestore НЕ возвращает документы без поля при фильтре "== false".
    const [snapFalse, snapNull] = await Promise.all([
      db.collection("bookings")
        .where("booking_date", ">=", admin.firestore.Timestamp.fromDate(tomorrowUtc))
        .where("booking_date", "<",  admin.firestore.Timestamp.fromDate(dayAfterUtc))
        .where("status", "in", ["pending", "confirmed"])
        .where("reminder_day_sent", "==", false)
        .get(),
      db.collection("bookings")
        .where("booking_date", ">=", admin.firestore.Timestamp.fromDate(tomorrowUtc))
        .where("booking_date", "<",  admin.firestore.Timestamp.fromDate(dayAfterUtc))
        .where("status", "in", ["pending", "confirmed"])
        .where("reminder_day_sent", "==", null)
        .get(),
    ]);

    const seen = new Set<string>();
    const docs = [...snapFalse.docs, ...snapNull.docs].filter(doc => {
      if (seen.has(doc.id)) return false;
      seen.add(doc.id);
      return true;
    });

    const batch = db.batch();
    for (const doc of docs) {
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
      const data = { type: "reminder_day", restaurant_id: restaurantId };

      const sellerId = await getOwnerId(restaurantId);
      if (sellerId) await sendToUser(sellerId, title, body, data);

      const userId: string = d.user_id ?? "";
      if (userId && userId !== sellerId) {
        await sendToUser(userId, title, body, data);
      }
      batch.update(doc.ref, { reminder_day_sent: true });
    }
    await batch.commit();
    functions.logger.info(`reminderDayBefore: processed ${docs.length} bookings`);
  });

// ─── 4. Напоминание за час — каждые 15 минут ─────────────────────────────────

export const reminderHourBefore = functions.pubsub
  .schedule("*/15 * * * *")
  .timeZone("UTC")
  .onRun(async () => {
    const now = nowUtcPlus5();
    const nowUtcMs = Date.now();
    
    functions.logger.info(`reminderHourBefore: starting at UTC+5 time: ${now.toISOString()}, UTC ms: ${nowUtcMs}`);

    const startOfTodayUtc = getUtcMidnightForUtcPlus5Day(now, 0);
    const startOfTomorrowUtc = getUtcMidnightForUtcPlus5Day(now, 1);
    
    functions.logger.info(`reminderHourBefore: searching bookings between ${startOfTodayUtc.toISOString()} and ${startOfTomorrowUtc.toISOString()}`);

    const [snapFalse, snapNull] = await Promise.all([
      db.collection("bookings")
        .where("booking_date", ">=", admin.firestore.Timestamp.fromDate(startOfTodayUtc))
        .where("booking_date", "<",  admin.firestore.Timestamp.fromDate(startOfTomorrowUtc))
        .where("status", "in", ["pending", "confirmed"])
        .where("reminder_hour_sent", "==", false)
        .get(),
      db.collection("bookings")
        .where("booking_date", ">=", admin.firestore.Timestamp.fromDate(startOfTodayUtc))
        .where("booking_date", "<",  admin.firestore.Timestamp.fromDate(startOfTomorrowUtc))
        .where("status", "in", ["pending", "confirmed"])
        .where("reminder_hour_sent", "==", null)
        .get(),
    ]);

    const seen = new Set<string>();
    const docs = [...snapFalse.docs, ...snapNull.docs].filter(doc => {
      if (seen.has(doc.id)) return false;
      seen.add(doc.id);
      return true;
    });

    const batch = db.batch();
    for (const doc of docs) {
      const d = doc.data();

// Считаем точный UTC-момент начала брони с учётом UTC+5
      const startUtc = getBookingStartTimeUtc(
        d.booking_date as admin.firestore.Timestamp,
        (d.start_time as string) ?? "0:0"
      );
      const minutesLeft = (startUtc.getTime() - nowUtcMs) / 60000;

functions.logger.info(`reminderHourBefore: booking ${doc.id} starts at ${startUtc.toISOString()}, minutesLeft: ${minutesLeft.toFixed(1)}`);

      // Окно: 45–75 минут до начала
      if (minutesLeft < 45 || minutesLeft > 75) {
        functions.logger.info(`reminderHourBefore: booking ${doc.id} outside window (45-75 min), skipping`);
        continue;
      }
      
      functions.logger.info(`reminderHourBefore: booking ${doc.id} IN WINDOW, sending notification`);

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
      const data = { type: "reminder_hour", restaurant_id: restaurantId };

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
