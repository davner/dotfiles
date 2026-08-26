import React from 'react';
import { Chip } from 'primereact/chip';

export default function ImageDemo() {
    return (
        <div className="card flex flex-wrap gap-2">
            <Chip label="Amy Elsner" image="https://primefaces.org/cdn/primereact/images/avatar/amyelsner.png" />
            <Chip label="Asiya Javayant" image="https://primefaces.org/cdn/primereact/images/avatar/asiyajavayant.png" />
            <Chip label="Onyama Limba" image="https://primefaces.org/cdn/primereact/images/avatar/onyamalimba.png" />
            <Chip label="Xuxue Feng" image="https://primefaces.org/cdn/primereact/images/avatar/xuxuefeng.png" removable />
        </div>
    );
}
