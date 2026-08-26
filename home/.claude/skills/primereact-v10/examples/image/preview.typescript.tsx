import React from 'react'; 
import { Image } from 'primereact/image';

export default function PreviewDemo() {
    return (
        <div className="card flex justify-content-center">
            <Image src="https://primefaces.org/cdn/primereact/images/galleria/galleria10.jpg" alt="Image" width="250" preview />
        </div>
    )
}
