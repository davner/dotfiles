<div className="mb-3">
    <Button label="Block" onClick={() => setBlocked(true)} className="mr-2"></Button>
    <Button label="Unblock" onClick={() => setBlocked(false)} severity="secondary"></Button>
</div>
<BlockUI blocked={blocked}>
    <Panel header="Basic">
        <p className="m-0">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
            consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est
            laborum.
        </p>
    </Panel>
</BlockUI>
