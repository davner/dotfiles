import React, { useState, useEffect } from 'react';
import { Galleria, GalleriaResponsiveOptions } from 'primereact/galleria';
import { PhotoService } from './service/PhotoService';

export default function CaptionDoc() {
    const [images, setImages] = useState(null);
    const responsiveOptions: GalleriaResponsiveOptions[] = [
        {
            breakpoint: '991px',
            numVisible: 4
        },
        {
            breakpoint: '767px',
            numVisible: 3
        },
        {
            breakpoint: '575px',
            numVisible: 1
        }
    ];

    useEffect(() => {
        PhotoService.getImages().then(data => setImages(data));
    }, []);

    const itemTemplate = (item) => {
        return <img src={item.itemImageSrc} alt={item.alt} style={{ width: '100%', display: 'block' }} />;
    }

    const thumbnailTemplate = (item) => {
        return <img src={item.thumbnailImageSrc} alt={item.alt} style={{ display: 'block' }} />;
    }

    const caption = (item: any) => {
        return (
            <React.Fragment>
                <div className="text-xl mb-2 font-bold">{item.title}</div>
                <p className="text-white">{item.alt}</p>
            </React.Fragment>
        );
    }

    return (
        <div className="card">
            <Galleria value={images} responsiveOptions={responsiveOptions} numVisible={5} 
                item={itemTemplate} thumbnail={thumbnailTemplate} caption={caption} style={{ maxWidth: '640px' }} />
        </div>
    )
}
