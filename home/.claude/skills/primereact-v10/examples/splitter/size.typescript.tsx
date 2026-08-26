import React from 'react'; 
import { Splitter, SplitterPanel } from 'primereact/splitter';

export default function SizeDemo() {
    return (
        <Splitter style={{ height: '300px' }}>
            <SplitterPanel className="flex align-items-center justify-content-center" size={25} minSize={10}>Panel 1</SplitterPanel>
            <SplitterPanel className="flex align-items-center justify-content-center" size={75}>Panel 2</SplitterPanel>
        </Splitter>
    )
}
