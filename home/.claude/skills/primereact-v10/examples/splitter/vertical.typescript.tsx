import React from 'react'; 
import { Splitter, SplitterPanel } from 'primereact/splitter';

export default function VerticalDemo() {
    return (
        <Splitter style={{ height: '300px' }} layout="vertical">
            <SplitterPanel className="flex align-items-center justify-content-center">Panel 1</SplitterPanel>
            <SplitterPanel className="flex align-items-center justify-content-center">Panel 2</SplitterPanel>
        </Splitter>
    )
}
