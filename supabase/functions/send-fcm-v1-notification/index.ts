import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"


const supabaseUrl = Deno.env.get("SUPABASE_URL")!
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
const supabase = createClient(supabaseUrl, supabaseServiceKey)

// Firebase Service Account для FCM V1 API
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!
const FIREBASE_SERVICE_ACCOUNT = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!)
// Приводим ключ к корректному виду с реальными переносами строк
FIREBASE_SERVICE_ACCOUNT.private_key = FIREBASE_SERVICE_ACCOUNT.private_key.replace(/\\n/g, "\n")

interface NotificationRequest {
  user_id?: string
  fcm_token?: string
  title: string
  body: string
  data?: Record<string, any>
  test?: boolean
  background_test?: boolean
}

// Функция для конвертации PEM -> Uint8Array DER
function pemToArrayBuffer(pem: string): Uint8Array {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "")
  const raw = atob(b64)
  const buffer = new Uint8Array(raw.length)
  for (let i = 0; i < raw.length; i++) {
    buffer[i] = raw.charCodeAt(i)
  }
  return buffer
}

serve(async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  }

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    console.log("🔥 === FCM V1 API ===")

    if (req.method !== "POST") {
      throw new Error("Method not allowed")
    }

    const requestBody: NotificationRequest = await req.json()
    console.log("📊 Request body:", requestBody)

    if (requestBody.test) {
      console.log("🧪 Test request - FCM V1 API работает!")

      return new Response(
        JSON.stringify({
          success: true,
          message: "FCM V1 API доступен!",
          project_id: FIREBASE_PROJECT_ID,
          timestamp: new Date().toISOString(),
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        },
      )
    }

    const { user_id, fcm_token, title, body, data, background_test } = requestBody

    if (!title || !body) {
      throw new Error("Missing required fields: title, body")
    }

    let targetToken = fcm_token

    if (user_id && !fcm_token) {
      console.log("🔍 Получение FCM токена для пользователя:", user_id)

      const { data: profile, error } = await supabase.from("profiles").select("fcm_token").eq("id", user_id).single()

      if (error || !profile?.fcm_token) {
        throw new Error(`FCM токен не найден для пользователя: ${user_id}`)
      }

      targetToken = profile.fcm_token
    }

    if (!targetToken) {
      throw new Error("FCM токен не предоставлен")
    }

    console.log("🔑 FCM токен:", targetToken.substring(0, 30) + "...")
    console.log("📱 Заголовок:", title)
    console.log("📝 Текст:", body)
    console.log("🌙 Фоновый режим:", background_test ? "Да" : "Нет")

    const result = await sendFCMV1Notification(targetToken, title, body, data, background_test)
    console.log("✅ Уведомление отправлено через FCM V1 API")

    return new Response(
      JSON.stringify({
        success: true,
        message_id: result.name,
        timestamp: new Date().toISOString(),
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    )
  } catch (error) {
    console.error("❌ Error:", error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString(),
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      },
    )
  }
})

async function getAccessToken(): Promise<string> {
  console.log("🔑 Получение Access Token для FCM V1...")

  const jwtHeader = {
    alg: "RS256",
    typ: "JWT",
  }

  const now = Math.floor(Date.now() / 1000)
  const jwtPayload = {
    iss: FIREBASE_SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }

  const base64url = (source: string) => btoa(source).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_")

  const headerB64 = base64url(JSON.stringify(jwtHeader))
  const payloadB64 = base64url(JSON.stringify(jwtPayload))
  const unsignedToken = `${headerB64}.${payloadB64}`

  // Правильный импорт приватного ключа
  const privateKeyDer = pemToArrayBuffer(FIREBASE_SERVICE_ACCOUNT.private_key)

  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    privateKeyDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  )

  const signatureBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(unsignedToken),
  )

  // base64url для подписи
  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")

  const jwt = `${unsignedToken}.${signatureB64}`

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  })

  if (!tokenResponse.ok) {
    const errorText = await tokenResponse.text()
    throw new Error(`Token error: ${tokenResponse.status} - ${errorText}`)
  }

  const tokenData = await tokenResponse.json()
  console.log("✅ Access Token получен")
  return tokenData.access_token
}

async function sendFCMV1Notification(
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, any>,
  backgroundMode = false,
): Promise<any> {
  console.log("📤 Отправка через FCM V1 API...")
  console.log("🌙 Режим фоновых уведомлений:", backgroundMode ? "Да" : "Нет")

  const accessToken = await getAccessToken()

  // Преобразуем все значения в строки для FCM
  const stringData = data ? Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])) : {}

  // Добавляем метку времени для уникальности сообщений
  stringData.timestamp = String(Date.now())

  // Для фоновых уведомлений используем другую структуру
  let message

  if (backgroundMode) {
    // Структура для фоновых уведомлений - приоритет на data
    message = {
      message: {
        token: fcmToken,
        data: {
          ...stringData,
          title: title,
          body: body,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          channel_id: "fcm_v1_background",
        },
        android: {
          priority: "high",
          ttl: "86400s", // 24 часа
          direct_boot_ok: true,
        },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-push-type": "background",
          },
          payload: {
            aps: {
              "content-available": 1,
            },
            data: stringData,
          },
        },
      },
    }
  } else {
    // Структура для обычных уведомлений
    message = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: stringData,
        android: {
          priority: "high",
          notification: {
            channel_id: "fcm_v1_foreground",
            color: "#4CAF50",
            icon: "icon_toi",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            tag: "booking_notification",
            sticky: false,
            default_sound: true,
            default_vibrate_timings: true,
            default_light_settings: true,
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
          },
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: "default",
              badge: 1,
            },
            data: stringData,
          },
        },
      },
    }
  }

  console.log("📊 Структура сообщения:", JSON.stringify(message, null, 2))

  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(message),
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`FCM V1 error: ${response.status} - ${errorText}`)
  }

  const result = await response.json()
  console.log("✅ FCM V1 response:", result)
  return result
}
