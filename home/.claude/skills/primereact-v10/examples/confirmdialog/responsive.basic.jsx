<Toast ref={toast} />
<ConfirmDialog
    group="declarative"
    visible={visible}
    onHide={() => setVisible(false)}
    message="Are you sure you want to proceed?"
    header="Confirmation"
    icon="pi pi-exclamation-triangle"
    accept={accept}
    reject={reject}
    style={{ width: '50vw' }}
    breakpoints={{ '1100px': '75vw', '960px': '100vw' }}
/>
<Button onClick={() => setVisible(true)} icon="pi pi-check" label="Confirm" />
