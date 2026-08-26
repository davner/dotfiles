import React from 'react';
import { Button } from 'primereact/button';
import { Badge } from 'primereact/badge';

export default function ButtonDemo() {
    return (
        <div className="card flex flex-wrap justify-content-center gap-2">
            <Button type="button" label="Emails">
                <Badge value="8"></Badge>
            </Button>
            <Button type="button" label="Messages" icon="pi pi-users" severity="secondary">
                <Badge value="8" severity="danger"></Badge>
            </Button>
        </div>
    );
}
