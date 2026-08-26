import React, { useState, useEffect } from 'react';
import { Galleria } from 'primereact/galleria';
import { PhotoService } from './service/PhotoService';

export default function IndicatorTemplateDemo() {
    const [images, setImages] = useState(null);

    useEffect(() => {
        PhotoService.getImages().then((data) => setImages(data));
    }, []);

    const itemTemplate = (item) => {
        return <img src={item.itemImageSrc} alt={item.alt} style={{ width: '100%', display: 'block' }} />;
    };

    const indicatorTemplate = (index) => {
        return <span style={{ color: '#ffffff', cursor: 'pointer'}}>{index + 1}</span>;
    };
    
    return (
        <div className="card">
            <Galleria
                value={images}
                style={{ maxWidth: '640px' }}
                className="custom-indicator-galleria"
                showThumbnails={false}
                showIndicators
                changeItemOnIndicatorHover
                showIndicatorsOnItem
                indicatorsPosition="left"
                item={itemTemplate}
                indicator={indicatorTemplate}
            />
        </div>
    )
}
