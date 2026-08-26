<div className="relative">
    <Button onClick={() => setVisible(true)} label="Show" />
    {visible ? (
        <div ref={overlayRef} className="absolute border-round shadow-2 p-5 surface-overlay z-2 white-space-nowrap scalein origin-top">
            Popup Content
        </div>
    ) : null}
</div>  
