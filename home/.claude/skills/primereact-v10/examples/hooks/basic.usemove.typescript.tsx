import React from 'react'; 
import { useMove } from 'primereact/hooks';
import { Button } from 'primereact/button';
import { classNames } from 'primereact/utils';

export default function BasicDemo() {
    const { ref, x, y, active, reset } = useMove({ initialValue: { x: 0.2, y: 0.6 } });

    return (
        <div className="card flex flex-column align-items-center gap-3">
            <div className="flex gap-3 text-xl">
                <span>
                    X: <strong>{`${Math.round(x * 100)}`}</strong>
                </span>
                <span>
                    Y: <strong>{`${Math.round(y * 100)}`}</strong>
                </span>
            </div>
            <div ref={ref} className="relative w-14rem h-8rem surface-ground border-round">
                <div className={classNames('absolute border-circle w-2rem h-2rem flex align-items-center justify-content-center', { 'bg-green-500': active, 'bg-primary': !active })}
                    style={{
                        left: `calc(${x * 100}% - 1rem)`,
                        top: `calc(${y * 100}% - 1rem)`,
                        cursor: 'grab'
                    }}>
                    <i className="pi pi-arrows-alt"></i>
                </div>
            </div>
            <Button onClick={reset} label="Reset" className="p-button-outlined"></Button>
        </div>
    )
}
