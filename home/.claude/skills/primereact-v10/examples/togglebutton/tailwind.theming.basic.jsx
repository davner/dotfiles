const Tailwind = {
    togglebutton: {
        root: ({ props }) => ({
            className: classNames(
                'inline-flex cursor-pointer select-none items-center align-bottom text-center overflow-hidden relative',
                'px-4 py-3 rounded-md text-base w-36',
                'border transition duration-200 ease-in-out',
                {
                    'bg-white dark:bg-gray-900 border-gray-300 dark:border-blue-900/40 text-gray-700 dark:text-white/80 hover:bg-gray-100 dark:hover:bg-gray-800/80 hover:border-gray-300 dark:hover:bg-gray-800/70 hover:text-gray-700 dark:hover:text-white/80':
                        !props.checked,
                    'bg-blue-500 border-blue-500 text-white hover:bg-blue-600 hover:border-blue-600': props.checked
                },
                { 'opacity-60 select-none pointer-events-none cursor-default': props.disabled }
            )
        }),
        label: 'font-bold text-center w-full',
        icon: ({ props }) => ({
            className: classNames(' mr-2', {
                'text-gray-600 dark:text-white/70': !props.checked,
                'text-white': props.checked
            })
        })
    }
}
