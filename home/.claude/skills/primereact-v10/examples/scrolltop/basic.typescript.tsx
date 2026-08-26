import React from 'react'; 
import { ScrollTop } from 'primereact/scrolltop';

export default function BasicDemo() {
    return (
        <div className="card flex flex-column align-items-center" style={{ height: '2000px' }}>
            <p>Scroll down the page to display the ScrollTo component.</p>
            <i className="pi pi-angle-down fadeout animation-duration-1000 animation-iteration-infinite" style={{ fontSize: '2rem' }}></i>
            <ScrollTop />
        </div>
    );
}
