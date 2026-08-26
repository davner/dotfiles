<Toast ref={toast} />
<ConfirmDialog group="declarative"  visible={visible} onHide={() => setVisible(false)} message="Are you sure you want to proceed?" 
    header="Confirmation" icon="pi pi-exclamation-triangle" accept={accept} reject={reject} />
<Button onClick={() => setVisible(true)} icon="pi pi-check" label="Confirm" />
