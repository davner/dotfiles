<Toast ref={toast} />
<ConfirmPopup target={buttonEl.current} visible={visible} onHide={() => setVisible(false)} 
    message="Are you sure you want to proceed?" icon="pi pi-exclamation-triangle" accept={accept} reject={reject} />
<Button ref={buttonEl} onClick={() => setVisible(true)} icon="pi pi-check" label="Confirm" />
