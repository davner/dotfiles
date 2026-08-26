<span className="inline-flex align-items-center justify-content-center border-2 border-primary border-round w-4rem h-4rem" onContextMenu={(event) => onRightClick(event)} aria-haspopup="true">
    <img alt="logo" src="https://primefaces.org/cdn/primereact/images/logo.png" height="40"></img>
</span>
<ContextMenu model={items} ref={cm} />