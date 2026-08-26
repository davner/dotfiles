import React from 'react'; 
import { Button } from 'primereact/button';

export default function RaisedTextDemo() {
    return (
        <div className="card flex flex-wrap justify-content-center gap-3">
            <Button label="Primary" text raised />
            <Button label="Secondary" severity="secondary" text raised />
            <Button label="Success" severity="success" text raised />
            <Button label="Info" severity="info" text raised />
            <Button label="Warning" severity="warning" text raised />
            <Button label="Help" severity="help" text raised />
            <Button label="Danger" severity="danger" text raised />
        </div>
    )
}
