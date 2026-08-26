import React from 'react';
import { Tag } from 'primereact/tag';

export default function TemplateDemo() {
    return (
        <Tag style={{background: 'linear-gradient(-225deg,#AC32E4 0%,#7918F2 48%,#4801FF 100%)'}}>
            <div className="flex align-items-center gap-2">
                <img alt="Country" src="https://primefaces.org/cdn/primereact/images/flag/flag_placeholder.png"
                    className="flag flag-it" style={{ width: '18px' }}/>
                <span className="text-base">Italy</span>
                <i className="pi pi-times text-xs"></i>
            </div>
        </Tag>
    );
}
