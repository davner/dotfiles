import React, { useState, useEffect, useRef } from 'react';
import { ProgressBar } from 'primereact/progressbar';
import { Toast } from 'primereact/toast';

export default function DynamicDemo() {
    const [value, setValue] = useState<number>(0);
    const toast = useRef<Toast | null>(null);
    const interval = useRef<number | null>(null);

    useEffect(() => {
        let _val = value;

        interval.current = setInterval(() => {
            _val += Math.floor(Math.random() * 10) + 1;

            if (_val >= 100) {
                _val = 100;
                toast.current.show({ severity: 'info', summary: 'Success', detail: 'Process Completed' });
                clearInterval(interval.current);
            }

            setValue(_val);
        }, 2000);

        return () => {
            if (interval.current) {
                clearInterval(interval.current);
                interval.current = null;
            }
        };
    }, []);

    return (
        <div className="card">
            <Toast ref={toast}></Toast>
            <ProgressBar value={value}></ProgressBar>
        </div>
    );
}
