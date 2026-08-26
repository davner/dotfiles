import React, { useRef } from 'react';
import { Toast } from 'primereact/toast';
import { Captcha } from 'primereact/captcha';

export default function CaptchaDoc() {
    const toast = useRef<Toast>(null);

    const showResponse = () => {
        toast.current?.show({ severity: 'info', summary: 'Success', detail: 'User Responded' });
    };

    return (
        <div className="card">
            <Toast ref={toast}></Toast>
            <Captcha siteKey="YOUR_SITE_KEY" onResponse={showResponse} />
        </div>
    );
}
