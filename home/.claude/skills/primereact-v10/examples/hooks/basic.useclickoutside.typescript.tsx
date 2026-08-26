import React, { useState, useRef } from 'react';
import { Button } from 'primereact/button';
import { useClickOutside } from 'primereact/hooks';

export default function BasicDemo() {
    const [visible, setVisible] = useState<boolean>(false);
    const overlayRef = useRef(null);

    useClickOutside(overlayRef, () => {
        setVisible(false);
    });

    return (
        <div className="relative">
            <Button onClick={() => setVisible(true)} label="Show" />
            {visible ? (
                <div ref={overlayRef} className="absolute border-round shadow-2 p-5 surface-overlay z-2 white-space-nowrap scalein origin-top">
                    Popup Content
                </div>
            ) : null}
        </div>
    )
}
