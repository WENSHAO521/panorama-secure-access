package com.follow.clash.service.ipc;

import com.follow.clash.service.ipc.Payload;

oneway interface ICoreCallback {
    void onResult(in Payload result);
}
