<Toast ref={toast}></Toast>

<Tooltip target=".custom-choose-btn" content="Choose" position="bottom" />
<Tooltip target=".custom-upload-btn" content="Upload" position="bottom" />
<Tooltip target=".custom-cancel-btn" content="Clear" position="bottom" />

<FileUpload ref={fileUploadRef} name="demo[]" url="/api/upload" multiple accept="image/*" maxFileSize={1000000}
    onUpload={onTemplateUpload} onSelect={onTemplateSelect} onError={onTemplateClear} onClear={onTemplateClear}
    headerTemplate={headerTemplate} itemTemplate={itemTemplate} emptyTemplate={emptyTemplate}
    chooseOptions={chooseOptions} uploadOptions={uploadOptions} cancelOptions={cancelOptions} />
