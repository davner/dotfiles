import React from 'react'; 
import { FileUpload, FileUploadHandlerEvent } from 'primereact/fileupload';

export default function CustomUploadDemo() {
    const customBase64Uploader = async (event: FileUploadHandlerEvent) => {
        // convert file to base64 encoded
        const file = event.files[0];
        const reader = new FileReader();
        let blob = await fetch(file.objectURL).then((r) => r.blob()); //blob:url

        reader.readAsDataURL(blob);

        reader.onloadend = function () {
            const base64data = reader.result;
        };
    };

    return (
        <div className="card flex justify-content-center">
            <FileUpload mode="basic" name="demo[]" url="/api/upload" accept="image/*" customUpload uploadHandler={customBase64Uploader} />
        </div>
    )
}
