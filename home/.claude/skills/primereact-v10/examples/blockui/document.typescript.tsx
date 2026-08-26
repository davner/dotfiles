import React, { useState, useEffect } from 'react';
import { BlockUI } from 'primereact/blockui';
import { Panel } from 'primereact/panel';
import { Button } from 'primereact/button';

export default function DocumentDemo() {
    const [blocked, setBlocked] = useState<boolean>(false);

    useEffect(() => {
        if (blocked) {
            setTimeout(() => {
                setBlocked(false);
            }, 3000);
        }
    }, [blocked]);

    return (
        <div className="card">
            <BlockUI blocked={blocked} fullScreen />
            <Button label="Block" onClick={() => setBlocked(true)} />
        </div>
    );
}
