<Toast ref={toast} />
<ConfirmPopup
    group="headless"
    content={({message, acceptBtnRef, rejectBtnRef, hide}) => 
        <div className="bg-gray-900 text-white border-round p-3">
            <span>{message}</span>
            <div className="flex align-items-center gap-2 mt-3">
                <Button ref={acceptBtnRef} label="Save" onClick={() => {accept(); hide();}} className="p-button-sm p-button-outlined"></Button>
                <Button ref={rejectBtnRef} label="Cancel" outlined onClick={() => {reject(); hide();}}className="p-button-sm p-button-text"></Button>
            </div>
        </div>
    }
/>
<div className="card flex flex-wrap gap-2 justify-content-center">
    <Button onClick={confirm1} icon="pi pi-check" label="Confirm"></Button>
    <Button onClick={confirm2} icon="pi pi-times" label="Delete" className="p-button-danger"></Button>
</div>
