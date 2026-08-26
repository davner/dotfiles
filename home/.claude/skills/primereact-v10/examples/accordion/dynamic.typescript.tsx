import React, { useState } from 'react';
import { Accordion, AccordionTab } from 'primereact/accordion';

export default function DynamicDemo() {
    const [tabs] = useState([
        {
            header: 'Title I',
            children: <p className="m-0">Content 1</p>
        },
        {
            header: 'Title II',
            children: <p className="m-0">Content 2 </p>
        },
        {
            header: 'Title III',
            children: <p className="m-0">Content 3 </p>
        }
    ]);

    const createDynamicTabs = () => {
        return tabs.map((tab, i) => {
            return (
                <AccordionTab key={tab.header} header={tab.header} disabled={tab.disabled}>
                    {tab.children}
                </AccordionTab>
            );
        });
    };
    
    return (
        <div className="card">
            <Accordion>{createDynamicTabs()}</Accordion>
        </div>
    )
}
