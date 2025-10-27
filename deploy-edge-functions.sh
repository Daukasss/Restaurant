#!/bin/bash

if [ -z "$1" ]; then
  echo "❌ Укажите project-ref. Пример: ./deploy-functions.sh abcdefgh12345678"
  exit 1
fi

echo "🚀 Деплой функции send_fcm_legacy..."
supabase functions deploy send_fcm_legacy --project-ref $1

echo "🚀 Деплой функции send_fcm_v1..."
supabase functions deploy send_fcm_v1 --project-ref $1

echo "✅ Деплой завершён!"
