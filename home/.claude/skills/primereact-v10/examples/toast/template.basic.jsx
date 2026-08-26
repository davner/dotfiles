toastBC.current.show({
    severity: 'success',
    summary: 'Can you send me the report?',
    sticky: true,
    content: (props) => (
        <div className="flex flex-column align-items-left" style={{ flex: '1' }}>
            <div className="flex align-items-center gap-2">
                <Avatar image="/images/avatar/amyelsner.png" shape="circle" />
                <span className="font-bold text-900">Amy Elsner</span>
            </div>
            <div className="font-medium text-lg my-3 text-900">{props.message.summary}</div>
            <Button className="p-button-sm flex" label="Reply" severity="success" onClick={clear}></Button>
        </div>
    )
});