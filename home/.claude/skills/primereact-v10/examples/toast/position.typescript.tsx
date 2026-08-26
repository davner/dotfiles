import React, { useRef } from 'react';
import { Button } from 'primereact/button';
import { Toast, ToastMessage } from 'primereact/toast';

export default function PositionDemo() {
    const toastTopCenter = useRef<Toast>(null);
    const toastTopLeft = useRef<Toast>(null);
    const toastTopRight = useRef<Toast>(null);
    const toastCenter = useRef<Toast>(null);
    const toastBottomLeft = useRef<Toast>(null);
    const toastBottomCenter = useRef<Toast>(null);
    const toastBottomRight = useRef<Toast>(null);

    const showMessage = (event: React.MouseEvent<HTMLButtonElement>, ref: React.RefObject<Toast>, severity: ToastMessage['severity']) => {
        const target = event.target as HTMLButtonElement;
        const label = target.innerText;

        ref.current?.show({ severity: severity, summary: label, detail: label, life: 3000 });
    };

    return (
        <div className="card flex justify-content-center">
            <Toast ref={toastTopLeft} position="top-left" />
            <Toast ref={toastTopCenter} position="top-center" />
            <Toast ref={toastTopRight} position="top-right" />
            <Toast ref={toastCenter} position="center" />
            <Toast ref={toastBottomLeft} position="bottom-left" />
            <Toast ref={toastBottomCenter} position="bottom-center" />
            <Toast ref={toastBottomRight} position="bottom-right" />
            <div className="flex flex-wrap gap-2">
                <Button label="Top Left" className="p-button-success" onClick={(e) => showMessage(e, toastTopLeft, 'success')} />
                <Button label="Top Center" onClick={(e) => showMessage(e, toastTopCenter, 'info')} />
                <Button label="Top Right" className="p-button-warning" onClick={(e) => showMessage(e, toastTopRight, 'warn')} />
                <Button label="Center" className="p-button-danger" onClick={(e) => showMessage(e, toastCenter, 'error')} />
                <Button label="Bottom Left" className="p-button-success" onClick={(e) => showMessage(e, toastBottomLeft, 'success')} />
                <Button label="Bottom Center" onClick={(e) => showMessage(e, toastBottomCenter, 'info')} />
                <Button label="Bottom Right" className="p-button-warning" onClick={(e) => showMessage(e, toastBottomRight, 'warn')} />
            </div>
        </div>
    )
}
