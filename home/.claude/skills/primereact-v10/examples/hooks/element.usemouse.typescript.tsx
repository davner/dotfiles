import React from 'react';
import { useMouse } from 'primereact/hooks';

export default function ElementDemo() {
    const { ref, x, y } = useMouse();

    return (
        <div className="card flex justify-content-center">
            <div ref={ref} className="border-round surface-ground flex flex-wrap gap-3 justify-content-center align-items-center w-full md:w-20rem h-10rem text-xl">
                <span>
                    X: <strong>{x}</strong>
                </span>
                <span>
                    Y: <strong>{y}</strong>
                </span>
            </div>
        </div>
    )
}
