<Button label="Login" icon="pi pi-user" onClick={() => setVisible(true)} />
<Dialog
    visible={visible}
    modal
    onHide={() => {if (!visible) return; setVisible(false); }}
    content={({ hide }) => (
        <div className="flex flex-column px-8 py-5 gap-4" style={{ borderRadius: '12px', backgroundImage: 'radial-gradient(circle at left top, var(--primary-400), var(--primary-700))' }}>
            <...>
        </div>
    )}
></Dialog>
