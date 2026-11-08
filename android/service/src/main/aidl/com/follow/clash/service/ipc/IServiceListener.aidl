package com.follow.clash.service.ipc;

oneway interface IServiceListener {
    void onServiceLost(String message);
}
