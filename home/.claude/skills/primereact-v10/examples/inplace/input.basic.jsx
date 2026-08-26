 <Inplace closable>
    <InplaceDisplay>{text || 'Click to Edit'}</InplaceDisplay>
    <InplaceContent>
        <InputText value={text} onChange={(e) => setText(e.target.value)} autoFocus />
    </InplaceContent>
</Inplace>
