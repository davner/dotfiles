import React from 'react'; 
import {useMove } from 'primereact/hooks';

export default function VerticalDemo() {
    const { ref, y } = useMove({ initialValue: { y: 0.2 }, mode: 'vertical' });

    return (
        <div className="card flex flex-column justify-content-center align-items-center gap-3">
            <div ref={ref} className="flex align-items-center justify-content-center relative surface-ground h-14rem z-1" style={{ width: '8px' }}>
                <div className="absolute bg-purple-500 z-2"
                    style={{
                        bottom: 0,
                        width: '8px',
                        height: `${y * 100}%`
                    }}>
                </div>
                <div className='absolute block border-circle border-solid border-2 border-purple -mb-2 surface-overlay z-3'
                    style={{
                        width: '18px',
                        height: '18px',
                        bottom: `calc(${y * 100}%)`,
                        cursor: 'grab'
                    }}>
                </div>
            </div>
            <span className="text-xl">
                Value: <strong>{Math.round(y * 100)}</strong>
            </span>
        </div>
    )
}
