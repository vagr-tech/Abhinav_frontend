package com.example.abhinav_tracking;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.telephony.TelephonyManager;
import android.util.Log;

public class CallReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {

        if (intent == null || intent.getAction() == null) {
            return;
        }

        String state = intent.getStringExtra(TelephonyManager.EXTRA_STATE);

        Log.d("CALL_RECEIVER", "Receiver triggered");

        if (TelephonyManager.EXTRA_STATE_IDLE.equals(state)) {
            Log.d("CALL_RECEIVER", "Call ended detected");

            Intent serviceIntent = new Intent(context, CallLogService.class);
            context.startService(serviceIntent);
        }
    }
}