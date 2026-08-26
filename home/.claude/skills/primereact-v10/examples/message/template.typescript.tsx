import React from 'react';
import { Message } from 'primereact/message';

export default function TemplateDemo() {
    const content = (
        <div className="flex align-items-center">
            <img alt="logo" src="https://primefaces.org/cdn/primereact/images/logo.png" width="32" />
            <div className="ml-2">Always bet on Prime.</div>
        </div>
    );

    return (
        <div className="card">
            <Message
                style={{
                    border: 'solid #696cff',
                    borderWidth: '0 0 0 6px',
                    color: '#696cff'
                }}
                className="border-primary w-full justify-content-start"
                severity="info"
                content={content}
            />
        </div>
    )
}
