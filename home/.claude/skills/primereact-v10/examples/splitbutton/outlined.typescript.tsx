import React, { useRef } from 'react';
//import { useRouter } from 'next/router';
import { SplitButton } from 'primereact/splitbutton';
import { MenuItem } from 'primereact/menuitem';
import { Toast } from 'primereact/toast';

export default function OutlinedDemo() {
    //const router = useRouter();
    const toast = useRef<Toast>(null);
    const items: MenuItem[] = [
        {
            label: 'Update',
            icon: 'pi pi-refresh',
            command: () => {
                toast.current.show({ severity: 'success', summary: 'Updated', detail: 'Data Updated' });
            }
        },
        {
            label: 'Delete',
            icon: 'pi pi-times',
            command: () => {
                toast.current.show({ severity: 'warn', summary: 'Delete', detail: 'Data Deleted' });
            }
        },
        {
            label: 'React Website',
            icon: 'pi pi-external-link',
            command: () => {
                window.location.href = 'https://reactjs.org/';
            }
        },
        {
            label: 'Upload',
            icon: 'pi pi-upload',
            command: () => {
                //router.push('/fileupload');
            }
        }
    ];

    const save = () => {
        toast.current.show({ severity: 'success', summary: 'Success', detail: 'Data Saved' });
    };

    return (
        <div className="card flex justify-content-center">
            <Toast ref={toast}></Toast>
            <SplitButton label="Save" icon="pi pi-plus" onClick={save} model={items} outlined />
            <SplitButton label="Save" icon="pi pi-plus" onClick={save} model={items} severity="secondary" outlined />
            <SplitButton label="Save" icon="pi pi-plus" onClick={save} model={items} severity="success" outlined />
            <SplitButton label="Save" icon="pi pi-plus" onClick={save} model={items} severity="info" outlined />
            <SplitButton label="Save" icon="pi pi-plus" onClick={save} model={items} severity="warning" outlined />
            <SplitButton label="Save" icon="pi pi-plus" onClick={save} model={items} severity="help" outlined />
            <SplitButton label="Save" icon="pi pi-plus" onClick={save} model={items} severity="danger" outlined />
            <SplitButton label="Save" icon="pi pi-plus" onClick={save} model={items} severity="contrast" outlined />
        </div>
    )
}
