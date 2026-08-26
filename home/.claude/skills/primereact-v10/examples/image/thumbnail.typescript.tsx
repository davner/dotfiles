import React from 'react'; 
import { Image } from 'primereact/image';

export default function ThumbnailDemo() {
    return (
        <div className="card flex justify-content-center">
            <Image src="https://primefaces.org/cdn/primereact/images/galleria/galleria14.jpg" zoomSrc="https://primefaces.org/cdn/primereact/images/galleria/galleria14.jpg" alt="Image" width="80" height="60" preview />
        </div>
    )
}
