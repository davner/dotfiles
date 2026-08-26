<ul className="m-0 p-0 list-none border-1 surface-border border-round p-3 flex flex-column gap-2 w-full md:w-30rem">
    {users.map((user) => (
        <li
            key={user.id}
            className={`p-2 hover:surface-hover border-round border-1 border-transparent transition-all transition-duration-200 flex align-items-center justify-content-between ${selectedUser?.id === user.id && 'border-primary'}`}
            onContextMenu={(event) => onRightClick(event, user)}
        >
            <div className="flex align-items-center gap-2">
                <img alt="user.name" src={`https://primefaces.org/cdn/primereact/images/avatar/${user.image}`} style={{ width: '32px' }} />
                <span className="font-bold">{user.name}</span>
            </div>
            <Tag value={user.role} severity={getBadge(user)} />
        </li>
    ))}
</ul>
<ContextMenu ref={cm} model={items} onHide={() => setSelectedUser(undefined)} />
<Toast ref={toast} />
