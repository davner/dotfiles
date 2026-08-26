import React from 'react'; 
import { Button } from 'primereact/button';

export default function BadgesDemo() {
    return (
        <div className="card flex flex-wrap justify-content-center gap-3">
            <Button type="button" label="Emails" badge="8" />
            <Button type="button" label="Messages" icon="pi pi-users" outlined badge="2" badgeClassName="p-badge-danger" />
        </div>
    )
}
