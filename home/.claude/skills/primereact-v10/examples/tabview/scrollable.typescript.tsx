import React, { useState } from 'react';
import { TabView, TabPanel } from 'primereact/tabview';

export default function ScrollableDemo() {
    const scrollableTabs = Array.from({ length: 50 }, (_, i) => ({ title: `Tab ${i + 1}`, content: `Tab ${i + 1} Content` }))

    return (
        <div className="card">
            <TabView scrollable>
                {scrollableTabs.map((tab) => {
                    return (
                        <TabPanel key={tab.title} header={tab.title}>
                            <p className="m-0">{tab.content}</p>
                        </TabPanel>
                    );
                })}
            </TabView>
        </div>
    )
}
