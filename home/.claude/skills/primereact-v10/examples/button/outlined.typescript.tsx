import React from 'react'; 
import { Button } from 'primereact/button';

export default function OutlinedDemo() {
    return (
        <div className="card flex flex-wrap justify-content-center gap-3">
            <Button label="Primary" outlined />
            <Button label="Secondary" severity="secondary" outlined />
            <Button label="Success" severity="success" outlined />
            <Button label="Info" severity="info" outlined />
            <Button label="Warning" severity="warning" outlined />
            <Button label="Help" severity="help" outlined />
            <Button label="Danger" severity="danger" outlined />
        </div>
    )
}
