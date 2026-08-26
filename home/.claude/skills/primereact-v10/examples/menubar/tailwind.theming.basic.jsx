const Tailwind = {
    menubar: {
        root: {
            className: classNames('p-2 bg-gray-100 dark:bg-gray-900 border border-gray-300 dark:border-blue-900/40 rounded-md', 'flex items-center relative')
        },
        menu: ({ state }) => ({
            className: classNames(
                'm-0 sm:p-0 list-none',
                'outline-none',
                'sm:flex items-center flex-wrap sm:flex-row sm:top-auto sm:left-auto sm:relative sm:bg-transparent sm:shadow-none sm:w-auto',
                'flex-col top-full left-0',
                'absolute py-1 bg-white dark:bg-gray-900 border-0 shadow-md w-full',
                {
                    'hidden ': !state?.mobileActive,
                    'flex ': state?.mobileActive
                }
            )
        }),
        menuitem: ({ props, context }) => ({
            className: classNames(
                'sm:relative sm:w-auto w-full static',
                'transition-shadow duration-200',
                { 'rounded-md': props.root },
                {
                    'text-gray-700 dark:text-white/80': !context.active,
                    'bg-blue-50 text-blue-700 dark:bg-blue-300 dark:text-white/80': context.active
                },
                {
                    'hover:text-gray-700 dark:hover:text-white/80 hover:bg-gray-200 dark:hover:bg-gray-800/80': !context.active,
                    'hover:bg-blue-200 dark:hover:bg-blue-500': context.active
                }
            )
        }),
        action: ({ context }) => ({
            className: classNames('select-none', 'cursor-pointer flex items-center no-underline overflow-hidden relative', 'py-3 px-5 select-none', {
                'pl-9 sm:pl-5': context.level === 1,
                'pl-14 sm:pl-5': context.level === 2
            })
        }),
        icon: 'mr-2',
        submenuicon: ({ props }) => ({
            className: classNames({
                'ml-auto sm:ml-2': props.root,
                'ml-auto': !props.root
            })
        }),
        submenu: ({ props }) => ({
            className: classNames('py-1 bg-white dark:bg-gray-900 border-0  sm:shadow-md sm:w-48', 'w-full static shadow-none', 'sm:absolute z-10', 'm-0 list-none', {
                'sm:absolute sm:left-full sm:top-0': !props.root
            })
        }),
        separator: 'border-t border-gray-300 dark:border-blue-900/40 my-1',
        button: {
            className: classNames(
                'flex sm:hidden w-8 h-8 rounded-full text-gray-600 dark:text-white/80 transition duration-200 ease-in-out',
                'cursor-pointer flex items-center justify-center no-underline',
                'hover:text-gray-700 dark:hover:text-white/80 hover:bg-gray-200 dark:hover:bg-gray-800/80 ',
                'focus:outline-none focus:outline-offset-0 focus:shadow-[0_0_0_0.2rem_rgba(191,219,254,1)] dark:focus:shadow-[0_0_0_0.2rem_rgba(147,197,253,0.5)]'
            )
        }
    }
}
