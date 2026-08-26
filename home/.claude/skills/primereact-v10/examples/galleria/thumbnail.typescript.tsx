import React, { useState, useEffect } from 'react';
import { Galleria, GalleriaResponsiveOptions } from 'primereact/galleria';
import { RadioButton } from 'primereact/radiobutton';
import { PhotoService } from './service/PhotoService';

export default function ThumbnailDemo() {
    const [images, setImages] = useState(null);
    const [position, setPosition] = useState<string>('bottom');
    const positionOptions: Array<{label: string, value: string}> = [
        {
            label: 'Bottom',
            value: 'bottom'
        },
        {
            label: 'Top',
            value: 'top'
        },
        {
            label: 'Left',
            value: 'left'
        },
        {
            label: 'Right',
            value: 'right'
        }
    ];
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
        return <img src={item.itemImageSrc} alt={item.alt} style={{ width: '100%', display: 'block' }} />
    }

    const thumbnailTemplate = (item) => {
        return <img src={item.thumbnailImageSrc} alt={item.alt} style={{ width: '100%', display: 'block' }} />
    }

    return (
        <div className="card">
            <div className="flex flex-wrap gap-3 mb-5">
                {positionOptions.map((option) => {
                    const { label, value } = option;

                    return (
                        <div className="flex align-items-center" key={label}>
                            <RadioButton value={value} onChange={(e) => setPosition(e.value)} checked={position === value} />
                            <label htmlFor={label} className="ml-2">
                                {label}
                            </label>
                        </div>
                    );
                })}
            </div>
            <Galleria style={{ maxWidth: '640px' }} value={images} responsiveOptions={responsiveOptions} numVisible={5} item={itemTemplate} thumbnailsPosition={position} thumbnail={thumbnailTemplate} />
        </div>
    )
}
