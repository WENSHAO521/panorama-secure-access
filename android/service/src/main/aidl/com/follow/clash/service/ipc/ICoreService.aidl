package com.follow.clash.service.ipc;

import com.follow.clash.service.ipc.ICoreCallback;
import com.follow.clash.service.ipc.IServiceListener;
import com.follow.clash.service.ipc.Payload;

interface ICoreService {
    oneway void invokeMethod(in Payload data, ICoreCallback callback);

    oneway void quickSetup(String initParams, in Payload setupParams, ICoreCallback callback);

    void setEventListener(ICoreCallback listener);

    void setServiceListener(IServiceListener listener);

    void updateNotificationParams(String params);

    long start(String vpnOptions);

    void stop();

    long runtimeStartedAt();

    boolean runtimeVpn();
}
