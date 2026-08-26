import React, { useState, useEffect } from 'react';
import { Galleria } from 'primereact/galleria';
import { Checkbox } from 'primereact/checkbox';
import { PhotoService } from './service/PhotoService';

export default function PositionDemo() {
    const [images, setImages] = useState(null);
    const [inside, setInside] = useState<boolean>(false);
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

    useEffect(() => {
        PhotoService.getImages().then((data) => setImages(data));
    }, []);

    const itemTemplate = (item) => {
        return <img src={item.itemImageSrc} alt={item.alt} style={{ width: '100%', display: 'block' }} />;
    };
    
    return (
        <div className="card">
            <div className="flex flex-wrap gap-3 mb-5">
                {positionOptions.map((option) => {
                    const { label, value } = option;

                    return (
                        <div className="flex align-items-center" key={label}>
                            <RadioButton value={value} onChange={(e) => setPosition(e.value)} checked={position === value} />
                            <label htmlFor={label} className="ml-2">{label}</label>
                        </div>
                    );
                })}
            </div>
            <div className="flex align-items-center mb-5">
                <Checkbox inputId="inside_cbox" onChange={e => setInside(e.checked)} checked={inside}></Checkbox>
                <label htmlFor="inside_cbox" className="ml-2">Inside</label>
            </div>
            <Galleria value={images} style={{ maxWidth: '640px' }} showThumbnails={false} showIndicators 
                    showIndicatorsOnItem={inside} indicatorsPosition={position} item={itemTemplate} />
        </div>
    )
}
