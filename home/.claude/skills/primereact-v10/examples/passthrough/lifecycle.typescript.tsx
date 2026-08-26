import React from 'react'; 
import { Panel } from 'primereact/panel';

export default function LifeCyleDemo() {
    const panelPt = {
        hooks: {
            useMountEffect: () => {
                //panel mounted
            },
            useUnmountEffect: () => {
                //panel unmounted
            }
    };
    
    return (
        <div className="card">
            <Panel header="Header" pt={panelPT}>
                Content
            </Panel>
        </div>
    )
}
