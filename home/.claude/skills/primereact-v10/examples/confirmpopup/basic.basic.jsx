<Toast ref={toast} />
<ConfirmPopup />
<div className="card flex flex-wrap gap-2 justify-content-center">
    <Button onClick={confirm1} icon="pi pi-check" label="Confirm"></Button>
    <Button onClick={confirm2} icon="pi pi-times" label="Delete" className="p-button-danger"></Button>
</div>
