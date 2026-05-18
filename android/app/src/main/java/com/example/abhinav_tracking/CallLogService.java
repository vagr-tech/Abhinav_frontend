package com.example.abhinav_tracking;

import android.Manifest;
import android.app.Service;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.os.IBinder;
import android.provider.CallLog;
import android.util.Log;

import androidx.core.content.ContextCompat;

import org.json.JSONObject;

import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Calendar;

public class CallLogService extends Service {

    private static long lastSavedTimestamp = 0;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {

        Log.d("CALL_LOG_SERVICE", "Service started");

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG)
                != PackageManager.PERMISSION_GRANTED) {
            Log.e("CALL_LOG_SERVICE", "READ_CALL_LOG permission not granted");
            stopSelf();
            return START_NOT_STICKY;
        }

        Cursor cursor = null;

        try {
            cursor = getContentResolver().query(
                    CallLog.Calls.CONTENT_URI,
                    null,
                    null,
                    null,
                    CallLog.Calls.DATE + " DESC"
            );

            if (cursor != null && cursor.moveToFirst()) {

                String number = cursor.getString(
                        cursor.getColumnIndexOrThrow(CallLog.Calls.NUMBER));

                int duration = cursor.getInt(
                        cursor.getColumnIndexOrThrow(CallLog.Calls.DURATION));

                long timestamp = cursor.getLong(
                        cursor.getColumnIndexOrThrow(CallLog.Calls.DATE));

                Log.d("CALL_LOG_SERVICE", "Number: " + number);
                Log.d("CALL_LOG_SERVICE", "Duration: " + duration);
                Log.d("CALL_LOG_SERVICE", "Timestamp: " + timestamp);

                if (duration == 0) {
                    stopSelf();
                    return START_NOT_STICKY;
                }

                if (timestamp == lastSavedTimestamp) {
                    Log.d("CALL_LOG_SERVICE", "Duplicate call skipped");
                    stopSelf();
                    return START_NOT_STICKY;
                }

                Calendar cal = Calendar.getInstance();
                cal.set(Calendar.HOUR_OF_DAY, 0);
                cal.set(Calendar.MINUTE, 0);
                cal.set(Calendar.SECOND, 0);
                cal.set(Calendar.MILLISECOND, 0);

                long todayStart = cal.getTimeInMillis();

                if (timestamp < todayStart) {
                    Log.d("CALL_LOG_SERVICE", "Old call ignored");
                    stopSelf();
                    return START_NOT_STICKY;
                }

                lastSavedTimestamp = timestamp;
                sendCallToServer(number, duration);
            }

        } catch (Exception e) {
            Log.e("CALL_LOG_SERVICE", "ERROR: " + e.getMessage(), e);
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }

        stopSelf();
        return START_NOT_STICKY;
    }

    private void sendCallToServer(String number, int duration) {
        new Thread(() -> {
            try {
                URL url = new URL("https://abhinav-backend.onrender.com/api/shops/calls");

                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("POST");
                conn.setRequestProperty("Content-Type", "application/json");
                conn.setDoOutput(true);

                JSONObject json = new JSONObject();
                json.put("phone", number);
                json.put("durationSec", duration);

                OutputStream os = conn.getOutputStream();
                os.write(json.toString().getBytes());
                os.flush();
                os.close();

                int responseCode = conn.getResponseCode();
                Log.d("CALL_LOG_SERVICE", "API Response: " + responseCode);

                conn.disconnect();

            } catch (Exception e) {
                Log.e("CALL_LOG_SERVICE", "API ERROR: " + e.getMessage(), e);
            }
        }).start();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}