<Toast
    ref={toast}
    content={({ message }) => (
        <section className="flex p-3 gap-3 w-full bg-black-alpha-90 shadow-2 fadeindown" style={{ borderRadius: '10px' }}>
            <i className="pi pi-cloud-upload text-primary-500 text-2xl"></i>
            <div className="flex flex-column gap-3 w-full">
                <p className="m-0 font-semibold text-base text-white">{message.summary}</p>
                <p className="m-0 text-base text-700">{message.detail}</p>
                <div className="flex flex-column gap-2">
                    <ProgressBar value={progress} showValue="false"></ProgressBar>
                    <label className="text-right text-xs text-white">{progress}% uploaded...</label>
                </div>
                <div className="flex gap-3 mb-3">
                    <Button label="Another Upload?" text className="p-0" onClick={clear}></Button>
                    <Button label="Cancel" text className="text-white p-0" onClick={clear}></Button>
                </div>
            </div>
        </section>
    )}
></Toast>
<Button onClick={show} label="View" />
