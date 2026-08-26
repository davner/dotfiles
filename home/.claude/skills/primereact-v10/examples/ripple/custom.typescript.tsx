import React from 'react';
import { Ripple } from 'primereact/ripple';

export default function CustomDemo() {
    return (
        <div className="card flex justify-content-center align-items-center gap-2">
            <div className="p-ripple p-5 border-round border-radius-10 shadow-2">
                Green
                <Ripple
                    pt={{
                        root: { style: { background: 'rgba(75, 175, 80, 0.3)' } }
                    }}
                />
            </div>
            <div className="p-ripple p-5 border-round border-radius-10 shadow-2">
                Orange
                <Ripple
                    pt={{
                        root: { style: { background: 'rgba(255, 193, 6, 0.3)' } }
                    }}
                />
            </div>
            <div className="p-ripple p-5 border-round border-radius-10 shadow-2">
                Purple
                <Ripple
                    pt={{
                        root: { style: { background: 'rgba(156, 39, 176, 0.3)' } }
                    }}
                />
            </div>
        </div>
    );
}
