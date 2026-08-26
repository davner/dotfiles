import React, { useState } from 'react'; 
import { Button } from 'primereact/button';
import { useFavicon } from 'primereact/hooks';

export default function BasicDemo() {
    const [favicon, setFavicon] = useState<string>('');
    const setFaviconToTwitter = () => setFavicon('https://twitter.com/favicon.ico');
    const setFaviconToPrimeReact = () => setFavicon('https://primefaces.org/cdn/primereact/images/favicon.ico');

    useFavicon(favicon);

    return (
        <div className="card flex justify-content-center gap-2">
            <Button icon="pi pi-twitter" label="Twitter" onClick={setFaviconToTwitter} />
            <Button icon="pi pi-prime" label="PrimeReact" onClick={setFaviconToPrimeReact} className="p-button-secondary" />
        </div>
    )
}
