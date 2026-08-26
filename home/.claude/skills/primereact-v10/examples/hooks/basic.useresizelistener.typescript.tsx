import React, { useState, useEffect } from 'react';
import { useResizeListener } from 'primereact/hooks';

export default function BasicDemo() {
    const [eventData, setEventData] = useState({ width: 0, height: 0 });

    const [bindWindowResizeListener, unbindWindowResizeListener] = useResizeListener({
        listener: (event) => {
            setEventData({
                width: event.currentTarget.innerWidth,
                height: event.currentTarget.innerHeight
            });
        }
    });

    useEffect(() => {
        setEventData({ width: window.innerWidth, height: window.innerHeight });
    }, []);

    useEffect(() => {
        bindWindowResizeListener();

        return () => {
            unbindWindowResizeListener();
        };
    }, [bindWindowResizeListener, unbindWindowResizeListener]);

    return (
        <div className="card flex flex-wrap justify-content-center gap-3 text-xl">
            <span>
                Width: <strong>{eventData.width}</strong>
            </span>
            <span>
                Height: <strong>{eventData.height}</strong>
            </span>
        </div>
    )
}
