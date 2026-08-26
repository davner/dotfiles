import React from 'react'; 
import { Image } from 'primereact/image';

export default function TemplateDemo() {
    const icon = (<i className="pi pi-search"></i>)

    return (
        <div className="card flex justify-content-center">
            <Image src="https://primefaces.org/cdn/primereact/images/galleria/galleria12.jpg" indicatorIcon={icon} alt="Image" preview width="250" />
        </div>
    )
}
