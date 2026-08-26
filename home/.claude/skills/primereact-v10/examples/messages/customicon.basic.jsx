msgs.current.show([
    { sticky: true, severity: 'info', icon: 'pi pi-send', detail: 'Info message' },
    {
        severity: 'success',
        sticky: true,
        content: (
            <React.Fragment>
                <img alt="logo" src="https://primefaces.org/cdn/primereact/images/avatar/amyelsner.png" width="32" />
                <div className="ml-2">How may I help you?</div>
            </React.Fragment>
        )
    }
]);
