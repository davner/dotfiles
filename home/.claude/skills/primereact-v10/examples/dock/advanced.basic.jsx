<Tooltip className="dark-tooltip" target=".dock-advanced .p-dock-action" my="center+15 bottom-15" at="center top" showDelay={150} />
<Menubar model={menubarItems} start={start} end={end} />
<div className="dock-window dock-advanced">
    <Toast ref={toast} />
    <Toast ref={toast2} position="top-center" />
    <Dock model={dockItems} />
    <Dialog visible={displayTerminal} breakpoints={{ '960px': '50vw', '600px': '75vw' }} style={{ width: '30vw' }} onHide={() => setDisplayTerminal(false)} maximizable blockScroll={false}>
        <Terminal welcomeMessage="Welcome to PrimeReact (cmd: 'date', 'greet {0}', 'random' and 'clear')" prompt="primereact $" />
    </Dialog>
    <Dialog visible={displayFinder} breakpoints={{ '960px': '50vw', '600px': '75vw' }} style={{ width: '30vw', height: '18rem' }} onHide={() => setDisplayFinder(false)} maximizable blockScroll={false}>
        <Tree value={nodes} />
    </Dialog>
    <Galleria ref={galleria} value={images} responsiveOptions={responsiveOptions} numVisible={2} style={{ width: '400px' }}
        circular fullScreen showThumbnails={false} showItemNavigators item={itemTemplate} />
</div>
