import React from 'react';
import { useMouse } from 'primereact/hooks';

export default function DocumentDemo() {
    const { x, y } = useMouse();

    return (
        <div className="card flex justify-content-center gap-3 text-xl">
            <span>
                X: <strong>{x}</strong>
            </span>
            <span>
                Y: <strong>{y}</strong>
            </span>
        </div>
    )
}
