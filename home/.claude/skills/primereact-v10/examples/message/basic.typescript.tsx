import React from 'react'; 
import { Message } from 'primereact/message';

export default function BasicDemo() {
    return (
        <div className="card flex justify-content-center">
            <Message text="Username is required" />
        </div>
    )
}
